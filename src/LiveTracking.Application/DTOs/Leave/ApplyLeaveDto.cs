// File: src/LiveTracking.Application/DTOs/Leave/ApplyLeaveDto.cs
namespace LiveTracking.Application.DTOs.Leave;

public class ApplyLeaveDto
{
    public int LeaveTypeId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public string Reason { get; set; } = string.Empty;
}
