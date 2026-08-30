// File: src/LiveTracking.API/Hubs/LocationHub.cs
using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;

namespace LiveTracking.API.Hubs;

[Authorize]
public class LocationHub : Hub
{
    public const string AdminGroup = "Admins";

    private readonly ILogger<LocationHub> _logger;

    public LocationHub(ILogger<LocationHub> logger)
    {
        _logger = logger;
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        var role = Context.User?.FindFirstValue(ClaimTypes.Role);

        if (string.Equals(role, "Admin", StringComparison.OrdinalIgnoreCase))
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, AdminGroup);
        }

        _logger.LogInformation("SignalR connected: user {UserId}, connection {ConnectionId}", userId, Context.ConnectionId);

        await Clients.Group(AdminGroup).SendAsync("UserConnected", userId);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);

        _logger.LogInformation("SignalR disconnected: user {UserId}, connection {ConnectionId}", userId, Context.ConnectionId);

        await Clients.Group(AdminGroup).SendAsync("UserDisconnected", userId);
        await base.OnDisconnectedAsync(exception);
    }
}
