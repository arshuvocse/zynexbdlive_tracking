// File: src/LiveTracking.API/Controllers/OfficeLocationsController.cs
using LiveTracking.Application.Common;
using LiveTracking.Application.DTOs.OfficeLocations;
using LiveTracking.Application.Interfaces;
using LiveTracking.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

[ApiController]
[Route("api/admin/office-locations")]
[Authorize(Roles = Roles.Admin)]
public class OfficeLocationsController : ControllerBase
{
    private readonly IOfficeLocationService _officeLocationService;

    public OfficeLocationsController(IOfficeLocationService officeLocationService)
    {
        _officeLocationService = officeLocationService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<OfficeLocationDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var result = await _officeLocationService.GetAllAsync(cancellationToken);
        return Ok(ApiResponse<List<OfficeLocationDto>>.SuccessResponse(result));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OfficeLocationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
    {
        var result = await _officeLocationService.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<OfficeLocationDto>.SuccessResponse(result));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<OfficeLocationDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] CreateOfficeLocationDto dto, CancellationToken cancellationToken)
    {
        var result = await _officeLocationService.CreateAsync(dto, cancellationToken);
        return Ok(ApiResponse<OfficeLocationDto>.SuccessResponse(result, "Office location created successfully."));
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<OfficeLocationDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateOfficeLocationDto dto, CancellationToken cancellationToken)
    {
        var result = await _officeLocationService.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<OfficeLocationDto>.SuccessResponse(result, "Office location updated successfully."));
    }
}
