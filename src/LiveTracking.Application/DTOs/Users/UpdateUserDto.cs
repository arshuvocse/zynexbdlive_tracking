// File: src/LiveTracking.Application/DTOs/Users/UpdateUserDto.cs
namespace LiveTracking.Application.DTOs.Users;

public class UpdateUserDto
{
    public string Name { get; set; } = string.Empty;
    public string Role { get; set; } = "User";
    public bool IsActive { get; set; } = true;
    public int? OfficeLocationId { get; set; }
}
