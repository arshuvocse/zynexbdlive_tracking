using LiveTracking.Api.Data;
using LiveTracking.Api.DTOs;
using LiveTracking.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace LiveTracking.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly LiveTrackingDbContext _db;
    private readonly IJwtTokenService _jwt;
    private readonly IPasswordHasherService _hasher;

    public AuthController(LiveTrackingDbContext db, IJwtTokenService jwt, IPasswordHasherService hasher)
    {
        _db = db;
        _jwt = jwt;
        _hasher = hasher;
    }

    [HttpPost("login")]
    public async Task<ActionResult<LoginResponse>> Login(LoginRequest request)
    {
        try
        {
            // Accept username OR phone number as the login identifier
            var user = await _db.Users
                .Include(u => u.Company)
                .FirstOrDefaultAsync(u =>
                    u.Username == request.Username ||
                    (u.PhoneNumber != null && u.PhoneNumber == request.Username));

            if (user is null || !user.IsActive)
                return Unauthorized(new { message = "Invalid username/mobile or password." });

            if (!_hasher.Verify(user, user.PasswordHash, request.Password))
                return Unauthorized(new { message = "Invalid username/mobile or password." });

            // Device Locking & Single-Device Enforcement for all users (including Admin)
            if (!string.IsNullOrWhiteSpace(request.DeviceId))
            {
                var reqDeviceId = request.DeviceId.Trim();
                var reqDeviceModel = request.DeviceModel?.Trim();

                if (string.IsNullOrWhiteSpace(user.BoundDeviceId))
                {
                    // First time login on a device -> Bind this device permanently to the user/admin
                    user.BoundDeviceId = reqDeviceId;
                    user.DeviceModel = reqDeviceModel;
                    user.UpdatedAtUtc = DateTime.UtcNow;
                    await _db.SaveChangesAsync();
                }
                else if (!string.Equals(user.BoundDeviceId.Trim(), reqDeviceId, StringComparison.OrdinalIgnoreCase))
                {
                    var boundDeviceName = !string.IsNullOrWhiteSpace(user.DeviceModel) ? user.DeviceModel : "রেজিস্টার্ড ডিভাইসে";
                    var contactPerson = user.Role == "Admin" ? "সুপার অ্যাডমিন / টেকনিক্যাল সাপোর্টের" : "অ্যাডমিনের";
                    return StatusCode(403, new
                    {
                        message = $"ডিভাইস অনুমোদিত নয়!\nআপনার {(user.Role == "Admin" ? "অ্যাডমিন " : "")}একাউন্টটি ইতোমধ্যে '{boundDeviceName}' ডিভাইসে নিবন্ধিত আছে। একটির বেশি ডিভাইসে লগইন করা যাবে না। ডিভাইস পরিবর্তন করতে {contactPerson} সাথে যোগাযোগ করুন।"
                    });
                }
            }

            var token = _jwt.GenerateToken(user);
            var expiresAt = DateTime.UtcNow.AddDays(7).ToString("o");
            var response = new LoginResponse(
                token,
                expiresAt,
                user.UserId,
                user.FullName,
                user.Username,
                user.Role,
                user.CompanyId,
                user.Company?.CompanyName,
                user.Company?.BrandLogo
            );
            return Ok(response);
        }
        catch (Exception ex)
        {
            return StatusCode(500, new
            {
                message = "An internal server error occurred while processing login.",
                error = ex.Message,
                innerError = ex.InnerException?.Message
            });
        }
    }

    [HttpPost("seed-admin")]
    [Authorize(Roles = "Admin")]
    public async Task<IActionResult> SeedAdmin()
    {
        try
        {
            var user = await _db.Users.FirstOrDefaultAsync(u => u.Username == "admin");
            if (user == null)
            {
                user = new LiveTracking.Api.Models.User
                {
                    Username = "admin",
                    FullName = "System Administrator",
                    Role = "Admin",
                    IsActive = true,
                    CreatedAtUtc = DateTime.UtcNow
                };
                user.PasswordHash = _hasher.Hash(user, "Admin@123");
                _db.Users.Add(user);
                await _db.SaveChangesAsync();
                return Ok(new { message = "Admin user created successfully with password Admin@123." });
            }

            user.IsActive = true;
            user.PasswordHash = _hasher.Hash(user, "Admin@123");
            user.UpdatedAtUtc = DateTime.UtcNow;
            await _db.SaveChangesAsync();
            return Ok(new { message = "Admin user password reset successfully to Admin@123 and activated." });
        }
        catch (Exception ex)
        {
            return StatusCode(500, new { message = "Failed to seed admin", error = ex.Message });
        }
    }
}
