using LiveTracking.Api.Data;
using LiveTracking.Api.DTOs;
using LiveTracking.Api.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize(Roles = UserRoles.Admin)]
public class UsersController : ControllerBase
{
    private readonly LiveTrackingDbContext _db;

    public UsersController(LiveTrackingDbContext db)
    {
        _db = db;
    }

    [HttpGet]
    public async Task<ActionResult<List<UserResponse>>> GetAll()
    {
        var users = await _db.Users
            .OrderBy(u => u.Name)
            .Select(u => new UserResponse
            {
                Id = u.Id,
                Name = u.Name,
                Username = u.Username,
                Role = u.Role,
                IsActive = u.IsActive,
                CreatedAt = u.CreatedAt
            })
            .ToListAsync();

        return Ok(users);
    }

    [HttpPost]
    public async Task<ActionResult<UserResponse>> Create(CreateUserRequest request)
    {
        if (request.Role != UserRoles.Admin && request.Role != UserRoles.User)
        {
            return BadRequest(new { message = "Role must be 'Admin' or 'User'." });
        }

        var usernameTaken = await _db.Users.AnyAsync(u => u.Username == request.Username);
        if (usernameTaken)
        {
            return Conflict(new { message = "Username already exists." });
        }

        var user = new User
        {
            Name = request.Name,
            Username = request.Username,
            PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.Password),
            Role = request.Role,
            IsActive = true
        };

        _db.Users.Add(user);
        await _db.SaveChangesAsync();

        var response = new UserResponse
        {
            Id = user.Id,
            Name = user.Name,
            Username = user.Username,
            Role = user.Role,
            IsActive = user.IsActive,
            CreatedAt = user.CreatedAt
        };

        return CreatedAtAction(nameof(GetAll), new { id = user.Id }, response);
    }

    [HttpPut("{id:int}/deactivate")]
    public async Task<IActionResult> Deactivate(int id)
    {
        var user = await _db.Users.FindAsync(id);
        if (user is null) return NotFound();

        user.IsActive = false;
        await _db.SaveChangesAsync();
        return NoContent();
    }
}
