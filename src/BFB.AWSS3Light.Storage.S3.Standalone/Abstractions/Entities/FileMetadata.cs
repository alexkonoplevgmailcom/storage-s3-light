using System;

namespace BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Entities;

/// <summary>
/// File metadata entity
/// </summary>
public class FileMetadata
{
    public string Id { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
    public string ContentType { get; set; } = string.Empty;
    public long FileSize { get; set; }
    public string BucketName { get; set; } = string.Empty;
    public string ObjectKey { get; set; } = string.Empty;
    public DateTime UploadedAt { get; set; }
    public bool IsActive { get; set; } = true;
    public string Tags { get; set; } = string.Empty;
}