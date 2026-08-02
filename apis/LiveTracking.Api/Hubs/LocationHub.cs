using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using LiveTracking.Api.Models;

namespace LiveTracking.Api.Hubs;

/// <summary>
/// Admin clients connect here and join the "Admins" group to receive live
/// location broadcasts. Driver location writes happen via REST
/// (LocationsController) so delivery is guaranteed even if a driver's
/// SignalR connection drops; the controller then broadcasts through this hub.
/// </summary>
[Authorize]
public class LocationHub : Hub
{
    public const string AdminsGroup = "Admins";

    public override async Task OnConnectedAsync()
    {
        if (Context.User?.IsInRole(UserRoles.Admin) == true)
        {
            await Groups.AddToGroupAsync(Context.ConnectionId, AdminsGroup);
        }

        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, AdminsGroup);
        await base.OnDisconnectedAsync(exception);
    }
}
