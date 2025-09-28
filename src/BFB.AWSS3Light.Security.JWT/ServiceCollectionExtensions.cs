using Microsoft.Extensions.DependencyInjection;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Security.JWT.Services;

namespace BFB.AWSS3Light.Security.JWT;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddJwtValidation(this IServiceCollection services)
    {
        services.AddScoped<IJwtValidationService, JwtValidationService>();
        services.AddScoped<IJwtGenerationService, JwtGenerationService>();
        return services;
    }
}