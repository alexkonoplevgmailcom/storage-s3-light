#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Serilog Configuration Test Script
.DESCRIPTION
    Tests Serilog logging configuration and functionality in the BFB AWSS3Light
.EXAMPLE
    ./test-serilog-config.ps1
#>

Write-Host "=== Serilog Configuration Test ===" -ForegroundColor Cyan
Write-Host "Testing Serilog logging configuration" -ForegroundColor Yellow

# Test configuration
$ApiUrl = "http://localhost:5111"
$TestResults = @{ Passed = 0; Failed = 0 }
$LogDirectory = "$PSScriptRoot/../../logs"

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

function Test-SerilogConfiguration {
    Write-Host "`nChecking Serilog configuration files..." -ForegroundColor Cyan
    
    $configFiles = @(
        "$PSScriptRoot/../../src/BFB.AWSS3Light.API/appsettings.json",
        "$PSScriptRoot/../../src/BFB.AWSS3Light.API/appsettings.Development.json"
    )
    
    foreach ($configFile in $configFiles) {
        if (Test-Path $configFile) {
            try {
                $content = Get-Content $configFile -Raw | ConvertFrom-Json
                if ($content.Serilog) {
                    Write-TestResult "Serilog Config in $(Split-Path $configFile -Leaf)" $true "Configuration found"
                } else {
                    Write-TestResult "Serilog Config in $(Split-Path $configFile -Leaf)" $false "No Serilog configuration found"
                }
            } catch {
                Write-TestResult "Serilog Config in $(Split-Path $configFile -Leaf)" $false "Error reading configuration: $($_.Exception.Message)"
            }
        } else {
            Write-TestResult "Serilog Config in $(Split-Path $configFile -Leaf)" $false "Configuration file not found"
        }
    }
}

function Test-LogDirectory {
    Write-Host "`nChecking log directory..." -ForegroundColor Cyan
    
    if (Test-Path $LogDirectory) {
        Write-TestResult "Log Directory Exists" $true "Path: $LogDirectory"
        
        # Check for log files
        $logFiles = Get-ChildItem -Path $LogDirectory -Filter "*.log" -ErrorAction SilentlyContinue
        if ($logFiles.Count -gt 0) {
            Write-TestResult "Log Files Present" $true "Found $($logFiles.Count) log file(s)"
            
            # Check the most recent log file
            $latestLog = $logFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
            $logAge = (Get-Date) - $latestLog.LastWriteTime
            
            if ($logAge.TotalHours -lt 24) {
                Write-TestResult "Recent Log Activity" $true "Latest log: $($latestLog.Name), Age: $([math]::Round($logAge.TotalHours, 1)) hours"
            } else {
                Write-TestResult "Recent Log Activity" $false "Latest log is older than 24 hours"
            }
        } else {
            Write-TestResult "Log Files Present" $false "No log files found"
        }
    } else {
        Write-TestResult "Log Directory Exists" $false "Log directory not found: $LogDirectory"
    }
}

function Test-ApiLogging {
    Write-Host "`nTesting API logging..." -ForegroundColor Cyan
    
    try {
        # Make a test request to generate log entries
        $response = Invoke-WebRequest -Uri "$ApiUrl/health" -Method GET -TimeoutSec 10
        Write-TestResult "API Request for Logging" ($response.StatusCode -eq 200) "Status: $($response.StatusCode)"
        
        # Wait a moment for logs to be written
        Start-Sleep -Seconds 2
        
        # Check if new log entries were created
        if (Test-Path $LogDirectory) {
            $recentLogs = Get-ChildItem -Path $LogDirectory -Filter "*.log" | Where-Object { $_.LastWriteTime -gt (Get-Date).AddMinutes(-5) }
            if ($recentLogs) {
                Write-TestResult "Log Entry Generation" $true "Recent log activity detected"
            } else {
                Write-TestResult "Log Entry Generation" $false "No recent log activity"
            }
        }
    } catch {
        Write-TestResult "API Request for Logging" $false $_.Exception.Message
    }
}

function Test-LogLevels {
    Write-Host "`nChecking log level configuration..." -ForegroundColor Cyan
    
    $appsettingsPath = "$PSScriptRoot/../../src/BFB.AWSS3Light.API/appsettings.json"
    if (Test-Path $appsettingsPath) {
        try {
            $config = Get-Content $appsettingsPath -Raw | ConvertFrom-Json
            
            if ($config.Serilog.MinimumLevel) {
                $minLevel = $config.Serilog.MinimumLevel.Default
                Write-TestResult "Minimum Log Level" $true "Level: $minLevel"
                
                # Check for appropriate log levels
                if ($config.Serilog.MinimumLevel.Override) {
                    $overrides = $config.Serilog.MinimumLevel.Override | Get-Member -MemberType NoteProperty | Measure-Object
                    Write-TestResult "Log Level Overrides" $true "Found $($overrides.Count) override(s)"
                } else {
                    Write-TestResult "Log Level Overrides" $false "No log level overrides configured"
                }
            } else {
                Write-TestResult "Minimum Log Level" $false "No minimum log level configured"
            }
        } catch {
            Write-TestResult "Log Level Configuration" $false "Error reading configuration: $($_.Exception.Message)"
        }
    }
}

function Show-TestSummary {
    Write-Host "`n=== Serilog Test Summary ===" -ForegroundColor Cyan
    Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
    
    if ($TestResults.Failed -eq 0) {
        Write-Host "`n🎉 All Serilog tests passed!" -ForegroundColor Green
    } else {
        Write-Host "[WARN]  Some Serilog tests failed. Check the results above." -ForegroundColor Yellow
    }
    
    Write-Host "`nTo view logs:" -ForegroundColor Cyan
    Write-Host "- Log directory: $LogDirectory" -ForegroundColor White
    Write-Host "- Recent logs: Get-ChildItem '$LogDirectory' -Filter '*.log' | Sort-Object LastWriteTime -Descending" -ForegroundColor White
}

# Main execution
try {
    Test-SerilogConfiguration
    Test-LogDirectory
    Test-LogLevels
    Test-ApiLogging
} finally {
    Show-TestSummary
}
