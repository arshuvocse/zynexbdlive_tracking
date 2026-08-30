// File: src/LiveTracking.API/Hubs/SignalRLocationBroadcaster.cs
using LiveTracking.Application.DTOs.Locations;
using LiveTracking.Application.Interfaces;
using Microsoft.AspNetCore.SignalR;

namespace LiveTracking.API.Hubs;

public class SignalRLocationBroadcaster : ILocationBroadcaster
{
    private readonly IHubContext<LocationHub> _hubContext;

    public SignalRLocationBroadcaster(IHubContext<LocationHub> hubContext)
    {
        _hubContext = hubContext;
    }

    public async Task BroadcastLocationUpdatedAsync(LocationResponseDto location, CancellationToken cancellationToken = default)
    {
        await _hubContext.Clients.Group(LocationHub.AdminGroup)
            .SendAsync("LocationUpdated", location, cancellationToken);
    }
}
