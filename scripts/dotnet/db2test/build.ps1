# DB2 Test Application Build Script
param(
    [switch]$Run,
    [switch]$Clean,
    [switch]$Help
)

if ($Help) {
    Write-Host "DB2 Test Application Build Script" -ForegroundColor Green
    Write-Host "Usage:"
    Write-Host "  .\build.ps1           # Build only"
    Write-Host "  .\build.ps1 -Run      # Build and run"
    Write-Host "  .\build.ps1 -Clean    # Clean, then build"
    exit 0
}

$ProjectPath = "C:\Users\FIBI\Repos\dotnet\bfb-awss3light-ng\scripts\dotnet\db2test"

Write-Host "=== DB2 Test Application Build ===" -ForegroundColor Green

try {
    Set-Location $ProjectPath
    Write-Host "Working directory: $ProjectPath" -ForegroundColor Cyan

    if ($Clean) {
        Write-Host "Cleaning project..." -ForegroundColor Yellow
        dotnet clean
        if ($LASTEXITCODE -ne 0) { throw "Clean failed" }
    }

    Write-Host "Restoring packages..." -ForegroundColor Yellow
    dotnet restore
    if ($LASTEXITCODE -ne 0) { throw "Restore failed" }

    Write-Host "Building application..." -ForegroundColor Yellow
    dotnet build --no-restore
    if ($LASTEXITCODE -ne 0) { throw "Build failed" }

    Write-Host "Build completed successfully!" -ForegroundColor Green

    if ($Run) {
        Write-Host ""
        Write-Host "Running DB2 test..." -ForegroundColor Yellow
        dotnet run --no-build
        if ($LASTEXITCODE -ne 0) { throw "Run failed" }
    } else {
        Write-Host "To run: .\build.ps1 -Run" -ForegroundColor Cyan
    }

} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    Write-Host "Troubleshooting:"
    Write-Host "1. Ensure .NET 8 SDK is installed"
    Write-Host "2. Start DB2 container first"
    exit 1
}
