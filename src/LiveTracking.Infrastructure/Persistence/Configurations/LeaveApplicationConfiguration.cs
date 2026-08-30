// File: src/LiveTracking.Infrastructure/Persistence/Configurations/LeaveApplicationConfiguration.cs
using LiveTracking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LiveTracking.Infrastructure.Persistence.Configurations;

public class LeaveApplicationConfiguration : IEntityTypeConfiguration<LeaveApplication>
{
    public void Configure(EntityTypeBuilder<LeaveApplication> builder)
    {
        builder.ToTable("myonline_tbl_LeaveApplications");

        builder.HasKey(l => l.Id);

        builder.Property(l => l.StartDate).HasColumnType("date").IsRequired();
        builder.Property(l => l.EndDate).HasColumnType("date").IsRequired();

        builder.Property(l => l.Reason)
            .HasMaxLength(500)
            .IsRequired();

        builder.Property(l => l.Status)
            .HasConversion<string>()
            .HasMaxLength(20)
            .HasDefaultValue(Domain.Enums.LeaveStatus.Pending)
            .IsRequired();

        builder.Property(l => l.AppliedAt)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();

        builder.Property(l => l.ReviewComment).HasMaxLength(500);

        builder.Ignore(l => l.TotalDays);

        builder.HasOne(l => l.User)
            .WithMany(u => u.LeaveApplications)
            .HasForeignKey(l => l.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasOne(l => l.LeaveType)
            .WithMany()
            .HasForeignKey(l => l.LeaveTypeId)
            .OnDelete(DeleteBehavior.NoAction);

        builder.HasIndex(l => new { l.UserId, l.Status });
    }
}
