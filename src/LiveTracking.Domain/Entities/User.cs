// File: src/LiveTracking.Domain/Entities/User.cs
using LiveTracking.Domain.Enums;

namespace LiveTracking.Domain.Entities;

public class User : BaseEntity<int>
{
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public UserRole Role { get; set; } = UserRole.User;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public bool IsActive { get; set; } = true;
    public int? OfficeLocationId { get; set; }

    public OfficeLocation? OfficeLocation { get; set; }
    public ICollection<DriverLocation> Locations { get; set; } = new List<DriverLocation>();
    public ICollection<Attendance> Attendances { get; set; } = new List<Attendance>();
    public ICollection<LeaveApplication> LeaveApplications { get; set; } = new List<LeaveApplication>();
}
