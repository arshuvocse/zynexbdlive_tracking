// File: src/LiveTracking.Application/Interfaces/IAuthService.cs
using LiveTracking.Application.DTOs.Auth;

namespace LiveTracking.Application.Interfaces;

public interface IAuthService
{
    Task<LoginResponseDto> LoginAsync(LoginRequestDto request, CancellationToken cancellationToken = default);
}
