// File: src/LiveTracking.Application/Services/AttendanceService.cs
using LiveTracking.Application.Common;
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.Attendance;
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;
using LiveTracking.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace LiveTracking.Application.Services;

public class AttendanceService : IAttendanceService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IFileStorageService _fileStorage;
    private readonly ILogger<AttendanceService> _logger;

    public AttendanceService(IUnitOfWork unitOfWork, IFileStorageService fileStorage, ILogger<AttendanceService> logger)
    {
        _unitOfWork = unitOfWork;
        _fileStorage = fileStorage;
        _logger = logger;
    }

    public Task<AttendanceResponseDto> PunchInAsync(int userId, PunchRequestDto dto, SelfieUpload selfie, CancellationToken cancellationToken = default)
        => PunchAsync(userId, AttendanceType.In, dto, selfie, cancellationToken);

    public Task<AttendanceResponseDto> PunchOutAsync(int userId, PunchRequestDto dto, SelfieUpload selfie, CancellationToken cancellationToken = default)
        => PunchAsync(userId, AttendanceType.Out, dto, selfie, cancellationToken);

    private async Task<AttendanceResponseDto> PunchAsync(int userId, AttendanceType type, PunchRequestDto dto, SelfieUpload selfie, CancellationToken cancellationToken)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Entities.User), userId);

        var existing = await _unitOfWork.Attendances.GetLastForUserOnDateAsync(userId, type, DateTime.UtcNow, cancellationToken);
        if (existing is not null)
        {
            throw new ValidationException($"You have already recorded Duty {type} today.");
        }

        bool isWithinGeofence = true;
        if (user.OfficeLocationId.HasValue)
        {
            var office = await _unitOfWork.OfficeLocations.GetByIdAsync(user.OfficeLocationId.Value, cancellationToken);
            if (office is not null)
            {
                var distance = GeoUtils.DistanceInMeters(office.Latitude, office.Longitude, dto.Latitude, dto.Longitude);
                isWithinGeofence = distance <= office.RadiusMeters;
            }
        }

        var timestamp = DateTime.UtcNow;
        var fileName = $"{timestamp:yyyyMMdd_HHmmss}_{type.ToString().ToLowerInvariant()}{selfie.FileExtension}";
        var relativePath = await _fileStorage.SaveAsync(selfie.Content, userId.ToString(), fileName, cancellationToken);

        var attendance = new Attendance
        {
            UserId = userId,
            Type = type,
            Timestamp = timestamp,
            SelfieImagePath = relativePath,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            IsWithinGeofence = isWithinGeofence,
            CreatedAt = timestamp
        };

        await _unitOfWork.Attendances.AddAsync(attendance, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Attendance {Type} recorded for user {UserId} at {Timestamp}.", type, userId, timestamp);

        return ToDto(attendance, user.Name);
    }

    public async Task<List<AttendanceResponseDto>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Entities.User), userId);

        var records = await _unitOfWork.Attendances.GetHistoryAsync(userId, from, to, cancellationToken);
        return records.Select(a => ToDto(a, user.Name)).ToList();
    }

    public async Task<List<AttendanceResponseDto>> GetAllAsync(int? userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        var records = await _unitOfWork.Attendances.GetAllAsync(userId, from, to, cancellationToken);
        return records.Select(a => ToDto(a, a.User.Name)).ToList();
    }

    public async Task<(Stream Stream, string ContentType)> GetSelfieAsync(long attendanceId, CancellationToken cancellationToken = default)
    {
        var attendance = await _unitOfWork.Attendances.GetByIdAsync(attendanceId, cancellationToken)
            ?? throw new NotFoundException(nameof(Attendance), attendanceId);

        var stream = _fileStorage.Open(attendance.SelfieImagePath)
            ?? throw new NotFoundException("Selfie image file was not found on the server.");

        var contentType = Path.GetExtension(attendance.SelfieImagePath).ToLowerInvariant() switch
        {
            ".png" => "image/png",
            _ => "image/jpeg"
        };

        return (stream, contentType);
    }

    private static AttendanceResponseDto ToDto(Attendance attendance, string userName) => new()
    {
        Id = attendance.Id,
        UserId = attendance.UserId,
        UserName = userName,
        Type = attendance.Type.ToString(),
        Timestamp = attendance.Timestamp,
        Latitude = attendance.Latitude,
        Longitude = attendance.Longitude,
        IsWithinGeofence = attendance.IsWithinGeofence,
        SelfieUrl = $"/api/attendance/selfie/{attendance.Id}"
    };
}
