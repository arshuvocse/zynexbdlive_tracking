// File: src/LiveTracking.Domain/Interfaces/IUnitOfWork.cs
namespace LiveTracking.Domain.Interfaces;

public interface IUnitOfWork : IDisposable
{
    IUserRepository Users { get; }
    ILocationRepository Locations { get; }
    IAttendanceRepository Attendances { get; }
    ILeaveRepository Leave { get; }
    IOfficeLocationRepository OfficeLocations { get; }
    Task<int> SaveChangesAsync(CancellationToken cancellationToken = default);
}
