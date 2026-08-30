// File: src/LiveTracking.Application/DTOs/Attendance/AttendanceResponseDto.cs
namespace LiveTracking.Application.DTOs.Attendance;

public class AttendanceResponseDto
{
    public long Id { get; set; }
    public int UserId { get; set; }
    public string UserName { get; set; } = string.Empty;
    public string Type { get; set; } = string.Empty;
    public DateTime Timestamp { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public bool IsWithinGeofence { get; set; }
    public string SelfieUrl { get; set; } = string.Empty;
}
