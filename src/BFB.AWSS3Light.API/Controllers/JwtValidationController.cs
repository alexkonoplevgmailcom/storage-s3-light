using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Options;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Models;
using BFB.AWSS3Light.API.Attributes;

namespace BFB.AWSS3Light.API.Controllers;

[ApiController]
[Route("api/[controller]")]
[Produces("application/json")]
[DevelopmentOnly]
public class JwtValidationController : ControllerBase
{
    private readonly IJwtValidationService _jwtValidationService;
    private readonly IJwtGenerationService _jwtGenerationService;
    private readonly ILogger<JwtValidationController> _logger;
    private readonly JwtConfiguration _jwtConfig;

    public JwtValidationController(IJwtValidationService jwtValidationService, IJwtGenerationService jwtGenerationService, ILogger<JwtValidationController> logger, IOptions<JwtConfiguration> jwtConfig)
    {
        _jwtValidationService = jwtValidationService;
        _jwtGenerationService = jwtGenerationService;
        _logger = logger;
        _jwtConfig = jwtConfig.Value;
    }

    [HttpPost("validate")]
    [ProducesResponseType(typeof(JwtValidationResult), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<ActionResult<JwtValidationResult>> ValidateJwt([FromBody] JwtTokenRequest request)
    {
        try
        {
            if (string.IsNullOrEmpty(request?.Token))
            {
                return BadRequest("JWT token is required");
            }

            _logger.LogInformation("Validating JWT token");

            var result = await _jwtValidationService.ValidateTokenAsync(
                request.Token, 
                "", 
                _jwtConfig.Audience, 
                _jwtConfig.Issuer, 
                DateTime.UtcNow.AddMinutes(30));

            return Ok(result);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error validating JWT token");
            return StatusCode(500, "An error occurred while validating the JWT token");
        }
    }

    [HttpPost("generate")]
    [ProducesResponseType(typeof(string), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public ActionResult<string> GenerateJwt([FromBody] Dictionary<string, object>? claims = null)
    {
        try
        {
            _logger.LogInformation("Generating JWT token");

            var token = _jwtGenerationService.GenerateToken(
                _jwtConfig.Audience,
                _jwtConfig.Issuer,
                DateTime.UtcNow.AddMinutes(30),
                claims);

            return Ok(token);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error generating JWT token");
            return StatusCode(500, "An error occurred while generating the JWT token");
        }
    }
}