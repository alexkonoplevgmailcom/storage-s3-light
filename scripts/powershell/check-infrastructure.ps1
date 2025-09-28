# Quick infrastructure health check script
$ErrorActionPreference = "Stop"

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

function Test-Port {
    param(
        [string]$HostName = "localhost",
        [int]$Port,
        [int]$TimeoutSeconds = 5
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect($HostName, $Port, $null, $null)
        $waitHandle = $asyncResult.AsyncWaitHandle
        
        if ($waitHandle.WaitOne($TimeoutSeconds * 1000)) {
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()
            return $true
        } else {
            $tcpClient.Close()
            return $false
        }
    }
    catch {
        return $false
    }
}

Write-Host "BFB AWSS3Light Infrastructure Health Check" -ForegroundColor Cyan
Write-Host "=======================================" -ForegroundColor Cyan
Write-Host ""

# Check Docker is running
Write-Info "Checking Docker status..."
try {
    $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
    if ($dockerVersion) {
        Write-Host "✓ Docker is running (version: $dockerVersion)" -ForegroundColor Green
    } else {
        Write-Host "✗ Docker is not running" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "✗ Docker is not accessible" -ForegroundColor Red
    exit 1
}

# Check running containers
Write-Info "Checking running containers..."
$containers = docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
Write-Host $containers

Write-Host ""
Write-Info "Checking service ports..."

# Define services to check
$services = @(
    @{ Name = "MongoDB"; Port = 27017 }
    @{ Name = "Redis"; Port = 6379 }
    @{ Name = "MinIO S3"; Port = 9000 }
    @{ Name = "MinIO Console"; Port = 9001 }
    @{ Name = "DB2"; Port = 50000 }
    @{ Name = "Kafka"; Port = 9092 }
    @{ Name = "SQL Server"; Port = 1433 }
    @{ Name = "Oracle"; Port = 1521 }
)

$healthyServices = 0
$totalServices = $services.Count

foreach ($service in $services) {
    $isHealthy = Test-Port -Port $service.Port
    if ($isHealthy) {
        Write-Host "✓ $($service.Name) (port $($service.Port)): HEALTHY" -ForegroundColor Green
        $healthyServices++
    } else {
        Write-Host "✗ $($service.Name) (port $($service.Port)): NOT ACCESSIBLE" -ForegroundColor Red
    }
}

Write-Host ""
Write-Info "Infrastructure Health Summary: $healthyServices/$totalServices services are healthy"

if ($healthyServices -eq $totalServices) {
    Write-Host "✓ All infrastructure services are running and accessible" -ForegroundColor Green
} elseif ($healthyServices -gt 0) {
    Write-Host "⚠ Some infrastructure services are not running" -ForegroundColor Yellow
} else {
    Write-Host "✗ No infrastructure services are accessible" -ForegroundColor Red
}

Write-Host ""
Write-Info "Service URLs:"
Write-Host "  MongoDB: mongodb://localhost:27017" -ForegroundColor Cyan
Write-Host "  Mongo Express: http://localhost:8081" -ForegroundColor Cyan
Write-Host "  Redis: redis://localhost:6379" -ForegroundColor Cyan
Write-Host "  MinIO S3: http://localhost:9000 (minioadmin/minioadmin)" -ForegroundColor Cyan
Write-Host "  MinIO Console: http://localhost:9001" -ForegroundColor Cyan
Write-Host "  DB2: jdbc:db2://localhost:50000/testdb" -ForegroundColor Cyan
Write-Host "  Kafka: localhost:9092" -ForegroundColor Cyan
Write-Host "  SQL Server: localhost:1433" -ForegroundColor Cyan
Write-Host "  Oracle: localhost:1521" -ForegroundColor Cyan

Write-Host ""
Write-Info "To start the API server, run:"
Write-Host "  cd src\BFB.AWSS3Light.API; dotnet run" -ForegroundColor Yellow
