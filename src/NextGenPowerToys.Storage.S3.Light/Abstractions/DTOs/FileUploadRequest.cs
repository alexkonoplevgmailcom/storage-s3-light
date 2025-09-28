using Microsoft.AspNetCore.Http;

namespace NextGenPowerToys.Storage.S3.Light.Abstractions.DTOs;

/// <summary>
/// File upload request DTO
/// </summary>
public class FileUploadRequest
{
    public IFormFile File { get; set; } = null!;
    public string? BucketName { get; set; }
    public string? Tags { get; set; }
}