// File: src/LiveTracking.Infrastructure/Persistence/Configurations/LeaveBalanceConfiguration.cs
using LiveTracking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LiveTracking.Infrastructure.Persistence.Configurations;

public class LeaveBalanceConfiguration : IEntityTypeConfiguration<LeaveBalance>
{
    public void Configure(EntityTypeBuilder<LeaveBalance> builder)
    {
        builder.ToTable("myonline_tbl_LeaveBalances");

        builder.HasKey(b => b.Id);

        builder.Property(b => b.UsedDays)
            .HasDefaultValue(0)
            .IsRequired();

        builder.HasOne(b => b.User)
            .WithMany()
            .HasForeignKey(b => b.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(b => b.LeaveType)
            .WithMany()
            .HasForeignKey(b => b.LeaveTypeId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.HasIndex(b => new { b.UserId, b.LeaveTypeId, b.Year }).IsUnique();
    }
}
