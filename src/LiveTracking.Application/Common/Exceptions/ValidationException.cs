// File: src/LiveTracking.Application/Common/Exceptions/ValidationException.cs
namespace LiveTracking.Application.Common.Exceptions;

public class ValidationException : Exception
{
    public List<string> Errors { get; }

    public ValidationException(List<string> errors) : base("One or more validation errors occurred.")
    {
        Errors = errors;
    }

    public ValidationException(string error) : base(error)
    {
        Errors = new List<string> { error };
    }
}
