using System.ComponentModel.DataAnnotations;

namespace LiveTracking.Api.DTOs;

public class LocationUpdateRequest
{
    [Range(-90, 90)] public double Latitude { get; set; }
    [Range(-180, 180)] public double Longitude { get; set; }
}

public class UserLocationResponse
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime RecordedAt { get; set; }
    public bool IsOnline { get; set; }
}
