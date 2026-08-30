// File: src/LiveTracking.Domain/Entities/LeaveApplication.cs
using LiveTracking.Domain.Enums;

namespace LiveTracking.Domain.Entities;

public class LeaveApplication : BaseEntity<int>
{
    public int UserId { get; set; }
    public int LeaveTypeId { get; set; }
    public DateOnly StartDate { get; set; }
    public DateOnly EndDate { get; set; }
    public string Reason { get; set; } = string.Empty;
    public LeaveStatus Status { get; set; } = LeaveStatus.Pending;
    public DateTime AppliedAt { get; set; } = DateTime.UtcNow;
    public int? ReviewedBy { get; set; }
    public DateTime? ReviewedAt { get; set; }
    public string? ReviewComment { get; set; }

    public User User { get; set; } = null!;
    public LeaveType LeaveType { get; set; } = null!;

    public int TotalDays => EndDate.DayNumber - StartDate.DayNumber + 1;
}
