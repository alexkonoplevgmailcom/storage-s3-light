# Master script to start all BFB AWSS3Light infrastructure and run tests
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("start", "stop", "restart", "test", "full")]
    [string]$Action = "full",
    
    [Parameter(Mandatory = $false)]
    [switch]$SkipTests = $false
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

# Function to check if Docker is running
function Test-DockerRunning {
    try {
        $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
        if ($dockerVersion) {
            Write-Info "Docker is running (version: $dockerVersion)"
            return $true
        }
    }
    catch {
        Write-Error "Docker is not running or not accessible"
        return $false
    }
    return $false
}

# Function to start infrastructure services
function Start-Infrastructure {
    Write-Section "STARTING ALL INFRASTRUCTURE SERVICES"
    
    if (-not (Test-DockerRunning)) {
        Write-Error "Docker must be running to start infrastructure services"
        return $false
    }
    
    # Stop any existing dotnet processes
    Stop-DotnetProcesses
    
    # Array of infrastructure services to start
    $services = @(
        @{ Name = "MongoDB"; File = "docker-compose.mongodb.yml"; Port = "27017"; HealthEndpoint = "mongodb://localhost:27017" }
        @{ Name = "Redis"; File = "docker-compose.redis.yml"; Port = "6379"; HealthEndpoint = "redis://localhost:6379" }
        @{ Name = "MinIO S3"; File = "docker-compose.minio.yml"; Port = "9000"; HealthEndpoint = "http://localhost:9000/minio/health/live" }
        @{ Name = "DB2"; File = "docker-compose.db2.yml"; Port = "50000"; HealthEndpoint = "db2://localhost:50000" }
        @{ Name = "Kafka"; File = "docker-compose.kafka.yml"; Port = "9092"; HealthEndpoint = "kafka://localhost:9092" }
        @{ Name = "SQL Server"; File = "docker-compose.sqlserver.yml"; Port = "1433"; HealthEndpoint = "sqlserver://localhost:1433" }
        @{ Name = "Oracle"; File = "docker-compose.oracle.yml"; Port = "1521"; HealthEndpoint = "oracle://localhost:1521" }
    )
    
    foreach ($service in $services) {
        try {
            Write-Info "Starting $($service.Name)..."
            $dockerComposePath = "docker-compose\$($service.File)"
            
            if (Test-Path $dockerComposePath) {
                docker-compose -f $dockerComposePath up -d
                Write-Info "$($service.Name) started successfully"
            } else {
                Write-Warning "Docker compose file not found: $dockerComposePath"
            }
        }        catch {
            Write-Warning "Failed to start $($service.Name): $($_.Exception.Message)"
        }
    }
    
    Write-Info "Waiting for services to initialize..."
    Start-Sleep -Seconds 30
    
    # Check service health
    Write-Info "Checking service status..."
    $runningContainers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
    Write-Host $runningContainers
    
    return $true
}

# Function to stop infrastructure services
function Stop-Infrastructure {
    Write-Section "STOPPING ALL INFRASTRUCTURE SERVICES"
    
    # Stop dotnet processes first
    Stop-DotnetProcesses
    
    # Array of compose files to stop
    $composeFiles = @(
        "docker-compose.mongodb.yml",
        "docker-compose.redis.yml",
        "docker-compose.minio.yml",
        "docker-compose.db2.yml",
        "docker-compose.kafka.yml",
        "docker-compose.sqlserver.yml",
        "docker-compose.oracle.yml"
    )
    
    foreach ($file in $composeFiles) {
        try {
            $dockerComposePath = "docker-compose\$file"
            if (Test-Path $dockerComposePath) {
                Write-Info "Stopping services in $file..."
                docker-compose -f $dockerComposePath down
            }
        }        catch {
            Write-Warning "Failed to stop services in $file`: $($_.Exception.Message)"
        }
    }
    
    Write-Info "All infrastructure services stopped"
}

# Function to build the solution
function Build-Solution {
    Write-Section "BUILDING SOLUTION"
    
    try {
        Write-Info "Building BFB AWSS3Light solution..."
        dotnet build BFB.AWSS3Light.sln --configuration Release --verbosity minimal
        
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Solution built successfully"
            return $true
        } else {
            Write-Error "Solution build failed"
            return $false
        }
    }    catch {
        Write-Error "Build failed: $($_.Exception.Message)"
        return $false
    }
}

# Function to run comprehensive tests
function Run-Tests {
    Write-Section "RUNNING COMPREHENSIVE TESTS"
    
    # Array of test scripts to run
    $testScripts = @(
        @{ Name = "Health Check Validation"; Script = "quick-validate.ps1" }
        @{ Name = "MongoDB Tests"; Script = "test-redis-simple.ps1" }
        @{ Name = "Redis Cache Tests"; Script = "test-redis-cache.ps1" }
        @{ Name = "S3 Storage Tests"; Script = "test-s3-api.ps1" }
        @{ Name = "Enhanced Banks API"; Script = "test-enhanced-banks-api-clean.ps1" }
        @{ Name = "Final Clean Tests"; Script = "test-final-clean.ps1" }
        @{ Name = "Resilience Validation"; Script = "validate-resilience.ps1" }
    )
    
    $testResults = @()
    
    foreach ($test in $testScripts) {
        try {
            Write-Info "Running $($test.Name)..."
            $testPath = "scripts\powershell\$($test.Script)"
            
            if (Test-Path $testPath) {
                $result = powershell -ExecutionPolicy Bypass -File $testPath
                $testResults += @{
                    Name = $test.Name
                    Status = if ($LASTEXITCODE -eq 0) { "PASSED" } else { "FAILED" }
                    Script = $test.Script
                }
                Write-Info "$($test.Name) completed"
            } else {
                Write-Warning "Test script not found: $testPath"
                $testResults += @{
                    Name = $test.Name
                    Status = "SKIPPED"
                    Script = $test.Script
                }
            }
        }        catch {
            Write-Warning "Failed to run $($test.Name)`: $($_.Exception.Message)"
            $testResults += @{
                Name = $test.Name
                Status = "ERROR"
                Script = $test.Script
            }
        }
    }
    
    # Display test summary
    Write-Section "TEST RESULTS SUMMARY"
    foreach ($result in $testResults) {
        $color = switch ($result.Status) {
            "PASSED" { "Green" }
            "FAILED" { "Red" }
            "SKIPPED" { "Yellow" }
            "ERROR" { "Red" }
        }
        Write-Host "$($result.Name): $($result.Status)" -ForegroundColor $color
    }
    
    $passedTests = ($testResults | Where-Object { $_.Status -eq "PASSED" }).Count
    $totalTests = $testResults.Count
    Write-Info "Tests Passed: $passedTests/$totalTests"
}

# Function to display service URLs
function Show-ServiceUrls {
    Write-Section "SERVICE URLS AND ENDPOINTS"
    
    $services = @(
        "MongoDB: mongodb://localhost:27017 (admin/password123)",
        "Mongo Express: http://localhost:8081",
        "Redis: redis://localhost:6379",
        "MinIO S3: http://localhost:9000 (minioadmin/minioadmin)",
        "MinIO Console: http://localhost:9001",
        "DB2: jdbc:db2://localhost:50000/testdb",
        "Kafka: localhost:9092",
        "SQL Server: localhost:1433",
        "Oracle: localhost:1521",
        "",
        "API Endpoints (when running):",
        "Health Check: http://localhost:5111/health",
        "Readiness: http://localhost:5111/health/ready",
        "Swagger: http://localhost:5111/swagger"
    )
    
    foreach ($service in $services) {
        if ($service -eq "") {
            Write-Host ""
        } else {
            Write-Host "  $service" -ForegroundColor Cyan
        }
    }
}

# Main execution logic
try {
    Write-Section "BFB TEMPLATE INFRASTRUCTURE MANAGER"
    Write-Info "Action: $Action"
    
    switch ($Action) {
        "start" {
            if (Start-Infrastructure) {
                Show-ServiceUrls
            }
        }
        
        "stop" {
            Stop-Infrastructure
        }
        
        "restart" {
            Stop-Infrastructure
            Start-Sleep -Seconds 5
            if (Start-Infrastructure) {
                Show-ServiceUrls
            }
        }
        
        "test" {
            if (-not $SkipTests) {
                Run-Tests
            }
        }
        
        "full" {
            # Full deployment and testing cycle
            Write-Info "Starting full infrastructure deployment and testing cycle..."
            
            # Stop any existing services
            Stop-Infrastructure
            Start-Sleep -Seconds 5
            
            # Start all infrastructure
            if (-not (Start-Infrastructure)) {
                Write-Error "Failed to start infrastructure services"
                exit 1
            }
            
            # Build solution
            if (-not (Build-Solution)) {
                Write-Error "Failed to build solution"
                exit 1
            }
            
            # Wait for services to be fully ready
            Write-Info "Waiting for all services to be fully ready..."
            Start-Sleep -Seconds 45
            
            # Show service URLs
            Show-ServiceUrls
            
            # Run tests if not skipped
            if (-not $SkipTests) {
                Write-Info "Starting automated tests in 10 seconds..."
                Start-Sleep -Seconds 10
                Run-Tests
            }
            
            Write-Section "DEPLOYMENT COMPLETE"
            Write-Info "All infrastructure services are running and ready for use"
            Write-Info "You can now start the API with: cd src\BFB.AWSS3Light.API; dotnet run"
        }
    }
}
catch {
    Write-Error "Script execution failed: $($_.Exception.Message)"
    exit 1
}

Write-Info "Script completed successfully"
