using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Models;

namespace BFB.AWSS3Light.Security.JWT.Services;

public class JwtGenerationService : IJwtGenerationService
{
    private readonly ILogger<JwtGenerationService> _logger;
    private readonly JwtConfiguration _jwtConfig;
    private readonly byte[] _key;

    public JwtGenerationService(ILogger<JwtGenerationService> logger, IOptions<JwtConfiguration> jwtConfig)
    {
        _logger = logger;
        _jwtConfig = jwtConfig.Value;
        _key = ReadKeyFromCertificateFile(_jwtConfig.CertificateFileName);
    }

    public string GenerateToken(string audience, string issuer, DateTime expiration, Dictionary<string, object>? claims = null)
    {
        var securityKey = new SymmetricSecurityKey(_key);
        var signingCredentials = new SigningCredentials(securityKey, SecurityAlgorithms.HmacSha256);
        
        var tokenClaims = new List<Claim>();
        if (claims != null)
        {
            tokenClaims.AddRange(claims.Select(c => new Claim(c.Key, c.Value.ToString() ?? "")));
        }
        
        tokenClaims.Add(new Claim(JwtRegisteredClaimNames.Aud, audience));
        tokenClaims.Add(new Claim(JwtRegisteredClaimNames.Iss, issuer));
        tokenClaims.Add(new Claim(JwtRegisteredClaimNames.Nbf, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString()));
        tokenClaims.Add(new Claim(JwtRegisteredClaimNames.Exp, ((DateTimeOffset)expiration).ToUnixTimeSeconds().ToString()));
        tokenClaims.Add(new Claim(JwtRegisteredClaimNames.Iat, DateTimeOffset.UtcNow.ToUnixTimeSeconds().ToString()));

        var tokenDescriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(tokenClaims),
            Expires = expiration,
            SigningCredentials = signingCredentials
        };

        var handler = new JwtSecurityTokenHandler();
        var token = handler.CreateToken(tokenDescriptor);
        
        _logger.LogInformation("JWT token generated");
        
        return handler.WriteToken(token);
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