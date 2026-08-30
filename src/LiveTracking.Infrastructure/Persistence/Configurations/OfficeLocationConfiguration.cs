// File: src/LiveTracking.Infrastructure/Persistence/Configurations/OfficeLocationConfiguration.cs
using LiveTracking.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace LiveTracking.Infrastructure.Persistence.Configurations;

public class OfficeLocationConfiguration : IEntityTypeConfiguration<OfficeLocation>
{
    public void Configure(EntityTypeBuilder<OfficeLocation> builder)
    {
        builder.ToTable("myonline_tbl_OfficeLocations");

        builder.HasKey(o => o.Id);

        builder.Property(o => o.Name)
            .HasMaxLength(150)
            .IsRequired();

        builder.Property(o => o.Latitude).IsRequired();
        builder.Property(o => o.Longitude).IsRequired();

        builder.Property(o => o.RadiusMeters)
            .HasDefaultValue(200)
            .IsRequired();

        builder.Property(o => o.IsActive)
            .HasDefaultValue(true)
            .IsRequired();

        builder.Property(o => o.CreatedAt)
            .HasDefaultValueSql("SYSUTCDATETIME()")
            .IsRequired();

        builder.HasMany(o => o.Users)
            .WithOne(u => u.OfficeLocation)
            .HasForeignKey(u => u.OfficeLocationId)
            .OnDelete(DeleteBehavior.NoAction);
    }
}
