#!/usr/bin/env pwsh

<#
.SYNOPSIS
    .NET 8 Performance Test Script
.DESCRIPTION
    Tests performance characteristics and .NET 8 specific features in the BFB AWSS3Light
.EXAMPLE
    ./test-net8-performance.ps1
#>

Write-Host "=== .NET 8 Performance Test ===" -ForegroundColor Cyan
Write-Host "Testing .NET 8 performance and features" -ForegroundColor Yellow

# Test configuration
$ApiUrl = "http://localhost:5111"
$TestResults = @{ Passed = 0; Failed = 0 }

function Write-TestResult {
    param([string]$Test, [bool]$Success, [string]$Details = "")
    
    if ($Success) {
        $script:TestResults.Passed++
        Write-Host "✅ $Test" -ForegroundColor Green
    } else {
        $script:TestResults.Failed++
        Write-Host "❌ $Test" -ForegroundColor Red
        if ($Details) { Write-Host "   Details: $Details" -ForegroundColor Yellow }
    }
}

function Test-DotNetVersion {
    Write-Host "`nChecking .NET version..." -ForegroundColor Cyan
    try {
        Push-Location -Path "$PSScriptRoot/../../src/BFB.AWSS3Light.API"
        $versionOutput = dotnet --version
        Write-Host "Detected .NET version: $versionOutput" -ForegroundColor White
        
        if ($versionOutput -match "^8\.") {
            Write-TestResult ".NET 8 Version Check" $true "Version: $versionOutput"
        } else {
            Write-TestResult ".NET 8 Version Check" $false "Expected .NET 8, found: $versionOutput"
        }
        Pop-Location
    } catch {
        Write-TestResult ".NET 8 Version Check" $false $_.Exception.Message
        Pop-Location
    }
}

function Test-BuildPerformance {
    Write-Host "`nTesting build performance..." -ForegroundColor Cyan
    try {
        Push-Location -Path "$PSScriptRoot/../.."
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        $buildResult = dotnet build --configuration Release --verbosity quiet
        $stopwatch.Stop()
        
        $buildTimeSeconds = $stopwatch.Elapsed.TotalSeconds
        Write-Host "Build completed in $([math]::Round($buildTimeSeconds, 2)) seconds" -ForegroundColor White
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Build Performance" $true "Time: $([math]::Round($buildTimeSeconds, 2))s"
        } else {
            Write-TestResult "Build Performance" $false "Build failed"
        }
        Pop-Location
    } catch {
        Write-TestResult "Build Performance" $false $_.Exception.Message
        Pop-Location
    }
}

function Test-StartupPerformance {
    Write-Host "`nTesting API startup performance..." -ForegroundColor Cyan
    try {
        Push-Location -Path "$PSScriptRoot/../../src/BFB.AWSS3Light.API"
        
        $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()
        
        # Start API in background
        $job = Start-Job -ScriptBlock {
            param($apiPath)
            Set-Location $apiPath
            dotnet run --configuration Release
        } -ArgumentList (Get-Location).Path
        
        # Wait for API to be ready
        $maxWaitTime = 30
        $waitTime = 0
        $apiReady = $false
        
        while ($waitTime -lt $maxWaitTime -and -not $apiReady) {
            Start-Sleep -Seconds 1
            $waitTime++
            
            try {
                $response = Invoke-WebRequest -Uri "$ApiUrl/health" -Method GET -TimeoutSec 2 -ErrorAction Stop
                if ($response.StatusCode -eq 200) {
                    $stopwatch.Stop()
                    $apiReady = $true
                }
            } catch {
                # Continue waiting
            }
        }
        
        # Clean up
        Stop-Job $job -ErrorAction SilentlyContinue
        Remove-Job $job -ErrorAction SilentlyContinue
        
        if ($apiReady) {
            $startupTimeSeconds = $stopwatch.Elapsed.TotalSeconds
            Write-TestResult "API Startup Performance" $true "Time: $([math]::Round($startupTimeSeconds, 2))s"
        } else {
            Write-TestResult "API Startup Performance" $false "API did not start within ${maxWaitTime}s"
        }
        
        Pop-Location
    } catch {
        Write-TestResult "API Startup Performance" $false $_.Exception.Message
        Pop-Location
    }
}

function Test-MemoryUsage {
    Write-Host "`nChecking memory usage..." -ForegroundColor Cyan
    try {
        $process = Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowTitle -eq "" }
        if ($process) {
            $memoryMB = [math]::Round($process.WorkingSet64 / 1MB, 2)
            Write-Host "API Memory Usage: ${memoryMB} MB" -ForegroundColor White
            
            # Basic memory check (should be reasonable for a small API)
            if ($memoryMB -lt 500) {
                Write-TestResult "Memory Usage Check" $true "Memory: ${memoryMB} MB"
            } else {
                Write-TestResult "Memory Usage Check" $false "High memory usage: ${memoryMB} MB"
            }
        } else {
            Write-TestResult "Memory Usage Check" $false "API process not found"
        }
    } catch {
        Write-TestResult "Memory Usage Check" $false $_.Exception.Message
    }
}

function Show-TestSummary {
    Write-Host "`n=== Performance Test Summary ===" -ForegroundColor Cyan
    Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
    
    if ($TestResults.Failed -eq 0) {
        Write-Host "`n🎉 All performance tests passed!" -ForegroundColor Green
    } else {
        Write-Host "[WARN]  Some performance tests failed. Check the results above." -ForegroundColor Yellow
    }
}

# Main execution
try {
    Test-DotNetVersion
    Test-BuildPerformance
    Test-StartupPerformance
    Test-MemoryUsage
} finally {
    Show-TestSummary
}
