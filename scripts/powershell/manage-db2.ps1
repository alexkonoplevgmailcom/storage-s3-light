#!/usr/bin/env pwsh

<#
.SYNOPSIS
    DB2 container management script
.DESCRIPTION
    Manages DB2 container using Docker Compose for the BFB AWSS3Light project
.PARAMETER Action
    The action to perform: start, stop, restart, or status
.EXAMPLE
    ./manage-db2.ps1 start
    ./manage-db2.ps1 stop
    ./manage-db2.ps1 status
#>

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("start", "stop", "restart", "status")]
    [string]$Action
)

$ErrorActionPreference = "Stop"
$ProjectRoot = "$PSScriptRoot/../.."
$ComposeFile = "$ProjectRoot/docker-compose/docker-compose.db2.yml"

function Start-DB2 {
    Write-Host "Starting DB2 container..." -ForegroundColor Green
    Push-Location -Path $ProjectRoot
    try {
        docker-compose -f $ComposeFile up -d
        if ($LASTEXITCODE -eq 0) {
            Write-Host "DB2 container started successfully" -ForegroundColor Green
            Write-Host "Note: DB2 may take several minutes to initialize on first run" -ForegroundColor Yellow
            Start-Sleep -Seconds 5
            Show-DB2Status
        } else {
            Write-Host "Failed to start DB2 container" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Stop-DB2 {
    Write-Host "Stopping DB2 container..." -ForegroundColor Yellow
    Push-Location -Path $ProjectRoot
    try {
        docker-compose -f $ComposeFile down
        if ($LASTEXITCODE -eq 0) {
            Write-Host "DB2 container stopped successfully" -ForegroundColor Green
        } else {
            Write-Host "Failed to stop DB2 container" -ForegroundColor Red
        }
    }
    finally {
        Pop-Location
    }
}

function Restart-DB2 {
    Write-Host "Restarting DB2 container..." -ForegroundColor Cyan
    Stop-DB2
    Start-Sleep -Seconds 3
    Start-DB2
}

function Show-DB2Status {
    Write-Host "DB2 container status:" -ForegroundColor Cyan
    $db2Container = docker ps --filter "name=db2" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    if ($db2Container) {
        Write-Host $db2Container -ForegroundColor Green
        
        # Show DB2 logs (last 10 lines)
        Write-Host "`nRecent DB2 logs:" -ForegroundColor Cyan
        docker logs db2-container --tail 10
        
        Write-Host "`nNote: DB2 container is running but may still be initializing." -ForegroundColor Yellow
        Write-Host "Check logs for 'Setup has completed' message to confirm DB2 is ready." -ForegroundColor Yellow
    } else {
        Write-Host "❌ DB2 container is not running" -ForegroundColor Red
        Write-Host "Note: DB2 requires significant resources and may not be supported on all platforms" -ForegroundColor Yellow
    }
}

# Main execution
switch ($Action.ToLower()) {
    "start" { Start-DB2 }
    "stop" { Stop-DB2 }
    "restart" { Restart-DB2 }
    "status" { Show-DB2Status }
}
