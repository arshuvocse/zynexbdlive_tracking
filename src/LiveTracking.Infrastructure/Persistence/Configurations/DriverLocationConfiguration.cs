// File: src/LiveTracking.Infrastructure/Persistence/Configurations/DriverLocationConfiguration.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Shared.Constants;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LiveTracking.Infrastructure.Persistence.Configurations;

public class DriverLocationConfiguration : IEntityTypeConfiguration<DriverLocation>
{
    public void Configure(EntityTypeBuilder<DriverLocation> builder)
    {
        builder.ToTable("myonline_tbl_DriverLocations");

        builder.HasKey(l => l.Id);

        builder.Property(l => l.Latitude).IsRequired();
        builder.Property(l => l.Longitude).IsRequired();

        // Location (GEOGRAPHY) is maintained by a DB trigger from Latitude/Longitude; EF never writes it.
        builder.Ignore(l => l.Location);

        builder.Property(l => l.RecordedAt)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();

        builder.Property(l => l.NetworkType)
            .HasMaxLength(20);

        builder.HasIndex(l => new { l.UserId, l.RecordedAt });
    }
}
