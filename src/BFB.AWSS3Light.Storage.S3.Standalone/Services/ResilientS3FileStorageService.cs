using Amazon.S3;
using Amazon.S3.Model;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Entities;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Exceptions;
using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Interfaces;
using BFB.AWSS3Light.Storage.S3.Standalone.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;
using Polly;
using Polly.CircuitBreaker;
using Polly.Retry;
using System;
using System.Collections.Concurrent;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;

namespace BFB.AWSS3Light.Storage.S3.Standalone.Services;

/// <summary>
/// Resilient S3 implementation of file storage service with Polly patterns
/// </summary>
public class ResilientS3FileStorageService : IFileStorageService
{
    private readonly IAmazonS3 _s3Client;
    private readonly S3StorageSettings _settings;
    private readonly S3ResilienceSettings _resilienceSettings;
    private readonly ILogger<ResilientS3FileStorageService> _logger;
    private static readonly ConcurrentDictionary<string, FileMetadata> _fileMetadata = new();
    private readonly ResiliencePipeline _resiliencePipeline;

    public ResilientS3FileStorageService(
        IAmazonS3 s3Client,
        IOptions<S3StorageSettings> settings,
        IOptions<S3ResilienceSettings> resilienceSettings,
        ILogger<ResilientS3FileStorageService> logger)
    {
        _s3Client = s3Client;
        _settings = settings.Value;
        _resilienceSettings = resilienceSettings.Value;
        _logger = logger;
        _resiliencePipeline = CreateResiliencePipeline();
    }

    private ResiliencePipeline CreateResiliencePipeline()
    {
        var pipelineBuilder = new ResiliencePipelineBuilder();

        // Add retry strategy
        pipelineBuilder.AddRetry(new RetryStrategyOptions
        {
            MaxRetryAttempts = _resilienceSettings.MaxRetryAttempts,
            Delay = TimeSpan.FromSeconds(_resilienceSettings.BaseDelaySeconds),
            MaxDelay = TimeSpan.FromSeconds(_resilienceSettings.MaxDelaySeconds),
            BackoffType = _resilienceSettings.UseExponentialBackoff ? DelayBackoffType.Exponential : DelayBackoffType.Linear,
            OnRetry = args =>
            {
                _logger.LogWarning("S3 operation retry {AttemptNumber}. Exception: {Exception}",
                    args.AttemptNumber, args.Outcome.Exception?.Message);
                return ValueTask.CompletedTask;
            }
        });

        // Add circuit breaker
        pipelineBuilder.AddCircuitBreaker(new CircuitBreakerStrategyOptions
        {
            FailureRatio = 0.6, // 60% failure rate
            SamplingDuration = TimeSpan.FromSeconds(30),
            MinimumThroughput = _resilienceSettings.CircuitBreakerFailureThreshold,
            BreakDuration = TimeSpan.FromSeconds(_resilienceSettings.CircuitBreakerDurationSeconds),
            OnOpened = args =>
            {
                _logger.LogError("S3 circuit breaker opened");
                return ValueTask.CompletedTask;
            },
            OnClosed = args =>
            {
                _logger.LogInformation("S3 circuit breaker closed");
                return ValueTask.CompletedTask;
            }
        });

        // Add timeout
        pipelineBuilder.AddTimeout(TimeSpan.FromSeconds(_resilienceSettings.RequestTimeoutSeconds));

        return pipelineBuilder.Build();
    }

    public async Task<FileUploadResponse> UploadFileAsync(FileUploadRequest request)
    {
        if (request?.File == null)
            throw new BadRequestException("File is required");

        var bucketName = string.IsNullOrEmpty(request.BucketName) ? _settings.DefaultBucketName : request.BucketName;
        if (string.IsNullOrEmpty(bucketName))
            throw new BadRequestException("Bucket name is required");

        var fileName = request.File.FileName;
        var objectKey = $"{DateTime.UtcNow:yyyy/MM/dd}/{fileName}";

        return await _resiliencePipeline.ExecuteAsync(async context =>
        {
            await EnsureBucketExistsAsync(bucketName);

            using var stream = request.File.OpenReadStream();
            var uploadRequest = new PutObjectRequest
            {
                BucketName = bucketName,
                Key = objectKey,
                InputStream = stream,
                ContentType = request.File.ContentType
            };

            // Only add server-side encryption if configured
            if (_settings.UseServerSideEncryption)
            {
                uploadRequest.ServerSideEncryptionMethod = ServerSideEncryptionMethod.AES256;
            }

            await _s3Client.PutObjectAsync(uploadRequest);

            var fileMetadata = new FileMetadata
            {
                Id = fileName,
                FileName = request.File.FileName,
                ContentType = request.File.ContentType,
                FileSize = request.File.Length,
                BucketName = bucketName,
                ObjectKey = objectKey,
                UploadedAt = DateTime.UtcNow,
                IsActive = true,
                Tags = request.Tags ?? string.Empty
            };
            
            _fileMetadata[fileName] = fileMetadata;
            _logger.LogInformation("File uploaded to S3 and metadata stored. FileName: {FileName}", fileName);

            return new FileUploadResponse
            {
                Id = fileMetadata.Id,
                FileName = fileMetadata.FileName,
                ContentType = fileMetadata.ContentType,
                FileSize = fileMetadata.FileSize,
                BucketName = fileMetadata.BucketName,
                ObjectKey = fileMetadata.ObjectKey,
                UploadedAt = fileMetadata.UploadedAt
            };
        });
    }

    public async Task<FileDownloadResponse> DownloadFileAsync(string fileName)
    {
        if (!_fileMetadata.TryGetValue(fileName, out var metadata) || !metadata.IsActive)
            throw new NotFoundException($"File with name {fileName} not found");

        return await _resiliencePipeline.ExecuteAsync(async context =>
        {
            var request = new GetObjectRequest
            {
                BucketName = metadata.BucketName,
                Key = metadata.ObjectKey
            };
            
            using var response = await _s3Client.GetObjectAsync(request);
            using var memoryStream = new MemoryStream();
            await response.ResponseStream.CopyToAsync(memoryStream);

            return new FileDownloadResponse
            {
                Content = memoryStream.ToArray(),
                ContentType = metadata.ContentType,
                FileName = metadata.FileName
            };
        });
    }

    public async Task<FileMetadata?> GetFileMetadataAsync(string fileName)
    {
        await Task.CompletedTask; // Make async for interface compatibility
        return _fileMetadata.TryGetValue(fileName, out var metadata) && metadata.IsActive ? metadata : null;
    }

    public async Task<IEnumerable<FileMetadata>> GetAllFilesAsync()
    {
        await Task.CompletedTask; // Make async for interface compatibility
        return _fileMetadata.Values.Where(f => f.IsActive).OrderByDescending(f => f.UploadedAt);
    }

    public async Task<bool> DeleteFileAsync(string fileName)
    {
        if (!_fileMetadata.TryGetValue(fileName, out var metadata) || !metadata.IsActive)
            throw new NotFoundException($"File with name {fileName} not found");

        return await _resiliencePipeline.ExecuteAsync(async context =>
        {
            var deleteRequest = new DeleteObjectRequest
            {
                BucketName = metadata.BucketName,
                Key = metadata.ObjectKey
            };
            
            await _s3Client.DeleteObjectAsync(deleteRequest);
            
            // Mark as deleted in memory
            metadata.IsActive = false;
            _fileMetadata[fileName] = metadata;
            
            _logger.LogInformation("File deleted from S3 and marked inactive. FileName: {FileName}", fileName);
            return true;
        });
    }

    public async Task<string> GenerateDownloadUrlAsync(string fileName, int expirationMinutes = 60)
    {
        if (!_fileMetadata.TryGetValue(fileName, out var metadata) || !metadata.IsActive)
            throw new NotFoundException($"File with name {fileName} not found");

        return await _resiliencePipeline.ExecuteAsync(async context =>
        {
            var request = new GetPreSignedUrlRequest
            {
                BucketName = metadata.BucketName,
                Key = metadata.ObjectKey,
                Verb = HttpVerb.GET,
                Expires = DateTime.UtcNow.AddMinutes(expirationMinutes)
            };
            
            // GetPreSignedURL is synchronous, so we await a completed task
            await Task.CompletedTask;
            return _s3Client.GetPreSignedURL(request);
        });
    }

    private async Task EnsureBucketExistsAsync(string bucketName)
    {
        var exists = await Amazon.S3.Util.AmazonS3Util.DoesS3BucketExistV2Async(_s3Client, bucketName);
        if (!exists)
            await _s3Client.PutBucketAsync(new PutBucketRequest { BucketName = bucketName });
    }
}