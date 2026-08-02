using NetTopologySuite.Geometries;

namespace LiveTracking.Api.Models;

public class DriverLocation
{
    public long Id { get; set; }
    public int UserId { get; set; }

    /// <summary>Geography point, SRID 4326. Kept in sync with Latitude/Longitude by a DB trigger,
    /// but also set here so EF Core can materialize it for spatial queries if needed.</summary>
    public Point? Location { get; set; }

    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public DateTime RecordedAt { get; set; } = DateTime.UtcNow;

    public User? User { get; set; }
}
