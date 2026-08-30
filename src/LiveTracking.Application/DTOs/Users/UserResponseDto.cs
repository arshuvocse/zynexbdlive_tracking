// File: src/LiveTracking.Application/DTOs/Users/UserResponseDto.cs
namespace LiveTracking.Application.DTOs.Users;

public class UserResponseDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int? OfficeLocationId { get; set; }
    public string? OfficeLocationName { get; set; }
}
