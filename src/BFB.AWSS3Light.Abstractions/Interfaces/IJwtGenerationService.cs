namespace BFB.AWSS3Light.Abstractions.Interfaces;

public interface IJwtGenerationService
{
    string GenerateToken(string audience, string issuer, DateTime expiration, Dictionary<string, object>? claims = null);
}