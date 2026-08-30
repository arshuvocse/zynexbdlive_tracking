// File: src/LiveTracking.Application/DTOs/Locations/LocationResponseDto.cs
namespace LiveTracking.Application.DTOs.Locations;

public class LocationResponseDto
{
    public int UserId { get; set; }
    public string Name { get; set; } = string.Empty;
    public string Username { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Bearing { get; set; }
    public DateTime RecordedAt { get; set; }
    public int? DeviceBattery { get; set; }
    public string? NetworkType { get; set; }
    public bool IsOnline { get; set; }
}
