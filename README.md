# NextGen PowerToys S3 Light - Standalone S3 NuGet Package

## Overview

This repository contains **NextGen PowerToys S3 Light** - a production-ready AWS S3 file storage service with file name-based identifiers. It provides comprehensive S3/MinIO storage functionality with advanced resilience patterns using Polly v8.

## Package Information

- **Package ID**: `NextGenPowerToys.Storage.S3.Light`
- **Current Version**: `1.4.0`
- **Target Framework**: `.NET 8.0`
- **License**: MIT

## Features

### Core Functionality
- ✅ **AWS S3 and MinIO Compatibility** - Works with both AWS S3 and MinIO storage
- ✅ **File Upload/Download** - Complete file management operations
- ✅ **Pre-signed URLs** - Secure temporary access to files
- ✅ **Metadata Tracking** - File information and custom tags
- ✅ **Automatic Bucket Management** - Creates buckets if they don't exist

### Enterprise Features
- ✅ **Advanced Resilience Patterns** - Polly v8 integration with retry, circuit breaker, and timeout
- ✅ **Health Check Integration** - ASP.NET Core health checks support
- ✅ **Structured Logging** - Microsoft.Extensions.Logging integration
- ✅ **Dependency Injection** - Full DI container support
- ✅ **Configuration Management** - IOptions pattern support
- ✅ **Server-side Encryption** - Optional SSE support

### Latest Updates (v1.1.0)
- ✅ **AWS SDK 4.0.7.4** - Latest AWS S3 SDK version
- ✅ **Microsoft.Extensions 9.0.9** - Updated to latest Microsoft packages
- ✅ **Polly 8.6.4** - Latest Polly resilience library
- ✅ **Enhanced Error Handling** - Improved error handling and logging

## Project Structure

```
├── src/
│   └── BFB.AWSS3Light.Storage.S3.Standalone/     # Main NuGet package project
├── test/
│   └── S3TestApp/                                  # Test console application
├── nupkg/                                          # Built NuGet packages
│   ├── BFB.AWSS3Light.Storage.S3.1.0.0.nupkg
│   ├── BFB.AWSS3Light.Storage.S3.1.1.0.nupkg     # Latest version
│   └── *.snupkg                                    # Symbol packages
└── README.md
```

## Quick Start

### 1. Install the NuGet Package

#### From Local Build
```bash
# Install from local nupkg folder
dotnet add package NextGenPowerToys.Storage.S3.Light --source ./nupkg
```

#### From NuGet.org (when published)
```bash
dotnet add package NextGenPowerToys.Storage.S3.Light
```

### 2. Configure Services

```csharp
using BFB.AWSS3Light.Storage.S3.Standalone.Extensions;

// In Program.cs or Startup.cs
services.AddS3Storage(configuration);
```

### 3. Configuration (appsettings.json)

```json
{
  "S3Storage": {
    "AccessKeyId": "your-access-key",
    "SecretAccessKey": "your-secret-key",
    "ServiceUrl": "https://s3.amazonaws.com",  // or MinIO endpoint
    "DefaultBucketName": "your-bucket",
    "Region": "us-east-1",
    "ForcePathStyle": false,                    // true for MinIO
    "UseServerSideEncryption": false
  },
  "S3Resilience": {
    "MaxRetryAttempts": 3,
    "BaseDelaySeconds": 1,
    "MaxDelaySeconds": 30,
    "UseExponentialBackoff": true,
    "CircuitBreakerFailureThreshold": 5,
    "CircuitBreakerDurationSeconds": 30,
    "RequestTimeoutSeconds": 60
  }
}
```

### 4. Use in Your Application

```csharp
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Interfaces;

public class FileController : ControllerBase
{
    private readonly IFileStorageService _storageService;

    public FileController(IFileStorageService storageService)
    {
        _storageService = storageService;
    }

    [HttpPost("upload")]
    public async Task<IActionResult> UploadFile(IFormFile file)
    {
        var request = new FileUploadRequest
        {
            File = file,
            BucketName = "my-bucket",
            Tags = "document,upload"
        };

        var response = await _storageService.UploadFileAsync(request);
        return Ok(response);
    }

    [HttpGet("download/{fileId}")]
    public async Task<IActionResult> DownloadFile(string fileId)
    {
        var response = await _storageService.DownloadFileAsync(fileId);
        return File(response.Content, response.ContentType, response.FileName);
    }
}
```

## MinIO Configuration

For MinIO compatibility, use these settings:

```json
{
  "S3Storage": {
    "AccessKeyId": "minioadmin",
    "SecretAccessKey": "minioadmin123",
    "ServiceUrl": "http://localhost:9000",
    "DefaultBucketName": "test-bucket",
    "Region": "us-east-1",
    "ForcePathStyle": true,              // Required for MinIO
    "UseServerSideEncryption": false
  }
}
```

## Testing

The repository includes a comprehensive test console application that demonstrates:

- ✅ **Real File Operations** - Creates actual files on disk
- ✅ **Upload/Download Testing** - Full round-trip testing
- ✅ **Content Verification** - Ensures data integrity
- ✅ **Pre-signed URL Generation** - Tests URL generation
- ✅ **Selective Operations** - Tests partial file operations
- ✅ **Health Check Validation** - Verifies service health

### Running Tests

```bash
cd test/S3TestApp
dotnet run
```

## Package Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| AWSSDK.S3 | 4.0.7.4 | AWS S3 SDK (Latest) |
| Polly | 8.6.4 | Resilience patterns |
| Microsoft.Extensions.* | 9.0.9 | Configuration, DI, Logging |
| Microsoft.AspNetCore.Http.Features | 5.0.17 | IFormFile support |

## Health Checks

The package includes built-in health checks:

```csharp
// Automatically registered with AddS3Storage()
services.AddHealthChecks(); // Will include S3 health check

// Check health endpoint
app.MapHealthChecks("/health");
```

## Resilience Patterns

### Retry Policy
- **Max Attempts**: 3 (configurable)
- **Backoff**: Exponential with jitter
- **Base Delay**: 1 second (configurable)

### Circuit Breaker
- **Failure Threshold**: 5 consecutive failures
- **Break Duration**: 30 seconds
- **Auto-recovery**: Automatic

### Timeout Policy
- **Request Timeout**: 60 seconds (configurable)
- **Applies to**: All S3 operations

## Contributing

This is a standalone extracted package. For the full BFB template implementation, see the [BFB Template repository](https://github.com/fibi-poc-dev/bfb-template-ng).

## License

MIT License - see the package metadata for full license terms.

---

**Ready for Production** ✅ | **Latest AWS SDK** ✅ | **Comprehensive Testing** ✅ | **Enterprise Features** ✅