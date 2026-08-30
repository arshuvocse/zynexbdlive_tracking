// File: src/LiveTracking.Infrastructure/Persistence/Repositories/AttendanceRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;
using LiveTracking.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Infrastructure.Persistence.Repositories;

public class AttendanceRepository : IAttendanceRepository
{
    private readonly LiveTrackingDbContext _context;

    public AttendanceRepository(LiveTrackingDbContext context)
    {
        _context = context;
    }

    public async Task AddAsync(Attendance attendance, CancellationToken cancellationToken = default)
        => await _context.Attendances.AddAsync(attendance, cancellationToken);

    public Task<Attendance?> GetLastForUserOnDateAsync(int userId, AttendanceType type, DateTime dateUtc, CancellationToken cancellationToken = default)
    {
        var dayStart = dateUtc.Date;
        var dayEnd = dayStart.AddDays(1);

        return _context.Attendances
            .Where(a => a.UserId == userId && a.Type == type && a.Timestamp >= dayStart && a.Timestamp < dayEnd)
            .OrderByDescending(a => a.Timestamp)
            .FirstOrDefaultAsync(cancellationToken);
    }

    public Task<List<Attendance>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        var query = _context.Attendances.AsNoTracking().Where(a => a.UserId == userId);

        if (from.HasValue) query = query.Where(a => a.Timestamp >= from.Value);
        if (to.HasValue) query = query.Where(a => a.Timestamp <= to.Value);

        return query.OrderByDescending(a => a.Timestamp).ToListAsync(cancellationToken);
    }

    public Task<List<Attendance>> GetAllAsync(int? userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        var query = _context.Attendances.AsNoTracking().Include(a => a.User).AsQueryable();

        if (userId.HasValue) query = query.Where(a => a.UserId == userId.Value);
        if (from.HasValue) query = query.Where(a => a.Timestamp >= from.Value);
        if (to.HasValue) query = query.Where(a => a.Timestamp <= to.Value);

        return query.OrderByDescending(a => a.Timestamp).ToListAsync(cancellationToken);
    }

    public Task<Attendance?> GetByIdAsync(long id, CancellationToken cancellationToken = default)
        => _context.Attendances.FirstOrDefaultAsync(a => a.Id == id, cancellationToken);
}
