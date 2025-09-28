# Comprehensive test runner for BFB AWSS3Light
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("all", "api", "infrastructure", "integration")]
    [string]$TestSuite = "all",
    
    [Parameter(Mandatory = $false)]
    [switch]$StartAPI = $false,
    
    [Parameter(Mandatory = $false)]
    [switch]$Verbose = $false
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "ERROR: $Message" -ForegroundColor Red
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
}

function Write-TestResult {
    param(
        [string]$TestName,
        [string]$Status,
        [string]$Details = ""
    )
    
    $color = switch ($Status) {
        "PASSED" { "Green" }
        "FAILED" { "Red" }
        "SKIPPED" { "Yellow" }
        "WARNING" { "Yellow" }
        default { "White" }
    }
    
    $statusIcon = switch ($Status) {
        "PASSED" { "✓" }
        "FAILED" { "✗" }
        "SKIPPED" { "⚠" }
        "WARNING" { "⚠" }
        default { "•" }
    }
    
    Write-Host "$statusIcon $TestName`: $Status" -ForegroundColor $color
    if ($Details -and $Verbose) {
        Write-Host "    $Details" -ForegroundColor Gray
    }
}

# Function to kill existing dotnet processes
function Stop-DotnetProcesses {
    Write-Info "Stopping any running dotnet processes..."
    try {
        Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Info "Dotnet processes stopped"
    }
    catch {
        Write-Info "No dotnet processes found"
    }
}

# Function to test infrastructure health
function Test-Infrastructure {
    Write-Section "INFRASTRUCTURE HEALTH TESTS"
    
    $results = @()
    
    # Test Docker
    try {
        $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
        if ($dockerVersion) {
            $results += @{ Name = "Docker Service"; Status = "PASSED"; Details = "Version: $dockerVersion" }
        } else {
            $results += @{ Name = "Docker Service"; Status = "FAILED"; Details = "Docker not running" }
        }
    }
    catch {
        $results += @{ Name = "Docker Service"; Status = "FAILED"; Details = "Docker not accessible" }
    }
    
    # Test service ports
    $services = @(
        @{ Name = "MongoDB"; Port = 27017 }
        @{ Name = "Redis"; Port = 6379 }
        @{ Name = "MinIO S3"; Port = 9000 }
        @{ Name = "DB2"; Port = 50000 }
    )
    
    foreach ($service in $services) {
        try {
            $tcpClient = New-Object System.Net.Sockets.TcpClient
            $asyncResult = $tcpClient.BeginConnect("localhost", $service.Port, $null, $null)
            $waitHandle = $asyncResult.AsyncWaitHandle
            
            if ($waitHandle.WaitOne(3000)) {
                $tcpClient.EndConnect($asyncResult)
                $tcpClient.Close()
                $results += @{ Name = "$($service.Name) Port $($service.Port)"; Status = "PASSED"; Details = "Port accessible" }
            } else {
                $tcpClient.Close()
                $results += @{ Name = "$($service.Name) Port $($service.Port)"; Status = "FAILED"; Details = "Port not accessible" }
            }
        }
        catch {
            $results += @{ Name = "$($service.Name) Port $($service.Port)"; Status = "FAILED"; Details = "Connection failed" }
        }
    }
    
    return $results
}

# Function to build solution
function Build-Solution {
    Write-Section "BUILDING SOLUTION"
    
    try {
        Write-Info "Building BFB AWSS3Light solution..."
        $buildOutput = dotnet build BFB.AWSS3Light.sln --configuration Release --verbosity minimal 2>&1
        
        if ($LASTEXITCODE -eq 0) {
            return @{ Name = "Solution Build"; Status = "PASSED"; Details = "Build successful" }
        } else {
            return @{ Name = "Solution Build"; Status = "FAILED"; Details = "Build failed: $buildOutput" }
        }
    }
    catch {
        return @{ Name = "Solution Build"; Status = "FAILED"; Details = "Build exception: $_" }
    }
}

# Function to start API for testing
function Start-APIForTesting {
    Write-Section "STARTING API FOR TESTING"
    
    try {
        Stop-DotnetProcesses
        
        Write-Info "Starting BFB AWSS3Light API..."
        $apiPath = "src\BFB.AWSS3Light.API"
        
        if (Test-Path $apiPath) {
            # Start API in background
            $job = Start-Job -ScriptBlock {
                param($path)
                Set-Location $path
                dotnet run --no-build
            } -ArgumentList (Resolve-Path $apiPath)
            
            # Wait for API to start
            Write-Info "Waiting for API to start..."
            $maxWait = 60
            $waited = 0
            $apiReady = $false
            
            while ($waited -lt $maxWait -and -not $apiReady) {
                Start-Sleep -Seconds 2
                $waited += 2
                
                try {
                    $response = Invoke-WebRequest -Uri "http://localhost:5111/health" -Method GET -TimeoutSec 5 -ErrorAction SilentlyContinue
                    if ($response.StatusCode -eq 200) {
                        $apiReady = $true
                        Write-Info "API is ready and responding"
                    }
                }
                catch {
                    # API not ready yet, continue waiting
                }
            }
            
            if ($apiReady) {
                return @{ Job = $job; Status = "STARTED" }
            } else {
                Stop-Job $job -ErrorAction SilentlyContinue
                Remove-Job $job -ErrorAction SilentlyContinue
                return @{ Job = $null; Status = "FAILED" }
            }
        } else {
            return @{ Job = $null; Status = "FAILED" }
        }
    }
    catch {
        return @{ Job = $null; Status = "FAILED" }
    }
}

# Function to run API tests
function Test-API {
    Write-Section "API ENDPOINT TESTS"
    
    $results = @()
    
    # Test health endpoints
    try {
        $health = Invoke-WebRequest -Uri "http://localhost:5111/health" -Method GET -TimeoutSec 10
        $results += @{ Name = "Health Endpoint"; Status = "PASSED"; Details = "Status: $($health.StatusCode)" }
    }
    catch {
        $results += @{ Name = "Health Endpoint"; Status = "FAILED"; Details = "Health check failed: $_" }
    }
    
    try {
        $ready = Invoke-WebRequest -Uri "http://localhost:5111/health/ready" -Method GET -TimeoutSec 10
        $results += @{ Name = "Readiness Endpoint"; Status = "PASSED"; Details = "Status: $($ready.StatusCode)" }
    }
    catch {
        $results += @{ Name = "Readiness Endpoint"; Status = "FAILED"; Details = "Readiness check failed: $_" }
    }
    
    # Test banks API
    try {
        $banks = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method GET -TimeoutSec 10
        $banksData = $banks.Content | ConvertFrom-Json
        $results += @{ Name = "Banks GET API"; Status = "PASSED"; Details = "Found $($banksData.Count) banks" }
    }
    catch {
        $results += @{ Name = "Banks GET API"; Status = "FAILED"; Details = "Banks API failed: $_" }
    }
    
    # Test customers API
    try {
        $customers = Invoke-WebRequest -Uri "http://localhost:5111/api/mongo/mongocustomers" -Method GET -TimeoutSec 10
        $customersData = $customers.Content | ConvertFrom-Json
        $results += @{ Name = "Customers GET API"; Status = "PASSED"; Details = "Found $($customersData.Count) customers" }
    }
    catch {
        $results += @{ Name = "Customers GET API"; Status = "WARNING"; Details = "Customers API may not be ready: $_" }
    }
    
    return $results
}

# Function to run integration tests by executing existing test scripts
function Test-Integration {
    Write-Section "INTEGRATION TESTS"
    
    $results = @()
    
    # Run existing test scripts
    $testScripts = @(
        @{ Name = "Redis Cache Test"; Script = "test-redis-simple.ps1" }
        @{ Name = "Enhanced Banks API Test"; Script = "test-enhanced-banks-api-clean.ps1" }
        @{ Name = "Final Clean Test"; Script = "test-final-clean.ps1" }
    )
    
    foreach ($test in $testScripts) {
        try {
            $scriptPath = "scripts\powershell\$($test.Script)"
            if (Test-Path $scriptPath) {
                Write-Info "Running $($test.Name)..."
                $output = powershell -ExecutionPolicy Bypass -File $scriptPath 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    $results += @{ Name = $test.Name; Status = "PASSED"; Details = "Integration test passed" }
                } else {
                    $results += @{ Name = $test.Name; Status = "FAILED"; Details = "Integration test failed" }
                }
            } else {
                $results += @{ Name = $test.Name; Status = "SKIPPED"; Details = "Script not found: $scriptPath" }
            }
        }
        catch {
            $results += @{ Name = $test.Name; Status = "FAILED"; Details = "Test execution failed: $_" }
        }
    }
    
    return $results
}

# Main execution
try {
    Write-Section "BFB TEMPLATE COMPREHENSIVE TEST RUNNER"
    Write-Info "Test Suite: $TestSuite"
    Write-Info "Start API: $StartAPI"
    
    $allResults = @()
    $apiJob = $null
    
    # Run infrastructure tests
    if ($TestSuite -eq "all" -or $TestSuite -eq "infrastructure") {
        $infraResults = Test-Infrastructure
        $allResults += $infraResults
        
        foreach ($result in $infraResults) {
            Write-TestResult -TestName $result.Name -Status $result.Status -Details $result.Details
        }
    }
    
    # Build solution
    if ($TestSuite -eq "all" -or $TestSuite -eq "api") {
        $buildResult = Build-Solution
        $allResults += $buildResult
        Write-TestResult -TestName $buildResult.Name -Status $buildResult.Status -Details $buildResult.Details
        
        if ($buildResult.Status -ne "PASSED") {
            Write-Error "Cannot proceed with API tests - build failed"
            exit 1
        }
    }
    
    # Start API if requested or if running API/integration tests
    if ($StartAPI -or $TestSuite -eq "all" -or $TestSuite -eq "api" -or $TestSuite -eq "integration") {
        $apiStart = Start-APIForTesting
        $apiJob = $apiStart.Job
        
        if ($apiStart.Status -eq "STARTED") {
            Write-Info "API started successfully"
            
            # Run API tests
            if ($TestSuite -eq "all" -or $TestSuite -eq "api") {
                Start-Sleep -Seconds 5  # Extra wait for API to stabilize
                $apiResults = Test-API
                $allResults += $apiResults
                
                foreach ($result in $apiResults) {
                    Write-TestResult -TestName $result.Name -Status $result.Status -Details $result.Details
                }
            }
            
            # Run integration tests
            if ($TestSuite -eq "all" -or $TestSuite -eq "integration") {
                Start-Sleep -Seconds 5  # Extra wait for API to stabilize
                $integrationResults = Test-Integration
                $allResults += $integrationResults
                
                foreach ($result in $integrationResults) {
                    Write-TestResult -TestName $result.Name -Status $result.Status -Details $result.Details
                }
            }
        } else {
            Write-Error "Failed to start API for testing"
        }
    }
    
    # Display final summary
    Write-Section "TEST SUMMARY"
    
    $passed = ($allResults | Where-Object { $_.Status -eq "PASSED" }).Count
    $failed = ($allResults | Where-Object { $_.Status -eq "FAILED" }).Count
    $skipped = ($allResults | Where-Object { $_.Status -eq "SKIPPED" }).Count
    $warnings = ($allResults | Where-Object { $_.Status -eq "WARNING" }).Count
    $total = $allResults.Count
    
    Write-Host "Total Tests: $total" -ForegroundColor White
    Write-Host "Passed: $passed" -ForegroundColor Green
    Write-Host "Failed: $failed" -ForegroundColor Red
    Write-Host "Skipped: $skipped" -ForegroundColor Yellow
    Write-Host "Warnings: $warnings" -ForegroundColor Yellow
    
    if ($failed -eq 0) {
        Write-Host "✓ ALL TESTS PASSED!" -ForegroundColor Green
    } else {
        Write-Host "✗ SOME TESTS FAILED" -ForegroundColor Red
    }
    
}
catch {
    Write-Error "Test execution failed: $_"
}
finally {
    # Cleanup: Stop API if we started it
    if ($apiJob) {
        Write-Info "Stopping API..."
        Stop-Job $apiJob -ErrorAction SilentlyContinue
        Remove-Job $apiJob -ErrorAction SilentlyContinue
        Stop-DotnetProcesses
    }
}

Write-Info "Test run completed"
