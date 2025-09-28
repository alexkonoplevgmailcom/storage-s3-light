# S3 File Storage API Test Script
# Tests the S3 file storage endpoints with MinIO

function Stop-DotnetProcesses {
    Write-Host "Stopping existing dotnet processes..." -ForegroundColor Yellow
    Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 2
}

function Test-MinIOStatus {
    Write-Host "Checking MinIO status..." -ForegroundColor Blue
    try {
        docker ps --filter "name=minio" --format "table {{.Names}}\t{{.Status}}"
        $minioRunning = docker ps --filter "name=minio" --filter "status=running" --quiet
        if (-not $minioRunning) {
            Write-Host "MinIO is not running. Please start MinIO with: docker-compose -f docker-compose/docker-compose.minio.yml up -d" -ForegroundColor Red
            return $false
        }
        Write-Host "MinIO is running" -ForegroundColor Green
        return $true
    } catch {
        Write-Host "Error checking MinIO status: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Build-Solution {
    Write-Host "Building solution..." -ForegroundColor Blue
    try {
        Push-Location -Path "$PSScriptRoot/../.."
        dotnet build --configuration Debug
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Build failed" -ForegroundColor Red
            Pop-Location
            return $false
        }
        Write-Host "Build successful" -ForegroundColor Green
        Pop-Location
        return $true
    } catch {
        Write-Host "Build error: $($_.Exception.Message)" -ForegroundColor Red
        Pop-Location
        return $false
    }
}

function Start-API {
    Write-Host "Starting API..." -ForegroundColor Blue
    try {
        Push-Location -Path "$PSScriptRoot/../../src/BFB.AWSS3Light.API"
        
        # Start the API in background
        $job = Start-Job -ScriptBlock {
            param($ApiPath)
            Set-Location $ApiPath
            dotnet run
        } -ArgumentList (Get-Location).Path
        
        # Wait for API to start
        Write-Host "Waiting for API to start..."
        Start-Sleep -Seconds 10
        
        Pop-Location
        return $job
    } catch {
        Write-Host "Error starting API: $($_.Exception.Message)" -ForegroundColor Red
        Pop-Location
        return $null
    }
}

function Test-APIHealth {
    $maxAttempts = 10
    $attempt = 1
    
    while ($attempt -le $maxAttempts) {
        try {
            Write-Host "Testing API health (attempt $attempt/$maxAttempts)..."
            $response = Invoke-WebRequest -Uri "http://localhost:5111/health" -Method GET -TimeoutSec 5
            if ($response.StatusCode -eq 200) {
                Write-Host "API is healthy" -ForegroundColor Green
                return $true
            }
        } catch {
            Write-Host "API not ready yet..." -ForegroundColor Yellow
            Start-Sleep -Seconds 3
            $attempt++
        }
    }
    
    Write-Host "API failed to start properly" -ForegroundColor Red
    return $false
}

function Test-S3Endpoints {
    Write-Host "`n=== Testing S3 File Storage Endpoints ===" -ForegroundColor Cyan
    $testResults = @()
    
    try {
        # Test 1: Get all files (should be empty initially)
        Write-Host "`n1. Testing GET all files..." -ForegroundColor Blue
        $response = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/metadata" -Method GET
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ GET all files successful" -ForegroundColor Green
            $testResults += "✅ GET all files"
        } else {
            Write-Host "❌ GET all files failed" -ForegroundColor Red
            $testResults += "❌ GET all files"
        }
        
        # Test 2: Create a test file and upload it
        Write-Host "`n2. Testing file upload..." -ForegroundColor Blue
        
        # Create a test file
        $testFileName = "test-file-$(Get-Random).txt"
        $testFilePath = Join-Path $env:TEMP $testFileName
        $testContent = "This is a test file for S3 storage. Created at $(Get-Date)"
        Set-Content -Path $testFilePath -Value $testContent
          try {
            # Upload the file using multipart form data
            $boundary = [System.Guid]::NewGuid().ToString()
            $fileBytes = [System.IO.File]::ReadAllBytes($testFilePath)
            $fileName = [System.IO.Path]::GetFileName($testFilePath)
            
            $bodyLines = @(
                "--$boundary",
                "Content-Disposition: form-data; name=`"File`"; filename=`"$fileName`"",
                "Content-Type: text/plain",
                "",
                [System.Text.Encoding]::UTF8.GetString($fileBytes),
                "--$boundary",
                "Content-Disposition: form-data; name=`"BucketName`"",
                "",
                "test-bucket",
                "--$boundary",
                "Content-Disposition: form-data; name=`"Tags`"",
                "",
                "test,api-test",
                "--$boundary--"
            )
            
            $body = [string]::Join("`r`n", $bodyLines)
            $bodyBytes = [System.Text.Encoding]::UTF8.GetBytes($body)
            
            $uploadResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/upload" -Method POST -Body $bodyBytes -ContentType "multipart/form-data; boundary=$boundary"
            
            if ($uploadResponse.StatusCode -eq 201) {
                Write-Host "✅ File upload successful" -ForegroundColor Green
                $testResults += "✅ File upload"
                
                $uploadResult = $uploadResponse.Content | ConvertFrom-Json
                $fileId = $uploadResult.id
                Write-Host "Uploaded file ID: $fileId"
                
                # Test 3: Get file metadata
                Write-Host "`n3. Testing GET file metadata..." -ForegroundColor Blue
                $metadataResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/metadata/$fileId" -Method GET
                if ($metadataResponse.StatusCode -eq 200) {
                    Write-Host "✅ GET file metadata successful" -ForegroundColor Green
                    $testResults += "✅ GET file metadata"
                } else {
                    Write-Host "❌ GET file metadata failed" -ForegroundColor Red
                    $testResults += "❌ GET file metadata"
                }
                
                # Test 4: Download file
                Write-Host "`n4. Testing file download..." -ForegroundColor Blue
                $downloadResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/download/$fileId" -Method GET
                if ($downloadResponse.StatusCode -eq 200) {
                    Write-Host "✅ File download successful" -ForegroundColor Green
                    $testResults += "✅ File download"
                      # Verify content
                    $downloadedContent = $downloadResponse.Content
                    if ($downloadedContent.Contains("This is a test file")) {
                        Write-Host "✅ Downloaded content matches original" -ForegroundColor Green
                        $testResults += "✅ Content verification"
                    } else {
                        Write-Host "❌ Downloaded content doesn't match" -ForegroundColor Red
                        $testResults += "❌ Content verification"
                    }
                } else {
                    Write-Host "❌ File download failed" -ForegroundColor Red
                    $testResults += "❌ File download"
                }
                
                # Test 5: Generate download URL
                Write-Host "`n5. Testing download URL generation..." -ForegroundColor Blue
                $urlResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/download-url/$fileId" -Method GET
                if ($urlResponse.StatusCode -eq 200) {
                    Write-Host "✅ Download URL generation successful" -ForegroundColor Green
                    $testResults += "✅ Download URL generation"
                    
                    $urlResult = $urlResponse.Content | ConvertFrom-Json
                    Write-Host "Generated URL: $($urlResult.url)"
                } else {
                    Write-Host "❌ Download URL generation failed" -ForegroundColor Red
                    $testResults += "❌ Download URL generation"
                }
                
                # Test 6: Delete file
                Write-Host "`n6. Testing file deletion..." -ForegroundColor Blue
                $deleteResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/$fileId" -Method DELETE
                if ($deleteResponse.StatusCode -eq 204) {
                    Write-Host "✅ File deletion successful" -ForegroundColor Green
                    $testResults += "✅ File deletion"
                } else {
                    Write-Host "❌ File deletion failed" -ForegroundColor Red
                    $testResults += "❌ File deletion"
                }
                
                # Test 7: Verify file is deleted
                Write-Host "`n7. Verifying file deletion..." -ForegroundColor Blue
                try {
                    $verifyResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/s3/files/metadata/$fileId" -Method GET
                    Write-Host "❌ File still exists after deletion" -ForegroundColor Red
                    $testResults += "❌ Deletion verification"
                } catch {
                    if ($_.Exception.Response.StatusCode -eq 404) {
                        Write-Host "✅ File properly deleted (404 response)" -ForegroundColor Green
                        $testResults += "✅ Deletion verification"
                    } else {
                        Write-Host "❌ Unexpected error verifying deletion" -ForegroundColor Red
                        $testResults += "❌ Deletion verification"
                    }
                }
                
            } else {
                Write-Host "❌ File upload failed" -ForegroundColor Red
                $testResults += "❌ File upload"
            }
        } finally {
            # Cleanup test file
            if (Test-Path $testFilePath) {
                Remove-Item $testFilePath -Force
            }
        }
        
    } catch {
        Write-Host "Error during S3 testing: $($_.Exception.Message)" -ForegroundColor Red
        $testResults += "❌ S3 tests failed with error"
    }
    
    return $testResults
}

function Show-TestSummary {
    param($results)
    
    Write-Host "`n=== S3 File Storage Test Summary ===" -ForegroundColor Cyan
    
    $passed = $results | Where-Object { $_.StartsWith("✅") }
    $failed = $results | Where-Object { $_.StartsWith("❌") }
    
    Write-Host "`nTest Results:" -ForegroundColor White
    foreach ($result in $results) {
        if ($result.StartsWith("✅")) {
            Write-Host $result -ForegroundColor Green
        } else {
            Write-Host $result -ForegroundColor Red
        }
    }
    
    Write-Host "`nSummary: $($passed.Count) passed, $($failed.Count) failed" -ForegroundColor $(if ($failed.Count -eq 0) { "Green" } else { "Yellow" })
    
    if ($failed.Count -eq 0) {
        Write-Host "`n🎉 All S3 file storage tests passed!" -ForegroundColor Green
    } else {
        Write-Host "[WARN]  Some tests failed. Check the logs above for details." -ForegroundColor Yellow
    }
}

# Main execution
Write-Host "=== S3 File Storage API Test ===" -ForegroundColor Cyan
Write-Host "Testing S3 file storage with MinIO backend" -ForegroundColor White

# Check prerequisites
if (-not (Test-MinIOStatus)) {
    Write-Host "Please start MinIO and try again" -ForegroundColor Red
    exit 1
}

# Build solution
if (-not (Build-Solution)) {
    Write-Host "Build failed, stopping tests" -ForegroundColor Red
    exit 1
}

# Stop existing processes
Stop-DotnetProcesses

# Start API
$apiJob = Start-API
if (-not $apiJob) {
    Write-Host "Failed to start API" -ForegroundColor Red
    exit 1
}

try {
    # Test API health
    if (-not (Test-APIHealth)) {
        Write-Host "API health check failed" -ForegroundColor Red
        exit 1
    }
    
    # Run S3 tests
    $testResults = Test-S3Endpoints
    
    # Show summary
    Show-TestSummary -results $testResults
    
} finally {
    # Cleanup
    Write-Host "`nCleaning up..." -ForegroundColor Yellow
    if ($apiJob) {
        Stop-Job $apiJob -ErrorAction SilentlyContinue
        Remove-Job $apiJob -ErrorAction SilentlyContinue
    }
    Stop-DotnetProcesses
    Write-Host "Cleanup complete" -ForegroundColor Green
}

Write-Host "`nS3 File Storage API test completed!" -ForegroundColor Cyan
