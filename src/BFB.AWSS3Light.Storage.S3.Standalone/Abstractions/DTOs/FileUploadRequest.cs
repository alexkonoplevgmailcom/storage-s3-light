using Microsoft.AspNetCore.Http;

namespace BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs;

/// <summary>
/// File upload request DTO
/// </summary>
public class FileUploadRequest
{
    public IFormFile File { get; set; } = null!;
    public string? BucketName { get; set; }
    public string? Tags { get; set; }
}