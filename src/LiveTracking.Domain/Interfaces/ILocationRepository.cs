// File: src/LiveTracking.Domain/Interfaces/ILocationRepository.cs
using LiveTracking.Domain.Entities;

namespace LiveTracking.Domain.Interfaces;

public interface ILocationRepository
{
    Task AddAsync(DriverLocation location, CancellationToken cancellationToken = default);
    Task<DriverLocation?> GetLatestForUserAsync(int userId, CancellationToken cancellationToken = default);
    Task<List<DriverLocation>> GetLatestForAllUsersAsync(CancellationToken cancellationToken = default);
    Task<List<DriverLocation>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default);
}
