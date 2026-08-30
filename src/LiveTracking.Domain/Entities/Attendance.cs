// File: src/LiveTracking.Domain/Entities/Attendance.cs
using LiveTracking.Domain.Enums;

namespace LiveTracking.Domain.Entities;

public class Attendance : BaseEntity<long>
{
    public int UserId { get; set; }
    public AttendanceType Type { get; set; }
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;
    public string SelfieImagePath { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public bool IsWithinGeofence { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public User User { get; set; } = null!;
}
