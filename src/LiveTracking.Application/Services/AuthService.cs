// File: src/LiveTracking.Application/Services/AuthService.cs
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.Auth;
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace LiveTracking.Application.Services;

public class AuthService : IAuthService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly ITokenService _tokenService;
    private readonly ILogger<AuthService> _logger;

    public AuthService(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        ITokenService tokenService,
        ILogger<AuthService> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _tokenService = tokenService;
        _logger = logger;
    }

    public async Task<LoginResponseDto> LoginAsync(LoginRequestDto request, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByUsernameAsync(request.Username, cancellationToken);

        if (user is null || !user.IsActive)
        {
            _logger.LogWarning("Login failed for username {Username}: user not found or inactive.", request.Username);
            throw new UnauthorizedException("Invalid username or password.");
        }

        if (!_passwordHasher.Verify(request.Password, user.PasswordHash))
        {
            _logger.LogWarning("Login failed for username {Username}: invalid password.", request.Username);
            throw new UnauthorizedException("Invalid username or password.");
        }

        var (token, expiresAt) = _tokenService.GenerateToken(user);

        _logger.LogInformation("User {Username} logged in successfully.", user.Username);

        return new LoginResponseDto
        {
            Token = token,
            ExpiresAt = expiresAt,
            UserId = user.Id,
            Name = user.Name,
            Username = user.Username,
            Role = user.Role.ToString()
        };
    }
}
