using System.Security.Claims;
using LiveTracking.Api.Data;
using LiveTracking.Api.DTOs;
using LiveTracking.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class AdminController : ControllerBase
{
    private readonly LiveTrackingDbContext _db;

    public AdminController(LiveTrackingDbContext db)
    {
        _db = db;
    }

    private int GetCurrentUserId()
    {
        var claim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value
                    ?? User.FindFirst("sub")?.Value;
        return int.TryParse(claim, out var id) ? id : 0;
    }

    private async Task<List<int>> GetAdminAssignedOfficeIdsAsync(int adminId)
    {
        if (adminId <= 0) return new List<int>();

        var assignedIds = await _db.AdminOfficeLocations
            .Where(a => a.AdminUserId == adminId)
            .Select(a => a.OfficeLocationId)
            .ToListAsync();

        if (assignedIds.Count == 0)
        {
            var singleOfficeId = await _db.Users
                .Where(u => u.UserId == adminId)
                .Select(u => u.OfficeLocationId)
                .FirstOrDefaultAsync();

            if (singleOfficeId.HasValue)
            {
                assignedIds.Add(singleOfficeId.Value);
            }
        }

        return assignedIds;
    }

    private async Task<List<int>> GetAccessibleEmployeeUserIdsAsync(int adminId)
    {
        var admin = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.UserId == adminId);
        int? companyId = admin?.CompanyId;
        var assignedOfficeIds = await GetAdminAssignedOfficeIdsAsync(adminId);
        var query = _db.Users.Where(u => u.Role != "Admin");

        if (companyId.HasValue && companyId.Value > 0)
        {
            query = query.Where(u => u.CompanyId == companyId.Value);
        }

        if (assignedOfficeIds.Count > 0)
        {
            query = query.Where(u => u.OfficeLocationId.HasValue && assignedOfficeIds.Contains(u.OfficeLocationId.Value));
        }

        return await query.Select(u => u.UserId).ToListAsync();
    }

    [HttpGet("office-locations")]
    public async Task<ActionResult<List<OfficeLocation>>> GetOfficeLocations([FromQuery] bool all = false)
    {
        var currentAdminId = GetCurrentUserId();
        var currentAdmin = currentAdminId > 0 ? await _db.Users.FindAsync(currentAdminId) : null;
        int? targetCompanyId = currentAdmin?.CompanyId;
        var assignedOfficeIds = await GetAdminAssignedOfficeIdsAsync(currentAdminId);

        var query = _db.OfficeLocations.AsQueryable();

        if (targetCompanyId.HasValue)
        {
            query = query.Where(o => o.CompanyId == targetCompanyId.Value || o.CompanyId == null);
        }

        if (!all)
        {
            query = query.Where(o => o.IsActive);
            // If user is regular admin with assigned offices, filter to their assigned offices
            if (assignedOfficeIds.Count > 0)
            {
                query = query.Where(o => assignedOfficeIds.Contains(o.OfficeLocationId));
            }
        }

        var locations = await query
            .OrderBy(o => o.Name)
            .ToListAsync();

        return Ok(locations);
    }

    [HttpGet("office-locations/{id:int}")]
    public async Task<ActionResult<OfficeLocation>> GetOfficeLocationById(int id)
    {
        var location = await _db.OfficeLocations.FindAsync(id);
        if (location == null) return NotFound(new { message = "Office location not found." });
        return Ok(location);
    }

    [HttpPost("office-locations")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<OfficeLocation>> CreateOfficeLocation([FromBody] CreateOfficeLocationRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.Name))
            return BadRequest(new { message = "Office name is required." });

        var currentAdminId = GetCurrentUserId();
        var currentAdmin = currentAdminId > 0 ? await _db.Users.FindAsync(currentAdminId) : null;
        int? targetCompanyId = currentAdmin?.CompanyId;

        var location = new OfficeLocation
        {
            Name = request.Name.Trim(),
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            RadiusMeters = request.RadiusMeters > 0 ? request.RadiusMeters : 200.0,
            Address = request.Address?.Trim(),
            CompanyId = targetCompanyId,
            IsActive = true,
            CreatedAtUtc = DateTime.UtcNow
        };

        _db.OfficeLocations.Add(location);
        await _db.SaveChangesAsync();

        // Automatically associate the newly created office with the creating admin so they immediately see and can assign users to it
        if (currentAdminId > 0)
        {
            var alreadyAssigned = await _db.AdminOfficeLocations
                .AnyAsync(a => a.AdminUserId == currentAdminId && a.OfficeLocationId == location.OfficeLocationId);
            if (!alreadyAssigned)
            {
                _db.AdminOfficeLocations.Add(new AdminOfficeLocation
                {
                    AdminUserId = currentAdminId,
                    OfficeLocationId = location.OfficeLocationId,
                    AssignedAtUtc = DateTime.UtcNow
                });
                await _db.SaveChangesAsync();
            }
        }

        return CreatedAtAction(nameof(GetOfficeLocationById), new { id = location.OfficeLocationId }, location);
    }

    [HttpPut("office-locations/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<OfficeLocation>> UpdateOfficeLocation(int id, [FromBody] UpdateOfficeLocationRequest request)
    {
        var location = await _db.OfficeLocations.FindAsync(id);
        if (location == null) return NotFound(new { message = "Office location not found." });

        if (!string.IsNullOrWhiteSpace(request.Name)) location.Name = request.Name.Trim();
        location.Latitude = request.Latitude;
        location.Longitude = request.Longitude;
        if (request.RadiusMeters > 0) location.RadiusMeters = request.RadiusMeters;
        if (request.Address != null) location.Address = request.Address.Trim();
        location.IsActive = request.IsActive;

        await _db.SaveChangesAsync();
        return Ok(location);
    }

    [HttpDelete("office-locations/{id:int}")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> DeleteOfficeLocation(int id)
    {
        var location = await _db.OfficeLocations.FindAsync(id);
        if (location == null) return NotFound(new { message = "Office location not found." });

        location.IsActive = false;
        await _db.SaveChangesAsync();
        return Ok(new { message = "Office location deactivated successfully." });
    }

    [HttpGet("summary")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<ExecutiveSummaryDto>> GetExecutiveSummary()
    {
        var currentAdminId = GetCurrentUserId();
        var accessibleUserIds = await GetAccessibleEmployeeUserIdsAsync(currentAdminId);

        var nowUtc = DateTime.UtcNow;
        // Bangladesh local date (UTC+6)
        var todayLocalDate = nowUtc.AddHours(6).Date;
        var todayStartUtc = todayLocalDate.AddHours(-6);
        var tomorrowStartUtc = todayStartUtc.AddDays(1);
        var cutoff15m = nowUtc.AddMinutes(-15);

        var totalUsers = accessibleUserIds.Count;
        var activeUsers = await _db.Users.CountAsync(u => accessibleUserIds.Contains(u.UserId) && u.IsActive);

        // Drivers with location pings in last 15 minutes
        var recentPings = await _db.DriverLocations
            .Where(l => accessibleUserIds.Contains(l.UserId) && l.RecordedAtUtc >= cutoff15m)
            .Select(l => l.UserId)
            .Distinct()
            .ToListAsync();
        var onlineTrackingUsers = recentPings.Count;

        // Today's attendance records
        var todayAttendance = await _db.AttendanceRecords
            .Include(a => a.User)
            .Where(a => accessibleUserIds.Contains(a.UserId) && a.RecordedAtUtc >= todayStartUtc && a.RecordedAtUtc < tomorrowStartUtc)
            .OrderByDescending(a => a.RecordedAtUtc)
            .ToListAsync();

        var inPunches = todayAttendance
            .Where(a => a.Type.Equals("In", StringComparison.OrdinalIgnoreCase))
            .ToList();

        // Unique users who punched in today
        var punchedInUserIds = inPunches.Select(a => a.UserId).Distinct().ToList();
        var todayPunchInCount = punchedInUserIds.Count;

        // Late punches today (grouped by unique user)
        var lateUserIds = inPunches
            .Where(a => !string.IsNullOrEmpty(a.Status) && a.Status.StartsWith("Late", StringComparison.OrdinalIgnoreCase))
            .Select(a => a.UserId)
            .Distinct()
            .ToList();
        var todayLateCount = lateUserIds.Count;
        var todayOnTimeCount = Math.Max(0, todayPunchInCount - todayLateCount);

        // Users on approved leave today (local date between StartDate and EndDate)
        var approvedLeavesToday = await _db.LeaveApplications
            .Where(l => accessibleUserIds.Contains(l.UserId) 
                     && l.Status != null && l.Status.ToLower() == "approved"
                     && l.StartDate.Date <= todayLocalDate && l.EndDate.Date >= todayLocalDate)
            .Select(l => l.UserId)
            .Distinct()
            .ToListAsync();
        var todayOnLeaveCount = approvedLeavesToday.Count;

        // Today absent: active users who did not punch in and are not on approved leave today
        var todayAbsentCount = Math.Max(0, activeUsers - todayPunchInCount - todayOnLeaveCount);

        var todayAttendanceRate = activeUsers > 0 ? (todayPunchInCount * 100) / activeUsers : (todayPunchInCount > 0 ? 100 : 0);

        // Pending Leave Applications
        var pendingLeaveRequestsCount = await _db.LeaveApplications
            .CountAsync(l => accessibleUserIds.Contains(l.UserId) && l.Status != null && l.Status.ToLower() == "pending");

        // Pending Follow ups
        var pendingCustomerFollowUpsCount = await _db.CustomerVisits
            .CountAsync(v => accessibleUserIds.Contains(v.UserId) && v.NextFollowUpDate.HasValue && !v.IsFollowUpCompleted);

        // GPS Disabled or no update today among active users
        var gpsDisabledUsersCount = Math.Max(0, activeUsers - onlineTrackingUsers);

        // Attention items
        var attentionItems = new List<AttentionItemDto>();
        var pendingLeaves = await _db.LeaveApplications
            .Include(l => l.User)
            .Include(l => l.LeaveType)
            .Where(l => accessibleUserIds.Contains(l.UserId) && l.Status != null && l.Status.ToLower() == "pending")
            .OrderByDescending(l => l.AppliedAtUtc)
            .Take(5)
            .ToListAsync();

        foreach (var leave in pendingLeaves)
        {
            var uName = leave.User?.FullName ?? leave.User?.Username ?? "Employee";
            attentionItems.Add(new AttentionItemDto(
                $"leave_{leave.LeaveApplicationId}",
                "PendingLeave",
                $"Leave Request: {uName}",
                $"{leave.LeaveType?.Name ?? "Leave"} ({leave.TotalDays} day(s)) from {leave.StartDate:yyyy-MM-dd}",
                leave.UserId,
                uName,
                "Medium",
                "Approve",
                leave.AppliedAtUtc.ToString("o")
            ));
        }

        var overdueVisits = await _db.CustomerVisits
            .Include(v => v.Customer)
            .Include(v => v.User)
            .Where(v => accessibleUserIds.Contains(v.UserId) && v.NextFollowUpDate.HasValue && !v.IsFollowUpCompleted)
            .OrderBy(v => v.NextFollowUpDate)
            .Take(5)
            .ToListAsync();

        foreach (var visit in overdueVisits)
        {
            var uName = visit.User?.FullName ?? visit.User?.Username ?? "Executive";
            attentionItems.Add(new AttentionItemDto(
                $"visit_{visit.VisitId}",
                "MissedFollowUp",
                $"Follow-up: {visit.Customer?.Name ?? "Customer"}",
                $"Assigned to {uName}. Remarks: {visit.Remarks ?? "Action required"}",
                visit.UserId,
                uName,
                "High",
                "Call",
                visit.VisitDate.ToString("o")
            ));
        }

        // 3. Collect Daily Activities (ONLY for TODAY)
        var dailyActivities = new List<DashboardDailyActivityDto>();

        // Attendance activities today
        foreach (var att in todayAttendance)
        {
            var uName = att.User?.FullName ?? att.User?.Username ?? "Officer";
            var isPunchIn = string.Equals(att.Type, "In", StringComparison.OrdinalIgnoreCase);
            var locInfo = att.IsWithinGeofence ? "Within Office" : "Outside Office";
            var localTimeStr = att.RecordedAtUtc.AddHours(6).ToString("hh:mm tt");

            dailyActivities.Add(new DashboardDailyActivityDto(
                isPunchIn ? "DUTY_IN" : "DUTY_OUT",
                $"{uName} completed duty {(isPunchIn ? "in" : "out")}",
                $"Geofence: {locInfo} • Status: {att.Status ?? (isPunchIn ? "On Time" : "Completed")}",
                localTimeStr,
                isPunchIn ? "DUTY IN" : "DUTY OUT",
                isPunchIn ? "#059669" : "#E11D48",
                att.UserId,
                uName,
                att.RecordedAtUtc.ToString("o")
            ));
        }

        // Visits recorded today
        var todayVisits = await _db.CustomerVisits
            .Include(v => v.Customer)
            .Include(v => v.User)
            .Where(v => accessibleUserIds.Contains(v.UserId) && v.VisitDate >= todayStartUtc && v.VisitDate < tomorrowStartUtc)
            .OrderByDescending(v => v.VisitDate)
            .ToListAsync();

        foreach (var v in todayVisits)
        {
            var uName = v.User?.FullName ?? v.User?.Username ?? "Officer";
            var custName = v.Customer?.Name ?? "Customer";
            var localTimeStr = v.VisitDate.AddHours(6).ToString("hh:mm tt");
            var remarks = string.IsNullOrWhiteSpace(v.Remarks) ? "Visit completed" : v.Remarks;

            dailyActivities.Add(new DashboardDailyActivityDto(
                "VISIT",
                $"{uName} visited {custName}",
                remarks,
                localTimeStr,
                "VISIT",
                "#2563EB",
                v.UserId,
                uName,
                v.VisitDate.ToString("o")
            ));
        }

        // Leave applications submitted today
        var todayLeaveApps = await _db.LeaveApplications
            .Include(l => l.User)
            .Include(l => l.LeaveType)
            .Where(l => accessibleUserIds.Contains(l.UserId) && l.AppliedAtUtc >= todayStartUtc && l.AppliedAtUtc < tomorrowStartUtc)
            .OrderByDescending(l => l.AppliedAtUtc)
            .ToListAsync();

        foreach (var l in todayLeaveApps)
        {
            var uName = l.User?.FullName ?? l.User?.Username ?? "Officer";
            var localTimeStr = l.AppliedAtUtc.AddHours(6).ToString("hh:mm tt");

            dailyActivities.Add(new DashboardDailyActivityDto(
                "LEAVE",
                $"{uName} applied for {l.LeaveType?.Name ?? "Leave"}",
                $"Reason: {l.Reason ?? "Personal"} • Status: {l.Status}",
                localTimeStr,
                "LEAVE",
                "#F59E0B",
                l.UserId,
                uName,
                l.AppliedAtUtc.ToString("o")
            ));
        }

        // Sort all daily activities descending by timestamp and take top 25
        dailyActivities = dailyActivities
            .OrderByDescending(a => DateTime.TryParse(a.TimestampUtc, out var dt) ? dt : DateTime.MinValue)
            .Take(25)
            .ToList();

        // 4. Collect Weekly Velocity (Past 7 Days for ALL accessible users)
        var weeklyVelocity = new List<WeeklyVelocityDayDto>();
        var sevenDaysStartUtc = todayLocalDate.AddDays(-6).AddHours(-6);

        var past7DaysVisits = await _db.CustomerVisits
            .Where(v => accessibleUserIds.Contains(v.UserId) && v.VisitDate >= sevenDaysStartUtc && v.VisitDate < tomorrowStartUtc)
            .Select(v => v.VisitDate)
            .ToListAsync();

        var past7DaysFollowUps = await _db.CustomerVisits
            .Where(v => accessibleUserIds.Contains(v.UserId) 
                     && v.NextFollowUpDate.HasValue 
                     && v.NextFollowUpDate.Value >= sevenDaysStartUtc 
                     && v.NextFollowUpDate.Value < tomorrowStartUtc)
            .Select(v => v.NextFollowUpDate!.Value)
            .ToListAsync();

        for (int i = 6; i >= 0; i--)
        {
            var dayLocal = todayLocalDate.AddDays(-i);
            var dayStartUtc = dayLocal.AddHours(-6);
            var dayEndUtc = dayStartUtc.AddDays(1);
            var dayLabel = (i == 0) ? "Today" : dayLocal.ToString("ddd");
            var datePrefix = dayLocal.ToString("yyyy-MM-dd");

            var vCount = past7DaysVisits.Count(v => v >= dayStartUtc && v < dayEndUtc);
            var fCount = past7DaysFollowUps.Count(f => f >= dayStartUtc && f < dayEndUtc);

            weeklyVelocity.Add(new WeeklyVelocityDayDto(dayLabel, datePrefix, vCount, fCount));
        }

        // System Health
        var health = new SystemHealthDto(
            "Healthy",
            "Connected",
            onlineTrackingUsers,
            nowUtc.ToString("o")
        );

        return Ok(new ExecutiveSummaryDto(
            totalUsers,
            activeUsers,
            onlineTrackingUsers,
            todayPunchInCount,
            todayAbsentCount,
            todayLateCount,
            pendingLeaveRequestsCount,
            pendingCustomerFollowUpsCount,
            gpsDisabledUsersCount,
            attentionItems,
            health,
            todayOnTimeCount,
            todayOnLeaveCount,
            todayAttendanceRate,
            dailyActivities,
            weeklyVelocity
        ));
    }

    [HttpGet("reports/employee-performance")]
    [Authorize(Roles = "Admin")]
    public async Task<ActionResult<MonthlyPerformanceReportResponse>> GetEmployeePerformanceReport(
        [FromQuery] int? year = null,
        [FromQuery] int? month = null,
        [FromQuery] int? userId = null)
    {
        var currentAdminId = GetCurrentUserId();
        var accessibleUserIds = await GetAccessibleEmployeeUserIdsAsync(currentAdminId);

        var now = DateTime.UtcNow;
        int targetYear = (year.HasValue && year.Value >= 2000 && year.Value <= 2100) ? year.Value : now.Year;
        int targetMonth = (month.HasValue && month.Value >= 1 && month.Value <= 12) ? month.Value : now.Month;

        var startDateUtc = new DateTime(targetYear, targetMonth, 1, 0, 0, 0, DateTimeKind.Utc);
        var endDateUtc = startDateUtc.AddMonths(1);

        var usersQuery = _db.Users.AsQueryable();
        if (userId.HasValue && userId.Value > 0)
        {
            usersQuery = usersQuery.Where(u => u.UserId == userId.Value && accessibleUserIds.Contains(u.UserId));
        }
        else
        {
            usersQuery = usersQuery.Where(u => accessibleUserIds.Contains(u.UserId) && u.Role != "Admin");
        }

        var targetUsers = await usersQuery
            .OrderBy(u => u.FullName ?? u.Username)
            .ToListAsync();

        var targetUserIds = targetUsers.Select(u => u.UserId).ToList();

        // 1. Visits in this month
        var visits = await _db.CustomerVisits
            .Include(v => v.Customer)
            .Where(v => targetUserIds.Contains(v.UserId) && v.VisitDate >= startDateUtc && v.VisitDate < endDateUtc)
            .OrderByDescending(v => v.VisitDate)
            .ToListAsync();

        // 2. Follow-ups scheduled or created in this month
        var followUps = await _db.CustomerVisits
            .Include(v => v.Customer)
            .Where(v => targetUserIds.Contains(v.UserId) 
                     && v.NextFollowUpDate.HasValue 
                     && v.NextFollowUpDate.Value >= startDateUtc 
                     && v.NextFollowUpDate.Value < endDateUtc)
            .OrderBy(v => v.NextFollowUpDate)
            .ToListAsync();

        // 3. Customers created by users in this month
        var customers = await _db.Customers
            .Where(c => c.CreatedByUserId.HasValue 
                     && targetUserIds.Contains(c.CreatedByUserId.Value)
                     && c.CreatedDate >= startDateUtc 
                     && c.CreatedDate < endDateUtc)
            .ToListAsync();

        var employeeReports = new List<EmployeePerformanceItemDto>();

        foreach (var user in targetUsers)
        {
            var uVisits = visits.Where(v => v.UserId == user.UserId).ToList();
            var uFollowUps = followUps.Where(v => v.UserId == user.UserId).ToList();
            var uCustomers = customers.Where(c => c.CreatedByUserId == user.UserId).ToList();

            var completedFollowUps = uFollowUps.Count(f => f.IsFollowUpCompleted);
            var pendingFollowUps = uFollowUps.Count(f => !f.IsFollowUpCompleted);

            employeeReports.Add(new EmployeePerformanceItemDto
            {
                UserId = user.UserId,
                FullName = user.FullName ?? user.Username,
                Username = user.Username,
                Role = user.Role,
                IsActive = user.IsActive,
                TotalCustomersAdded = uCustomers.Count,
                TotalVisits = uVisits.Count,
                TotalFollowUps = uFollowUps.Count,
                CompletedFollowUps = completedFollowUps,
                PendingFollowUps = pendingFollowUps,
                Customers = uCustomers.Select(c => new ReportCustomerItemDto
                {
                    CustomerId = c.CustomerId,
                    Name = c.Name,
                    Mobile = c.Mobile,
                    Address = c.Address,
                    CreatedDate = c.CreatedDate,
                    Remarks = c.Remarks
                }).ToList(),
                Visits = uVisits.Select(v => new ReportVisitItemDto
                {
                    VisitId = v.VisitId,
                    CustomerId = v.CustomerId,
                    CustomerName = v.Customer?.Name ?? "Unknown",
                    CustomerMobile = v.Customer?.Mobile ?? "",
                    CustomerAddress = v.Customer?.Address ?? "",
                    VisitDate = v.VisitDate,
                    Remarks = v.Remarks,
                    VisitStatus = v.VisitStatus,
                    ShopPhotoPath = v.ShopPhotoPath
                }).ToList(),
                FollowUps = uFollowUps.Select(f => new ReportFollowUpItemDto
                {
                    VisitId = f.VisitId,
                    CustomerId = f.CustomerId,
                    CustomerName = f.Customer?.Name ?? "Customer",
                    CustomerMobile = f.Customer?.Mobile ?? "",
                    FollowUpDate = f.NextFollowUpDate,
                    IsCompleted = f.IsFollowUpCompleted,
                    Remarks = f.Remarks
                }).ToList()
            });
        }

        var monthName = new DateTime(targetYear, targetMonth, 1).ToString("MMMM yyyy");

        var response = new MonthlyPerformanceReportResponse
        {
            Year = targetYear,
            Month = targetMonth,
            MonthName = monthName,
            TotalVisits = visits.Count,
            TotalFollowUps = followUps.Count,
            CompletedFollowUps = followUps.Count(f => f.IsFollowUpCompleted),
            PendingFollowUps = followUps.Count(f => !f.IsFollowUpCompleted),
            TotalCustomersAdded = customers.Count,
            Employees = employeeReports
        };

        return Ok(response);
    }
}
