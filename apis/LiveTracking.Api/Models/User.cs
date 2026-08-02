namespace LiveTracking.Api.Models;

public static class UserRoles
{
    public const string Admin = "Admin";
    public const string User = "User";
}

public class User
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string Role { get; set; } = UserRoles.User;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;

    public ICollection<DriverLocation> Locations { get; set; } = new List<DriverLocation>();
}
