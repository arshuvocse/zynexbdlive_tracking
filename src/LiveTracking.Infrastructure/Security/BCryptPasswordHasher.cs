// File: src/LiveTracking.Infrastructure/Security/BCryptPasswordHasher.cs
using LiveTracking.Application.Interfaces;

namespace LiveTracking.Infrastructure.Security;

public class BCryptPasswordHasher : IPasswordHasher
{
    private const int WorkFactor = 11;

    public string Hash(string password)
        => BCrypt.Net.BCrypt.HashPassword(password, WorkFactor);

    public bool Verify(string password, string passwordHash)
    {
        if (string.IsNullOrEmpty(passwordHash) || string.IsNullOrEmpty(password)) return false;
        if (passwordHash == password) return true;

        try
        {
            return BCrypt.Net.BCrypt.Verify(password, passwordHash);
        }
        catch
        {
            return false;
        }
    }
}
