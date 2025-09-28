#region file:BFB.AWSS3Light.Storage.S3
using BFB.AWSS3Light.Abstractions.DTOs;
using BFB.AWSS3Light.Abstractions.Interfaces;
using BFB.AWSS3Light.Abstractions.Models;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Logging;
using System;
using System.Threading.Tasks;

namespace BFB.AWSS3Light.API.Controllers
{
    [ApiController]
    [Authorize]
    [Route("api/s3/files")]
    public class S3FilesController : ControllerBase
    {
        private readonly IFileStorageService _fileStorageService;
        private readonly ILogger<S3FilesController> _logger;
        private readonly FIBIContext _fibiContext;

        public S3FilesController(IFileStorageService fileStorageService, ILogger<S3FilesController> logger, FIBIContext fibiContext)
        {
            _fileStorageService = fileStorageService;
            _logger = logger;
            _fibiContext = fibiContext;
        }

        /// <summary>
        /// Uploads a file to S3 storage
        /// </summary>
        [HttpPost("upload")]
        [ProducesResponseType(typeof(FileUploadResponse), StatusCodes.Status201Created)]
        public async Task<IActionResult> Upload([FromForm] FileUploadRequest request)
        {
            _logger.LogInformation("Uploading file - Transaction: {TransactionId}", _fibiContext.TransactionId);
            var result = await _fileStorageService.UploadFileAsync(request);
            return CreatedAtAction(nameof(GetMetadata), new { id = result.Id }, result);
        }

        /// <summary>
        /// Downloads a file from S3 storage
        /// </summary>
        [HttpGet("download/{id}")]
        [ProducesResponseType(typeof(FileDownloadResponse), StatusCodes.Status200OK)]
        public async Task<IActionResult> Download(Guid id)
        {
            _logger.LogInformation("Downloading file {FileId} - Transaction: {TransactionId}", id, _fibiContext.TransactionId);
            var file = await _fileStorageService.DownloadFileAsync(id);
            return File(file.Content, file.ContentType, file.FileName);
        }

        /// <summary>
        /// Gets file metadata by ID
        /// </summary>
        [HttpGet("metadata/{id}")]
        public async Task<IActionResult> GetMetadata(Guid id)
        {
            _logger.LogInformation("Getting file metadata {FileId} - Transaction: {TransactionId}", id, _fibiContext.TransactionId);
            var metadata = await _fileStorageService.GetFileMetadataAsync(id);
            if (metadata == null) return NotFound();
            return Ok(metadata);
        }

        /// <summary>
        /// Gets all file metadata
        /// </summary>
        [HttpGet("metadata")]
        public async Task<IActionResult> GetAllMetadata()
        {
            _logger.LogInformation("Getting all file metadata - Transaction: {TransactionId}", _fibiContext.TransactionId);
            var files = await _fileStorageService.GetAllFilesAsync();
            return Ok(files);
        }

        /// <summary>
        /// Deletes a file from S3 storage
        /// </summary>
        [HttpDelete("{id}")]
        public async Task<IActionResult> Delete(Guid id)
        {
            var result = await _fileStorageService.DeleteFileAsync(id);
            if (!result) return NotFound();
            return NoContent();
        }

        /// <summary>
        /// Generates a pre-signed download URL for a file
        /// </summary>
        [HttpGet("download-url/{id}")]
        public async Task<IActionResult> GetDownloadUrl(Guid id, [FromQuery] int expirationMinutes = 60)
        {
            var url = await _fileStorageService.GenerateDownloadUrlAsync(id, expirationMinutes);
            return Ok(new { Url = url });
        }
    }
}
#endregion
