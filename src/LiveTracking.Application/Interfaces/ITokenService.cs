// File: src/LiveTracking.Application/Interfaces/ITokenService.cs
using LiveTracking.Domain.Entities;

namespace LiveTracking.Application.Interfaces;

public interface ITokenService
{
    (string Token, DateTime ExpiresAt) GenerateToken(User user);
}
