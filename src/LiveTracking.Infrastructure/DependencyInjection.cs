// File: src/LiveTracking.Infrastructure/DependencyInjection.cs
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Interfaces;
using LiveTracking.Infrastructure.Files;
using LiveTracking.Infrastructure.Persistence;
using LiveTracking.Infrastructure.Persistence.Repositories;
using LiveTracking.Infrastructure.Security;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace LiveTracking.Infrastructure;

public static class DependencyInjection
{
    public static IServiceCollection AddInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        services.AddDbContext<LiveTrackingDbContext>(options =>
            options.UseSqlServer(
                configuration.GetConnectionString("DefaultConnection"),
                sqlOptions => sqlOptions.UseNetTopologySuite()));

        services.Configure<JwtSettings>(configuration.GetSection(JwtSettings.SectionName));

        services.AddScoped<IUnitOfWork, UnitOfWork>();
        services.AddScoped<IUserRepository, UserRepository>();
        services.AddScoped<ILocationRepository, LocationRepository>();
        services.AddScoped<IAttendanceRepository, AttendanceRepository>();
        services.AddScoped<ILeaveRepository, LeaveRepository>();
        services.AddScoped<IOfficeLocationRepository, OfficeLocationRepository>();

        services.AddScoped<IPasswordHasher, BCryptPasswordHasher>();
        services.AddScoped<ITokenService, TokenService>();
        services.AddSingleton<IFileStorageService, LocalFileStorageService>();

        return services;
    }
}
