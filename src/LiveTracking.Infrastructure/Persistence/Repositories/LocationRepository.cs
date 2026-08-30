// File: src/LiveTracking.Infrastructure/Persistence/Repositories/LocationRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Infrastructure.Persistence.Repositories;

public class LocationRepository : ILocationRepository
{
    private readonly LiveTrackingDbContext _context;

    public LocationRepository(LiveTrackingDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(DriverLocation location, CancellationToken cancellationToken = default)
        => await _context.DriverLocations.AddAsync(location, cancellationToken);

    public Task<DriverLocation?> GetLatestForUserAsync(int userId, CancellationToken cancellationToken = default)
        => _context.DriverLocations
            .AsNoTracking()
            .Where(l => l.UserId == userId)
            .OrderByDescending(l => l.RecordedAt)
            .FirstOrDefaultAsync(cancellationToken);

    public async Task<List<DriverLocation>> GetLatestForAllUsersAsync(CancellationToken cancellationToken = default)
    {
        var latestIds = _context.DriverLocations
            .GroupBy(l => l.UserId)
            .Select(g => g.OrderByDescending(l => l.RecordedAt).Select(l => l.Id).First());

        return await _context.DriverLocations
            .AsNoTracking()
            .Include(l => l.User)
            .Where(l => latestIds.Contains(l.Id))
            .ToListAsync(cancellationToken);
    }

    public Task<List<DriverLocation>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        var query = _context.DriverLocations
            .AsNoTracking()
            .Where(l => l.UserId == userId);

        if (from.HasValue)
        {
            query = query.Where(l => l.RecordedAt >= from.Value);
        }

        if (to.HasValue)
        {
            query = query.Where(l => l.RecordedAt <= to.Value);
        }

        return query.OrderBy(l => l.RecordedAt).ToListAsync(cancellationToken);
    }
}
