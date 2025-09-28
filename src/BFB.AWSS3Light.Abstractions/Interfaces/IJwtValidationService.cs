using BFB.AWSS3Light.Abstractions.Models;

namespace BFB.AWSS3Light.Abstractions.Interfaces;

public interface IJwtValidationService
{
    Task<JwtValidationResult> ValidateTokenAsync(string jwt, string publicKey, string audience, string issuer, DateTime expiration);
}