// File: src/LiveTracking.API/Controllers/LeaveTypesController.cs
using LiveTracking.Application.Common;
using LiveTracking.Application.DTOs.Leave;
using LiveTracking.Application.Interfaces;
using LiveTracking.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

[ApiController]
[Route("api/admin/leave-types")]
[Authorize(Roles = Roles.Admin)]
public class LeaveTypesController : ControllerBase
{
    private readonly ILeaveService _leaveService;

    public LeaveTypesController(ILeaveService leaveService)
    {
        _leaveService = leaveService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<LeaveTypeDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var result = await _leaveService.GetAllLeaveTypesAsync(cancellationToken);
        return Ok(ApiResponse<List<LeaveTypeDto>>.SuccessResponse(result));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<LeaveTypeDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] CreateLeaveTypeDto dto, CancellationToken cancellationToken)
    {
        var result = await _leaveService.CreateLeaveTypeAsync(dto, cancellationToken);
        return Ok(ApiResponse<LeaveTypeDto>.SuccessResponse(result, "Leave type created successfully."));
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<LeaveTypeDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateLeaveTypeDto dto, CancellationToken cancellationToken)
    {
        var result = await _leaveService.UpdateLeaveTypeAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<LeaveTypeDto>.SuccessResponse(result, "Leave type updated successfully."));
    }
}
