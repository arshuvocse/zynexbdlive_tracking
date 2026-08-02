using LiveTracking.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Api.Data;

public class LiveTrackingDbContext : DbContext
{
    public LiveTrackingDbContext(DbContextOptions<LiveTrackingDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<DriverLocation> DriverLocations => Set<DriverLocation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("myonline_tbl_Users");
            e.HasKey(u => u.Id);
            e.Property(u => u.Name).HasMaxLength(150).IsRequired();
            e.Property(u => u.Username).HasMaxLength(100).IsRequired();
            e.HasIndex(u => u.Username).IsUnique();
            e.Property(u => u.PasswordHash).HasMaxLength(300).IsRequired();
            e.Property(u => u.Role).HasMaxLength(20).IsRequired();
            e.Property(u => u.CreatedAt).HasDefaultValueSql("SYSUTCDATETIME()");
            e.Property(u => u.IsActive).HasDefaultValue(true);
        });

        modelBuilder.Entity<DriverLocation>(e =>
        {
            e.ToTable("myonline_tbl_DriverLocations");
            e.HasKey(dl => dl.Id);
            e.Property(dl => dl.Location).HasColumnType("geography");
            e.Property(dl => dl.RecordedAt).HasDefaultValueSql("SYSUTCDATETIME()");

            e.HasOne(dl => dl.User)
                .WithMany(u => u.Locations)
                .HasForeignKey(dl => dl.UserId)
                .OnDelete(DeleteBehavior.Cascade);

            e.HasIndex(dl => new { dl.UserId, dl.RecordedAt });
        });
    }
}
