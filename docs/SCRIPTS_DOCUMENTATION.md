# BFB AWSS3Light Scripts Documentation

This document provides comprehensive documentation for all scripts in the BFB AWSS3Light project, organized in the `scripts/` directory.

## Table of Contents

- [Overview](#overview)
- [PowerShell Scripts](#powershell-scripts)
  - [Infrastructure Management](#infrastructure-management)
  - [Database Management](#database-management)
  - [Testing Scripts](#testing-scripts)
  - [Utility Scripts](#utility-scripts)
- [Bash Scripts](#bash-scripts)
- [Script Dependencies](#script-dependencies)
- [Usage Guidelines](#usage-guidelines)

## Overview

All scripts in this project have been organized into the `scripts/` directory with the following structure:

```
scripts/
├── powershell/     # PowerShell scripts for cross-platform use
├── bash/          # Bash scripts for Unix/Linux/macOS
└── init/          # Initialization scripts and data
```

All scripts are designed to be cross-platform compatible and use relative paths from their script locations.

## PowerShell Scripts

### Infrastructure Management

#### `initialize-infrastructure.ps1`
**Purpose**: Comprehensive infrastructure initialization script that sets up all required services before running tests.

**Features**:
- Starts all Docker containers (MongoDB, Redis, Kafka, SQL Server, Oracle, DB2)
- Validates service connectivity and health
- Initializes databases with required schemas and data
- Configures message queues and topics
- Provides colored output for better visibility

**Parameters**:
- `-Force`: Forces reinitialization even if services are already running

**Usage**:
```powershell
./initialize-infrastructure.ps1
./initialize-infrastructure.ps1 -Force
```

#### `start-all-infrastructure.ps1`
**Purpose**: Starts all infrastructure services using Docker Compose.

**Features**:
- Orchestrates startup of all required services
- Validates service availability
- Provides status reporting

**Usage**:
```powershell
./start-all-infrastructure.ps1
```

#### `check-infrastructure.ps1`
**Purpose**: Checks the health and status of all infrastructure components.

**Features**:
- Tests connectivity to all services
- Validates database connections
- Checks message queue status
- Reports service health status

**Usage**:
```powershell
./check-infrastructure.ps1
```

#### `check-infrastructure-fixed.ps1`
**Purpose**: Enhanced version of infrastructure checking with improved error handling and reporting.

**Features**:
- More robust health checks
- Better error reporting
- Service-specific validation
- Cross-platform compatibility improvements

**Usage**:
```powershell
./check-infrastructure-fixed.ps1
```

### Database Management

#### `manage-mongodb.ps1`
**Purpose**: MongoDB container management using Docker Compose.

**Parameters**:
- `Action`: start, stop, restart, or status

**Features**:
- Starts/stops MongoDB container
- Displays container status
- Initializes MongoDB with required collections
- Validates MongoDB connectivity

**Usage**:
```powershell
./manage-mongodb.ps1 start
./manage-mongodb.ps1 stop
./manage-mongodb.ps1 status
```

#### `manage-redis.ps1`
**Purpose**: Redis container management using Docker Compose.

**Parameters**:
- `Action`: start, stop, restart, or status

**Features**:
- Manages Redis container lifecycle
- Tests Redis connectivity
- Validates cache operations

**Usage**:
```powershell
./manage-redis.ps1 start
./manage-redis.ps1 stop
```

#### `manage-oracle.ps1`
**Purpose**: Oracle database container management.

**Parameters**:
- `Action`: start, stop, restart, or status

**Features**:
- Manages Oracle container
- Handles Oracle-specific initialization
- Validates database connectivity

**Usage**:
```powershell
./manage-oracle.ps1 start
```

#### `manage-oracle-migrations.ps1`
**Purpose**: Handles Oracle database migrations and schema updates.

**Features**:
- Runs database migrations
- Creates required schemas
- Validates migration status

**Usage**:
```powershell
./manage-oracle-migrations.ps1
```

#### `manage-db2.ps1`
**Purpose**: IBM DB2 container management.

**Parameters**:
- `Action`: start, stop, restart, or status

**Features**:
- Manages DB2 container (Linux/macOS compatible)
- Handles DB2-specific configuration
- Validates database connectivity
- OS-conditional execution for macOS compatibility

**Usage**:
```powershell
./manage-db2.ps1 start
```

### Messaging and Kafka Management

#### `manage-kafka.ps1`
**Purpose**: Kafka container management using Docker Compose.

**Parameters**:
- `Action`: start, stop, restart, or status

**Features**:
- Manages Kafka and Zookeeper containers
- Validates Kafka connectivity
- Tests message publishing/consuming

**Usage**:
```powershell
./manage-kafka.ps1 start
```

#### `manage-kafka-topics.ps1`
**Purpose**: Kafka topic management and configuration.

**Features**:
- Creates required Kafka topics
- Configures topic partitions and replication
- Validates topic creation

**Usage**:
```powershell
./manage-kafka-topics.ps1
```

#### `verify-kafka.ps1`
**Purpose**: Comprehensive Kafka functionality testing.

**Features**:
- Tests Kafka producer/consumer functionality
- Validates message flow
- Checks topic configuration

**Usage**:
```powershell
./verify-kafka.ps1
```

### Testing Scripts

#### `run-all-tests.ps1`
**Purpose**: Comprehensive test runner for all test suites.

**Parameters**:
- `TestSuite`: "all", "api", "infrastructure", "integration"
- `-StartAPI`: Automatically starts the API before testing
- `-Verbose`: Enables verbose output

**Features**:
- Runs unit tests, integration tests, and API tests
- Provides comprehensive test reporting
- Supports selective test execution
- Includes performance metrics

**Usage**:
```powershell
./run-all-tests.ps1
./run-all-tests.ps1 -TestSuite api -StartAPI
./run-all-tests.ps1 -TestSuite integration -Verbose
```

#### `test-enhanced-banks-api-clean.ps1`
**Purpose**: Clean and comprehensive testing of the Banks API with enhanced validation.

**Features**:
- Tests all Bank API endpoints
- Validates response schemas
- Tests error handling scenarios
- Performance testing

**Usage**:
```powershell
./test-enhanced-banks-api-clean.ps1
```

#### `test-bank-tellers-api.ps1`
**Purpose**: Specific testing for Bank Tellers API endpoints.

**Features**:
- Tests CRUD operations for bank tellers
- Validates business logic
- Tests authentication and authorization

**Usage**:
```powershell
./test-bank-tellers-api.ps1
```

#### `test-bank-working-hours-api.ps1`
**Purpose**: Tests Bank Working Hours API functionality.

**Features**:
- Tests working hours CRUD operations
- Validates time zone handling
- Tests schedule conflicts

**Usage**:
```powershell
./test-bank-working-hours-api.ps1
```

#### `test-redis-api.ps1`
**Purpose**: Tests Redis integration and caching functionality.

**Features**:
- Tests cache operations
- Validates cache expiration
- Tests cache invalidation scenarios

**Usage**:
```powershell
./test-redis-api.ps1
```

#### `test-redis-cache.ps1`
**Purpose**: Comprehensive Redis caching tests.

**Features**:
- Tests caching strategies
- Validates cache performance
- Tests distributed caching scenarios

**Usage**:
```powershell
./test-redis-cache.ps1
```

#### `test-redis-simple.ps1`
**Purpose**: Simple Redis connectivity and basic operation tests.

**Features**:
- Basic Redis connection testing
- Simple key-value operations
- Health check validation

**Usage**:
```powershell
./test-redis-simple.ps1
```

#### `test-s3-api.ps1`
**Purpose**: Tests S3-compatible storage integration (MinIO).

**Features**:
- Tests file upload/download operations
- Validates bucket operations
- Tests file metadata handling

**Usage**:
```powershell
./test-s3-api.ps1
```

#### `test-kafka-integration.ps1`
**Purpose**: Integration testing for Kafka messaging.

**Features**:
- Tests message publishing and consuming
- Validates message ordering
- Tests error handling scenarios

**Usage**:
```powershell
./test-kafka-integration.ps1
```

#### `test-mongo-redis-s3-kafka.ps1`
**Purpose**: Comprehensive integration testing across MongoDB, Redis, S3, and Kafka.

**Features**:
- Cross-service integration testing
- Data flow validation
- End-to-end scenario testing

**Usage**:
```powershell
./test-mongo-redis-s3-kafka.ps1
```

#### `test-net8-performance.ps1`
**Purpose**: .NET 8 specific performance testing and benchmarking.

**Features**:
- Performance benchmarking
- Memory usage analysis
- Startup time measurements
- Throughput testing

**Usage**:
```powershell
./test-net8-performance.ps1
```

#### `test-serilog-config.ps1`
**Purpose**: Tests Serilog logging configuration and functionality.

**Features**:
- Validates logging configuration
- Tests different log levels
- Validates log output formats
- Tests structured logging

**Usage**:
```powershell
./test-serilog-config.ps1
```

#### `test-final-clean.ps1`
**Purpose**: Final comprehensive test suite with cleanup.

**Features**:
- Runs complete test suite
- Performs environment cleanup
- Generates final test reports

**Usage**:
```powershell
./test-final-clean.ps1
```

#### `test-final-enhancements.ps1`
**Purpose**: Tests for final enhancements and optimizations.

**Features**:
- Tests latest features
- Validates enhancements
- Performance regression testing

**Usage**:
```powershell
./test-final-enhancements.ps1
```

### Utility Scripts

#### `GenerateDependencyGraph.ps1`
**Purpose**: Generates project dependency graphs and analysis.

**Features**:
- Creates visual dependency graphs
- Analyzes project dependencies
- Identifies circular dependencies
- Generates documentation

**Usage**:
```powershell
./GenerateDependencyGraph.ps1
```

#### `init-simple.ps1`
**Purpose**: Simple initialization script for basic setup.

**Features**:
- Quick environment setup
- Basic service validation
- Minimal configuration

**Usage**:
```powershell
./init-simple.ps1
```

#### `quick-validate.ps1`
**Purpose**: Quick validation of system health and readiness.

**Features**:
- Fast health checks
- Basic connectivity testing
- Quick status overview

**Usage**:
```powershell
./quick-validate.ps1
```

#### `validate-resilience.ps1`
**Purpose**: Tests system resilience and fault tolerance.

**Features**:
- Chaos engineering tests
- Failure scenario testing
- Recovery validation
- Circuit breaker testing

**Usage**:
```powershell
./validate-resilience.ps1
```

## Bash Scripts

### `test-serilog-config.sh`
**Purpose**: Bash version of Serilog configuration testing for Unix/Linux/macOS environments.

**Features**:
- Cross-platform Serilog testing
- Log file validation
- Configuration verification
- Structured logging tests

**Usage**:
```bash
./test-serilog-config.sh
```

**Key Features**:
- Colored output for better readability
- Comprehensive test coverage
- Log file analysis
- JSON log format validation
- Error handling and reporting

## Script Dependencies

### Required Tools
- **PowerShell Core** (7.0+): For PowerShell scripts
- **Docker & Docker Compose**: For container management
- **dotnet CLI**: For .NET operations
- **curl**: For HTTP API testing
- **jq**: For JSON processing (optional but recommended)

### Service Dependencies
Scripts depend on the following services being available:
- MongoDB (Port 27017)
- Redis (Port 6379)
- Kafka (Port 9092)
- SQL Server (Port 1433)
- Oracle (Port 1521)
- DB2 (Port 50000)
- MinIO S3 (Port 9000)
- API Service (Port 5111)

### Docker Compose Files
Scripts reference these Docker Compose files:
- `docker-compose/docker-compose.mongodb.yml`
- `docker-compose/docker-compose.redis.yml`
- `docker-compose/docker-compose.kafka.yml`
- `docker-compose/docker-compose.sqlserver.yml`
- `docker-compose/docker-compose.oracle.yml`
- `docker-compose/docker-compose.db2.yml`
- `docker-compose/docker-compose.minio.yml`

## Usage Guidelines

### General Principles
1. **Run from Script Directory**: All scripts use relative paths and should be run from their respective directories
2. **Check Prerequisites**: Ensure Docker and required tools are installed
3. **Environment Setup**: Run infrastructure initialization before testing
4. **Cross-Platform**: Scripts are designed to work on Windows, macOS, and Linux

### Recommended Workflow
1. **Initialize Infrastructure**:
   ```powershell
   ./initialize-infrastructure.ps1
   ```

2. **Validate Setup**:
   ```powershell
   ./check-infrastructure.ps1
   ```

3. **Run Tests**:
   ```powershell
   ./run-all-tests.ps1
   ```

4. **Specific Testing**:
   ```powershell
   ./test-enhanced-banks-api-clean.ps1
   ```

### macOS Specific Notes
- DB2 tests may be skipped or show warnings due to IBM DB2 macOS limitations
- Ensure Docker Desktop is running before executing scripts
- Some scripts may require elevated permissions for Docker operations

### Troubleshooting
- **Port Conflicts**: Check if required ports are available
- **Docker Issues**: Ensure Docker daemon is running
- **Permission Errors**: Check script execution permissions
- **Path Issues**: Verify working directory and relative paths

### Environment Variables
Some scripts may use these environment variables:
- `ASPNETCORE_ENVIRONMENT`: Set to Development or Production
- `ConnectionStrings__*`: Database connection strings
- `DOCKER_HOST`: For remote Docker daemon access

### Log Files
Scripts generate logs in:
- `logs/`: Application logs
- Console output with colored formatting
- Docker container logs accessible via `docker logs`

## Contributing to Scripts

When modifying or adding new scripts:
1. Follow the established naming convention
2. Use relative paths with `$PSScriptRoot` (PowerShell) or `$SCRIPT_DIR` (Bash)
3. Include proper error handling and colored output
4. Add comprehensive documentation and comments
5. Test on multiple platforms
6. Update this documentation file

## Script Execution Permissions

For bash scripts, ensure they have execute permissions:
```bash
chmod +x scripts/bash/*.sh
```

PowerShell scripts should be executable by default on most systems with PowerShell Core installed.
