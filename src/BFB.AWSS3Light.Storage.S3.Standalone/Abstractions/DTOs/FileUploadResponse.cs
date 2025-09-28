using System;

namespace BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs;

/// <summary>
/// File upload response DTO
/// </summary>
public class FileUploadResponse
{
    public string Id { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string BucketName { get; set; } = string.Empty;
    public string ObjectKey { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
}