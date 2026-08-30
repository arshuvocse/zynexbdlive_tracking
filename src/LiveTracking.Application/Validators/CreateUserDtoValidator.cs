// File: src/LiveTracking.Application/Validators/CreateUserDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Users;
using LiveTracking.Shared.Constants;

namespace LiveTracking.Application.Validators;

public class CreateUserDtoValidator : AbstractValidator<CreateUserDto>
{
    public CreateUserDtoValidator()
    {
        RuleFor(x => x.Name).NotEmpty().MaximumLength(150);
        RuleFor(x => x.Username).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Password).NotEmpty().MinimumLength(6).MaximumLength(200);
        RuleFor(x => x.Role)
            .NotEmpty()
            .Must(r => r == Roles.Admin || r == Roles.User)
            .WithMessage($"Role must be either '{Roles.Admin}' or '{Roles.User}'.");
    }
}
