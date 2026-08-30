// File: src/LiveTracking.Application/Services/UserService.cs
using AutoMapper;
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.Users;
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Enums;
using LiveTracking.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace LiveTracking.Application.Services;

public class UserService : IUserService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IPasswordHasher _passwordHasher;
    private readonly IMapper _mapper;
    private readonly ILogger<UserService> _logger;

    public UserService(
        IUnitOfWork unitOfWork,
        IPasswordHasher passwordHasher,
        IMapper mapper,
        ILogger<UserService> logger)
    {
        _unitOfWork = unitOfWork;
        _passwordHasher = passwordHasher;
        _mapper = mapper;
        _logger = logger;
    }

    public async Task<List<UserResponseDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var users = await _unitOfWork.Users.GetAllAsync(cancellationToken);
        return _mapper.Map<List<UserResponseDto>>(users);
    }

    public async Task<UserResponseDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(User), id);

        return _mapper.Map<UserResponseDto>(user);
    }

    public async Task<UserResponseDto> CreateAsync(CreateUserDto dto, CancellationToken cancellationToken = default)
    {
        if (await _unitOfWork.Users.UsernameExistsAsync(dto.Username, null, cancellationToken))
        {
            throw new ValidationException($"Username '{dto.Username}' is already taken.");
        }

        var user = new User
        {
            Name = dto.Name,
            Username = dto.Username,
            PasswordHash = _passwordHasher.Hash(dto.Password),
            Role = Enum.Parse<UserRole>(dto.Role, ignoreCase: true),
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            OfficeLocationId = dto.OfficeLocationId
        };

        await _unitOfWork.Users.AddAsync(user, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User {Username} created with role {Role}.", user.Username, user.Role);

        return _mapper.Map<UserResponseDto>(user);
    }

    public async Task<UserResponseDto> UpdateAsync(int id, UpdateUserDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(User), id);

        user.Name = dto.Name;
        user.Role = Enum.Parse<UserRole>(dto.Role, ignoreCase: true);
        user.IsActive = dto.IsActive;
        user.OfficeLocationId = dto.OfficeLocationId;

        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User {UserId} updated.", id);

        return _mapper.Map<UserResponseDto>(user);
    }

    public async Task DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(User), id);

        user.IsActive = false;
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("User {UserId} disabled.", id);
    }

    public async Task ResetPasswordAsync(int id, ResetPasswordDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(User), id);

        user.PasswordHash = _passwordHasher.Hash(dto.NewPassword);
        _unitOfWork.Users.Update(user);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        _logger.LogInformation("Password reset for user {UserId}.", id);
    }
}
