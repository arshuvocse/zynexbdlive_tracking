using System.Security.Claims;
using LiveTracking.Api.Data;
using LiveTracking.Api.DTOs;
using LiveTracking.Api.Hubs;
using LiveTracking.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using NetTopologySuite.Geometries;

namespace LiveTracking.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class LocationsController : ControllerBase
{
    private static readonly GeometryFactory GeometryFactory =
        NetTopologySuite.NtsGeometryServices.Instance.CreateGeometryFactory(srid: 4326);

    private readonly LiveTrackingDbContext _db;
    private readonly IHubContext<LocationHub> _hub;
    private readonly IConfiguration _config;

    public LocationsController(LiveTrackingDbContext db, IHubContext<LocationHub> hub, IConfiguration config)
    {
        _db = db;
        _hub = hub;
        _config = config;
    }

    /// <summary>Called by the driver app's foreground service every 60 seconds.</summary>
    [HttpPost]
    public async Task<IActionResult> PostLocation(LocationUpdateRequest request)
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (userIdClaim is null || !int.TryParse(userIdClaim, out var userId))
        {
            return Unauthorized();
        }

        var user = await _db.Users.FindAsync(userId);
        if (user is null || !user.IsActive)
        {
            return Unauthorized(new { message = "User not found or inactive." });
        }

        var location = new DriverLocation
        {
            UserId = userId,
            Latitude = request.Latitude,
            Longitude = request.Longitude,
            Location = GeometryFactory.CreatePoint(new Coordinate(request.Longitude, request.Latitude)),
            RecordedAt = DateTime.UtcNow
        };

        _db.DriverLocations.Add(location);
        await _db.SaveChangesAsync();

        var payload = new UserLocationResponse
        {
            UserId = user.Id,
            Name = user.Name,
            Username = user.Username,
            Latitude = location.Latitude,
            Longitude = location.Longitude,
            RecordedAt = location.RecordedAt,
            IsOnline = true
        };

        await _hub.Clients.Group(LocationHub.AdminsGroup).SendAsync("ReceiveLocationUpdate", payload);

        return Ok();
    }

    /// <summary>Admin: latest known location for every user, with online/offline status.</summary>
    [HttpGet("active")]
    [Authorize(Roles = UserRoles.Admin)]
    public async Task<ActionResult<List<UserLocationResponse>>> GetActiveUsers()
    {
        var offlineThresholdMinutes = _config.GetValue<int>("Tracking:OfflineThresholdMinutes", 3);
        var cutoff = DateTime.UtcNow.AddMinutes(-offlineThresholdMinutes);

        var latestLocations = await _db.DriverLocations
            .GroupBy(dl => dl.UserId)
            .Select(g => g.OrderByDescending(dl => dl.RecordedAt).First())
            .ToListAsync();

        var userIds = latestLocations.Select(l => l.UserId).ToList();
        var users = await _db.Users
            .Where(u => userIds.Contains(u.Id) && u.IsActive)
            .ToDictionaryAsync(u => u.Id);

        var result = latestLocations
            .Where(l => users.ContainsKey(l.UserId))
            .Select(l => new UserLocationResponse
            {
                UserId = l.UserId,
                Name = users[l.UserId].Name,
                Username = users[l.UserId].Username,
                Latitude = l.Latitude,
                Longitude = l.Longitude,
                RecordedAt = l.RecordedAt,
                IsOnline = l.RecordedAt >= cutoff
            })
            .OrderBy(r => r.Name)
            .ToList();

        return Ok(result);
    }
}
