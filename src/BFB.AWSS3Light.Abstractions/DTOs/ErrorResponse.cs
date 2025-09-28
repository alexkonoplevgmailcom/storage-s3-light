
namespace BFB.AWSS3Light.Abstractions.DTOs;

/// <summary>
/// DTO for API error responses
/// </summary>
public class ErrorResponse
{
    /// <summary>
    /// Error message
    /// </summary>
    public string Message { get; set; } = string.Empty;

    /// <summary>
    /// Error code (optional)
    /// </summary>
    public string? Code { get; set; }

    /// <summary>
    /// Additional error details (optional)
    /// </summary>
    public object? Details { get; set; }

    /// <summary>
    /// Timestamp when the error occurred
    /// </summary>
    public DateTime Timestamp { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Initializes a new instance of ErrorResponse with a message
    /// </summary>
    /// <param name="message">Error message</param>
    public ErrorResponse(string message)
    {
        Message = message;
    }

    /// <summary>
    /// Initializes a new instance of ErrorResponse with message and code
    /// </summary>
    /// <param name="message">Error message</param>
    /// <param name="code">Error code</param>
    public ErrorResponse(string message, string code) : this(message)
    {
        Code = code;
    }

    /// <summary>
    /// Initializes a new instance of ErrorResponse with message, code, and details
    /// </summary>
    /// <param name="message">Error message</param>
    /// <param name="code">Error code</param>
    /// <param name="details">Additional details</param>
    public ErrorResponse(string message, string code, object details) : this(message, code)
    {
        Details = details;
    }
}
