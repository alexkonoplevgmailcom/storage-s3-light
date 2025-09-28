# NextGen PowerToys Storage S3 Light

A lightweight, resilient S3 storage library for .NET 8 with advanced features including Polly resilience patterns, health checks, and comprehensive file management capabilities.

## 🚀 Features

- **🛡️ Resilient Operations** - Built-in retry policies, circuit breakers, and timeout handling using Polly v8
- **📁 File Management** - Upload, download, delete, and list files with metadata tracking
- **🔗 Pre-signed URLs** - Generate secure, time-limited download URLs
- **🏥 Health Checks** - Integrated health monitoring for S3 connectivity
- **📊 Structured Logging** - Comprehensive logging with structured data
- **⚡ High Performance** - Optimized for speed and reliability
- **🔧 Easy Configuration** - Simple setup with appsettings.json or code configuration
- **🪣 S3 Compatible** - Works with AWS S3, MinIO, and other S3-compatible storage

## 📦 Installation

Install the NuGet package:

```bash
dotnet add package NextGenPowerToys.Storage.S3.Light
```

Or via Package Manager Console:

```powershell
Install-Package NextGenPowerToys.Storage.S3.Light
```

## ⚙️ Configuration

### appsettings.json

```json
{
  "S3Storage": {
    "AccessKeyId": "your-access-key",
    "SecretAccessKey": "your-secret-key",
    "ServiceUrl": "https://s3.amazonaws.com",
    "DefaultBucketName": "my-bucket",
    "Region": "us-east-1",
    "ForcePathStyle": false,
    "UseServerSideEncryption": true
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

### Dependency Injection Setup

```csharp
using NextGenPowerToys.Storage.S3.Light.Extensions;

// Configure services
services.AddS3Storage(configuration);

// Add health checks (optional)
services.AddHealthChecks()
    .AddS3HealthCheck();
```

## 🎯 Usage

### Basic File Operations

```csharp
using NextGenPowerToys.Storage.S3.Light.Abstractions.Interfaces;
using NextGenPowerToys.Storage.S3.Light.Abstractions.DTOs;

public class FileService
{
    private readonly IFileStorageService _storageService;

    public FileService(IFileStorageService storageService)
    {
        _storageService = storageService;
    }

    // Upload a file
    public async Task<string> UploadFileAsync(IFormFile file)
    {
        var request = new FileUploadRequest
        {
            File = file,
            BucketName = "my-bucket",
            Tags = "document,upload"
        };

        var response = await _storageService.UploadFileAsync(request);
        return response.Id; // Returns the file name as ID
    }

    // Download a file
    public async Task<byte[]> DownloadFileAsync(string fileName)
    {
        var response = await _storageService.DownloadFileAsync(fileName);
        return response.Content;
    }

    // Get file metadata
    public async Task<FileMetadata?> GetFileInfoAsync(string fileName)
    {
        return await _storageService.GetFileMetadataAsync(fileName);
    }

    // Generate download URL
    public async Task<string> GetDownloadUrlAsync(string fileName)
    {
        return await _storageService.GenerateDownloadUrlAsync(fileName, 60);
    }

    // List all files
    public async Task<IEnumerable<FileMetadata>> GetAllFilesAsync()
    {
        return await _storageService.GetAllFilesAsync();
    }

    // Delete a file
    public async Task<bool> DeleteFileAsync(string fileName)
    {
        return await _storageService.DeleteFileAsync(fileName);
    }
}
```

### Advanced Configuration

```csharp
// Manual configuration
services.AddS3Storage(s3Settings =>
{
    s3Settings.AccessKeyId = "your-key";
    s3Settings.SecretAccessKey = "your-secret";
    s3Settings.Region = "us-east-1";
    s3Settings.DefaultBucketName = "my-bucket";
}, resilienceSettings =>
{
    resilienceSettings.MaxRetryAttempts = 5;
    resilienceSettings.CircuitBreakerFailureThreshold = 3;
});
```

## 🏥 Health Checks

The library includes built-in health checks to monitor S3 connectivity:

```csharp
// Add health checks
services.AddHealthChecks()
    .AddS3HealthCheck("s3-storage");

// In Startup.cs or Program.cs
app.MapHealthChecks("/health");
```

Health check endpoint returns:
- ✅ **Healthy** - S3 bucket is accessible
- ❌ **Unhealthy** - Connection issues or bucket not accessible

## 🛠️ Resilience Features

### Retry Policies
- **Exponential Backoff** - Intelligent delay between retries
- **Max Attempts** - Configurable retry limits
- **Jittered Delays** - Prevents thundering herd problems

### Circuit Breaker
- **Failure Threshold** - Opens circuit after consecutive failures
- **Recovery Time** - Automatic circuit recovery
- **Fast Fail** - Immediate failure during circuit open state

### Timeout Handling
- **Request Timeouts** - Per-operation timeout configuration
- **Cancellation Support** - Proper cancellation token handling

## 📊 Logging

The library provides structured logging for all operations:

```csharp
// Example log output
[INFO] File uploaded to S3 and metadata stored. FileName: document.pdf
[INFO] File downloaded from S3. FileName: document.pdf, Size: 1024 bytes
[WARN] Retry attempt 2/3 for S3 operation. FileName: document.pdf
[ERROR] S3 operation failed after all retry attempts. FileName: document.pdf
```

## 🔧 Supported Storage Providers

- **Amazon S3** - Native AWS S3 support
- **MinIO** - Self-hosted S3-compatible storage
- **DigitalOcean Spaces** - S3-compatible object storage
- **Any S3-Compatible Storage** - Standard S3 API compliance

## 📋 Requirements

- **.NET 8.0** or higher
- **AWS SDK for .NET** (included)
- **Polly v8** for resilience (included)
- **Microsoft.Extensions.*** packages (included)

## 🎮 Quick Start Example

1. **Install the package**:
   ```bash
   dotnet add package NextGenPowerToys.Storage.S3.Light
   ```

2. **Configure your app**:
   ```csharp
   services.AddS3Storage(configuration);
   ```

3. **Use in your controller**:
   ```csharp
   [ApiController]
   public class FilesController : ControllerBase
   {
       private readonly IFileStorageService _storage;
       
       public FilesController(IFileStorageService storage)
       {
           _storage = storage;
       }
       
       [HttpPost("upload")]
       public async Task<IActionResult> Upload(IFormFile file)
       {
           var request = new FileUploadRequest { File = file };
           var result = await _storage.UploadFileAsync(request);
           return Ok(new { FileId = result.Id, Size = result.FileSize });
       }
   }
   ```

## 📚 API Reference

### IFileStorageService Methods

| Method | Description | Returns |
|--------|-------------|---------|
| `UploadFileAsync(request)` | Upload a file to storage | `FileUploadResponse` |
| `DownloadFileAsync(fileName)` | Download file by name | `FileDownloadResponse` |
| `GetFileMetadataAsync(fileName)` | Get file metadata | `FileMetadata?` |
| `GetAllFilesAsync()` | List all files | `IEnumerable<FileMetadata>` |
| `DeleteFileAsync(fileName)` | Delete a file | `bool` |
| `GenerateDownloadUrlAsync(fileName, expiry)` | Create pre-signed URL | `string` |

### Configuration Options

| Setting | Description | Default |
|---------|-------------|---------|
| `AccessKeyId` | S3 access key | Required |
| `SecretAccessKey` | S3 secret key | Required |
| `Region` | AWS region | `us-east-1` |
| `DefaultBucketName` | Default bucket | Required |
| `ForcePathStyle` | Use path-style URLs | `false` |
| `UseServerSideEncryption` | Enable SSE | `false` |

## 🤝 Contributing

Contributions are welcome! Please feel free to submit pull requests, report bugs, or suggest features.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🏷️ Version

Current version: **1.4.0**

## 🔗 Links

- **Repository**: [https://github.com/alexkonoplevgmailcom/storage-s3-light](https://github.com/alexkonoplevgmailcom/storage-s3-light)
- **NuGet Package**: [NextGenPowerToys.Storage.S3.Light](https://www.nuget.org/packages/NextGenPowerToys.Storage.S3.Light)
- **Issues**: [Report a bug or request a feature](https://github.com/alexkonoplevgmailcom/storage-s3-light/issues)

---

**NextGen PowerToys** - Empowering developers with powerful, easy-to-use tools. 🚀