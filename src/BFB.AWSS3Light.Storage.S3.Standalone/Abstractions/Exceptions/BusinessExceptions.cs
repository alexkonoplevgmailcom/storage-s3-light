namespace BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Exceptions;

/// <summary>
/// Generic exception thrown when a resource is not found
/// </summary>
public class NotFoundException : Exception
{
    public NotFoundException(string message) : base(message)
    {
    }

    public NotFoundException(string resourceType, string identifier) 
        : base($"{resourceType} with identifier '{identifier}' was not found.")
    {
        ResourceType = resourceType;
        Identifier = identifier;
    }

    public string? ResourceType { get; }
    public string? Identifier { get; }
}

/// <summary>
/// Exception thrown for bad request data
/// </summary>
public class BadRequestException : Exception
{
    public BadRequestException(string message) : base(message)
    {
    }

    public BadRequestException(string field, string errorMessage) 
        : base($"Invalid {field}: {errorMessage}")
    {
        Field = field;
        ErrorMessage = errorMessage;
    }

    public string? Field { get; }
    public string? ErrorMessage { get; }
}