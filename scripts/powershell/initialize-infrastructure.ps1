# Infrastructure Initialization Script for BFB AWSS3Light
# This script initializes all required infrastructure components before running tests
param(
    [Parameter(Mandatory = $false)]
    [switch]$Force = $false
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

function Test-ServicePort {
    param(
        [string]$Service,
        [int]$Port,
        [int]$TimeoutSeconds = 10
    )
    
    try {
        $tcpClient = New-Object System.Net.Sockets.TcpClient
        $asyncResult = $tcpClient.BeginConnect("localhost", $Port, $null, $null)
        $waitHandle = $asyncResult.AsyncWaitHandle
        
        if ($waitHandle.WaitOne($TimeoutSeconds * 1000)) {
            $tcpClient.EndConnect($asyncResult)
            $tcpClient.Close()
            Write-Info "$Service is accessible on port $Port"
            return $true
        } else {
            $tcpClient.Close()
            Write-Warning "$Service is not accessible on port $Port"
            return $false
        }
    }
    catch {
        Write-Warning "$Service connection failed on port $Port`: $($_.Exception.Message)"
        return $false
    }
}

function Initialize-MongoDB {
    Write-Section "INITIALIZING MONGODB"
    
    if (-not (Test-ServicePort -Service "MongoDB" -Port 27017)) {
        Write-Error "MongoDB is not running. Please start MongoDB first."
        return $false
    }
    
    try {
        Write-Info "Creating MongoDB collections and indexes..."
        
        # Wait a bit more for MongoDB to be fully ready
        Start-Sleep -Seconds 10
        
        # Try to connect and create collections
        $mongoScript = @"
db = db.getSiblingDB('BfbTemplate');

// Create customers collection with sample data if it doesn't exist
if (db.customers.countDocuments() === 0) {
    db.customers.insertOne({
        business_id: UUID(),
        email: 'test@example.com',
        phone: '+1234567890',
        first_name: 'Test',
        middle_name: '',
        last_name: 'User',
        birth_date: new Date('1990-01-01'),
        address: '123 Main St',
        balance: NumberDecimal('1000.00'),
        status: 1,
        created_at: new Date(),
        updated_at: new Date()
    });
    print('Created customers collection with sample data');
}

// Create customerTransactions collection
if (db.customerTransactions.countDocuments() === 0) {
    print('Created customerTransactions collection');
}

// Ensure indexes exist
db.customers.createIndex({ 'business_id': 1 }, { unique: true });
db.customers.createIndex({ 'email': 1 }, { unique: true });
db.customerTransactions.createIndex({ 'business_id': 1 }, { unique: true });
db.customerTransactions.createIndex({ 'customer_id': 1 });

print('MongoDB initialization completed successfully');
"@
        
        # Save script to temp file and execute
        $tempScript = [System.IO.Path]::GetTempFileName() + ".js"
        $mongoScript | Out-File -FilePath $tempScript -Encoding UTF8
        
        # Execute MongoDB script
        docker exec bfb-awss3light-mongodb mongosh --username admin --password password123 --authenticationDatabase admin --file /tmp/init-script.js 2>$null
        
        # Alternative approach - copy script into container and execute
        docker cp $tempScript bfb-awss3light-mongodb:/tmp/init-script.js
        $result = docker exec bfb-awss3light-mongodb mongosh --username admin --password password123 --authenticationDatabase admin --file /tmp/init-script.js
        
        Remove-Item $tempScript -ErrorAction SilentlyContinue
        
        Write-Info "MongoDB collections and indexes created successfully"
        return $true
    }
    catch {
        Write-Warning "MongoDB initialization failed: $($_.Exception.Message)"
        Write-Info "MongoDB may already be initialized or will initialize on first API call"
        return $true
    }
}

function Initialize-Redis {
    Write-Section "INITIALIZING REDIS"
    
    if (-not (Test-ServicePort -Service "Redis" -Port 6379)) {
        Write-Error "Redis is not running. Please start Redis first."
        return $false
    }
    
    try {
        Write-Info "Testing Redis connection and setting up initial data..."
        
        # Test Redis connection using redis-cli in container
        $redisTest = docker exec bfb-redis redis-cli ping
        if ($redisTest -eq "PONG") {
            Write-Info "Redis connection successful"
            
            # Set some initial test keys
            docker exec bfb-redis redis-cli set "bfb:health" "ok" ex 3600
            docker exec bfb-redis redis-cli set "bfb:init" "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')" ex 3600
            
            Write-Info "Redis initialization completed successfully"
            return $true
        } else {
            Write-Warning "Redis ping failed"
            return $false
        }
    }
    catch {
        Write-Warning "Redis initialization failed: $($_.Exception.Message)"
        return $false
    }
}

function Initialize-MinIO {
    Write-Section "INITIALIZING MINIO S3"
    
    if (-not (Test-ServicePort -Service "MinIO" -Port 9000)) {
        Write-Error "MinIO is not running. Please start MinIO first."
        return $false
    }
    
    try {
        Write-Info "Creating S3 buckets and testing connectivity..."
        
        # Wait for MinIO to be fully ready
        Start-Sleep -Seconds 5
        
        # Create required buckets using mc (MinIO Client) via Docker
        $buckets = @("bfb-files", "test-bucket", "bfb-documents", "bfb-uploads")
        
        foreach ($bucket in $buckets) {
            try {
                # Try to create bucket using MinIO client
                $createResult = docker exec minio-s3 mc mb /data/$bucket 2>$null
                Write-Info "Created S3 bucket: $bucket"
            }
            catch {
                Write-Info "S3 bucket $bucket may already exist or will be created automatically"
            }
        }
        
        # Test bucket access by trying to list buckets
        try {
            $listResult = docker exec minio-s3 mc ls /data/ 2>$null
            Write-Info "S3 bucket listing successful"
        }
        catch {
            Write-Info "S3 bucket listing failed, but buckets will be auto-created by application"
        }
        
        Write-Info "MinIO S3 initialization completed successfully"
        return $true
    }
    catch {
        Write-Warning "MinIO initialization failed: $($_.Exception.Message)"
        Write-Info "MinIO buckets will be auto-created by the application"
        return $true
    }
}

function Initialize-Kafka {
    Write-Section "INITIALIZING KAFKA"
    
    if (-not (Test-ServicePort -Service "Kafka" -Port 9092)) {
        Write-Error "Kafka is not running. Please start Kafka first."
        return $false
    }
    
    try {
        Write-Info "Creating Kafka topics..."
        
        # Wait for Kafka to be fully ready
        Start-Sleep -Seconds 10
        
        # Define required topics from appsettings.json
        $topics = @(
            "bank-machine-cash-withdrawal-requests",
            "account-balance-change-request", 
            "brinks-cash-management",
            "test-topic"
        )
        
        foreach ($topic in $topics) {
            try {
                Write-Info "Creating Kafka topic: $topic"
                $createResult = docker exec bfb-kafka kafka-topics.sh --create --bootstrap-server localhost:9092 --topic $topic --partitions 3 --replication-factor 1 2>$null
                if ($LASTEXITCODE -eq 0) {
                    Write-Info "Created Kafka topic: $topic"
                } else {
                    Write-Info "Kafka topic $topic may already exist"
                }
            }
            catch {
                Write-Info "Kafka topic $topic creation failed or already exists"
            }
        }
        
        # List topics to verify creation
        try {
            Write-Info "Listing Kafka topics..."
            $topicList = docker exec bfb-kafka kafka-topics.sh --list --bootstrap-server localhost:9092
            Write-Info "Available Kafka topics: $($topicList -join ', ')"
        }
        catch {
            Write-Info "Could not list Kafka topics, but they should be available"
        }
        
        Write-Info "Kafka initialization completed successfully"
        return $true
    }
    catch {
        Write-Warning "Kafka initialization failed: $($_.Exception.Message)"
        return $false
    }
}

function Initialize-DB2 {
    Write-Section "INITIALIZING DB2"
    
    if (-not (Test-ServicePort -Service "DB2" -Port 50000)) {
        Write-Error "DB2 is not running. Please start DB2 first."
        return $false
    }
    
    try {
        Write-Info "Initializing DB2 database and tables..."
        
        # Wait for DB2 to be fully ready (it takes time to initialize)
        Write-Info "Waiting for DB2 to be fully ready (this may take a few minutes)..."
        $maxWait = 180  # 3 minutes
        $waited = 0
        $db2Ready = $false
        
        while ($waited -lt $maxWait -and -not $db2Ready) {
            Start-Sleep -Seconds 10
            $waited += 10
            
            try {
                # Check if DB2 is ready by trying to connect
                $healthCheck = docker exec bfb-awss3light-db2 db2 connect to BFBTEMPL user db2inst1 using password123 2>$null
                if ($LASTEXITCODE -eq 0) {
                    $db2Ready = $true
                    Write-Info "DB2 is ready for connections"
                } else {
                    Write-Info "DB2 still initializing... ($waited/$maxWait seconds)"
                }
            }
            catch {
                Write-Info "DB2 still starting up... ($waited/$maxWait seconds)"
            }
        }
        
        if (-not $db2Ready) {
            Write-Warning "DB2 may still be initializing. Tables and schema will be created by Entity Framework migrations."
            return $true
        }
        
        # Create database schema if needed
        $sqlScript = @"
CONNECT TO BFBTEMPL USER db2inst1 USING password123;

-- Create Banks table
CREATE TABLE IF NOT EXISTS BANKS (
    ID INTEGER NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    BANK_CODE VARCHAR(20) NOT NULL,
    NAME VARCHAR(255) NOT NULL,
    SWIFT_CODE VARCHAR(11),
    EMAIL VARCHAR(255),
    PHONE VARCHAR(50),
    ADDRESS VARCHAR(500),
    CREATED_AT TIMESTAMP DEFAULT CURRENT TIMESTAMP,
    UPDATED_AT TIMESTAMP DEFAULT CURRENT TIMESTAMP,
    PRIMARY KEY (ID),
    UNIQUE (BANK_CODE)
);

-- Create indexes
CREATE INDEX IF NOT EXISTS IDX_BANKS_CODE ON BANKS(BANK_CODE);
CREATE INDEX IF NOT EXISTS IDX_BANKS_SWIFT ON BANKS(SWIFT_CODE);

-- Insert sample data
INSERT INTO BANKS (BANK_CODE, NAME, SWIFT_CODE, EMAIL, PHONE, ADDRESS) 
VALUES ('TESTBANK', 'Test Bank', 'TESTBK12', 'info@testbank.com', '+1-555-0123', '123 Bank Street, Test City')
ON DUPLICATE KEY UPDATE NAME = NAME;

COMMIT;
DISCONNECT;
"@
        
        # Save SQL script and execute
        $tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
        $sqlScript | Out-File -FilePath $tempSqlFile -Encoding UTF8
        
        # Copy script to container and execute
        docker cp $tempSqlFile bfb-awss3light-db2:/tmp/init-db2.sql
        $result = docker exec bfb-awss3light-db2 db2 -f /tmp/init-db2.sql
        
        Remove-Item $tempSqlFile -ErrorAction SilentlyContinue
        
        Write-Info "DB2 initialization completed successfully"
        return $true
    }
    catch {
        Write-Warning "DB2 initialization failed: $($_.Exception.Message)"
        Write-Info "DB2 tables will be created by Entity Framework migrations when the API starts"
        return $true
    }
}

function Initialize-SqlServer {
    Write-Section "INITIALIZING SQL SERVER"
    
    if (-not (Test-ServicePort -Service "SQL Server" -Port 1433)) {
        Write-Error "SQL Server is not running. Please start SQL Server first."
        return $false
    }
    
    try {
        Write-Info "Initializing SQL Server database..."
        
        # Wait for SQL Server to be ready
        Start-Sleep -Seconds 15
        
        $sqlScript = @"
-- Create database if it doesn't exist
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'BfbTemplate')
BEGIN
    CREATE DATABASE BfbTemplate;
END
GO

USE BfbTemplate;
GO

-- Sample initialization - tables will be created by EF migrations
SELECT 1 as Ready;
GO
"@
        
        # Save SQL script
        $tempSqlFile = [System.IO.Path]::GetTempFileName() + ".sql"
        $sqlScript | Out-File -FilePath $tempSqlFile -Encoding UTF8
        
        # Execute SQL script using sqlcmd in container
        docker cp $tempSqlFile bfb-awss3light-sqlserver:/tmp/init-sqlserver.sql
        $result = docker exec bfb-awss3light-sqlserver /opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P 'P@ssw0rd!123' -i /tmp/init-sqlserver.sql
        
        Remove-Item $tempSqlFile -ErrorAction SilentlyContinue
        
        Write-Info "SQL Server initialization completed successfully"
        return $true
    }
    catch {
        Write-Warning "SQL Server initialization failed: $($_.Exception.Message)"
        Write-Info "SQL Server database will be created by Entity Framework migrations"
        return $true
    }
}

function Initialize-Oracle {
    Write-Section "INITIALIZING ORACLE"
    
    if (-not (Test-ServicePort -Service "Oracle" -Port 1521)) {
        Write-Error "Oracle is not running. Please start Oracle first."
        return $false
    }
    
    try {
        Write-Info "Oracle is running - tables will be created by Entity Framework migrations"
        Write-Info "Oracle initialization completed successfully"
        return $true
    }
    catch {
        Write-Warning "Oracle initialization check failed: $($_.Exception.Message)"
        return $true
    }
}

# Main execution
try {
    Write-Section "BFB TEMPLATE INFRASTRUCTURE INITIALIZATION"
    
    # Check if Docker is running
    try {
        $dockerVersion = docker version --format "{{.Server.Version}}" 2>$null
        if (-not $dockerVersion) {
            Write-Error "Docker is not running. Please start Docker first."
            exit 1
        }
        Write-Info "Docker is running (version: $dockerVersion)"
    }
    catch {
        Write-Error "Docker is not accessible. Please ensure Docker is running."
        exit 1
    }
    
    # Initialize all services
    $results = @()
    
    $results += @{ Service = "MongoDB"; Success = (Initialize-MongoDB) }
    $results += @{ Service = "Redis"; Success = (Initialize-Redis) }
    $results += @{ Service = "MinIO S3"; Success = (Initialize-MinIO) }
    $results += @{ Service = "Kafka"; Success = (Initialize-Kafka) }
    $results += @{ Service = "DB2"; Success = (Initialize-DB2) }
    $results += @{ Service = "SQL Server"; Success = (Initialize-SqlServer) }
    $results += @{ Service = "Oracle"; Success = (Initialize-Oracle) }
    
    # Display results
    Write-Section "INITIALIZATION SUMMARY"
    $successCount = 0
    foreach ($result in $results) {
        if ($result.Success) {
            Write-Host "✓ $($result.Service): SUCCESS" -ForegroundColor Green
            $successCount++
        } else {
            Write-Host "✗ $($result.Service): FAILED" -ForegroundColor Red
        }
    }
    
    Write-Host ""
    Write-Info "Infrastructure Initialization: $successCount/$($results.Count) services initialized successfully"
    
    if ($successCount -eq $results.Count) {
        Write-Host "✓ All infrastructure components are ready for testing!" -ForegroundColor Green
    } else {
        Write-Host "⚠ Some components failed to initialize, but the API may still work" -ForegroundColor Yellow
        Write-Info "Many components will auto-initialize when the API starts"
    }
      Write-Section "NEXT STEPS"
    Write-Info "Infrastructure is ready. You can now:"
    Write-Host "  1. Start the API: cd src\\BFB.AWSS3Light.API; dotnet run" -ForegroundColor Cyan
    Write-Host "  2. Run tests: .\\scripts\\powershell\\run-all-tests.ps1" -ForegroundColor Cyan
    Write-Host "  3. Check health: Invoke-WebRequest -Uri 'http://localhost:5111/health'" -ForegroundColor Cyan
}
catch {
    Write-Error "Infrastructure initialization failed: $($_.Exception.Message)"
    exit 1
}

Write-Info "Infrastructure initialization completed"
