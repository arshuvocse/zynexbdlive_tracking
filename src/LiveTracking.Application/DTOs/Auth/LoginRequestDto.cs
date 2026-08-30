// File: src/LiveTracking.Application/DTOs/Auth/LoginRequestDto.cs
namespace LiveTracking.Application.DTOs.Auth;

public class LoginRequestDto
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
}
