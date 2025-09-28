using Amazon.S3;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Diagnostics.HealthChecks;
using Microsoft.Extensions.Options;
using BFB.AWSS3Light.Storage.S3.Standalone.Configuration;

namespace BFB.AWSS3Light.Storage.S3.Standalone;

/// <summary>
/// Extension methods for registering S3 storage health checks
/// </summary>
public static class HealthCheckExtensions
{
    /// <summary>
    /// Adds S3 storage health check to the service collection
    /// </summary>
    /// <param name="builder">The health checks builder</param>
    /// <param name="name">The health check name (optional)</param>
    /// <param name="failureStatus">The failure status (optional)</param>
    /// <param name="tags">The health check tags (optional)</param>
    /// <returns>The health checks builder</returns>
    public static IHealthChecksBuilder AddS3HealthCheck(
        this IHealthChecksBuilder builder,
        string? name = null,
        HealthStatus? failureStatus = null,
        IEnumerable<string>? tags = null)
    {
        return builder.AddCheck<S3HealthCheck>(
            name ?? "s3-storage",
            failureStatus,
            tags ?? new[] { "storage", "s3" });
    }
}

/// <summary>
/// S3 health check implementation
/// </summary>
internal class S3HealthCheck : IHealthCheck
{
    private readonly IAmazonS3 _s3Client;
    private readonly S3StorageSettings _settings;

    public S3HealthCheck(IAmazonS3 s3Client, IOptions<S3StorageSettings> settings)
    {
        _s3Client = s3Client;
        _settings = settings.Value;
    }

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context,
        CancellationToken cancellationToken = default)
    {
        try
        {
            // Check if the configured bucket exists and is accessible
            var bucketExists = await Amazon.S3.Util.AmazonS3Util.DoesS3BucketExistV2Async(_s3Client, _settings.DefaultBucketName);
            
            if (bucketExists)
            {
                return HealthCheckResult.Healthy($"S3 bucket '{_settings.DefaultBucketName}' is accessible");
            }
            else
            {
                return HealthCheckResult.Unhealthy($"S3 bucket '{_settings.DefaultBucketName}' is not accessible");
            }
        }
        catch (Exception ex)
        {
            return HealthCheckResult.Unhealthy("S3 connection failed", ex);
        }
    }
}