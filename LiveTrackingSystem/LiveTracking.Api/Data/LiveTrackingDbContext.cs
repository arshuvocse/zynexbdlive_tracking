using LiveTracking.Api.Models;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Api.Data;

public class LiveTrackingDbContext : DbContext
{
    public LiveTrackingDbContext(DbContextOptions<LiveTrackingDbContext> options) : base(options) { }

    public DbSet<User> Users => Set<User>();
    public DbSet<DriverLocation> DriverLocations => Set<DriverLocation>();
    public DbSet<AttendanceRecord> AttendanceRecords => Set<AttendanceRecord>();
    public DbSet<LeaveType> LeaveTypes => Set<LeaveType>();
    public DbSet<LeaveBalance> LeaveBalances => Set<LeaveBalance>();
    public DbSet<LeaveApplication> LeaveApplications => Set<LeaveApplication>();
    public DbSet<OfficeLocation> OfficeLocations => Set<OfficeLocation>();
    public DbSet<Customer> Customers => Set<Customer>();
    public DbSet<CustomerVisit> CustomerVisits => Set<CustomerVisit>();
    public DbSet<Shift> Shifts => Set<Shift>();
    public DbSet<Company> Companies => Set<Company>();
    public DbSet<Holiday> Holidays => Set<Holiday>();
    public DbSet<AppVersion> AppVersions => Set<AppVersion>();
    public DbSet<NotificationItem> Notifications => Set<NotificationItem>();
    public DbSet<SubscriptionPlan> SubscriptionPlans => Set<SubscriptionPlan>();
    public DbSet<AdminOfficeLocation> AdminOfficeLocations => Set<AdminOfficeLocation>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<Company>(e =>
        {
            e.ToTable("myonline_tbl_Companies");
            e.HasKey(c => c.CompanyId);
            e.HasIndex(c => c.CompanyCode).IsUnique();
            e.Property(c => c.CompanyName).HasMaxLength(200);
            e.Property(c => c.CompanyCode).HasMaxLength(50);
            e.Property(c => c.BrandLogo).HasMaxLength(500);
            e.HasMany(c => c.Users)
                .WithOne(u => u.Company)
                .HasForeignKey(u => u.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasMany(c => c.OfficeLocations)
                .WithOne(o => o.Company)
                .HasForeignKey(o => o.CompanyId)
                .OnDelete(DeleteBehavior.Restrict);
        });
        modelBuilder.Entity<Holiday>(e =>
        {
            e.ToTable("myonline_tbl_Holidays");
            e.HasKey(h => h.HolidayId);
            e.Property(h => h.Name).HasMaxLength(150);
        });

        modelBuilder.Entity<Shift>(e =>
        {
            e.ToTable("myonline_tbl_Shifts");
            e.HasKey(s => s.ShiftId);
            e.Property(s => s.ShiftName).HasMaxLength(100);
        });

        modelBuilder.Entity<Customer>(e =>
        {
            e.ToTable("myonline_tbl_Customers");
            e.HasKey(c => c.CustomerId);
            e.HasIndex(c => new { c.Name, c.Mobile });
        });

        modelBuilder.Entity<CustomerVisit>(e =>
        {
            e.ToTable("myonline_tbl_CustomerVisits");
            e.HasKey(v => v.VisitId);
            e.HasOne(v => v.Customer)
                .WithMany(c => c.Visits)
                .HasForeignKey(v => v.CustomerId);
            e.HasOne(v => v.User)
                .WithMany()
                .HasForeignKey(v => v.UserId);
        });
        modelBuilder.Entity<User>(e =>
        {
            e.ToTable("myonline_tbl_Users");
            e.HasKey(u => u.UserId);
            e.Property(u => u.UserId).HasColumnName("Id");
            e.Property(u => u.FullName).HasColumnName("Name");
            e.Property(u => u.CreatedAtUtc).HasColumnName("CreatedAt");
            e.Ignore(u => u.UpdatedAtUtc);
            e.HasIndex(u => u.Username).IsUnique();
            e.Property(u => u.Role).HasMaxLength(20);
            e.Property(u => u.CreatedByAdminId).HasColumnName("CreatedByAdminId");
            e.HasOne(u => u.OfficeLocation)
                .WithMany()
                .HasForeignKey(u => u.OfficeLocationId);
            e.HasOne(u => u.Shift)
                .WithMany()
                .HasForeignKey(u => u.ShiftId);
            e.HasMany(u => u.AdminOfficeLocations)
                .WithOne(a => a.AdminUser)
                .HasForeignKey(a => a.AdminUserId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<DriverLocation>(e =>
        {
            e.ToTable("myonline_tbl_DriverLocations");
            e.HasKey(l => l.LocationId);
            e.Property(l => l.LocationId).HasColumnName("Id");
            e.Property(l => l.RecordedAtUtc).HasColumnName("RecordedAt");
            e.Property(l => l.LocationAddress).HasColumnName("LocationAddress").HasMaxLength(500);
            e.Ignore(l => l.ReceivedAtUtc);
            e.HasIndex(l => new { l.UserId, l.RecordedAtUtc });
            e.HasOne(l => l.User)
                .WithMany(u => u.Locations)
                .HasForeignKey(l => l.UserId);
        });

        modelBuilder.Entity<AttendanceRecord>(e =>
        {
            e.ToTable("myonline_tbl_Attendances");
            e.HasKey(a => a.AttendanceId);
            e.Property(a => a.AttendanceId).HasColumnName("Id");
            e.Property(a => a.RecordedAtUtc).HasColumnName("Timestamp");
            e.Property(a => a.SelfieUrl).HasColumnName("SelfieImagePath");
            e.HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId);
        });

        modelBuilder.Entity<LeaveType>(e =>
        {
            e.ToTable("myonline_tbl_LeaveTypes");
            e.HasKey(t => t.LeaveTypeId);
            e.Property(t => t.LeaveTypeId).HasColumnName("Id");
        });

        modelBuilder.Entity<LeaveBalance>(e =>
        {
            e.ToTable("myonline_tbl_LeaveBalances");
            e.HasKey(b => b.LeaveBalanceId);
            e.Property(b => b.LeaveBalanceId).HasColumnName("Id");
            e.Property(b => b.Year).HasColumnName("Year");
            e.HasOne(b => b.User)
                .WithMany()
                .HasForeignKey(b => b.UserId);
            e.HasOne(b => b.LeaveType)
                .WithMany()
                .HasForeignKey(b => b.LeaveTypeId);
        });

        modelBuilder.Entity<LeaveApplication>(e =>
        {
            e.ToTable("myonline_tbl_LeaveApplications");
            e.HasKey(a => a.LeaveApplicationId);
            e.Property(a => a.LeaveApplicationId).HasColumnName("Id");
            e.Property(a => a.AppliedAtUtc).HasColumnName("AppliedAt");
            e.Property(a => a.ReviewedAtUtc).HasColumnName("ReviewedAt");
            e.Property(a => a.ReviewedBy).HasColumnName("ReviewedBy");
            e.HasOne(a => a.User)
                .WithMany()
                .HasForeignKey(a => a.UserId);
            e.HasOne(a => a.LeaveType)
                .WithMany()
                .HasForeignKey(a => a.LeaveTypeId);
        });

        modelBuilder.Entity<OfficeLocation>(e =>
        {
            e.ToTable("myonline_tbl_OfficeLocations");
            e.HasKey(o => o.OfficeLocationId);
            e.Property(o => o.OfficeLocationId).HasColumnName("Id");
            e.Property(o => o.CreatedAtUtc).HasColumnName("CreatedAt");
            e.HasMany(o => o.AdminOfficeLocations)
                .WithOne(a => a.OfficeLocation)
                .HasForeignKey(a => a.OfficeLocationId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<AdminOfficeLocation>(e =>
        {
            e.ToTable("myonline_tbl_AdminOfficeLocations");
            e.HasKey(a => a.Id);
            e.Property(a => a.Id).HasColumnName("Id");
            e.Property(a => a.AssignedAtUtc).HasColumnName("AssignedAtUtc");
            e.HasIndex(a => new { a.AdminUserId, a.OfficeLocationId }).IsUnique();
        });

        modelBuilder.Entity<AppVersion>(e =>
        {
            e.ToTable("myonline_tbl_AppVersions");
            e.HasKey(v => v.AppVersionId);
            e.Property(v => v.AppVersionId).HasColumnName("Id");
            e.Property(v => v.CreatedAtUtc).HasColumnName("CreatedAt");
            e.HasIndex(v => new { v.Platform, v.IsActive, v.VersionCode });
        });

        modelBuilder.Entity<NotificationItem>(e =>
        {
            e.ToTable("myonline_tbl_Notifications");
            e.HasKey(n => n.NotificationId);
            e.Property(n => n.NotificationId).HasColumnName("Id");
            e.Property(n => n.CreatedAtUtc).HasColumnName("CreatedAt");
            e.HasIndex(n => new { n.UserId, n.IsRead, n.CreatedAtUtc });
            e.HasOne(n => n.User)
                .WithMany()
                .HasForeignKey(n => n.UserId)
                .OnDelete(DeleteBehavior.SetNull);
            e.HasOne(n => n.Company)
                .WithMany()
                .HasForeignKey(n => n.CompanyId)
                .OnDelete(DeleteBehavior.Cascade);
        });


        // Seed Default Leave Types
        modelBuilder.Entity<LeaveType>().HasData(
            new LeaveType { LeaveTypeId = 1, Name = "Casual Leave", DefaultDaysPerYear = 14, IsActive = true },
            new LeaveType { LeaveTypeId = 2, Name = "Sick Leave", DefaultDaysPerYear = 14, IsActive = true },
            new LeaveType { LeaveTypeId = 3, Name = "Earned Leave", DefaultDaysPerYear = 10, IsActive = true }
        );

        // Seed Default Office Location
        modelBuilder.Entity<OfficeLocation>().HasData(
            new OfficeLocation { OfficeLocationId = 1, Name = "Headquarters", Latitude = 23.8103, Longitude = 90.4125, RadiusMeters = 200, IsActive = true }
        );
    }
}
