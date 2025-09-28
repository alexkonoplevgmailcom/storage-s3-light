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
- **🪣 Universal S3 Compatibility** - Works with ANY S3-compatible storage including AWS S3, MinIO, NetApp StorageGRID, DigitalOcean Spaces, and more

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

**Universal S3 Compatibility** - Works with ANY storage that implements the S3 API:

### ☁️ **Cloud Providers**
- **Amazon S3** - Native AWS S3 support with all features
- **DigitalOcean Spaces** - Full S3 API compatibility
- **Google Cloud Storage** - S3-compatible interoperability mode
- **Microsoft Azure Blob** - S3 API gateway support
- **IBM Cloud Object Storage** - S3-compatible interface
- **Oracle Cloud Infrastructure** - S3-compatible API

### 🏢 **Enterprise Storage**
- **NetApp StorageGRID** - Enterprise S3-compatible object storage
- **Dell EMC ECS** - S3-compatible enterprise storage platform  
- **HPE Scality RING** - S3-compatible distributed storage
- **Hitachi Content Platform** - S3 API support
- **Pure Storage FlashBlade** - S3-compatible NAS platform

### 🏠 **Self-Hosted Solutions**
- **MinIO** - High-performance S3-compatible server
- **Ceph RadosGW** - S3-compatible interface for Ceph
- **OpenStack Swift** - S3 API compatibility layer
- **SeaweedFS** - S3-compatible distributed file system
- **Rook Ceph** - Kubernetes-native S3-compatible storage

### 🔌 **Requirements**
Any storage system that implements the **AWS S3 REST API** including:
- Standard S3 operations (GET, PUT, DELETE, LIST)
- Bucket operations and management  
- Pre-signed URL generation
- Multipart upload support (optional but recommended)

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

#### S3Storage Settings

| Setting | Description | Required | Default | Example |
|---------|-------------|----------|---------|---------|
| `AccessKeyId` | AWS S3 or MinIO access key identifier. Used for authentication with the S3 service. | ✅ Yes | None | `"AKIAIOSFODNN7EXAMPLE"` |
| `SecretAccessKey` | AWS S3 or MinIO secret access key. Keep this secure and never expose in client-side code. | ✅ Yes | None | `"wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY"` |
| `ServiceUrl` | Custom S3 endpoint URL. Use for MinIO or other S3-compatible services. Leave empty for AWS S3. | ❌ No | None | `"http://localhost:9000"` |
| `DefaultBucketName` | Default S3 bucket name for file operations. Must exist or be created automatically. | ✅ Yes | None | `"my-app-storage"` |
| `Region` | AWS region where your S3 bucket is located. Required for AWS S3, optional for MinIO. | ❌ No | `"us-east-1"` | `"us-west-2"` |
| `ForcePathStyle` | Use path-style URLs (bucket.s3.amazonaws.com vs s3.amazonaws.com/bucket). Required for MinIO. | ❌ No | `false` | `true` for MinIO |
| `UseServerSideEncryption` | Enable AWS S3 server-side encryption (AES256). Not supported by all S3-compatible services. | ❌ No | `false` | `true` |

#### S3Resilience Settings

| Setting | Description | Required | Default | Recommended |
|---------|-------------|----------|---------|-------------|
| `MaxRetryAttempts` | Maximum number of retry attempts for failed S3 operations before giving up. | ❌ No | `3` | `3-5` |
| `BaseDelaySeconds` | Initial delay in seconds before the first retry attempt. Used as base for exponential backoff. | ❌ No | `1` | `1-2` |
| `MaxDelaySeconds` | Maximum delay in seconds between retry attempts. Prevents excessive wait times. | ❌ No | `30` | `30-60` |
| `UseExponentialBackoff` | Enable exponential backoff with jitter. Increases delay between retries to reduce server load. | ❌ No | `true` | `true` |
| `CircuitBreakerFailureThreshold` | Number of consecutive failures before opening the circuit breaker. | ❌ No | `5` | `3-10` |
| `CircuitBreakerDurationSeconds` | Time in seconds the circuit stays open before attempting recovery. | ❌ No | `30` | `30-120` |
| `RequestTimeoutSeconds` | Maximum time in seconds to wait for a single S3 operation to complete. | ❌ No | `60` | `30-120` |

#### Environment-Specific Examples

**AWS S3 Production:**
```json
{
  "S3Storage": {
    "AccessKeyId": "AKIAIOSFODNN7EXAMPLE",
    "SecretAccessKey": "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY",
    "DefaultBucketName": "my-production-bucket",
    "Region": "us-east-1",
    "ForcePathStyle": false,
    "UseServerSideEncryption": true
  }
}
```

**MinIO Development:**
```json
{
  "S3Storage": {
    "AccessKeyId": "minioadmin",
    "SecretAccessKey": "minioadmin123",
    "ServiceUrl": "http://localhost:9000",
    "DefaultBucketName": "dev-bucket",
    "Region": "us-east-1",
    "ForcePathStyle": true,
    "UseServerSideEncryption": false
  }
}
```

**NetApp StorageGRID Enterprise:**
```json
{
  "S3Storage": {
    "AccessKeyId": "your-netapp-access-key",
    "SecretAccessKey": "your-netapp-secret-key",
    "ServiceUrl": "https://storagegrid.company.com",
    "DefaultBucketName": "enterprise-data",
    "Region": "us-east-1",
    "ForcePathStyle": true,
    "UseServerSideEncryption": true
  }
}
```

**DigitalOcean Spaces:**
```json
{
  "S3Storage": {
    "AccessKeyId": "your-spaces-key",
    "SecretAccessKey": "your-spaces-secret",
    "ServiceUrl": "https://nyc3.digitaloceanspaces.com",
    "DefaultBucketName": "my-app-storage",
    "Region": "nyc3",
    "ForcePathStyle": false,
    "UseServerSideEncryption": false
  }
}
```

**High-Traffic Production:**
```json
{
  "S3Resilience": {
    "MaxRetryAttempts": 5,
    "BaseDelaySeconds": 2,
    "MaxDelaySeconds": 60,
    "UseExponentialBackoff": true,
    "CircuitBreakerFailureThreshold": 10,
    "CircuitBreakerDurationSeconds": 120,
    "RequestTimeoutSeconds": 90
  }
}
```

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