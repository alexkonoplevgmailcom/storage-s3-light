#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Test script for Bank Working Hours API endpoints
.DESCRIPTION
    Tests the bank working hours functionality in the BFB AWSS3Light API
.EXAMPLE
    ./test-bank-working-hours-api.ps1
#>

Write-Host "=== Bank Working Hours API Test ===" -ForegroundColor Cyan
Write-Host "This test validates bank working hours functionality" -ForegroundColor Yellow

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

function Test-ApiHealth {
    Write-Host "`nTesting API health..." -ForegroundColor Cyan
    try {
        $response = Invoke-WebRequest -Uri "$ApiUrl/health" -Method GET -TimeoutSec 10
        Write-TestResult "API Health Check" ($response.StatusCode -eq 200) "Status: $($response.StatusCode)"
        return $response.StatusCode -eq 200
    } catch {
        Write-TestResult "API Health Check" $false $_.Exception.Message
        return $false
    }
}

function Test-BankWorkingHours {
    Write-Host "`nTesting Bank Working Hours endpoints..." -ForegroundColor Cyan
    
    # Test getting working hours (if endpoint exists)
    try {
        $response = Invoke-WebRequest -Uri "$ApiUrl/api/banks/working-hours" -Method GET -ErrorAction Stop
        Write-TestResult "Get Working Hours" ($response.StatusCode -eq 200) "Status: $($response.StatusCode)"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-TestResult "Get Working Hours" $false "Endpoint not implemented yet"
        } else {
            Write-TestResult "Get Working Hours" $false $_.Exception.Message
        }
    }
    
    # Test setting working hours (if endpoint exists)
    try {
        $workingHours = @{
            Monday = @{ Open = "09:00"; Close = "17:00" }
            Tuesday = @{ Open = "09:00"; Close = "17:00" }
            Wednesday = @{ Open = "09:00"; Close = "17:00" }
            Thursday = @{ Open = "09:00"; Close = "17:00" }
            Friday = @{ Open = "09:00"; Close = "17:00" }
            Saturday = @{ Open = "10:00"; Close = "14:00" }
            Sunday = @{ Open = ""; Close = "" }
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "$ApiUrl/api/banks/working-hours" -Method POST -Body $workingHours -ContentType "application/json" -ErrorAction Stop
        Write-TestResult "Set Working Hours" ($response.StatusCode -eq 200 -or $response.StatusCode -eq 201) "Status: $($response.StatusCode)"
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-TestResult "Set Working Hours" $false "Endpoint not implemented yet"
        } else {
            Write-TestResult "Set Working Hours" $false $_.Exception.Message
        }
    }
}

function Show-TestSummary {
    Write-Host "`n=== Test Summary ===" -ForegroundColor Cyan
    Write-Host "Passed: $($TestResults.Passed)" -ForegroundColor Green
    Write-Host "Failed: $($TestResults.Failed)" -ForegroundColor Red
    
    if ($TestResults.Failed -eq 0) {
        Write-Host "`n🎉 All tests passed!" -ForegroundColor Green
    } else {
        Write-Host "[WARN]  Some tests failed. Check the results above." -ForegroundColor Yellow
    }
}

# Main execution
try {
    if (Test-ApiHealth) {
        Test-BankWorkingHours
    } else {
        Write-Host "API is not available. Make sure the API is running:" -ForegroundColor Red
        Write-Host "1. cd $PSScriptRoot/../../src/BFB.AWSS3Light.API" -ForegroundColor Yellow
        Write-Host "2. dotnet run" -ForegroundColor Yellow
    }
} finally {
    Show-TestSummary
}
