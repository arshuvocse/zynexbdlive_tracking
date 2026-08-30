// File: src/LiveTracking.Application/Interfaces/IOfficeLocationService.cs
using LiveTracking.Application.DTOs.OfficeLocations;

namespace LiveTracking.Application.Interfaces;

public interface IOfficeLocationService
{
    Task<List<OfficeLocationDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<OfficeLocationDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<OfficeLocationDto> CreateAsync(CreateOfficeLocationDto dto, CancellationToken cancellationToken = default);
    Task<OfficeLocationDto> UpdateAsync(int id, UpdateOfficeLocationDto dto, CancellationToken cancellationToken = default);
}
