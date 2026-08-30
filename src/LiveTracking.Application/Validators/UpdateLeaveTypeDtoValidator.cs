// File: src/LiveTracking.Application/Validators/UpdateLeaveTypeDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Leave;

namespace LiveTracking.Application.Validators;

public class UpdateLeaveTypeDtoValidator : AbstractValidator<UpdateLeaveTypeDto>
{
    public UpdateLeaveTypeDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.DefaultDaysPerYear).GreaterThanOrEqualTo(0);
    }
}
