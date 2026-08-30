// File: src/LiveTracking.Domain/Interfaces/IAttendanceRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;

namespace LiveTracking.Domain.Interfaces;

public interface IAttendanceRepository
{
    Task AddAsync(Attendance attendance, CancellationToken cancellationToken = default);
    Task<Attendance?> GetLastForUserOnDateAsync(int userId, AttendanceType type, DateTime dateUtc, CancellationToken cancellationToken = default);
    Task<List<Attendance>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default);
    Task<List<Attendance>> GetAllAsync(int? userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default);
    Task<Attendance?> GetByIdAsync(long id, CancellationToken cancellationToken = default);
}
