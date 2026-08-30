// File: src/LiveTracking.Application/DTOs/Users/CreateUserDto.cs
namespace LiveTracking.Application.DTOs.Users;

public class CreateUserDto
{
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Role { get; set; } = "User";
    public int? OfficeLocationId { get; set; }
}
