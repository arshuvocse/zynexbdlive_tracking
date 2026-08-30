// File: src/LiveTracking.Application/Interfaces/ILocationService.cs
using LiveTracking.Application.DTOs.Locations;

namespace LiveTracking.Application.Interfaces;

public interface ILocationService
{
    Task<LocationResponseDto> UpdateLocationAsync(int userId, LocationUpdateDto dto, CancellationToken cancellationToken = default);
    Task<List<LocationResponseDto>> GetLatestAsync(CancellationToken cancellationToken = default);
    Task<List<LocationHistoryDto>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default);
}
