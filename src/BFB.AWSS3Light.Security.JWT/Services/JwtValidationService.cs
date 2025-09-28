using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Models;

namespace BFB.AWSS3Light.Security.JWT.Services;

public class JwtValidationService : IJwtValidationService
{
    private readonly ILogger<JwtValidationService> _logger;
    private readonly JwtConfiguration _jwtConfig;
    private readonly byte[] _key;

    public JwtValidationService(ILogger<JwtValidationService> logger, IOptions<JwtConfiguration> jwtConfig)
    {
        _logger = logger;
        _jwtConfig = jwtConfig.Value;
        _key = ReadKeyFromCertificateFile(_jwtConfig.CertificateFileName);
    }

    public async Task<JwtValidationResult> ValidateTokenAsync(string jwt, string publicKey, string audience, string issuer, DateTime expiration)
    {
        try
        {
            var validationParameters = new TokenValidationParameters
            {
                ValidateIssuer = false,
                ValidateAudience = false,
                ValidateLifetime = true,
                IssuerSigningKey = new SymmetricSecurityKey(_key)
            };

            var handler = new JwtSecurityTokenHandler();
            var principal = handler.ValidateToken(jwt, validationParameters, out _);
            
            var claims = principal.Claims.ToDictionary(c => c.Type, c => (object)c.Value);

            _logger.LogInformation("JWT token validated successfully");

            return new JwtValidationResult
            {
                IsValid = true,
                Claims = claims
            };
        }
        catch (Exception ex)
        {
            _logger.LogWarning("JWT validation failed: {Message}", ex.Message);
            return new JwtValidationResult
            {
                IsValid = false,
                ErrorMessage = "Token validation failed"
            };
        }
    }

    private byte[] ReadKeyFromCertificateFile(string certificateFileName)
    {
        if (!File.Exists(certificateFileName))
            throw new IOException($"Unable to load certificate from {certificateFileName}");

        using var fileStream = File.OpenRead(certificateFileName);
        var retval = new byte[(int)fileStream.Length];
        fileStream.Read(retval, 0, (int)fileStream.Length);
        if (null == retval || Encoding.UTF8.GetString(retval).Contains('\r'))
            throw new InvalidDataException($"Token file is invalid. Please check it exists and is in Unix format ('LF')");
        return retval;
    }
}