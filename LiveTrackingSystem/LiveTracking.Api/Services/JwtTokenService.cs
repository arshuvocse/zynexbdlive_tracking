using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using LiveTracking.Api.Models;
using Microsoft.IdentityModel.Tokens;

namespace LiveTracking.Api.Services;

public interface IJwtTokenService
{
    string GenerateToken(User user);
}

public class JwtTokenService : IJwtTokenService
{
    private readonly IConfiguration _config;

    public JwtTokenService(IConfiguration config)
    {
        _config = config;
    }

    public string GenerateToken(User user)
    {
        var jwtSection = _config.GetSection("Jwt");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtSection["Key"]!));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, user.UserId.ToString()),
            new(JwtRegisteredClaimNames.Sub, user.UserId.ToString()),
            new(ClaimTypes.Name, user.Username ?? string.Empty),
            new(ClaimTypes.Role, user.Role ?? "User"),
            new("fullName", !string.IsNullOrEmpty(user.FullName) ? user.FullName : (user.Username ?? "User"))
        };

        if (user.CompanyId.HasValue && user.CompanyId.Value > 0)
        {
            claims.Add(new Claim("companyId", user.CompanyId.Value.ToString()));
        }

        var token = new JwtSecurityToken(
            issuer: jwtSection["Issuer"],
            audience: jwtSection["Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddHours(double.Parse(jwtSection["ExpiryHours"] ?? "12")),
            signingCredentials: creds);

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
