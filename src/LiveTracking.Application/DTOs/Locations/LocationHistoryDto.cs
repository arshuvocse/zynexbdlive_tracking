// File: src/LiveTracking.Application/DTOs/Locations/LocationHistoryDto.cs
namespace LiveTracking.Application.DTOs.Locations;

public class LocationHistoryDto
{
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Bearing { get; set; }
    public DateTime RecordedAt { get; set; }
    public int? DeviceBattery { get; set; }
    public string? NetworkType { get; set; }
}
