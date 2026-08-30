// File: src/LiveTracking.Application/Common/Exceptions/UnauthorizedException.cs
namespace LiveTracking.Application.Common.Exceptions;

public class UnauthorizedException : Exception
{
    public UnauthorizedException(string message) : base(message) { }
}
