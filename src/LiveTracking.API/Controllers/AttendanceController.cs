// File: src/LiveTracking.API/Controllers/AttendanceController.cs
using System.Security.Claims;
using LiveTracking.Application.Common;
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.Attendance;
using LiveTracking.Application.Interfaces;
using LiveTracking.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

public class PunchFormRequest
{
    public IFormFile Selfie { get; set; } = null!;
    public double Latitude { get; set; }
    public double Longitude { get; set; }
}

[ApiController]
[Route("api/attendance")]
[Authorize]
public class AttendanceController : ControllerBase
{
    private static readonly string[] AllowedExtensions = { ".jpg", ".jpeg", ".png" };
    private const long MaxSelfieBytes = 5 * 1024 * 1024;

    private readonly IAttendanceService _attendanceService;

    public AttendanceController(IAttendanceService attendanceService)
    {
        _attendanceService = attendanceService;
    }

    [HttpPost("punch-in")]
    [Authorize(Roles = Roles.User)]
    [RequestSizeLimit(MaxSelfieBytes)]
    [ProducesResponseType(typeof(ApiResponse<AttendanceResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> PunchIn([FromForm] PunchFormRequest request, CancellationToken cancellationToken)
    {
        var selfie = ValidateAndOpenSelfie(request.Selfie);
        var dto = new PunchRequestDto { Latitude = request.Latitude, Longitude = request.Longitude };

        await using var stream = selfie.Content;
        var result = await _attendanceService.PunchInAsync(GetUserId(), dto, selfie, cancellationToken);
        return Ok(ApiResponse<AttendanceResponseDto>.SuccessResponse(result, "Duty In recorded successfully."));
    }

    [HttpPost("punch-out")]
    [Authorize(Roles = Roles.User)]
    [RequestSizeLimit(MaxSelfieBytes)]
    [ProducesResponseType(typeof(ApiResponse<AttendanceResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> PunchOut([FromForm] PunchFormRequest request, CancellationToken cancellationToken)
    {
        var selfie = ValidateAndOpenSelfie(request.Selfie);
        var dto = new PunchRequestDto { Latitude = request.Latitude, Longitude = request.Longitude };

        await using var stream = selfie.Content;
        var result = await _attendanceService.PunchOutAsync(GetUserId(), dto, selfie, cancellationToken);
        return Ok(ApiResponse<AttendanceResponseDto>.SuccessResponse(result, "Duty Out recorded successfully."));
    }

    [HttpGet("history")]
    [Authorize(Roles = Roles.User)]
    [ProducesResponseType(typeof(ApiResponse<List<AttendanceResponseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyHistory([FromQuery] DateTime? from, [FromQuery] DateTime? to, CancellationToken cancellationToken)
    {
        var result = await _attendanceService.GetHistoryAsync(GetUserId(), from, to, cancellationToken);
        return Ok(ApiResponse<List<AttendanceResponseDto>>.SuccessResponse(result));
    }

    [HttpGet("admin")]
    [Authorize(Roles = Roles.Admin)]
    [ProducesResponseType(typeof(ApiResponse<List<AttendanceResponseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll([FromQuery] int? userId, [FromQuery] DateTime? from, [FromQuery] DateTime? to, CancellationToken cancellationToken)
    {
        var result = await _attendanceService.GetAllAsync(userId, from, to, cancellationToken);
        return Ok(ApiResponse<List<AttendanceResponseDto>>.SuccessResponse(result));
    }

    [HttpGet("selfie/{id:long}")]
    public async Task<IActionResult> GetSelfie(long id, CancellationToken cancellationToken)
    {
        var (stream, contentType) = await _attendanceService.GetSelfieAsync(id, cancellationToken);
        return File(stream, contentType);
    }

    private static SelfieUpload ValidateAndOpenSelfie(IFormFile? file)
    {
        if (file is null || file.Length == 0)
        {
            throw new ValidationException("Selfie image is required.");
        }

        var extension = Path.GetExtension(file.FileName).ToLowerInvariant();
        if (!AllowedExtensions.Contains(extension))
        {
            throw new ValidationException("Selfie must be a JPG or PNG image.");
        }

        return new SelfieUpload { Content = file.OpenReadStream(), FileExtension = extension == ".jpeg" ? ".jpg" : extension };
    }

    private int GetUserId()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.Parse(value!);
    }
}
