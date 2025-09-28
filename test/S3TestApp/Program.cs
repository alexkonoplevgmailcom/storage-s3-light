using BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.Interfaces;
using BFB.AWSS3Light.Storage.S3.Standalone.Extensions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.Text;

namespace S3TestApp;

class Program
{
    static async Task Main(string[] args)
    {
        Console.WriteLine("🚀 S3 Storage NuGet Package Test Application");
        Console.WriteLine("============================================");
        
        // Build configuration
        var configuration = new ConfigurationBuilder()
            .SetBasePath(Directory.GetCurrentDirectory())
            .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
            .AddEnvironmentVariables()
            .Build();

        // Create host builder
        var host = Host.CreateDefaultBuilder(args)
            .ConfigureServices((context, services) =>
            {
                // Add our S3 storage service using the NuGet package
                services.AddS3Storage(configuration);
                
                // Add basic health checks
                services.AddHealthChecks();
            })
            .Build();

        try
        {
            Console.WriteLine("✅ Host configured successfully");
            
            // Get the S3 storage service
            var storageService = host.Services.GetRequiredService<IFileStorageService>();
            var logger = host.Services.GetRequiredService<ILogger<Program>>();
            
            logger.LogInformation("Starting S3 storage test");

            // Test file upload
            await TestFileOperations(storageService, logger);
            
            // Test health checks
            await TestHealthChecks(host, logger);
            
            // Verify bucket contents after test
            await VerifyBucketContents(host, logger);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Error: {ex.Message}");
            Console.WriteLine($"Stack trace: {ex.StackTrace}");
        }
        finally
        {
            await host.StopAsync();
        }

        Console.WriteLine("\n🎉 Test completed! Press any key to exit...");
        Console.ReadKey();
    }

    private static async Task TestFileOperations(IFileStorageService storageService, ILogger logger)
    {
        try
        {
            Console.WriteLine("\n📁 Testing file operations with disk files...");
            
            // Create test files directory
            var testDir = Path.Combine(Directory.GetCurrentDirectory(), "test-files");
            Directory.CreateDirectory(testDir);
            
            // Create first test file
            var timestamp = DateTime.Now.ToString("yyyyMMdd-HHmmss");
            var testFile1Name = $"document-{timestamp}.txt";
            var testFile1Path = Path.Combine(testDir, testFile1Name);
            var testContent1 = $"Document Test File #1\nCreated: {DateTime.Now}\nContent: This is the first test document for S3 upload/download testing.\nRandom ID: {Guid.NewGuid()}";
            await File.WriteAllTextAsync(testFile1Path, testContent1);
            
            // Create second test file
            var testFile2Name = $"data-{timestamp}.json";
            var testFile2Path = Path.Combine(testDir, testFile2Name);
            var testContent2 = $@"{{
  ""type"": ""test-data"",
  ""created"": ""{DateTime.Now:yyyy-MM-ddTHH:mm:ssZ}"",
  ""id"": ""{Guid.NewGuid()}"",
  ""description"": ""This is the second test file for S3 upload/download testing"",
  ""version"": 2,
  ""metadata"": {{
    ""source"": ""S3TestApp"",
    ""environment"": ""development""
  }}
}}";
            await File.WriteAllTextAsync(testFile2Path, testContent2);
            
            Console.WriteLine($"✅ Created test files:");
            Console.WriteLine($"   - {testFile1Name} ({new FileInfo(testFile1Path).Length} bytes)");
            Console.WriteLine($"   - {testFile2Name} ({new FileInfo(testFile2Path).Length} bytes)");

            // Upload first file
            Console.WriteLine($"\n📤 Uploading first file: {testFile1Name}");
            var testFormFile1 = await CreateFormFileFromDisk(testFile1Path, "text/plain");
            var uploadRequest1 = new BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs.FileUploadRequest
            {
                File = testFormFile1,
                BucketName = "test-bucket",
                Tags = "test,console-app,document,disk-file"
            };
            var uploadResponse1 = await storageService.UploadFileAsync(uploadRequest1);
            
            Console.WriteLine($"✅ First file uploaded successfully!");
            Console.WriteLine($"   File ID: {uploadResponse1.Id}");
            Console.WriteLine($"   Object Key: {uploadResponse1.ObjectKey}");
            Console.WriteLine($"   File Size: {uploadResponse1.FileSize} bytes");

            // Upload second file
            Console.WriteLine($"\n📤 Uploading second file: {testFile2Name}");
            var testFormFile2 = await CreateFormFileFromDisk(testFile2Path, "application/json");
            var uploadRequest2 = new BFB.AWSS3Light.Storage.S3.Standalone.Abstractions.DTOs.FileUploadRequest
            {
                File = testFormFile2,
                BucketName = "test-bucket",
                Tags = "test,console-app,json-data,disk-file"
            };
            var uploadResponse2 = await storageService.UploadFileAsync(uploadRequest2);
            
            Console.WriteLine($"✅ Second file uploaded successfully!");
            Console.WriteLine($"   File ID: {uploadResponse2.Id}");
            Console.WriteLine($"   Object Key: {uploadResponse2.ObjectKey}");
            Console.WriteLine($"   File Size: {uploadResponse2.FileSize} bytes");

            // Get metadata for both files
            Console.WriteLine($"\n📋 Getting metadata for both files...");
            var metadata1 = await storageService.GetFileMetadataAsync(uploadResponse1.Id);
            var metadata2 = await storageService.GetFileMetadataAsync(uploadResponse2.Id);
            
            if (metadata1 != null)
            {
                Console.WriteLine($"✅ First file metadata:");
                Console.WriteLine($"   File Name: {metadata1.FileName}");
                Console.WriteLine($"   Content Type: {metadata1.ContentType}");
                Console.WriteLine($"   Tags: {metadata1.Tags}");
            }
            
            if (metadata2 != null)
            {
                Console.WriteLine($"✅ Second file metadata:");
                Console.WriteLine($"   File Name: {metadata2.FileName}");
                Console.WriteLine($"   Content Type: {metadata2.ContentType}");
                Console.WriteLine($"   Tags: {metadata2.Tags}");
            }

            // Download both files
            Console.WriteLine($"\n📥 Downloading both files...");
            
            var downloadResponse1 = await storageService.DownloadFileAsync(uploadResponse1.Id);
            var downloadedContent1 = Encoding.UTF8.GetString(downloadResponse1.Content);
            var downloadedFile1Path = Path.Combine(testDir, $"downloaded-{testFile1Name}");
            await File.WriteAllBytesAsync(downloadedFile1Path, downloadResponse1.Content);
            
            Console.WriteLine($"✅ First file downloaded and saved to disk!");
            Console.WriteLine($"   Content Type: {downloadResponse1.ContentType}");
            Console.WriteLine($"   Saved to: {downloadedFile1Path}");
            Console.WriteLine($"   Content preview: {downloadedContent1.Substring(0, Math.Min(100, downloadedContent1.Length))}...");

            var downloadResponse2 = await storageService.DownloadFileAsync(uploadResponse2.Id);
            var downloadedContent2 = Encoding.UTF8.GetString(downloadResponse2.Content);
            var downloadedFile2Path = Path.Combine(testDir, $"downloaded-{testFile2Name}");
            await File.WriteAllBytesAsync(downloadedFile2Path, downloadResponse2.Content);
            
            Console.WriteLine($"✅ Second file downloaded and saved to disk!");
            Console.WriteLine($"   Content Type: {downloadResponse2.ContentType}");
            Console.WriteLine($"   Saved to: {downloadedFile2Path}");
            Console.WriteLine($"   Content preview: {downloadedContent2.Substring(0, Math.Min(100, downloadedContent2.Length))}...");

            // Generate pre-signed URLs for both files
            Console.WriteLine($"\n🔗 Generating pre-signed URLs...");
            var preSignedUrl1 = await storageService.GenerateDownloadUrlAsync(uploadResponse1.Id, 10);
            var preSignedUrl2 = await storageService.GenerateDownloadUrlAsync(uploadResponse2.Id, 10);
            
            Console.WriteLine($"✅ Pre-signed URLs generated (10 minutes expiry):");
            Console.WriteLine($"   File 1: {preSignedUrl1}");
            Console.WriteLine($"   File 2: {preSignedUrl2}");

            // List all files
            Console.WriteLine($"\n📂 Listing all files in bucket...");
            var allFiles = await storageService.GetAllFilesAsync();
            Console.WriteLine($"✅ Found {allFiles.Count()} files in bucket:");
            foreach (var file in allFiles.Take(10)) // Show first 10 files
            {
                Console.WriteLine($"   - {file.FileName} (ID: {file.Id}, Size: {file.FileSize} bytes)");
            }

            // Delete only the first file (keep second file in bucket)
            Console.WriteLine($"\n🗑️ Deleting only the first file (keeping second file in bucket)...");
            var deleteResult1 = await storageService.DeleteFileAsync(uploadResponse1.Id);
            if (deleteResult1)
            {
                Console.WriteLine($"✅ First file ({testFile1Name}) deleted from bucket");
            }
            
            Console.WriteLine($"📁 Second file ({testFile2Name}) remains in bucket for verification");
            Console.WriteLine($"   File ID: {uploadResponse2.Id}");
            Console.WriteLine($"   Object Key: {uploadResponse2.ObjectKey}");
            
            Console.WriteLine($"\n📋 Local test files created in: {testDir}");
            Console.WriteLine($"   - Original files: {testFile1Name}, {testFile2Name}");
            Console.WriteLine($"   - Downloaded files: downloaded-{testFile1Name}, downloaded-{testFile2Name}");
            
            logger.LogInformation("File operations test completed successfully with disk files");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ File operations test failed: {ex.Message}");
            logger.LogError(ex, "File operations test failed");
        }
    }

    private static async Task<TestFormFile> CreateFormFileFromDisk(string filePath, string contentType)
    {
        var fileName = Path.GetFileName(filePath);
        var fileBytes = await File.ReadAllBytesAsync(filePath);
        return new TestFormFile(fileBytes, fileName, contentType);
    }

    private static async Task VerifyBucketContents(IHost host, ILogger logger)
    {
        try
        {
            Console.WriteLine("\n🔍 Final bucket verification...");
            
            var storageService = host.Services.GetRequiredService<IFileStorageService>();
            var allFiles = await storageService.GetAllFilesAsync();
            
            Console.WriteLine($"📊 Current bucket status:");
            Console.WriteLine($"   Total files in bucket: {allFiles.Count()}");
            
            if (allFiles.Any())
            {
                Console.WriteLine($"✅ Remaining files (as expected):");
                foreach (var file in allFiles)
                {
                    Console.WriteLine($"   📄 {file.FileName}");
                    Console.WriteLine($"      ID: {file.Id}");
                    Console.WriteLine($"      Size: {file.FileSize} bytes");
                    Console.WriteLine($"      Content Type: {file.ContentType}");
                    Console.WriteLine($"      Uploaded: {file.UploadedAt:yyyy-MM-dd HH:mm:ss}");
                    
                    // Try to access the file to confirm it's still accessible
                    try
                    {
                        var preSignedUrl = await storageService.GenerateDownloadUrlAsync(file.Id, 1);
                        Console.WriteLine($"      ✅ File is accessible (pre-signed URL generated)");
                    }
                    catch
                    {
                        Console.WriteLine($"      ❌ File not accessible");
                    }
                    Console.WriteLine();
                }
                
                Console.WriteLine("✅ Verification complete: Files preserved in bucket as intended!");
            }
            else
            {
                Console.WriteLine("⚠️  No files found in bucket (all were deleted).");
            }
            
            logger.LogInformation("Bucket verification completed");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Bucket verification failed: {ex.Message}");
            logger.LogError(ex, "Bucket verification failed");
        }
    }

    private static async Task TestHealthChecks(IHost host, ILogger logger)
    {
        try
        {
            Console.WriteLine("\n🏥 Testing health checks...");
            
            // Get health check service
            var healthCheckService = host.Services.GetService<Microsoft.Extensions.Diagnostics.HealthChecks.HealthCheckService>();
            
            if (healthCheckService != null)
            {
                var healthReport = await healthCheckService.CheckHealthAsync();
                
                Console.WriteLine($"✅ Health check completed:");
                Console.WriteLine($"   Overall Status: {healthReport.Status}");
                Console.WriteLine($"   Total Duration: {healthReport.TotalDuration.TotalMilliseconds}ms");
                
                foreach (var entry in healthReport.Entries)
                {
                    Console.WriteLine($"   - {entry.Key}: {entry.Value.Status} ({entry.Value.Duration.TotalMilliseconds}ms)");
                    if (!string.IsNullOrEmpty(entry.Value.Description))
                    {
                        Console.WriteLine($"     Description: {entry.Value.Description}");
                    }
                }
                
                logger.LogInformation("Health check test completed successfully");
            }
            else
            {
                Console.WriteLine("⚠️ Health check service not available");
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine($"❌ Health check test failed: {ex.Message}");
            logger.LogError(ex, "Health check test failed");
        }
    }
}

// Simple test implementation of IFormFile for console app
public class TestFormFile : Microsoft.AspNetCore.Http.IFormFile
{
    private readonly byte[] _content;
    
    public TestFormFile(byte[] content, string fileName, string contentType)
    {
        _content = content;
        FileName = fileName;
        Name = fileName;
        ContentType = contentType;
        Length = content.Length;
    }

    public string ContentType { get; }
    public string ContentDisposition => $"form-data; name=\"{Name}\"; filename=\"{FileName}\"";
    public Microsoft.AspNetCore.Http.IHeaderDictionary Headers { get; } = new Microsoft.AspNetCore.Http.HeaderDictionary();
    public long Length { get; }
    public string Name { get; }
    public string FileName { get; }

    public void CopyTo(Stream target) => target.Write(_content, 0, _content.Length);

    public Task CopyToAsync(Stream target, CancellationToken cancellationToken = default)
    {
        return target.WriteAsync(_content, 0, _content.Length, cancellationToken);
    }

    public Stream OpenReadStream() => new MemoryStream(_content);
}
