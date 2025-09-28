using System;

namespace NextGenPowerToys.Storage.S3.Light.Configuration;

/// <summary>
/// Configuration settings for S3 storage
/// </summary>
public class S3StorageSettings
{
    public string AccessKeyId { get; set; } = string.Empty;
    public string SecretAccessKey { get; set; } = string.Empty;
    public string Region { get; set; } = "us-east-1";
    public string? ServiceUrl { get; set; }
    public string DefaultBucketName { get; set; } = string.Empty;
    public bool ForcePathStyle { get; set; } = false;
    public bool UseServerSideEncryption { get; set; } = false;
}