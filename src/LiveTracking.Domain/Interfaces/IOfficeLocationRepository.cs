// File: src/LiveTracking.Domain/Interfaces/IOfficeLocationRepository.cs
using LiveTracking.Domain.Entities;

namespace LiveTracking.Domain.Interfaces;

public interface IOfficeLocationRepository
{
    Task<List<OfficeLocation>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<OfficeLocation?> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task AddAsync(OfficeLocation officeLocation, CancellationToken cancellationToken = default);
    void Update(OfficeLocation officeLocation);
}
