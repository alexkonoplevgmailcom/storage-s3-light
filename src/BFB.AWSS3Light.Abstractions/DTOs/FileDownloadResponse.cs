#region file:BFB.AWSS3Light.Storage.S3
namespace BFB.AWSS3Light.Abstractions.DTOs;

/// <summary>
/// File download response DTO
/// </summary>
public class FileDownloadResponse
{
    public byte[] Content { get; set; } = Array.Empty<byte>();
    public string ContentType { get; set; } = string.Empty;
    public string FileName { get; set; } = string.Empty;
}
#endregion
