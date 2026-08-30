// File: src/LiveTracking.Infrastructure/Persistence/LiveTrackingDbContext.cs
using LiveTracking.Domain.Entities;
using LiveTracking.Infrastructure.Persistence.Configurations;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Infrastructure.Persistence;

public class LiveTrackingDbContext : DbContext
{
    public LiveTrackingDbContext(DbContextOptions<LiveTrackingDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<DriverLocation> DriverLocations => Set<DriverLocation>();
    public DbSet<OfficeLocation> OfficeLocations => Set<OfficeLocation>();
    public DbSet<Attendance> Attendances => Set<Attendance>();
    public DbSet<LeaveType> LeaveTypes => Set<LeaveType>();
    public DbSet<LeaveBalance> LeaveBalances => Set<LeaveBalance>();
    public DbSet<LeaveApplication> LeaveApplications => Set<LeaveApplication>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        base.OnModelCreating(modelBuilder);

        modelBuilder.ApplyConfiguration(new UserConfiguration());
        modelBuilder.ApplyConfiguration(new DriverLocationConfiguration());
        modelBuilder.ApplyConfiguration(new OfficeLocationConfiguration());
        modelBuilder.ApplyConfiguration(new AttendanceConfiguration());
        modelBuilder.ApplyConfiguration(new LeaveTypeConfiguration());
        modelBuilder.ApplyConfiguration(new LeaveBalanceConfiguration());
        modelBuilder.ApplyConfiguration(new LeaveApplicationConfiguration());
    }
}
