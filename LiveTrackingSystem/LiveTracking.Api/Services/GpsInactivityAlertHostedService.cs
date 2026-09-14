using LiveTracking.Api.Data;
using LiveTracking.Api.DTOs;
using LiveTracking.Api.Hubs;
using LiveTracking.Api.Models;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Api.Services;

/// <summary>
/// Background hosted service that monitors on-duty field employees.
/// If an employee on active duty within company shift does not send any GPS location to the server
/// within 10 minutes, an automated high-priority alert notification is dispatched
/// to company admins via SignalR and stored in the database.
/// </summary>
public class GpsInactivityAlertHostedService : BackgroundService
{
    private readonly IServiceProvider _services;
    private readonly ILogger<GpsInactivityAlertHostedService> _logger;
    private const int InactivityThresholdMinutes = 10;
    private const int ReminderCooldownHours = 1;

    public GpsInactivityAlertHostedService(
        IServiceProvider services,
        ILogger<GpsInactivityAlertHostedService> logger)
    {
        _services = services;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInformation("GpsInactivityAlertHostedService is starting (10-minute threshold, 2-minute check loop).");

        // Brief delay to allow API and database context to initialize
        await Task.Delay(TimeSpan.FromSeconds(15), stoppingToken);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                await CheckGpsInactivityAndAlertAdminsAsync();
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error occurred during GPS inactivity checking.");
            }

            // Run check every 2 minutes for fast 10-minute threshold detection
            await Task.Delay(TimeSpan.FromMinutes(2), stoppingToken);
        }

        _logger.LogInformation("GpsInactivityAlertHostedService is stopping.");
    }

    private async Task CheckGpsInactivityAndAlertAdminsAsync()
    {
        using var scope = _services.CreateScope();
        var db = scope.ServiceProvider.GetRequiredService<LiveTrackingDbContext>();
        var hub = scope.ServiceProvider.GetRequiredService<IHubContext<LocationHub>>();

        var nowUtc = DateTime.UtcNow;
        var todayBd = nowUtc.AddHours(6).Date;
        var todayStartUtc = todayBd.AddHours(-6);
        var todayEndUtc = todayStartUtc.AddDays(1);
        var localTimeOfDay = nowUtc.AddHours(6).TimeOfDay;

        var companies = await db.Companies
            .AsNoTracking()
            .Where(c => c.IsActive)
            .ToListAsync();

        foreach (var company in companies)
        {
            // 1. Fetch active field employees of this company
            var activeEmployees = await db.Users
                .AsNoTracking()
                .Include(u => u.Shift)
                .Where(u => u.CompanyId == company.CompanyId && u.Role != "Admin" && u.IsActive)
                .ToListAsync();

            if (activeEmployees.Count == 0) continue;

            var employeeIds = activeEmployees.Select(e => e.UserId).ToList();

            // 2. Fetch today's attendance records for these employees
            var attendanceToday = await db.AttendanceRecords
                .AsNoTracking()
                .Where(a => employeeIds.Contains(a.UserId) && a.RecordedAtUtc >= todayStartUtc && a.RecordedAtUtc < todayEndUtc)
                .ToListAsync();

            // 3. Fetch approved leaves for today
            var onLeaveUserIds = await db.LeaveApplications
                .AsNoTracking()
                .Where(l => employeeIds.Contains(l.UserId) && l.Status == "Approved" && l.StartDate <= todayBd && l.EndDate >= todayBd)
                .Select(l => l.UserId)
                .Distinct()
                .ToListAsync();

            // 4. Default company shift as fallback
            var defaultShift = await db.Shifts
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.CompanyId == company.CompanyId && s.IsDefault && s.IsActive)
                ?? await db.Shifts
                .AsNoTracking()
                .FirstOrDefaultAsync(s => s.CompanyId == company.CompanyId && s.IsActive);

            foreach (var employee in activeEmployees)
            {
                // Skip if on approved leave
                if (onLeaveUserIds.Contains(employee.UserId)) continue;

                var userRecords = attendanceToday.Where(a => a.UserId == employee.UserId).ToList();
                var punchIn = userRecords.FirstOrDefault(r => r.Type == "In");
                var punchOut = userRecords.FirstOrDefault(r => r.Type == "Out");

                // If employee already Punched Out today, their duty is completed for the day
                if (punchOut != null) continue;

                // 5. Check Company-wise Shift window
                var shift = employee.Shift ?? defaultShift;
                if (shift == null ||
                    !TimeSpan.TryParse(shift.StartTime, out var shiftStart) ||
                    !TimeSpan.TryParse(shift.EndTime, out var shiftEnd))
                {
                    continue;
                }

                // Strictly verify that current local time is within the employee's / company's shift hours
                bool isWithinShiftHours = false;
                if (shiftStart < shiftEnd)
                {
                    isWithinShiftHours = localTimeOfDay >= shiftStart && localTimeOfDay <= shiftEnd;
                }
                else
                {
                    // Overnight shift (e.g. 20:00 to 04:00)
                    isWithinShiftHours = localTimeOfDay >= shiftStart || localTimeOfDay <= shiftEnd;
                }

                // If currently outside company shift hours, do NOT send offline alerts
                if (!isWithinShiftHours) continue;

                // Determine baseline time for duty start
                DateTime dutyStartTimeUtc = punchIn != null 
                    ? punchIn.RecordedAtUtc 
                    : todayStartUtc.Add(shiftStart);

                // 5. Find the latest GPS location ping for this employee
                var latestPing = await db.DriverLocations
                    .AsNoTracking()
                    .Where(l => l.UserId == employee.UserId)
                    .OrderByDescending(l => l.RecordedAtUtc)
                    .Select(l => new { l.RecordedAtUtc, l.LocationAddress })
                    .FirstOrDefaultAsync();

                DateTime baselineTimeUtc = (latestPing != null && latestPing.RecordedAtUtc >= todayStartUtc)
                    ? latestPing.RecordedAtUtc
                    : dutyStartTimeUtc;

                var inactiveDuration = nowUtc - baselineTimeUtc;
                int inactiveMinutes = (int)inactiveDuration.TotalMinutes;

                // Inactivity threshold: 30+ minutes without a location update
                if (inactiveMinutes < InactivityThresholdMinutes) continue;

                // 6. Anti-Spam / Deduplication:
                // Check if an alert has already been sent for this employee during this offline episode
                var cooldownWindow = nowUtc.AddHours(-ReminderCooldownHours);
                var alreadyAlerted = await db.Notifications
                    .AsNoTracking()
                    .AnyAsync(n =>
                        n.CompanyId == company.CompanyId &&
                        n.Type == "GpsOfflineAlert" &&
                        n.ReferenceId == employee.UserId.ToString() &&
                        n.CreatedAtUtc >= baselineTimeUtc &&
                        n.CreatedAtUtc >= cooldownWindow);

                if (alreadyAlerted) continue;

                // 7. Compose and save alert notification
                var displayName = !string.IsNullOrWhiteSpace(employee.FullName)
                    ? employee.FullName
                    : employee.Username;

                var lastKnownText = latestPing != null && !string.IsNullOrWhiteSpace(latestPing.LocationAddress)
                    ? $" (সর্বশেষ অবস্থান: {latestPing.LocationAddress})"
                    : "";

                var notification = new NotificationItem
                {
                    UserId = null, // Broadcast to all admins of this company
                    CompanyId = company.CompanyId,
                    TargetRole = "Admin",
                    Title = "⚠️ জিপিএস ট্র্যাকিং বিচ্ছিন্ন (GPS Offline Alert)",
                    Message = $"{displayName} শিফট চলাকালীন বিগত {inactiveMinutes} মিনিট ধরে কোনো লোকেশন দিচ্ছেন না (শিফট: {shift.ShiftName}{lastKnownText})। ফোন বন্ধ, ইন্টারনেট অথবা জিপিএস অফ থাকতে পারে।",
                    Type = "GpsOfflineAlert",
                    ReferenceId = employee.UserId.ToString(),
                    IsRead = false,
                    CreatedAtUtc = nowUtc
                };

                db.Notifications.Add(notification);
                await db.SaveChangesAsync();

                _logger.LogWarning(
                    "⚠️ [GPS Alert Triggered] User {UserId} ({UserName}) inactive for {Minutes} mins. Alert sent to Company {CompanyId} admins.",
                    employee.UserId, displayName, inactiveMinutes, company.CompanyId);

                // 8. Push real-time notification to company admins via SignalR
                var notifDto = new NotificationDto
                {
                    NotificationId = notification.NotificationId,
                    UserId = notification.UserId,
                    CompanyId = notification.CompanyId,
                    TargetRole = notification.TargetRole,
                    Title = notification.Title,
                    Message = notification.Message,
                    Type = notification.Type,
                    ReferenceId = notification.ReferenceId,
                    IsRead = false,
                    CreatedAtUtc = notification.CreatedAtUtc
                };

                await hub.Clients.Group(LocationHub.CompanyAdminsGroup(company.CompanyId))
                    .SendAsync("ReceiveNotification", notifDto);
                await hub.Clients.Group(LocationHub.AdminsGroup)
                    .SendAsync("ReceiveNotification", notifDto);
            }
        }
    }
}
