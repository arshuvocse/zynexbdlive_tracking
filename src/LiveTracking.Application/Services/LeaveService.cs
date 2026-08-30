// File: src/LiveTracking.Application/Services/LeaveService.cs
using AutoMapper;
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.Leave;
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;
using LiveTracking.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace LiveTracking.Application.Services;

public class LeaveService : ILeaveService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly ILogger<LeaveService> _logger;

    public LeaveService(IUnitOfWork unitOfWork, IMapper mapper, ILogger<LeaveService> logger)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<List<LeaveTypeDto>> GetActiveLeaveTypesAsync(CancellationToken cancellationToken = default)
    {
        var types = await _unitOfWork.Leave.GetActiveLeaveTypesAsync(cancellationToken);
        return _mapper.Map<List<LeaveTypeDto>>(types);
    }

    public async Task<List<LeaveTypeDto>> GetAllLeaveTypesAsync(CancellationToken cancellationToken = default)
    {
        var types = await _unitOfWork.Leave.GetAllLeaveTypesAsync(cancellationToken);
        return _mapper.Map<List<LeaveTypeDto>>(types);
    }

    public async Task<LeaveTypeDto> CreateLeaveTypeAsync(CreateLeaveTypeDto dto, CancellationToken cancellationToken = default)
    {
        if (await _unitOfWork.Leave.LeaveTypeNameExistsAsync(dto.Name, null, cancellationToken))
        {
            throw new ValidationException($"Leave type '{dto.Name}' already exists.");
        }

        var leaveType = new LeaveType
        {
            Name = dto.Name,
            DefaultDaysPerYear = dto.DefaultDaysPerYear,
            IsActive = true
        };

        await _unitOfWork.Leave.AddLeaveTypeAsync(leaveType, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return _mapper.Map<LeaveTypeDto>(leaveType);
    }

    public async Task<LeaveTypeDto> UpdateLeaveTypeAsync(int id, UpdateLeaveTypeDto dto, CancellationToken cancellationToken = default)
    {
        var leaveType = await _unitOfWork.Leave.GetLeaveTypeByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(LeaveType), id);

        if (await _unitOfWork.Leave.LeaveTypeNameExistsAsync(dto.Name, id, cancellationToken))
        {
            throw new ValidationException($"Leave type '{dto.Name}' already exists.");
        }

        leaveType.Name = dto.Name;
        leaveType.DefaultDaysPerYear = dto.DefaultDaysPerYear;
        leaveType.IsActive = dto.IsActive;

        _unitOfWork.Leave.UpdateLeaveType(leaveType);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return _mapper.Map<LeaveTypeDto>(leaveType);
    }

    public async Task<List<LeaveBalanceDto>> GetMyBalancesAsync(int userId, CancellationToken cancellationToken = default)
    {
        var year = DateTime.UtcNow.Year;
        var balances = await _unitOfWork.Leave.GetBalancesForUserAsync(userId, year, cancellationToken);
        return balances.Select(b => new LeaveBalanceDto
        {
            LeaveTypeId = b.LeaveTypeId,
            LeaveTypeName = b.LeaveType.Name,
            TotalDays = b.TotalDays,
            UsedDays = b.UsedDays
        }).ToList();
    }

    public async Task<LeaveApplicationResponseDto> ApplyAsync(int userId, ApplyLeaveDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Entities.User), userId);

        var leaveType = await _unitOfWork.Leave.GetLeaveTypeByIdAsync(dto.LeaveTypeId, cancellationToken)
            ?? throw new NotFoundException(nameof(LeaveType), dto.LeaveTypeId);

        if (!leaveType.IsActive)
        {
            throw new ValidationException($"Leave type '{leaveType.Name}' is not currently active.");
        }

        if (dto.EndDate < dto.StartDate)
        {
            throw new ValidationException("End date cannot be before start date.");
        }

        if (await _unitOfWork.Leave.HasOverlappingApplicationAsync(userId, dto.StartDate, dto.EndDate, cancellationToken))
        {
            throw new ValidationException("You already have a leave application overlapping these dates.");
        }

        var application = new LeaveApplication
        {
            UserId = userId,
            LeaveTypeId = dto.LeaveTypeId,
            StartDate = dto.StartDate,
            EndDate = dto.EndDate,
            Reason = dto.Reason,
            Status = LeaveStatus.Pending,
            AppliedAt = DateTime.UtcNow
        };

        await _unitOfWork.Leave.AddApplicationAsync(application, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Leave application {ApplicationId} created for user {UserId}.", application.Id, userId);

        return ToDto(application, user.Name, leaveType.Name);
    }

    public async Task<List<LeaveApplicationResponseDto>> GetMyHistoryAsync(int userId, CancellationToken cancellationToken = default)
    {
        var applications = await _unitOfWork.Leave.GetApplicationsForUserAsync(userId, cancellationToken);
        return applications.Select(a => ToDto(a, a.User?.Name ?? string.Empty, a.LeaveType.Name)).ToList();
    }

    public async Task<LeaveApplicationResponseDto> CancelAsync(int userId, int applicationId, CancellationToken cancellationToken = default)
    {
        var application = await _unitOfWork.Leave.GetApplicationByIdAsync(applicationId, cancellationToken)
            ?? throw new NotFoundException(nameof(LeaveApplication), applicationId);

        if (application.UserId != userId)
        {
            throw new ValidationException("You can only cancel your own leave applications.");
        }

        if (application.Status != LeaveStatus.Pending)
        {
            throw new ValidationException("Only pending leave applications can be cancelled.");
        }

        application.Status = LeaveStatus.Cancelled;
        _unitOfWork.Leave.UpdateApplication(application);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return ToDto(application, application.User.Name, application.LeaveType.Name);
    }

    public async Task<List<LeaveApplicationResponseDto>> GetApplicationsAsync(string? status, CancellationToken cancellationToken = default)
    {
        LeaveStatus? parsedStatus = null;
        if (!string.IsNullOrWhiteSpace(status))
        {
            if (!Enum.TryParse<LeaveStatus>(status, ignoreCase: true, out var value))
            {
                throw new ValidationException($"Invalid leave status '{status}'.");
            }
            parsedStatus = value;
        }

        var applications = await _unitOfWork.Leave.GetApplicationsAsync(parsedStatus, cancellationToken);
        return applications.Select(a => ToDto(a, a.User.Name, a.LeaveType.Name)).ToList();
    }

    public Task<LeaveApplicationResponseDto> ApproveAsync(int reviewerId, int applicationId, LeaveReviewDto dto, CancellationToken cancellationToken = default)
        => ReviewAsync(reviewerId, applicationId, LeaveStatus.Approved, dto, cancellationToken);

    public Task<LeaveApplicationResponseDto> RejectAsync(int reviewerId, int applicationId, LeaveReviewDto dto, CancellationToken cancellationToken = default)
        => ReviewAsync(reviewerId, applicationId, LeaveStatus.Rejected, dto, cancellationToken);

    private async Task<LeaveApplicationResponseDto> ReviewAsync(int reviewerId, int applicationId, LeaveStatus decision, LeaveReviewDto dto, CancellationToken cancellationToken)
    {
        var application = await _unitOfWork.Leave.GetApplicationByIdAsync(applicationId, cancellationToken)
            ?? throw new NotFoundException(nameof(LeaveApplication), applicationId);

        if (application.Status != LeaveStatus.Pending)
        {
            throw new ValidationException("Only pending leave applications can be reviewed.");
        }

        application.Status = decision;
        application.ReviewedBy = reviewerId;
        application.ReviewedAt = DateTime.UtcNow;
        application.ReviewComment = dto.Comment;

        _unitOfWork.Leave.UpdateApplication(application);

        if (decision == LeaveStatus.Approved)
        {
            var year = application.StartDate.Year;
            var balance = await _unitOfWork.Leave.GetBalanceAsync(application.UserId, application.LeaveTypeId, year, cancellationToken);

            if (balance is null)
            {
                balance = new LeaveBalance
                {
                    UserId = application.UserId,
                    LeaveTypeId = application.LeaveTypeId,
                    Year = year,
                    TotalDays = application.LeaveType.DefaultDaysPerYear,
                    UsedDays = 0
                };
                await _unitOfWork.Leave.AddBalanceAsync(balance, cancellationToken);
            }

            balance.UsedDays += application.TotalDays;
            _unitOfWork.Leave.UpdateBalance(balance);
        }

        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Leave application {ApplicationId} {Decision} by reviewer {ReviewerId}.", applicationId, decision, reviewerId);

        return ToDto(application, application.User.Name, application.LeaveType.Name);
    }

    private static LeaveApplicationResponseDto ToDto(LeaveApplication application, string userName, string leaveTypeName) => new()
    {
        Id = application.Id,
        UserId = application.UserId,
        UserName = userName,
        LeaveTypeId = application.LeaveTypeId,
        LeaveTypeName = leaveTypeName,
        StartDate = application.StartDate,
        EndDate = application.EndDate,
        TotalDays = application.TotalDays,
        Reason = application.Reason,
        Status = application.Status.ToString(),
        AppliedAt = application.AppliedAt,
        ReviewedAt = application.ReviewedAt,
        ReviewComment = application.ReviewComment
    };
}
