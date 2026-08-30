// File: src/LiveTracking.API/Controllers/LocationController.cs
using System.Security.Claims;
using LiveTracking.Application.Common;
using LiveTracking.Application.DTOs.Locations;
using LiveTracking.Application.Interfaces;
using LiveTracking.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

[ApiController]
[Route("api/location")]
[Authorize]
public class LocationController : ControllerBase
{
    private readonly ILocationService _locationService;

    public LocationController(ILocationService locationService)
    {
        _locationService = locationService;
    }

    [HttpPost("update")]
    [Authorize(Roles = Roles.User)]
    [ProducesResponseType(typeof(ApiResponse<LocationResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UpdateLocation([FromBody] LocationUpdateDto dto, CancellationToken cancellationToken)
    {
        var userId = GetUserId();
        var result = await _locationService.UpdateLocationAsync(userId, dto, cancellationToken);
        return Ok(ApiResponse<LocationResponseDto>.SuccessResponse(result, "Location updated successfully."));
    }

    [HttpGet("latest")]
    [Authorize(Roles = Roles.Admin)]
    [ProducesResponseType(typeof(ApiResponse<List<LocationResponseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetLatest(CancellationToken cancellationToken)
    {
        var result = await _locationService.GetLatestAsync(cancellationToken);
        return Ok(ApiResponse<List<LocationResponseDto>>.SuccessResponse(result));
    }

    [HttpGet("history/{userId:int}")]
    [Authorize(Roles = Roles.Admin)]
    [ProducesResponseType(typeof(ApiResponse<List<LocationHistoryDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetHistory(int userId, [FromQuery] DateTime? from, [FromQuery] DateTime? to, CancellationToken cancellationToken)
    {
        var result = await _locationService.GetHistoryAsync(userId, from, to, cancellationToken);
        return Ok(ApiResponse<List<LocationHistoryDto>>.SuccessResponse(result));
    }

    private int GetUserId()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.Parse(value!);
    }
}
