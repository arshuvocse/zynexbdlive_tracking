// File: src/LiveTracking.API/Controllers/LeaveController.cs
using System.Security.Claims;
using LiveTracking.Application.Common;
using LiveTracking.Application.DTOs.Leave;
using LiveTracking.Application.Interfaces;
using LiveTracking.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

[ApiController]
[Route("api/leave")]
[Authorize]
public class LeaveController : ControllerBase
{
    private readonly ILeaveService _leaveService;

    public LeaveController(ILeaveService leaveService)
    {
        _leaveService = leaveService;
    }

    [HttpGet("types")]
    [ProducesResponseType(typeof(ApiResponse<List<LeaveTypeDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetActiveTypes(CancellationToken cancellationToken)
    {
        var result = await _leaveService.GetActiveLeaveTypesAsync(cancellationToken);
        return Ok(ApiResponse<List<LeaveTypeDto>>.SuccessResponse(result));
    }

    [HttpGet("my-balances")]
    [Authorize(Roles = Roles.User)]
    [ProducesResponseType(typeof(ApiResponse<List<LeaveBalanceDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyBalances(CancellationToken cancellationToken)
    {
        var result = await _leaveService.GetMyBalancesAsync(GetUserId(), cancellationToken);
        return Ok(ApiResponse<List<LeaveBalanceDto>>.SuccessResponse(result));
    }

    [HttpPost("apply")]
    [Authorize(Roles = Roles.User)]
    [ProducesResponseType(typeof(ApiResponse<LeaveApplicationResponseDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Apply([FromBody] ApplyLeaveDto dto, CancellationToken cancellationToken)
    {
        var result = await _leaveService.ApplyAsync(GetUserId(), dto, cancellationToken);
        return Ok(ApiResponse<LeaveApplicationResponseDto>.SuccessResponse(result, "Leave application submitted successfully."));
    }

    [HttpGet("my-history")]
    [Authorize(Roles = Roles.User)]
    [ProducesResponseType(typeof(ApiResponse<List<LeaveApplicationResponseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyHistory(CancellationToken cancellationToken)
    {
        var result = await _leaveService.GetMyHistoryAsync(GetUserId(), cancellationToken);
        return Ok(ApiResponse<List<LeaveApplicationResponseDto>>.SuccessResponse(result));
    }

    [HttpPut("{id:int}/cancel")]
    [Authorize(Roles = Roles.User)]
    [ProducesResponseType(typeof(ApiResponse<LeaveApplicationResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Cancel(int id, CancellationToken cancellationToken)
    {
        var result = await _leaveService.CancelAsync(GetUserId(), id, cancellationToken);
        return Ok(ApiResponse<LeaveApplicationResponseDto>.SuccessResponse(result, "Leave application cancelled."));
    }

    [HttpGet("admin")]
    [Authorize(Roles = Roles.Admin)]
    [ProducesResponseType(typeof(ApiResponse<List<LeaveApplicationResponseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetApplications([FromQuery] string? status, CancellationToken cancellationToken)
    {
        var result = await _leaveService.GetApplicationsAsync(status, cancellationToken);
        return Ok(ApiResponse<List<LeaveApplicationResponseDto>>.SuccessResponse(result));
    }

    [HttpPut("admin/{id:int}/approve")]
    [Authorize(Roles = Roles.Admin)]
    [ProducesResponseType(typeof(ApiResponse<LeaveApplicationResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Approve(int id, [FromBody] LeaveReviewDto dto, CancellationToken cancellationToken)
    {
        var result = await _leaveService.ApproveAsync(GetUserId(), id, dto, cancellationToken);
        return Ok(ApiResponse<LeaveApplicationResponseDto>.SuccessResponse(result, "Leave application approved."));
    }

    [HttpPut("admin/{id:int}/reject")]
    [Authorize(Roles = Roles.Admin)]
    [ProducesResponseType(typeof(ApiResponse<LeaveApplicationResponseDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Reject(int id, [FromBody] LeaveReviewDto dto, CancellationToken cancellationToken)
    {
        var result = await _leaveService.RejectAsync(GetUserId(), id, dto, cancellationToken);
        return Ok(ApiResponse<LeaveApplicationResponseDto>.SuccessResponse(result, "Leave application rejected."));
    }

    private int GetUserId()
    {
        var value = User.FindFirstValue(ClaimTypes.NameIdentifier);
        return int.Parse(value!);
    }
}
