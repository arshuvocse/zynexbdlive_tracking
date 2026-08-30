// File: src/LiveTracking.Infrastructure/Persistence/Configurations/AttendanceConfiguration.cs
using LiveTracking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LiveTracking.Infrastructure.Persistence.Configurations;

public class AttendanceConfiguration : IEntityTypeConfiguration<Attendance>
{
    public void Configure(EntityTypeBuilder<Attendance> builder)
    {
        builder.ToTable("myonline_tbl_Attendances");

        builder.HasKey(a => a.Id);

        builder.Property(a => a.Type)
            .HasConversion<string>()
            .HasMaxLength(10)
            .IsRequired();

        builder.Property(a => a.Timestamp)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();

        builder.Property(a => a.SelfieImagePath)
            .HasMaxLength(400)
            .IsRequired();

        builder.Property(a => a.Latitude).IsRequired();
        builder.Property(a => a.Longitude).IsRequired();

        builder.Property(a => a.IsWithinGeofence)
            .HasDefaultValue(false)
            .IsRequired();

        builder.Property(a => a.CreatedAt)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();

        builder.HasOne(a => a.User)
            .WithMany(u => u.Attendances)
            .HasForeignKey(a => a.UserId)
            .OnDelete(DeleteBehavior.Cascade);

        builder.HasIndex(a => new { a.UserId, a.Timestamp });
    }
}
