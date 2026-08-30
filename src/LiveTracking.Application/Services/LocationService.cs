// File: src/LiveTracking.Application/Services/LocationService.cs
using AutoMapper;
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.Locations;
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Interfaces;
using Microsoft.Extensions.Logging;

namespace LiveTracking.Application.Services;

public class LocationService : ILocationService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;
    private readonly ILocationBroadcaster _broadcaster;
    private readonly ILogger<LocationService> _logger;

    public LocationService(
        IUnitOfWork unitOfWork,
        IMapper mapper,
        ILocationBroadcaster broadcaster,
        ILogger<LocationService> logger)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
        _broadcaster = broadcaster;
        _logger = logger;
    }

    public async Task<LocationResponseDto> UpdateLocationAsync(int userId, LocationUpdateDto dto, CancellationToken cancellationToken = default)
    {
        var user = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Entities.User), userId);

        var location = new DriverLocation
        {
            UserId = userId,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            Accuracy = dto.Accuracy,
            Speed = dto.Speed,
            Bearing = dto.Bearing,
            RecordedAt = dto.RecordedAt,
            DeviceBattery = dto.DeviceBattery,
            NetworkType = dto.NetworkType
        };

        await _unitOfWork.Locations.AddAsync(location, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        var response = new LocationResponseDto
        {
            UserId = user.Id,
            Name = user.Name,
            Username = user.Username,
            Latitude = location.Latitude,
            Longitude = location.Longitude,
            Accuracy = location.Accuracy,
            Speed = location.Speed,
            Bearing = location.Bearing,
            RecordedAt = location.RecordedAt,
            DeviceBattery = location.DeviceBattery,
            NetworkType = location.NetworkType,
            IsOnline = true
        };

        await _broadcaster.BroadcastLocationUpdatedAsync(response, cancellationToken);

        _logger.LogInformation("Location updated for user {UserId} at {RecordedAt}.", userId, location.RecordedAt);

        return response;
    }

    public async Task<List<LocationResponseDto>> GetLatestAsync(CancellationToken cancellationToken = default)
    {
        var locations = await _unitOfWork.Locations.GetLatestForAllUsersAsync(cancellationToken);
        return _mapper.Map<List<LocationResponseDto>>(locations);
    }

    public async Task<List<LocationHistoryDto>> GetHistoryAsync(int userId, DateTime? from, DateTime? to, CancellationToken cancellationToken = default)
    {
        _ = await _unitOfWork.Users.GetByIdAsync(userId, cancellationToken)
            ?? throw new NotFoundException(nameof(Domain.Entities.User), userId);

        var history = await _unitOfWork.Locations.GetHistoryAsync(userId, from, to, cancellationToken);
        return _mapper.Map<List<LocationHistoryDto>>(history);
    }
}
