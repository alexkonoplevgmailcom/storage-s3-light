namespace NextGenPowerToys.Storage.S3.Light.Abstractions.DTOs;

/// <summary>
/// File download response DTO
/// </summary>
public class FileDownloadResponse
{
    public byte[] Content { get; set; } = Array.Empty<byte>();
    public string ContentType { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
}