// File: src/LiveTracking.Application/Common/Exceptions/NotFoundException.cs
namespace LiveTracking.Application.Common.Exceptions;

public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message) { }

    public NotFoundException(string entityName, object key)
        : base($"{entityName} with key '{key}' was not found.") { }
}
