using Amazon.S3;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Interfaces;
using BFB.AWSS3Light.Storage.S3.Standalone.Configuration;
using BFB.AWSS3Light.Storage.S3.Standalone.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using System;

namespace BFB.AWSS3Light.Storage.S3.Standalone.Extensions;

/// <summary>
/// Extension methods for registering S3 storage services
/// </summary>
public static class ServiceCollectionExtensions
{
    /// <summary>
    /// Adds S3 storage services to the service collection
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <param name="configuration">The configuration instance</param>
    /// <returns>The service collection for chaining</returns>
    public static IServiceCollection AddS3Storage(
        this IServiceCollection services,
        IConfiguration configuration)
    {
        // Configure S3 settings
        services.Configure<S3StorageSettings>(
            configuration.GetSection("S3Storage"));

        // Configure resilience settings
        services.Configure<S3ResilienceSettings>(
            configuration.GetSection("S3Resilience"));

        // Register S3 client with enhanced resilience
        services.AddSingleton<IAmazonS3>(provider =>
        {
            var settings = configuration.GetSection("S3Storage").Get<S3StorageSettings>()
                ?? throw new InvalidOperationException("S3Storage configuration is missing");

            var config = new AmazonS3Config
            {
                RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(settings.Region),
                ForcePathStyle = settings.ForcePathStyle,
                Timeout = TimeSpan.FromSeconds(30),
                MaxErrorRetry = 3
            };

            if (!string.IsNullOrEmpty(settings.ServiceUrl))
            {
                config.ServiceURL = settings.ServiceUrl;
                config.UseHttp = settings.ServiceUrl.StartsWith("http://");
            }

            return new AmazonS3Client(settings.AccessKeyId, settings.SecretAccessKey, config);
        });

        // Register file storage service with resilience
        services.AddScoped<IFileStorageService, ResilientS3FileStorageService>();

        return services;
    }

    /// <summary>
    /// Adds S3 storage services to the service collection with explicit settings
    /// </summary>
    /// <param name="services">The service collection</param>
    /// <param name="configureS3">Action to configure S3 settings</param>
    /// <param name="configureResilience">Action to configure resilience settings (optional)</param>
    /// <returns>The service collection for chaining</returns>
    public static IServiceCollection AddS3Storage(
        this IServiceCollection services,
        Action<S3StorageSettings> configureS3,
        Action<S3ResilienceSettings>? configureResilience = null)
    {
        // Configure S3 settings
        services.Configure(configureS3);

        // Configure resilience settings with defaults
        if (configureResilience != null)
        {
            services.Configure(configureResilience);
        }
        else
        {
            services.Configure<S3ResilienceSettings>(settings => { }); // Use defaults
        }

        // Register S3 client
        services.AddSingleton<IAmazonS3>(provider =>
        {
            var settings = provider.GetRequiredService<Microsoft.Extensions.Options.IOptions<S3StorageSettings>>().Value;

            var config = new AmazonS3Config
            {
                RegionEndpoint = Amazon.RegionEndpoint.GetBySystemName(settings.Region),
                ForcePathStyle = settings.ForcePathStyle,
                Timeout = TimeSpan.FromSeconds(30),
                MaxErrorRetry = 3
            };

            if (!string.IsNullOrEmpty(settings.ServiceUrl))
            {
                config.ServiceURL = settings.ServiceUrl;
                config.UseHttp = settings.ServiceUrl.StartsWith("http://");
            }

            return new AmazonS3Client(settings.AccessKeyId, settings.SecretAccessKey, config);
        });

        // Register file storage service
        services.AddScoped<IFileStorageService, ResilientS3FileStorageService>();

        return services;
    }
}