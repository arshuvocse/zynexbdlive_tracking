// File: src/LiveTracking.Domain/Interfaces/ILeaveRepository.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;

namespace LiveTracking.Domain.Interfaces;

public interface ILeaveRepository
{
    Task<List<LeaveType>> GetActiveLeaveTypesAsync(CancellationToken cancellationToken = default);
    Task<List<LeaveType>> GetAllLeaveTypesAsync(CancellationToken cancellationToken = default);
    Task<LeaveType?> GetLeaveTypeByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<bool> LeaveTypeNameExistsAsync(string name, int? excludeId = null, CancellationToken cancellationToken = default);
    Task AddLeaveTypeAsync(LeaveType leaveType, CancellationToken cancellationToken = default);
    void UpdateLeaveType(LeaveType leaveType);

    Task<LeaveBalance?> GetBalanceAsync(int userId, int leaveTypeId, int year, CancellationToken cancellationToken = default);
    Task<List<LeaveBalance>> GetBalancesForUserAsync(int userId, int year, CancellationToken cancellationToken = default);
    Task AddBalanceAsync(LeaveBalance balance, CancellationToken cancellationToken = default);
    void UpdateBalance(LeaveBalance balance);

    Task AddApplicationAsync(LeaveApplication application, CancellationToken cancellationToken = default);
    Task<LeaveApplication?> GetApplicationByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<List<LeaveApplication>> GetApplicationsForUserAsync(int userId, CancellationToken cancellationToken = default);
    Task<List<LeaveApplication>> GetApplicationsAsync(LeaveStatus? status, CancellationToken cancellationToken = default);
    void UpdateApplication(LeaveApplication application);

    Task<bool> HasOverlappingApplicationAsync(int userId, DateOnly startDate, DateOnly endDate, CancellationToken cancellationToken = default);
}
