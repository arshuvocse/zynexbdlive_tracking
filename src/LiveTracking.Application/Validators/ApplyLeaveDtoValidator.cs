// File: src/LiveTracking.Application/Validators/ApplyLeaveDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Leave;

namespace LiveTracking.Application.Validators;

public class ApplyLeaveDtoValidator : AbstractValidator<ApplyLeaveDto>
{
    public ApplyLeaveDtoValidator()
    {
        RuleFor(x => x.LeaveTypeId).GreaterThan(0);
        RuleFor(x => x.StartDate).NotEmpty();
        RuleFor(x => x.EndDate).GreaterThanOrEqualTo(x => x.StartDate);
        RuleFor(x => x.Reason).NotEmpty().MaximumLength(500);
    }
}
