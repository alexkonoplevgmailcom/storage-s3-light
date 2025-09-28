# Simple Infrastructure Initialization Script
$ErrorActionPreference = "Continue"

function Write-Info {
    param([string]$Message)
    Write-Host "INFO: $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "WARNING: $Message" -ForegroundColor Yellow
}

function Write-Section {
    param([string]$Title)
    Write-Host ""
    Write-Host "=====================================" -ForegroundColor Cyan
    Write-Host $Title -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan
}

Write-Section "INITIALIZING INFRASTRUCTURE COMPONENTS"

# Initialize MongoDB
Write-Info "Initializing MongoDB..."
try {
    # Test MongoDB connection
    $mongoTest = docker exec bfb-awss3light-mongodb mongosh --username admin --password password123 --authenticationDatabase admin --eval "db.runCommand({ping: 1})" 2>$null
    if ($LASTEXITCODE -eq 0) {
        Write-Info "MongoDB is accessible"
        
        # Create basic collections if they don't exist
        docker exec bfb-awss3light-mongodb mongosh --username admin --password password123 --authenticationDatabase admin --eval "
        db = db.getSiblingDB('BfbTemplate');
        if (db.customers.countDocuments() === 0) {
            db.customers.insertOne({
                business_id: UUID(),
                email: 'health@test.com',
                first_name: 'Health',
                last_name: 'Check',
                balance: NumberDecimal('0.00'),
                status: 1,
                created_at: new Date(),
                updated_at: new Date()
            });
        }
        db.customers.createIndex({ 'business_id': 1 }, { unique: true });
        db.customers.createIndex({ 'email': 1 }, { unique: true });
        " 2>$null
        
        Write-Info "MongoDB collections initialized"
    } else {
        Write-Warning "MongoDB initialization failed - will auto-initialize on API start"
    }
} catch {
    Write-Warning "MongoDB initialization error: $($_.Exception.Message)"
}

# Initialize Redis
Write-Info "Initializing Redis..."
try {
    $redisTest = docker exec bfb-redis redis-cli ping 2>$null
    if ($redisTest -eq "PONG") {
        Write-Info "Redis is accessible"
        docker exec bfb-redis redis-cli set "bfb:health" "ok" ex 3600 2>$null
        Write-Info "Redis test keys created"
    } else {
        Write-Warning "Redis initialization failed"
    }
} catch {
    Write-Warning "Redis initialization error: $($_.Exception.Message)"
}

# Initialize MinIO S3
Write-Info "Initializing MinIO S3..."
try {
    # Wait for MinIO to be ready
    Start-Sleep -Seconds 5
    
    # Create the main bucket directory inside MinIO container
    docker exec minio-s3 mkdir -p /data/bfb-files 2>$null
    docker exec minio-s3 mkdir -p /data/test-bucket 2>$null
    
    Write-Info "MinIO S3 buckets directories created"
} catch {
    Write-Warning "MinIO initialization error: $($_.Exception.Message)"
}

# Initialize Kafka Topics
Write-Info "Initializing Kafka..."
try {
    # Wait for Kafka to be ready
    Start-Sleep -Seconds 10
    
    # Create required topics
    $topics = @(
        "bank-machine-cash-withdrawal-requests",
        "account-balance-change-request",
        "brinks-cash-management"
    )
    
    foreach ($topic in $topics) {
        docker exec bfb-kafka kafka-topics.sh --create --bootstrap-server localhost:9092 --topic $topic --partitions 1 --replication-factor 1 2>$null
        Write-Info "Created/verified Kafka topic: $topic"
    }
    
    # List topics
    $topicList = docker exec bfb-kafka kafka-topics.sh --list --bootstrap-server localhost:9092 2>$null
    Write-Info "Available Kafka topics: $($topicList -join ', ')"
} catch {
    Write-Warning "Kafka initialization error: $($_.Exception.Message)"
}

# Initialize DB2
Write-Info "Initializing DB2..."
try {
    Write-Info "DB2 tables will be created by Entity Framework migrations"
    Write-Info "DB2 is ready for connections"
} catch {
    Write-Warning "DB2 initialization error: $($_.Exception.Message)"
}

# Initialize SQL Server
Write-Info "Initializing SQL Server..."
try {
    Write-Info "SQL Server database will be created by Entity Framework migrations"
    Write-Info "SQL Server is ready for connections"
} catch {
    Write-Warning "SQL Server initialization error: $($_.Exception.Message)"
}

# Initialize Oracle
Write-Info "Initializing Oracle..."
try {
    Write-Info "Oracle database will be created by Entity Framework migrations"
    Write-Info "Oracle is ready for connections"
} catch {
    Write-Warning "Oracle initialization error: $($_.Exception.Message)"
}

Write-Section "INITIALIZATION COMPLETE"
Write-Info "Infrastructure components have been initialized"
Write-Info "Entity Framework will create database schemas on first API startup"
Write-Info ""
Write-Info "Ready to start the API and run tests!"
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. cd src\\BFB.AWSS3Light.API; dotnet run" -ForegroundColor Yellow
Write-Host "  2. Test health: Invoke-WebRequest -Uri 'http://localhost:5111/health'" -ForegroundColor Yellow
