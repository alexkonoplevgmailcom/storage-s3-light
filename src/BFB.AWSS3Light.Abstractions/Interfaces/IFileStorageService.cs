#region file:BFB.AWSS3Light.Storage.S3
using BFB.AWSS3Light.Abstractions.DTOs;
using BFB.AWSS3Light.Abstractions.Entities;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace BFB.AWSS3Light.Abstractions.Interfaces;

/// <summary>
/// Interface for file storage operations
/// </summary>
public interface IFileStorageService
{
    /// <summary>
    /// Uploads a file to storage
    /// </summary>
    /// <param name="request">File upload request</param>
    /// <returns>File upload response with metadata</returns>
    Task<FileUploadResponse> UploadFileAsync(FileUploadRequest request);

    /// <summary>
    /// Downloads a file from storage
    /// </summary>
    /// <param name="fileId">File identifier</param>
    /// <returns>File download response with content</returns>
    Task<FileDownloadResponse> DownloadFileAsync(Guid fileId);

    /// <summary>
    /// Gets file metadata
    /// </summary>
    /// <param name="fileId">File identifier</param>
    /// <returns>File metadata or null if not found</returns>
    Task<FileMetadata?> GetFileMetadataAsync(Guid fileId);

    /// <summary>
    /// Gets all files metadata
    /// </summary>
    /// <returns>Collection of file metadata</returns>
    Task<IEnumerable<FileMetadata>> GetAllFilesAsync();

    /// <summary>
    /// Deletes a file from storage
    /// </summary>
    /// <param name="fileId">File identifier</param>
    /// <returns>True if deleted successfully</returns>
    Task<bool> DeleteFileAsync(Guid fileId);

    /// <summary>
    /// Generates a download URL for a file
    /// </summary>
    /// <param name="fileId">File identifier</param>
    /// <param name="expirationMinutes">URL expiration time in minutes</param>
    /// <returns>Download URL</returns>
    Task<string> GenerateDownloadUrlAsync(Guid fileId, int expirationMinutes = 60);
}
#endregion
