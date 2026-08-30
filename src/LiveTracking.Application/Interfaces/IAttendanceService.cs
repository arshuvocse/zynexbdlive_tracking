// File: src/LiveTracking.Application/Interfaces/IAttendanceService.cs
using LiveTracking.Application.DTOs.Attendance;

namespace LiveTracking.Application.Interfaces;

public class SelfieUpload
{
    public Stream Content { get; set; } = Stream.Null;
    public string FileExtension { get; set; } = ".jpg";
}

public interface IAttendanceService
{
    Task<AttendanceResponseDto> PunchInAsync(int userId, PunchRequestDto dto, SelfieUpload selfie, CancellationToken cancellationToken = default);
    Task<AttendanceResponseDto> PunchOutAsync(int userId, PunchRequestDto dto, SelfieUpload selfie, CancellationToken cancellationToken = default);
    Task<List<AttendanceResponseDto>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default);
    Task<List<AttendanceResponseDto>> GetAllAsync(int? userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default);
    Task<(Stream Stream, string ContentType)> GetSelfieAsync(long attendanceId, CancellationToken cancellationToken = default);
}
