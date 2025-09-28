#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Oracle container management script
.DESCRIPTION
    Manages Oracle container using Docker Compose for the BFB AWSS3Light project
.PARAMETER Action
    The action to perform: start, stop, restart, or status
.EXAMPLE
    ./manage-oracle.ps1 start
    ./manage-oracle.ps1 stop
    ./manage-oracle.ps1 status
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "$PSScriptRoot/../.."
$ComposeFile = "$ProjectRoot/docker-compose/docker-compose.oracle.yml"

function Start-Oracle {
    Write-Host "Starting Oracle container..." -ForegroundColor Green
    Push-Location -Path $ProjectRoot
    try {
        docker-compose -f $ComposeFile up -d
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Oracle container started successfully" -ForegroundColor Green
            Write-Host "Note: Oracle may take several minutes to initialize on first run" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Show-OracleStatus
        } else {
            Write-Host "Failed to start Oracle container" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Stop-Oracle {
    Write-Host "Stopping Oracle container..." -ForegroundColor Yellow
    Push-Location -Path $ProjectRoot
    try {
        docker-compose -f $ComposeFile down
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Oracle container stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to stop Oracle container" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Restart-Oracle {
    Write-Host "Restarting Oracle container..." -ForegroundColor Cyan
    Stop-Oracle
    Start-Sleep -Seconds 3
    Start-Oracle
}

function Show-OracleStatus {
    Write-Host "Oracle container status:" -ForegroundColor Cyan
    $oracleContainer = docker ps --filter "name=oracle" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    if ($oracleContainer) {
        Write-Host $oracleContainer -ForegroundColor Green
        
        # Show Oracle logs (last 10 lines)
        Write-Host "`nRecent Oracle logs:" -ForegroundColor Cyan
        docker logs oracle-container --tail 10
        
        Write-Host "`nNote: Oracle container is running but may still be initializing." -ForegroundColor Yellow
        Write-Host "Check logs for 'DATABASE IS READY TO USE!' message to confirm Oracle is ready." -ForegroundColor Yellow
    } else {
        Write-Host "❌ Oracle container is not running" -ForegroundColor Red
        Write-Host "Note: Oracle requires significant resources and may not be supported on all platforms" -ForegroundColor Yellow
    }
}

# Main execution
switch ($Action.ToLower()) {
    "start" { Start-Oracle }
    "stop" { Stop-Oracle }
    "restart" { Restart-Oracle }
    "status" { Show-OracleStatus }
}
