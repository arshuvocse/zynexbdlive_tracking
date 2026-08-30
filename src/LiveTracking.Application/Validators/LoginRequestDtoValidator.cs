// File: src/LiveTracking.Application/Validators/LoginRequestDtoValidator.cs
using FluentValidation;
using LiveTracking.Application.DTOs.Auth;

namespace LiveTracking.Application.Validators;

public class LoginRequestDtoValidator : AbstractValidator<LoginRequestDto>
{
    public LoginRequestDtoValidator()
    {
        RuleFor(x => x.Username).NotEmpty().MaximumLength(100);
        RuleFor(x => x.Password).NotEmpty().MaximumLength(200);
    }
}
