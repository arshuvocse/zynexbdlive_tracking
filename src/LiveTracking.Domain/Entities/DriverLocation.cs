// File: src/LiveTracking.Domain/Entities/DriverLocation.cs
using NetTopologySuite.Geometries;

namespace LiveTracking.Domain.Entities;

public class DriverLocation : BaseEntity<long>
{
    public int UserId { get; set; }
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public Point? Location { get; set; }
    public double? Accuracy { get; set; }
    public double? Speed { get; set; }
    public double? Bearing { get; set; }
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;
    public int? DeviceBattery { get; set; }
    public string? NetworkType { get; set; }

    public User User { get; set; } = null!;
}
