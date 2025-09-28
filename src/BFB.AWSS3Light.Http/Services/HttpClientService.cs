using System.IdentityModel.Tokens.Jwt;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Models;
using BFB.AWSS3Light.Http.Handlers;

namespace BFB.AWSS3Light.Http.Services;

public class HttpClientService : IHttpClientService
{
    private readonly IHttpClientFactory _httpClientFactory;
    private readonly IJwtGenerationService _jwtGenerationService;
    private readonly FIBIContext _fibiContext;
    private readonly IConfiguration _configuration;
    private readonly ILogger<HttpClientService> _logger;

    public HttpClientService(
        IHttpClientFactory httpClientFactory,
        IJwtGenerationService jwtGenerationService,
        FIBIContext fibiContext,
        IConfiguration configuration,
        ILogger<HttpClientService> logger)
    {
        _httpClientFactory = httpClientFactory;
        _jwtGenerationService = jwtGenerationService;
        _fibiContext = fibiContext;
        _configuration = configuration;
        _logger = logger;
    }

    public HttpClient CreateClient(string clientName, FibiHttpRequestOptions? options = null)
    {
        var client = _httpClientFactory.CreateClient(clientName);
        
        // Check if verbose logging is enabled
        var isVerboseLogging = _logger.IsEnabled(LogLevel.Debug) && 
                              _configuration.GetValue<bool>("Serilog:HttpClient:EnableVerboseLogging", false);
        
        if (isVerboseLogging)
        {
            _logger.LogInformation("[HttpClient-{ClientName}] Verbose logging enabled for HTTP requests", clientName);
        }
        
        // Load configuration from appsettings
        var config = _configuration.GetSection($"HttpClients:{clientName}").Get<HttpClientConfiguration>();
        if (config != null)
        {
            if (!string.IsNullOrEmpty(config.BaseUrl))
                client.BaseAddress = new Uri(config.BaseUrl);
            
            client.Timeout = TimeSpan.FromSeconds(config.TimeoutSeconds);
            
            // Add default headers from config
            if (config.DefaultHeaders != null)
            {
                foreach (var header in config.DefaultHeaders)
                {
                    client.DefaultRequestHeaders.Add(header.Key, header.Value);
                }
            }
        }

        // Always add transaction ID
        client.DefaultRequestHeaders.Add("x-fibi-transaction-id", _fibiContext.TransactionId);
        
        // Log client configuration in verbose mode
        if (isVerboseLogging)
        {
            LogClientConfiguration(clientName, client, config, options);
        }

        // Add custom headers from options
        if (options?.Headers != null)
        {
            foreach (var header in options.Headers)
            {
                client.DefaultRequestHeaders.Add(header.Key, header.Value);
            }
        }

        // Handle JWT
        var jwt = GetJwtToken(options);
        if (!string.IsNullOrEmpty(jwt))
        {
            client.DefaultRequestHeaders.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", jwt);
        }

        return client;
    }

    private string? GetJwtToken(FibiHttpRequestOptions? options)
    {
        if (options?.JwtMode == JwtMode.None) return null;

        return options?.JwtMode switch
        {
            JwtMode.UseExisting => options.ExistingJwt ?? _fibiContext.JwtToken,
            JwtMode.GenerateFresh => GenerateFreshJwt(options.JwtClaims),
            JwtMode.EnhanceExisting => EnhanceExistingJwt(options.ExistingJwt ?? _fibiContext.JwtToken, options.JwtClaims),
            _ => null
        };
    }

    private string GenerateFreshJwt(Dictionary<string, object>? claims)
    {
        return _jwtGenerationService.GenerateToken("", "", DateTime.UtcNow.AddMinutes(30), claims);
    }

    private string EnhanceExistingJwt(string? existingJwt, Dictionary<string, object>? additionalClaims)
    {
        if (string.IsNullOrEmpty(existingJwt)) return GenerateFreshJwt(additionalClaims);

        var handler = new JwtSecurityTokenHandler();
        var token = handler.ReadJwtToken(existingJwt);
        
        var existingClaims = token.Claims.ToDictionary(c => c.Type, c => (object)c.Value);
        
        if (additionalClaims != null)
        {
            foreach (var claim in additionalClaims)
            {
                existingClaims[claim.Key] = claim.Value;
            }
        }

        return _jwtGenerationService.GenerateToken("", "", DateTime.UtcNow.AddMinutes(30), existingClaims);
    }

    private void LogClientConfiguration(string clientName, HttpClient client, HttpClientConfiguration? config, FibiHttpRequestOptions? options)
    {
        _logger.LogDebug("[HttpClient-{ClientName}] Configuration Details:\n" +
                        "BaseAddress: {BaseAddress}\n" +
                        "Timeout: {Timeout}\n" +
                        "TransactionId: {TransactionId}\n" +
                        "Headers: {Headers}\n" +
                        "JWT Mode: {JwtMode}",
            clientName,
            client.BaseAddress,
            client.Timeout,
            _fibiContext.TransactionId,
            string.Join(", ", client.DefaultRequestHeaders.Select(h => $"{h.Key}={string.Join(",", h.Value)}")),
            options?.JwtMode ?? JwtMode.None);
    }
}