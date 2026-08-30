// File: src/LiveTracking.Infrastructure/Persistence/Configurations/LeaveTypeConfiguration.cs
using LiveTracking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LiveTracking.Infrastructure.Persistence.Configurations;

public class LeaveTypeConfiguration : IEntityTypeConfiguration<LeaveType>
{
    public void Configure(EntityTypeBuilder<LeaveType> builder)
    {
        builder.ToTable("myonline_tbl_LeaveTypes");

        builder.HasKey(l => l.Id);

        builder.Property(l => l.Name)
            .HasMaxLength(100)
            .IsRequired();

        builder.HasIndex(l => l.Name).IsUnique();

        builder.Property(l => l.DefaultDaysPerYear)
            .HasDefaultValue(0)
            .IsRequired();

        builder.Property(l => l.IsActive)
            .HasDefaultValue(true)
            .IsRequired();

        builder.Property(l => l.CreatedAt)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();
    }
}
