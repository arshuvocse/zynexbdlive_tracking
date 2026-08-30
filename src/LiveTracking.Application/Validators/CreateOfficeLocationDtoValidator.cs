// File: src/LiveTracking.Application/Validators/CreateOfficeLocationDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.OfficeLocations;

namespace LiveTracking.Application.Validators;

public class CreateOfficeLocationDtoValidator : AbstractValidator<CreateOfficeLocationDto>
{
    public CreateOfficeLocationDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
        RuleFor(x => x.RadiusMeters).GreaterThan(0);
    }
}
