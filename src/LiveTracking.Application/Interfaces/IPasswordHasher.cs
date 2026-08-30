// File: src/LiveTracking.Application/Interfaces/IPasswordHasher.cs
namespace LiveTracking.Application.Interfaces;

public interface IPasswordHasher
{
    string Hash(string password);
    bool Verify(string password, string passwordHash);
}
