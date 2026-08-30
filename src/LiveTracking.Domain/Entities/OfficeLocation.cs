// File: src/LiveTracking.Domain/Entities/OfficeLocation.cs
namespace LiveTracking.Domain.Entities;

public class OfficeLocation : BaseEntity<int>
{
    public string Name { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double RadiusMeters { get; set; } = 200;
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<User> Users { get; set; } = new List<User>();
}
