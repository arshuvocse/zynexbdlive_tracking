// File: src/LiveTracking.API/Middleware/GlobalExceptionMiddleware.cs
using System.Net;
using System.Text.Json;
using LiveTracking.Application.Common;
using LiveTracking.Application.Common.Exceptions;

namespace LiveTracking.API.Middleware;

public class GlobalExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<GlobalExceptionMiddleware> _logger;
    private readonly IHostEnvironment _environment;

    public GlobalExceptionMiddleware(RequestDelegate next, ILogger<GlobalExceptionMiddleware> logger, IHostEnvironment environment)
    {
        _next = next;
        _logger = logger;
        _environment = environment;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception exception)
    {
        context.Response.ContentType = "application/json";

        var response = exception switch
        {
            NotFoundException notFoundEx => (
                StatusCode: HttpStatusCode.NotFound,
                Body: ApiResponse<object>.FailureResponse(notFoundEx.Message)),

            ValidationException validationEx => (
                StatusCode: HttpStatusCode.BadRequest,
                Body: ApiResponse<object>.FailureResponse(validationEx.Message, validationEx.Errors)),

            UnauthorizedException unauthorizedEx => (
                StatusCode: HttpStatusCode.Unauthorized,
                Body: ApiResponse<object>.FailureResponse(unauthorizedEx.Message)),

            _ => (
                StatusCode: HttpStatusCode.InternalServerError,
                Body: ApiResponse<object>.FailureResponse(
                    _environment.IsDevelopment() ? exception.Message : "An unexpected error occurred."))
        };

        if (response.StatusCode == HttpStatusCode.InternalServerError)
        {
            _logger.LogError(exception, "Unhandled exception occurred while processing {Path}", context.Request.Path);
        }
        else
        {
            _logger.LogWarning("Handled exception {ExceptionType} for {Path}: {Message}",
                exception.GetType().Name, context.Request.Path, exception.Message);
        }

        context.Response.StatusCode = (int)response.StatusCode;
        var json = JsonSerializer.Serialize(response.Body, new JsonSerializerOptions
        {
            PropertyNamingPolicy = JsonNamingPolicy.CamelCase
        });

        await context.Response.WriteAsync(json);
    }
}
