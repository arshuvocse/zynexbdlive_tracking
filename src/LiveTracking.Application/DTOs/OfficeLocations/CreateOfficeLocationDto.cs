// File: src/LiveTracking.Application/DTOs/OfficeLocations/CreateOfficeLocationDto.cs
namespace LiveTracking.Application.DTOs.OfficeLocations;

public class CreateOfficeLocationDto
{
    public string Name { get; set; } = string.Empty;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
    public double RadiusMeters { get; set; } = 200;
}
