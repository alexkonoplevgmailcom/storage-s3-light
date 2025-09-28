namespace BFB.AWSS3Light.Abstractions.Models;

public class JwtValidationResult
{
    public bool IsValid { get; set; }
    public string? ErrorMessage { get; set; }
    public Dictionary<string, object>? Claims { get; set; }
}