using LiveTracking.Api.Data;
using LiveTracking.Api.DTOs;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using LiveTracking.Api.Services;

namespace LiveTracking.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly LiveTrackingDbContext _db;
    private readonly IJwtTokenService _jwt;

    public AuthController(LiveTrackingDbContext db, IJwtTokenService jwt)
    {
        _db = db;
        _jwt = jwt;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        var user = await _db.Users.FirstOrDefaultAsync(u => u.Username == request.Username);

        if (user is null || !user.IsActive || !BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
        {
            return Unauthorized(new { message = "Invalid username or password." });
        }

        var (token, expiresAt) = _jwt.GenerateToken(user);

        return Ok(new LoginResponse
        {
            Token = token,
            Role = user.Role,
            UserId = user.Id,
            Name = user.Name,
            ExpiresAt = expiresAt
        });
    }
}
