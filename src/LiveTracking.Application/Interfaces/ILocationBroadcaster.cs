// File: src/LiveTracking.Application/Interfaces/ILocationBroadcaster.cs
using LiveTracking.Application.DTOs.Locations;

namespace LiveTracking.Application.Interfaces;

public interface ILocationBroadcaster
{
    Task BroadcastLocationUpdatedAsync(LocationResponseDto location, CancellationToken cancellationToken = default);
}
