// File: src/LiveTracking.Application/DTOs/Leave/LeaveTypeDto.cs
namespace LiveTracking.Application.DTOs.Leave;

public class LeaveTypeDto
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public int DefaultDaysPerYear { get; set; }
    public bool IsActive { get; set; }
}
