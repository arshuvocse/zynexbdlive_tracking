// File: src/LiveTracking.Application/DTOs/Leave/LeaveBalanceDto.cs
namespace LiveTracking.Application.DTOs.Leave;

public class LeaveBalanceDto
{
    public int LeaveTypeId { get; set; }
    public string LeaveTypeName { get; set; } = string.Empty;
    public int TotalDays { get; set; }
    public int UsedDays { get; set; }
    public int RemainingDays => TotalDays - UsedDays;
}
