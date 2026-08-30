// File: src/LiveTracking.API/Controllers/AuthController.cs
using LiveTracking.Application.Common;
using LiveTracking.Application.DTOs.Auth;
using LiveTracking.Application.Interfaces;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    [HttpPost("login")]
    [ProducesResponseType(typeof(ApiResponse<LoginResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequestDto request, CancellationToken cancellationToken)
    {
        var result = await _authService.LoginAsync(request, cancellationToken);
        return Ok(ApiResponse<LoginResponseDto>.SuccessResponse(result, "Login successful."));
    }
}
