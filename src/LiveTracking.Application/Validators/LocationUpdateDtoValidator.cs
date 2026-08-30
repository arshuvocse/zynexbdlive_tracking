// File: src/LiveTracking.Application/Validators/LocationUpdateDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Locations;

namespace LiveTracking.Application.Validators;

public class LocationUpdateDtoValidator : AbstractValidator<LocationUpdateDto>
{
    public LocationUpdateDtoValidator()
    {
        RuleFor(x => x.Latitude).InclusiveBetween(-90, 90);
        RuleFor(x => x.Longitude).InclusiveBetween(-180, 180);
        RuleFor(x => x.RecordedAt).NotEmpty();
        RuleFor(x => x.Accuracy).GreaterThanOrEqualTo(0).When(x => x.Accuracy.HasValue);
        RuleFor(x => x.Speed).GreaterThanOrEqualTo(0).When(x => x.Speed.HasValue);
        RuleFor(x => x.Bearing).InclusiveBetween(0, 360).When(x => x.Bearing.HasValue);
        RuleFor(x => x.DeviceBattery).InclusiveBetween(0, 100).When(x => x.DeviceBattery.HasValue);
    }
}
