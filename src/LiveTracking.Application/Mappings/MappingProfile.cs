// File: src/LiveTracking.Application/Mappings/MappingProfile.cs
using AutoMapper;
using LiveTracking.Application.DTOs.Locations;
using LiveTracking.Application.DTOs.OfficeLocations;
using LiveTracking.Application.DTOs.Leave;
using LiveTracking.Application.DTOs.Users;
using LiveTracking.Domain.Entities;
using LiveTracking.Shared.Constants;

namespace LiveTracking.Application.Mappings;

public class MappingProfile : Profile
{
    public MappingProfile()
    {
        CreateMap<User, UserResponseDto>()
            .ForMember(d => d.Role, opt => opt.MapFrom(s => s.Role.ToString()))
            .ForMember(d => d.OfficeLocationName, opt => opt.MapFrom(s => s.OfficeLocation != null ? s.OfficeLocation.Name : null));

        CreateMap<DriverLocation, LocationHistoryDto>();

        CreateMap<DriverLocation, LocationResponseDto>()
            .ForMember(d => d.Name, opt => opt.MapFrom(s => s.User.Name))
            .ForMember(d => d.Username, opt => opt.MapFrom(s => s.User.Username))
            .ForMember(d => d.IsOnline, opt => opt.MapFrom(s =>
                (DateTime.UtcNow - s.RecordedAt).TotalMinutes <= AppConstants.OfflineThresholdMinutes));

        CreateMap<OfficeLocation, OfficeLocationDto>();
        CreateMap<LeaveType, LeaveTypeDto>();
    }
}
