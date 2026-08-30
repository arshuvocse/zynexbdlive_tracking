// File: src/LiveTracking.Application/Validators/CreateLeaveTypeDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Leave;

namespace LiveTracking.Application.Validators;

public class CreateLeaveTypeDtoValidator : AbstractValidator<CreateLeaveTypeDto>
{
    public CreateLeaveTypeDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(100);
        RuleFor(x => x.DefaultDaysPerYear).GreaterThanOrEqualTo(0);
    }
}
