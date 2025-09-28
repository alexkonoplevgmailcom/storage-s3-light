param(
    [Parameter(Mandatory = $true)]
    [ValidateSet("add", "apply")]
    [string]$Action,
    
    [Parameter(Mandatory = $false)]
    [string]$MigrationName
)

$ErrorActionPreference = "Stop"

function Add-OracleMigration {
    param(
        [Parameter(Mandatory = $true)]
        [string]$MigrationName
    )
    
    Write-Host "Adding Oracle migration: $MigrationName" -ForegroundColor Cyan
    
    # Navigate to the project directory
    Push-Location -Path "$PSScriptRoot/../../src/BFB.AWSS3Light.DataAccess.Oracle"
    
    # Add the migration
    dotnet ef migrations add $MigrationName --startup-project "..\BFB.AWSS3Light.API\BFB.AWSS3Light.API.csproj"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to add Oracle migration!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host "Oracle migration '$MigrationName' added successfully." -ForegroundColor Green
    Pop-Location
}

function Apply-OracleMigration {
    Write-Host "Applying Oracle migrations to the database..." -ForegroundColor Cyan
    
    # Navigate to the project directory
    Push-Location -Path "$PSScriptRoot/../../src/BFB.AWSS3Light.DataAccess.Oracle"
    
    # Apply the migrations
    dotnet ef database update --startup-project "..\BFB.AWSS3Light.API\BFB.AWSS3Light.API.csproj"
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Failed to apply Oracle migrations!" -ForegroundColor Red
        Pop-Location
        exit 1
    }
    
    Write-Host "Oracle migrations applied successfully." -ForegroundColor Green
    Pop-Location
}

# Execute the requested action
switch ($Action) {
    "add" { 
        if ([string]::IsNullOrEmpty($MigrationName)) {
            Write-Host "Migration name is required for 'add' action!" -ForegroundColor Red
            exit 1
        }
        Add-OracleMigration -MigrationName $MigrationName 
    }
    "apply" { 
        Apply-OracleMigration 
    }
}
