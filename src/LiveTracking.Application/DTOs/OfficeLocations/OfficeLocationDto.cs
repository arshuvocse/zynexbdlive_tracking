// File: src/LiveTracking.Application/DTOs/OfficeLocations/OfficeLocationDto.cs
namespace LiveTracking.Application.DTOs.OfficeLocations;

public class OfficeLocationDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double RadiusMeters { get; set; }
    public bool IsActive { get; set; }
}
