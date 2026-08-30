// File: src/LiveTracking.Application/Services/OfficeLocationService.cs
using AutoMapper;
using LiveTracking.Application.Common.Exceptions;
using LiveTracking.Application.DTOs.OfficeLocations;
using LiveTracking.Application.Interfaces;
using LiveTracking.Domain.Entities;
using LiveTracking.Domain.Interfaces;

namespace LiveTracking.Application.Services;

public class OfficeLocationService : IOfficeLocationService
{
    private readonly IUnitOfWork _unitOfWork;
    private readonly IMapper _mapper;

    public OfficeLocationService(IUnitOfWork unitOfWork, IMapper mapper)
    {
        _unitOfWork = unitOfWork;
        _mapper = mapper;
    }

    public async Task<List<OfficeLocationDto>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var locations = await _unitOfWork.OfficeLocations.GetAllAsync(cancellationToken);
        return _mapper.Map<List<OfficeLocationDto>>(locations);
    }

    public async Task<OfficeLocationDto> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var location = await _unitOfWork.OfficeLocations.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(OfficeLocation), id);

        return _mapper.Map<OfficeLocationDto>(location);
    }

    public async Task<OfficeLocationDto> CreateAsync(CreateOfficeLocationDto dto, CancellationToken cancellationToken = default)
    {
        var location = new OfficeLocation
        {
            Name = dto.Name,
            Latitude = dto.Latitude,
            Longitude = dto.Longitude,
            RadiusMeters = dto.RadiusMeters,
            IsActive = true
        };

        await _unitOfWork.OfficeLocations.AddAsync(location, cancellationToken);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return _mapper.Map<OfficeLocationDto>(location);
    }

    public async Task<OfficeLocationDto> UpdateAsync(int id, UpdateOfficeLocationDto dto, CancellationToken cancellationToken = default)
    {
        var location = await _unitOfWork.OfficeLocations.GetByIdAsync(id, cancellationToken)
            ?? throw new NotFoundException(nameof(OfficeLocation), id);

        location.Name = dto.Name;
        location.Latitude = dto.Latitude;
        location.Longitude = dto.Longitude;
        location.RadiusMeters = dto.RadiusMeters;
        location.IsActive = dto.IsActive;

        _unitOfWork.OfficeLocations.Update(location);
        await _unitOfWork.SaveChangesAsync(cancellationToken);

        return _mapper.Map<OfficeLocationDto>(location);
    }
}
