// File: src/LiveTracking.Application/Interfaces/ILeaveService.cs
using LiveTracking.Application.DTOs.Leave;

namespace LiveTracking.Application.Interfaces;

public interface ILeaveService
{
    Task<List<LeaveTypeDto>> GetActiveLeaveTypesAsync(CancellationToken cancellationToken = default);
    Task<List<LeaveTypeDto>> GetAllLeaveTypesAsync(CancellationToken cancellationToken = default);
    Task<LeaveTypeDto> CreateLeaveTypeAsync(CreateLeaveTypeDto dto, CancellationToken cancellationToken = default);
    Task<LeaveTypeDto> UpdateLeaveTypeAsync(int id, UpdateLeaveTypeDto dto, CancellationToken cancellationToken = default);

    Task<List<LeaveBalanceDto>> GetMyBalancesAsync(int userId, CancellationToken cancellationToken = default);

    Task<LeaveApplicationResponseDto> ApplyAsync(int userId, ApplyLeaveDto dto, CancellationToken cancellationToken = default);
    Task<List<LeaveApplicationResponseDto>> GetMyHistoryAsync(int userId, CancellationToken cancellationToken = default);
    Task<LeaveApplicationResponseDto> CancelAsync(int userId, int applicationId, CancellationToken cancellationToken = default);

    Task<List<LeaveApplicationResponseDto>> GetApplicationsAsync(string? status, CancellationToken cancellationToken = default);
    Task<LeaveApplicationResponseDto> ApproveAsync(int reviewerId, int applicationId, LeaveReviewDto dto, CancellationToken cancellationToken = default);
    Task<LeaveApplicationResponseDto> RejectAsync(int reviewerId, int applicationId, LeaveReviewDto dto, CancellationToken cancellationToken = default);
}
