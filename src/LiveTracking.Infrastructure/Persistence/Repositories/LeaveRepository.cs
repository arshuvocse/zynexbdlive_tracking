// File: src/LiveTracking.Infrastructure/Persistence/Repositories/LeaveRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;
using LiveTracking.Domain.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Infrastructure.Persistence.Repositories;

public class LeaveRepository : ILeaveRepository
{
    private readonly LiveTrackingDbContext _context;

    public LeaveRepository(LiveTrackingDbContext context)
    {
        _context = context;
    }

    public Task<List<LeaveType>> GetActiveLeaveTypesAsync(CancellationToken cancellationToken = default)
        => _context.LeaveTypes.AsNoTracking().Where(t => t.IsActive).OrderBy(t => t.Name).ToListAsync(cancellationToken);

    public Task<List<LeaveType>> GetAllLeaveTypesAsync(CancellationToken cancellationToken = default)
        => _context.LeaveTypes.AsNoTracking().OrderBy(t => t.Name).ToListAsync(cancellationToken);

    public Task<LeaveType?> GetLeaveTypeByIdAsync(int id, CancellationToken cancellationToken = default)
        => _context.LeaveTypes.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);

    public Task<bool> LeaveTypeNameExistsAsync(string name, int? excludeId = null, CancellationToken cancellationToken = default)
    {
        var query = _context.LeaveTypes.Where(t => t.Name == name);
        if (excludeId.HasValue) query = query.Where(t => t.Id != excludeId.Value);
        return query.AnyAsync(cancellationToken);
    }

    public async Task AddLeaveTypeAsync(LeaveType leaveType, CancellationToken cancellationToken = default)
        => await _context.LeaveTypes.AddAsync(leaveType, cancellationToken);

    public void UpdateLeaveType(LeaveType leaveType)
        => _context.LeaveTypes.Update(leaveType);

    public Task<LeaveBalance?> GetBalanceAsync(int userId, int leaveTypeId, int year, CancellationToken cancellationToken = default)
        => _context.LeaveBalances.FirstOrDefaultAsync(
            b => b.UserId == userId && b.LeaveTypeId == leaveTypeId && b.Year == year, cancellationToken);

    public Task<List<LeaveBalance>> GetBalancesForUserAsync(int userId, int year, CancellationToken cancellationToken = default)
        => _context.LeaveBalances
            .AsNoTracking()
            .Include(b => b.LeaveType)
            .Where(b => b.UserId == userId && b.Year == year)
            .ToListAsync(cancellationToken);

    public async Task AddBalanceAsync(LeaveBalance balance, CancellationToken cancellationToken = default)
        => await _context.LeaveBalances.AddAsync(balance, cancellationToken);

    public void UpdateBalance(LeaveBalance balance)
        => _context.LeaveBalances.Update(balance);

    public async Task AddApplicationAsync(LeaveApplication application, CancellationToken cancellationToken = default)
        => await _context.LeaveApplications.AddAsync(application, cancellationToken);

    public Task<LeaveApplication?> GetApplicationByIdAsync(int id, CancellationToken cancellationToken = default)
        => _context.LeaveApplications
            .Include(l => l.LeaveType)
            .Include(l => l.User)
            .FirstOrDefaultAsync(l => l.Id == id, cancellationToken);

    public Task<List<LeaveApplication>> GetApplicationsForUserAsync(int userId, CancellationToken cancellationToken = default)
        => _context.LeaveApplications
            .AsNoTracking()
            .Include(l => l.LeaveType)
            .Include(l => l.User)
            .Where(l => l.UserId == userId)
            .OrderByDescending(l => l.AppliedAt)
            .ToListAsync(cancellationToken);

    public Task<List<LeaveApplication>> GetApplicationsAsync(LeaveStatus? status, CancellationToken cancellationToken = default)
    {
        var query = _context.LeaveApplications
            .AsNoTracking()
            .Include(l => l.LeaveType)
            .Include(l => l.User)
            .AsQueryable();

        if (status.HasValue) query = query.Where(l => l.Status == status.Value);

        return query.OrderByDescending(l => l.AppliedAt).ToListAsync(cancellationToken);
    }

    public void UpdateApplication(LeaveApplication application)
        => _context.LeaveApplications.Update(application);

    public Task<bool> HasOverlappingApplicationAsync(int userId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken = default)
        => _context.LeaveApplications.AnyAsync(l =>
            l.UserId == userId &&
            l.Status != LeaveStatus.Rejected && l.Status != LeaveStatus.Cancelled &&
            l.StartDate <= endDate && l.EndDate >= startDate,
            cancellationToken);
}
