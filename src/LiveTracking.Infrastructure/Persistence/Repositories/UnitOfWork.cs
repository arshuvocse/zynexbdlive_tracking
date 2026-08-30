// File: src/LiveTracking.Infrastructure/Persistence/Repositories/UnitOfWork.cs
using LiveTracking.Domain.Interfaces;

namespace LiveTracking.Infrastructure.Persistence.Repositories;

public class UnitOfWork : IUnitOfWork
{
    private readonly LiveTrackingDbContext _context;
    private IUserRepository? _users;
    private ILocationRepository? _locations;
    private IAttendanceRepository? _attendances;
    private ILeaveRepository? _leave;
    private IOfficeLocationRepository? _officeLocations;

    public UnitOfWork(LiveTrackingDbContext context)
    {
        _context = context;
    }

    public IUserRepository Users => _users ??= new UserRepository(_context);
    public ILocationRepository Locations => _locations ??= new LocationRepository(_context);
    public IAttendanceRepository Attendances => _attendances ??= new AttendanceRepository(_context);
    public ILeaveRepository Leave => _leave ??= new LeaveRepository(_context);
    public IOfficeLocationRepository OfficeLocations => _officeLocations ??= new OfficeLocationRepository(_context);

    public Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        => _context.SaveChangesAsync(cancellationToken);

    public void Dispose()
    {
        _context.Dispose();
        GC.SuppressFinalize(this);
    }
}
