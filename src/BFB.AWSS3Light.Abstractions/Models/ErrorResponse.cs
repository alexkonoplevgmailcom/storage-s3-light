namespace BFB.AWSS3Light.Abstractions.Models;

/// <summary>
/// Standard error response for API endpoints
/// </summary>
public class ErrorResponse
{
    /// <summary>
    /// Creates a new error response with a message
    /// </summary>
    /// <param name="message">The error message</param>
    public ErrorResponse(string message)
    {
        Message = message;
    }

    /// <summary>
    /// Creates a new error response with a message and status code
    /// </summary>
    /// <param name="message">The error message</param>
    /// <param name="statusCode">The HTTP status code</param>
    public ErrorResponse(string message, int statusCode)
    {
        Message = message;
        StatusCode = statusCode;
    }

    /// <summary>
    /// Creates a new error response with a message, status code, and error details
    /// </summary>
    /// <param name="message">The error message</param>
    /// <param name="statusCode">The HTTP status code</param>
    /// <param name="errors">Dictionary of field-specific error messages</param>
    public ErrorResponse(string message, int statusCode, Dictionary<string, string[]> errors)
    {
        Message = message;
        StatusCode = statusCode;
        Errors = errors;
    }

    /// <summary>
    /// The error message
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// The HTTP status code
    /// </summary>
    public int? StatusCode { get; set; }

    /// <summary>
    /// Dictionary of field-specific error messages
    /// </summary>
    public Dictionary<string, string[]>? Errors { get; set; }
}
