// File: src/LiveTracking.Application/DTOs/Leave/CreateLeaveTypeDto.cs
namespace LiveTracking.Application.DTOs.Leave;

public class CreateLeaveTypeDto
{
    public string Name { get; set; } = string.Empty;
    public int DefaultDaysPerYear { get; set; }
}
