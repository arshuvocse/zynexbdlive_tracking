// File: src/LiveTracking.Infrastructure/Persistence/Repositories/OfficeLocationRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Infrastructure.Persistence.Repositories;

public class OfficeLocationRepository : IOfficeLocationRepository
{
    private readonly LiveTrackingDbContext _context;

    public OfficeLocationRepository(LiveTrackingDbContext context)
    {
        _context = context;
    }

    public Task<List<OfficeLocation>> GetAllAsync(CancellationToken cancellationToken = default)
        => _context.OfficeLocations.AsNoTracking().OrderBy(o => o.Name).ToListAsync(cancellationToken);

    public Task<OfficeLocation?> GetByIdAsync(int id, CancellationToken cancellationToken = default)
        => _context.OfficeLocations.FirstOrDefaultAsync(o => o.Id == id, cancellationToken);

    public async Task AddAsync(OfficeLocation officeLocation, CancellationToken cancellationToken = default)
        => await _context.OfficeLocations.AddAsync(officeLocation, cancellationToken);

    public void Update(OfficeLocation officeLocation)
        => _context.OfficeLocations.Update(officeLocation);
}
