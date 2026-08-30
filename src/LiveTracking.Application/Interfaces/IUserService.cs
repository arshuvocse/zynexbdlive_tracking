// File: src/LiveTracking.Application/Interfaces/IUserService.cs
using LiveTracking.Application.DTOs.Users;

namespace LiveTracking.Application.Interfaces;

public interface IUserService
{
    Task<List<UserResponseDto>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<UserResponseDto> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<UserResponseDto> CreateAsync(CreateUserDto dto, CancellationToken cancellationToken = default);
    Task<UserResponseDto> UpdateAsync(int id, UpdateUserDto dto, CancellationToken cancellationToken = default);
    Task DeleteAsync(int id, CancellationToken cancellationToken = default);
    Task ResetPasswordAsync(int id, ResetPasswordDto dto, CancellationToken cancellationToken = default);
}
