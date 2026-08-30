// File: src/LiveTracking.Application/DTOs/Leave/UpdateLeaveTypeDto.cs
namespace LiveTracking.Application.DTOs.Leave;

public class UpdateLeaveTypeDto
{
    public string Name { get; set; } = string.Empty;
    public int DefaultDaysPerYear { get; set; }
    public bool IsActive { get; set; }
}
