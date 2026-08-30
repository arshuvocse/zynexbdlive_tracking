// File: src/LiveTracking.Application/DTOs/OfficeLocations/UpdateOfficeLocationDto.cs
namespace LiveTracking.Application.DTOs.OfficeLocations;

public class UpdateOfficeLocationDto
{
    public string Name { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double RadiusMeters { get; set; }
    public bool IsActive { get; set; }
}
