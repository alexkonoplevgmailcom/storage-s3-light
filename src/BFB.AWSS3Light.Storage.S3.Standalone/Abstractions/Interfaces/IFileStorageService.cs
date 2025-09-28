using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Entities;
using System;
using System.Collections.Generic;
using System.Threading.Tasks;

namespace BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Interfaces;

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
    /// <param name="fileName">File name identifier</param>
    /// <returns>File download response with content</returns>
    Task<FileDownloadResponse> DownloadFileAsync(string fileName);

    /// <summary>
    /// Gets file metadata
    /// </summary>
    /// <param name="fileName">File name identifier</param>
    /// <returns>File metadata or null if not found</returns>
    Task<FileMetadata?> GetFileMetadataAsync(string fileName);

    /// <summary>
    /// Gets all files metadata
    /// </summary>
    /// <returns>Collection of file metadata</returns>
    Task<IEnumerable<FileMetadata>> GetAllFilesAsync();

    /// <summary>
    /// Deletes a file from storage
    /// </summary>
    /// <param name="fileName">File name identifier</param>
    /// <returns>True if deleted successfully</returns>
    Task<bool> DeleteFileAsync(string fileName);

    /// <summary>
    /// Generates a download URL for a file
    /// </summary>
    /// <param name="fileName">File name identifier</param>
    /// <param name="expirationMinutes">URL expiration time in minutes</param>
    /// <returns>Download URL</returns>
    Task<string> GenerateDownloadUrlAsync(string fileName, int expirationMinutes = 60);
}