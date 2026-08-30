// File: src/LiveTracking.API/Controllers/UsersController.cs
using LiveTracking.Application.Common;
using LiveTracking.Application.DTOs.Users;
using LiveTracking.Application.Interfaces;
using LiveTracking.Shared.Constants;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace LiveTracking.API.Controllers;

[ApiController]
[Route("api/users")]
[Authorize(Roles = Roles.Admin)]
public class UsersController : ControllerBase
{
    private readonly IUserService _userService;

    public UsersController(IUserService userService)
    {
        _userService = userService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiResponse<List<UserResponseDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken)
    {
        var users = await _userService.GetAllAsync(cancellationToken);
        return Ok(ApiResponse<List<UserResponseDto>>.SuccessResponse(users));
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<UserResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken)
    {
        var user = await _userService.GetByIdAsync(id, cancellationToken);
        return Ok(ApiResponse<UserResponseDto>.SuccessResponse(user));
    }

    [HttpPost]
    [ProducesResponseType(typeof(ApiResponse<UserResponseDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateUserDto dto, CancellationToken cancellationToken)
    {
        var user = await _userService.CreateAsync(dto, cancellationToken);
        return CreatedAtAction(nameof(GetById), new { id = user.Id },
            ApiResponse<UserResponseDto>.SuccessResponse(user, "User created successfully."));
    }

    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<UserResponseDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateUserDto dto, CancellationToken cancellationToken)
    {
        var user = await _userService.UpdateAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<UserResponseDto>.SuccessResponse(user, "User updated successfully."));
    }

    [HttpDelete("{id:int}")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken)
    {
        await _userService.DeleteAsync(id, cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { }, "User disabled successfully."));
    }

    [HttpPost("{id:int}/reset-password")]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiResponse<object>), StatusCodes.Status404NotFound)]
    public async Task<IActionResult> ResetPassword(int id, [FromBody] ResetPasswordDto dto, CancellationToken cancellationToken)
    {
        await _userService.ResetPasswordAsync(id, dto, cancellationToken);
        return Ok(ApiResponse<object>.SuccessResponse(new { }, "Password reset successfully."));
    }
}
