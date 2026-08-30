// File: src/LiveTracking.Application/Validators/PunchRequestDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Attendance;

namespace LiveTracking.Application.Validators;

public class PunchRequestDtoValidator : AbstractValidator<PunchRequestDto>
{
    public PunchRequestDtoValidator()
    {
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
    }
}
