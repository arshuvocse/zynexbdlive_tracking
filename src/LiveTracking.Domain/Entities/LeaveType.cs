// File: src/LiveTracking.Domain/Entities/LeaveType.cs
namespace LiveTracking.Domain.Entities;

public class LeaveType : BaseEntity<int>
{
    public string Name { get; set; } = string.Empty;
    public int DefaultDaysPerYear { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
