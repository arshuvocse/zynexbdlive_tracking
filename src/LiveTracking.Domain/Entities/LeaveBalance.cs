// File: src/LiveTracking.Domain/Entities/LeaveBalance.cs
namespace LiveTracking.Domain.Entities;

public class LeaveBalance : BaseEntity<int>
{
    public int UserId { get; set; }
    public int LeaveTypeId { get; set; }
    public int Year { get; set; }
    public int TotalDays { get; set; }
    public int UsedDays { get; set; }

    public User User { get; set; } = null!;
    public LeaveType LeaveType { get; set; } = null!;
}
