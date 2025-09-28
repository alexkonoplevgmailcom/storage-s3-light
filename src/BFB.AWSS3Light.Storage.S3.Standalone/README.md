# BFB.AWSS3Light.Storage.S3

A production-ready .NET library for AWS S3 file storage with advanced resilience patterns using Polly. Supports both AWS S3 and MinIO compatibility.

## Features

- ✅ **AWS S3 & MinIO Compatibility** - Works with both AWS S3 and MinIO servers
- ✅ **Advanced Resilience Patterns** - Built-in retry, circuit breaker, and timeout policies using Polly v8
- ✅ **Automatic Bucket Management** - Creates buckets automatically if they don't exist
- ✅ **Pre-signed URL Support** - Generate secure download URLs with configurable expiration
- ✅ **Health Check Integration** - Built-in health checks for monitoring S3 connectivity
- ✅ **Metadata Tracking** - In-memory metadata storage for fast access
- ✅ **Server-side Encryption** - Optional AES256 encryption support
- ✅ **Comprehensive Logging** - Structured logging with Serilog compatibility
- ✅ **.NET 9.0 Ready** - Optimized for the latest .NET version

## Installation

```bash
dotnet add package BFB.AWSS3Light.Storage.S3
```

## Quick Start

### 1. Configuration

Add the following to your `appsettings.json`:

```json
{
  "S3Storage": {
    "AccessKeyId": "your-access-key",
    "SecretAccessKey": "your-secret-key",
    "ServiceUrl": "http://localhost:9000",
    "DefaultBucketName": "my-files",
    "Region": "us-east-1",
    "ForcePathStyle": true,
    "UseServerSideEncryption": false
  },
  "S3Resilience": {
    "MaxRetryAttempts": 3,
    "BaseDelaySeconds": 1,
    "MaxDelaySeconds": 30,
    "UseExponentialBackoff": true,
    "CircuitBreakerFailureThreshold": 5,
    "CircuitBreakerDurationSeconds": 30,
    "RequestTimeoutSeconds": 30
  }
}
```

### 2. Service Registration

```csharp
using BFB.AWSS3Light.Storage.S3.Standalone.Extensions;

// Using configuration
builder.Services.AddS3Storage(builder.Configuration);

// Or using explicit configuration
builder.Services.AddS3Storage(
    s3Settings =>
    {
        s3Settings.AccessKeyId = "minioadmin";
        s3Settings.SecretAccessKey = "minioadmin";
        s3Settings.ServiceUrl = "http://localhost:9000";
        s3Settings.DefaultBucketName = "my-files";
        s3Settings.ForcePathStyle = true;
    },
    resilienceSettings =>
    {
        resilienceSettings.MaxRetryAttempts = 5;
        resilienceSettings.UseExponentialBackoff = true;
    }
);

// Add health checks (optional)
builder.Services.AddHealthChecks()
    .AddS3HealthCheck();
```

### 3. Usage

```csharp
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Interfaces;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs;

public class FileController : ControllerBase
{
    private readonly IFileStorageService _fileStorage;

    public FileController(IFileStorageService fileStorage)
    {
        _fileStorage = fileStorage;
    }

    [HttpPost("upload")]
    public async Task<IActionResult> Upload([FromForm] FileUploadRequest request)
    {
        var result = await _fileStorage.UploadFileAsync(request);
        return Ok(result);
    }

    [HttpGet("download/{id}")]
    public async Task<IActionResult> Download(Guid id)
    {
        var file = await _fileStorage.DownloadFileAsync(id);
        return File(file.Content, file.ContentType, file.FileName);
    }

    [HttpGet("metadata/{id}")]
    public async Task<IActionResult> GetMetadata(Guid id)
    {
        var metadata = await _fileStorage.GetFileMetadataAsync(id);
        return metadata == null ? NotFound() : Ok(metadata);
    }

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _fileStorage.DeleteFileAsync(id);
        return NoContent();
    }

    [HttpGet("download-url/{id}")]
    public async Task<IActionResult> GetDownloadUrl(Guid id, int expirationMinutes = 60)
    {
        var url = await _fileStorage.GenerateDownloadUrlAsync(id, expirationMinutes);
        return Ok(new { Url = url });
    }
}
```

## Configuration Options

### S3StorageSettings

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `AccessKeyId` | string | `""` | AWS access key ID or MinIO username |
| `SecretAccessKey` | string | `""` | AWS secret key or MinIO password |
| `ServiceUrl` | string? | `null` | Custom S3 endpoint URL (for MinIO) |
| `DefaultBucketName` | string | `""` | Default bucket name for operations |
| `Region` | string | `"us-east-1"` | AWS region or MinIO region |
| `ForcePathStyle` | bool | `false` | Use path-style URLs (required for MinIO) |
| `UseServerSideEncryption` | bool | `false` | Enable AES256 server-side encryption |

### S3ResilienceSettings

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `MaxRetryAttempts` | int | `3` | Maximum number of retry attempts |
| `BaseDelaySeconds` | int | `1` | Base delay between retries |
| `MaxDelaySeconds` | int | `30` | Maximum delay between retries |
| `UseExponentialBackoff` | bool | `true` | Use exponential backoff for retries |
| `CircuitBreakerFailureThreshold` | int | `5` | Circuit breaker failure threshold |
| `CircuitBreakerDurationSeconds` | int | `30` | Circuit breaker open duration |
| `RequestTimeoutSeconds` | int | `30` | Request timeout duration |

## MinIO Setup

To test with MinIO locally:

```bash
# Run MinIO with Docker
docker run -d \
  --name s3-minio \
  -p 9000-9001:9000-9001 \
  -e MINIO_ROOT_USER=minioadmin \
  -e MINIO_ROOT_PASSWORD=minioadmin \
  minio/minio server /data --console-address ":9001"
```

Access the MinIO console at http://localhost:9001

## Error Handling

The library includes comprehensive error handling with custom exceptions:

- `NotFoundException` - Thrown when a file is not found
- `BadRequestException` - Thrown for invalid requests

All S3 operations are wrapped with resilience policies that handle:
- Network timeouts
- Temporary S3 service unavailability  
- Rate limiting
- Connection issues

## Logging

The library uses `ILogger<T>` for structured logging. Key events logged:

- File upload/download operations
- Retry attempts
- Circuit breaker state changes
- S3 errors and exceptions

## Health Checks

The built-in health check verifies:
- S3 service connectivity
- Default bucket accessibility
- Authentication validity

## License

MIT License - see LICENSE file for details.

## Contributing

Contributions are welcome! Please submit pull requests or issues on GitHub.