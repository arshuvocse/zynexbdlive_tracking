// File: src/LiveTracking.Application/Validators/UpdateUserDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Users;
using LiveTracking.Shared.Constants;

namespace LiveTracking.Application.Validators;

public class UpdateUserDtoValidator : AbstractValidator<UpdateUserDto>
{
    public UpdateUserDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Role)
            .NotEmpty()
            .Must(r => r == Roles.Admin || r == Roles.User)
            .WithMessage($"Role must be either '{Roles.Admin}' or '{Roles.User}'.");
    }
}
