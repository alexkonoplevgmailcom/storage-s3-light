# DB2 Database Initialization Instructions

This document provides comprehensive instructions for initializing IBM DB2 databases for BFB AWSS3Light projects using Docker containers.

## 🎯 Current Status: .NET 8 Complete Migration

**✅ COMPLETED:** Full migration to .NET 8.0 with clean build

### What Was Accomplished:
- ✅ All projects now target `net8.0` (migrated from `net9.0`)
- ✅ All NuGet packages downgraded to .NET 8 compatible versions
- ✅ Removed .NET 8-compatible APIs configuration from the API project
- ✅ Fixed EntityFrameworkCore version conflicts across all projects
- ✅ Removed all references to `ConnectionStrings:DB2Connection` configuration
- ✅ Standardized DB2 connection configuration to use only the `DB2` section
- ✅ Created and tested DB2 connectivity test console app at `scripts/dotnet/db2test/`
- ✅ Entire solution builds successfully on .NET 8

### Key Benefits:
- **Stable Platform**: .NET 8 is an LTS (Long Term Support) release
- **Production Ready**: All dependencies are stable and well-tested
- **Consistent Configuration**: Single source of DB2 connection configuration
- **Better Testing**: Dedicated DB2 test application for connection validation

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Docker Container Setup](#docker-container-setup)
3. [Database Creation](#database-creation)
4. [Schema Setup](#schema-setup)
5. [Connection Configuration](#connection-configuration)
6. [Testing and Verification](#testing-and-verification)
7. [Common Issues and Solutions](#common-issues-and-solutions)
8. [Best Practices](#best-practices)

## ⚠️ CRITICAL REQUIREMENT: OS-Conditional NuGet Packages

**ALL BFB AWSS3Light projects MUST use OS-conditional DB2 NuGet packages.** This is not optional.

```xml
<!-- MANDATORY: Use this pattern in ALL BFB template .csproj files -->
<ItemGroup>
  <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Windows'))" />
  <PackageReference Include="Net.IBM.Data.Db2-lnx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Linux'))" />
  <PackageReference Include="Net.IBM.Data.Db2-osx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('OSX'))" />
</ItemGroup>
```

**Why this is required:**
- Ensures optimal native library loading across all platforms
- Prevents runtime errors on specific platforms
- Maintains consistency across all BFB template projects
- Required for proper Docker container deployment across environments

See [Connection Configuration](#connection-configuration) section for complete details.

## Prerequisites

### Required Software
- **Docker Desktop** - Latest version
- **PowerShell** - For running automation scripts
- **IBM Data Server Client** (optional) - For advanced DB2 administration

### Docker Images
- **IBM DB2**: `ibmcom/db2:11.5.7.0a`
- Container runs with privileged access for proper DB2 operation

## Docker Container Setup

### 1. Start DB2 Container
Use the provided Docker Compose configuration:

```powershell
# Navigate to project root
cd C:\Users\{Username}\Repos\dotnet\{ProjectName}

# Start DB2 using infrastructure compose
docker-compose -f docker-compose/docker-compose.infrastructure.yml up -d db2

# Or start DB2 specifically
docker-compose -f docker-compose/docker-compose.db2.yml up -d
```

### 2. Verify Container Status
```powershell
# Check container is running and healthy
docker ps --filter "name=bfb-{projectname}-db2"

# Check logs for startup completion
docker logs bfb-{projectname}-db2
```

### 3. Container Configuration
```yaml
# docker-compose.db2.yml configuration
services:
  db2:
    image: ibmcom/db2:11.5.7.0a
    container_name: bfb-{projectname}-db2
    restart: unless-stopped
    privileged: true
    ports:
      - "50000:50000"
    environment:
      LICENSE: accept
      DB2INSTANCE: db2inst1
      DB2INST1_PASSWORD: password123
      DBNAME: BFBTEMPL
      BLU: false
      ENABLE_ORACLE_COMPATIBILITY: false
      UPDATEAVAIL: NO
      TO_CREATE_SAMPLEDB: false
      REPODB: false
    volumes:
      - db2_data:/database
    healthcheck:
      test: ["CMD", "su", "-", "db2inst1", "-c", "db2 connect to BFBTEMPL"]
      interval: 30s
      timeout: 10s
      retries: 5
      start_period: 300s
```

## Database Creation

### 1. Default Database (BFBTEMPL)
The container automatically creates the `BFBTEMPL` database during initialization.

**Connection Parameters:**
- **Database:** BFBTEMPL
- **User:** db2inst1
- **Password:** password123
- **Host:** localhost
- **Port:** 50000

### 2. Creating Additional Databases

#### Option A: Using SQL Scripts
Create a SQL script for database creation:

```sql
-- db2-database-setup.sql
CREATE DATABASE {PROJDB};
CONNECT TO {PROJDB};

-- Create schemas
CREATE SCHEMA {PROJSCHEMA};
CREATE SCHEMA FILES;

-- Verify creation
SELECT SCHEMANAME FROM SYSCAT.SCHEMATA 
WHERE SCHEMANAME IN ('{PROJSCHEMA}', 'FILES');

CONNECT RESET;
```

#### Option B: Using DB2 Commands
```powershell
# Connect to container and create database
docker exec -it bfb-{projectname}-db2 su - db2inst1

# Inside container
db2 create database {PROJDB}
db2 connect to {PROJDB}
db2 "CREATE SCHEMA {PROJSCHEMA}"
db2 "CREATE SCHEMA FILES"
```

### 3. Database Naming Conventions
- **Maximum Length:** 8 characters (DB2 limitation)
- **Format:** UPPERCASE recommended
- **Examples:**
  - `BFBTEMPL` - BFB AWSS3Light database (default)
  - `{PROJDB}` - Project-specific database
  - `TESTDB` - Test database

**Naming Pattern for BFB Projects:**
- Use abbreviated project names (max 8 characters)
- Examples: `BANKAPI`, `FILEPROC`, `CUSTMGMT`, `PAYMNT`

## Schema Setup

### 1. Standard Schema Structure
```sql
-- Standard schemas for BFB applications
CREATE SCHEMA BFBAPP;     -- Main application schema
CREATE SCHEMA FILES;      -- File management schema
CREATE SCHEMA AUDIT;      -- Audit logging schema
CREATE SCHEMA CONFIG;     -- Configuration schema

-- Project-specific schemas (adjust based on domain)
CREATE SCHEMA {PROJSCHEMA}; -- Main project schema
CREATE SCHEMA DATA;       -- Data processing schema
CREATE SCHEMA REPORTS;    -- Reporting schema
```

### 2. Schema Permissions
```sql
-- Grant permissions to application user
GRANT CREATETAB ON SCHEMA BFBAPP TO USER db2inst1;
GRANT CREATETAB ON SCHEMA FILES TO USER db2inst1;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA BFBAPP TO USER db2inst1;
GRANT SELECT, INSERT, UPDATE, DELETE ON SCHEMA FILES TO USER db2inst1;
```

### 3. Test Table Creation
```sql
-- Create test table to verify setup
CREATE TABLE FILES.TEST_FILES (
    TEST_ID BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    FILE_NAME VARCHAR(255) NOT NULL,
    FILE_SIZE BIGINT NOT NULL,
    CREATED_DATE TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (TEST_ID)
);

-- Insert test data
INSERT INTO FILES.TEST_FILES (FILE_NAME, FILE_SIZE) 
VALUES ('test_document.pdf', 1024);

-- Verify insertion
SELECT * FROM FILES.TEST_FILES;
```

## Connection Configuration

### 1. NuGet Package Requirements

#### Required OS-Conditional Package Pattern (MANDATORY)
All BFB template projects **MUST** use OS-conditional DB2 packages for optimal platform compatibility:

```xml
<!-- OS-conditional DB2 packages - MANDATORY for all BFB template projects -->
<ItemGroup>
  <!-- OS-conditional DB2 packages for optimal platform compatibility -->
  <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Windows'))" />
  <PackageReference Include="Net.IBM.Data.Db2-lnx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Linux'))" />
  <PackageReference Include="Net.IBM.Data.Db2-osx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('OSX'))" />
</ItemGroup>
```

**Critical Requirements:**
- **OS-conditional logic is MANDATORY** for all BFB template projects
- **Each platform must use its specific package** for optimal driver support
- **This pattern ensures** proper native library loading across all platforms
- **Failure to use this pattern** may cause runtime errors on specific platforms

#### Alternative Package (Legacy Single Platform Only)
If targeting a legacy single platform, you may use the base package without conditions:

```xml
<!-- Legacy single-platform alternative (use OS-conditional pattern above for multi-platform) -->
<PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" />
```

**Notes:**
- The base Net.IBM.Data.Db2 provides cross-platform support but OS-conditional packages are preferred
- OS-conditional pattern above is the **required standard** for BFB template projects

#### .NET Framework Requirement
```xml
<!-- Target .NET 8 for DB2 compatibility -->
<TargetFramework>net8.0</TargetFramework>
```

### 2. Connection String Format
**For OS-conditional Net.IBM.Data.Db2 packages (recommended):**
```
Server={Host}:{Port};Database={DatabaseName};UserID={Username};Password={Password};
```

**For legacy IBM.Data.DB2.Core package (not recommended):**
```
Database={DatabaseName};Server={Host}:{Port};UserID={Username};Password={Password};
```

**Key differences:**
- Net.IBM.Data.Db2 family: Uses `Server=` first, then `Database=`
- IBM.Data.DB2.Core: Uses `Database=` first, then `Server=`
- Both use semicolon-terminated format
- No quotes around parameter values

### 3. Application Configuration (appsettings.json)
```json
{
  "DB2": {
    "ConnectionString": "Server=localhost:50000;Database=BFBTEMPL;UserID=db2inst1;Password=password123;ConnectTimeout=30;",
    "CommandTimeout": 30,
    "MaxRetryAttempts": 3,
    "RetryDelayMilliseconds": 1000
  }
}
```

**Important Notes:**
- **ONLY use the DB2 section**: All DB2 code must use the `ConnectionString` from the `DB2` section
- **Configuration binding**: Configured via `services.Configure<DB2Settings>(configuration.GetSection("DB2"))`
- **Connection string format**: Must use `Server=` prefix for Net.IBM.Data.Db2 packages
- **Replace placeholders**: Update `{PROJDB}` with your actual project database name

### 4. Example Project Configuration
**Sample DB2TestApp.csproj for testing (using MANDATORY OS-conditional pattern):**
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <!-- OS-conditional DB2 packages - MANDATORY for all BFB template projects -->
    <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Windows'))" />
    <PackageReference Include="Net.IBM.Data.Db2-lnx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Linux'))" />
    <PackageReference Include="Net.IBM.Data.Db2-osx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('OSX'))" />
    
    <!-- Configuration and logging (use .NET 8 versions) -->
    <PackageReference Include="Microsoft.Extensions.Configuration" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging.Console" Version="9.0.0" />
  </ItemGroup>

  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
```

### 5. Culture Configuration for DB2
**CRITICAL**: Set invariant culture to prevent localization issues with DB2:
```csharp
using System.Globalization;

// Set at application startup (in Program.cs or Main method)
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;
```

**Why this is required:**
- DB2 may encounter formatting issues with date/time and numeric values in different locales
- Prevents "Invalid argument" errors during database operations
- Ensures consistent behavior across different Windows regional settings

### 6. Connection Validation
```powershell
# Test connection using db2cli
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 connect to BFBTEMPL user db2inst1 using password123"

# Test query execution
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 connect to BFBTEMPL; db2 'SELECT COUNT(*) FROM SYSCAT.TABLES'"

# Test project-specific database
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 connect to {PROJDB} user db2inst1 using password123"
```

## Testing and Verification

### 1. Health Check Verification
```powershell
# Check container health status
docker inspect bfb-{projectname}-db2 | findstr "Health"

# Manual health check
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 connect to BFBTEMPL"
```

### 2. Database Listing
```powershell
# List all databases
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 list database directory"
```

### 3. Schema and Table Verification
```sql
-- List all schemas (excluding system schemas)
SELECT SCHEMANAME FROM SYSCAT.SCHEMATA 
WHERE SCHEMANAME NOT LIKE 'SYS%' 
AND SCHEMANAME NOT LIKE 'NULLID%';

-- List all tables in custom schemas
SELECT TABSCHEMA, TABNAME FROM SYSCAT.TABLES 
WHERE TABSCHEMA NOT LIKE 'SYS%';

-- Count records in test table
SELECT COUNT(*) AS TOTAL_RECORDS FROM FILES.TEST_FILES;
```

### 4. Connection Testing Script
```powershell
# test-db2-connection.ps1
function Test-DB2Connection {
    param(
        [string]$DatabaseName = "BFBTEMPL"
    )
    
    Write-Host "Testing DB2 connection to database: $DatabaseName" -ForegroundColor Yellow
    
    try {
        $result = docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 connect to $DatabaseName user db2inst1 using password123"
        
        if ($result -match "Database Connection Information") {
            Write-Host "✅ Connection successful to $DatabaseName" -ForegroundColor Green
            return $true
        } else {
            Write-Host "❌ Connection failed to $DatabaseName" -ForegroundColor Red
            return $false
        }
    }
    catch {
        Write-Host "❌ Error testing connection: $_" -ForegroundColor Red
        return $false
    }
}

# Test connections
Test-DB2Connection -DatabaseName "BFBTEMPL"
Test-DB2Connection -DatabaseName "{PROJDB}"
```

## Common Issues and Solutions

### 1. Container Startup Issues
**Problem:** Container fails to start or becomes unhealthy
**Solutions:**
```powershell
# Check container logs
docker logs bfb-{projectname}-db2

# Restart container
docker restart bfb-{projectname}-db2

# Remove and recreate if needed
docker-compose -f docker-compose/docker-compose.db2.yml down
docker-compose -f docker-compose/docker-compose.db2.yml up -d
```

### 2. Connection Timeout Issues
**Problem:** Connection attempts timeout
**Solutions:**
- Verify container is fully started (wait 5-10 minutes after startup)
- Check port 50000 is not blocked by firewall
- Increase connection timeout in connection string

### 3. Permission Denied Errors
**Problem:** Cannot create databases or tables
**Solutions:**
```sql
-- Grant additional permissions
GRANT DBADM ON DATABASE TO USER db2inst1;
GRANT CREATETAB ON DATABASE TO USER db2inst1;
```

### 4. Database Name Limitations
**Problem:** Database names longer than 8 characters fail
**Solutions:**
- Use abbreviated names (BFBTEMPL, TEVELFLS)
- Follow DB2 naming conventions
- Use schemas for organization instead of multiple databases

### 5. Character Encoding Issues
**Problem:** Special characters in data cause errors
**Solutions:**
```csharp
// Set invariant culture in .NET applications
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;
```

### 6. .NET/DB2 Driver Issues

#### Problem: Platform-Specific Driver Issues
**Symptoms:**
- "AES encryption is not supported in this environment"
- "Invalid argument" errors during connection
- Runtime errors on specific platforms (Windows/Linux/macOS)

**Solution (MANDATORY for BFB template projects):**
```xml
<!-- USE OS-conditional packages for optimal platform compatibility -->
<ItemGroup>
  <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Windows'))" />
  <PackageReference Include="Net.IBM.Data.Db2-lnx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Linux'))" />
  <PackageReference Include="Net.IBM.Data.Db2-osx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('OSX'))" />
</ItemGroup>

<!-- Legacy alternative for single-platform deployment only -->
<!-- <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" /> -->
```

#### Problem: .NET Version Compatibility
**Symptoms:**
- Runtime errors with .NET versions
- Driver compatibility issues

**Solution:**
```xml
<!-- Use .NET 8 for DB2 compatibility -->
<TargetFramework>net8.0</TargetFramework>

<!-- Ensure compatible Microsoft.Extensions packages -->
<PackageReference Include="Microsoft.Extensions.Configuration" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="8.0.0" />
<PackageReference Include="Microsoft.Extensions.Logging" Version="8.0.0" />
```

#### Problem: Column Access Errors
**Symptoms:**
- "Column 'COLUMN_NAME' not found" errors
- Case sensitivity issues

**Solution:**
```csharp
// Use exact column names as defined in DB2 (usually UPPERCASE)
var testId = reader.GetInt64("TEST_ID");        // Not "Id" or "test_id"
var fileName = reader.GetString("FILE_NAME");   // Not "FileName" or "file_name"
var fileSize = reader.GetInt64("FILE_SIZE");    // Not "FileSize" or "file_size"
var createdDate = reader.GetDateTime("CREATED_DATE"); // Not "CreatedDate"

// Check for NULL values properly
if (!reader.IsDBNull("CREATED_DATE"))
{
    var createdDate = reader.GetDateTime("CREATED_DATE");
}
```

### 7. Connection String Issues
**Problem:** Connection string format incompatibility between drivers

**For OS-conditional Net.IBM.Data.Db2 packages (RECOMMENDED):**
```
Server=localhost:50000;Database=BFBTEMPL;UserID=db2inst1;Password=password123;
```

**For legacy IBM.Data.DB2.Core package (not recommended):**
```
Database=BFBTEMPL;Server=localhost:50000;UserID=db2inst1;Password=password123;
```

**Key differences:**
- Net.IBM.Data.Db2 family: `Server=` comes first, then `Database=`
- IBM.Data.DB2.Core: `Database=` comes first, then `Server=`
- Both require semicolon termination
- Parameter order matters for each driver type

## Best Practices

### 1. **MANDATORY: OS-Conditional NuGet Package Usage**
**This is the most critical requirement for all BFB template projects:**

```xml
<!-- REQUIRED PATTERN: Must be used in ALL BFB template .csproj files -->
<ItemGroup>
  <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Windows'))" />
  <PackageReference Include="Net.IBM.Data.Db2-lnx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Linux'))" />
  <PackageReference Include="Net.IBM.Data.Db2-osx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('OSX'))" />
</ItemGroup>
```

**Enforcement Rules:**
- **NEVER use single platform packages** without OS conditions in BFB template projects
- **ALWAYS verify OS-conditional logic** is present during code reviews
- **REJECT pull requests** that don't follow this pattern
- **Update existing projects** that don't follow this pattern immediately

### 2. **MANDATORY: Use GetOrdinal() for DataReader Column Access**
**All DB2 repository implementations MUST use GetOrdinal() instead of numeric indexers:**

```csharp
// ✅ CORRECT: Use GetOrdinal for column access
private static BankEntity MapFromReader(IDataReader reader)
{
    return new BankEntity
    {
        Id = reader.GetString(reader.GetOrdinal("ID")),
        Name = reader.GetString(reader.GetOrdinal("NAME")),
        BankCode = reader.GetString(reader.GetOrdinal("BANK_CODE")),
        SwiftCode = reader.IsDBNull(reader.GetOrdinal("SWIFT_CODE")) ? string.Empty : reader.GetString(reader.GetOrdinal("SWIFT_CODE")),
        Address = reader.IsDBNull(reader.GetOrdinal("ADDRESS")) ? string.Empty : reader.GetString(reader.GetOrdinal("ADDRESS")),
        PhoneNumber = reader.IsDBNull(reader.GetOrdinal("PHONE_NUMBER")) ? string.Empty : reader.GetString(reader.GetOrdinal("PHONE_NUMBER")),
        Email = reader.IsDBNull(reader.GetOrdinal("EMAIL")) ? string.Empty : reader.GetString(reader.GetOrdinal("EMAIL")),
        IsActive = reader.GetInt16(reader.GetOrdinal("IS_ACTIVE")) == 1,
        CreatedAt = reader.GetDateTime(reader.GetOrdinal("CREATED_AT")),
        UpdatedAt = reader.GetDateTime(reader.GetOrdinal("UPDATED_AT"))
    };
}

// ❌ WRONG: Never use numeric indexers
private static BankEntity MapFromReader(IDataReader reader)
{
    return new BankEntity
    {
        Id = reader.GetString(0), // Fragile - column order dependent
        Name = reader.GetString(1), // Hard to maintain
        BankCode = reader.GetString(2), // Error-prone
        // ... etc
    };
}
```

**Why GetOrdinal() is mandatory:**
- **Column Order Independence**: Queries can add/remove columns without breaking code
- **Self-Documenting**: Makes column names explicit in the mapping code
- **Maintainability**: Easy to see which database columns map to which properties
- **Error Prevention**: Compile-time safety vs runtime index-out-of-bounds errors
- **Refactoring Safe**: Adding columns to SELECT statements won't break existing code

**Enforcement Rules:**
- **ALWAYS use GetOrdinal()** in all DataReader mapping methods
- **NEVER use numeric indexers** (0, 1, 2, etc.) for column access
- **UPDATE existing code** that uses numeric indexers immediately
- **REJECT pull requests** that introduce numeric indexer usage

### 3. Database Organization
- **Use schemas** for logical data separation
- **Limit database names** to 8 characters or less
- **Follow naming conventions**: UPPERCASE for databases, mixed case for schemas
- **Create dedicated schemas** for different functional areas (FILES, AUDIT, CONFIG)

### 4. Security Considerations
- **Change default passwords** in production environments
- **Use environment variables** for sensitive configuration
- **Implement proper user management** with minimal required privileges
- **Enable SSL/TLS** for production connections

### 5. Performance Optimization
- **Use connection pooling** in application configuration
- **Set appropriate timeouts** for commands and connections
- **Create indexes** on frequently queried columns
- **Monitor connection counts** to avoid exhaustion

### 6. Backup and Recovery
```powershell
# Create database backup
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 backup database BFBTEMPL to /tmp"

# Copy backup from container
docker cp bfb-{projectname}-db2:/tmp/BFBTEMPL.0.db2inst1.DBPART000.20231226120000.001 ./backups/

# Backup project-specific database
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 backup database {PROJDB} to /tmp"
```

### 7. Monitoring and Maintenance
- **Monitor container health** regularly
- **Check database sizes** and growth patterns
- **Review logs** for errors or warnings
- **Update statistics** periodically for optimal performance

```sql
-- Update table statistics
RUNSTATS ON TABLE FILES.TEST_FILES WITH DISTRIBUTION AND DETAILED INDEXES ALL;

-- Check database size
SELECT SUBSTR(TBSP_NAME,1,20) AS TABLESPACE_NAME,
       TBSP_TOTAL_SIZE_KB,
       TBSP_USED_SIZE_KB,
       TBSP_FREE_SIZE_KB
FROM SYSIBMADM.TBSP_UTILIZATION;
```

## Automation Scripts

### 1. Complete Setup Script
```powershell
# setup-db2-environment.ps1
function Setup-DB2Environment {
    Write-Host "Setting up DB2 environment..." -ForegroundColor Blue
    
    # Start containers
    docker-compose -f docker-compose/docker-compose.infrastructure.yml up -d db2
    
    # Wait for container to be ready
    Write-Host "Waiting for DB2 to initialize (this may take 5-10 minutes)..." -ForegroundColor Yellow
    do {
        Start-Sleep 30
        $health = docker inspect bfb-tevelfilesdownload-db2 --format='{{.State.Health.Status}}'
        Write-Host "Current health status: $health" -ForegroundColor Cyan
    } while ($health -ne "healthy")
    
    # Create additional databases
    Write-Host "Creating project-specific database..." -ForegroundColor Green
    docker cp db2-project-setup-basic.sql bfb-{projectname}-db2:/tmp/
    docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 -tf /tmp/db2-project-setup-basic.sql"
    
    # Verify setup
    Test-DB2Connection -DatabaseName "BFBTEMPL"
    Test-DB2Connection -DatabaseName "{PROJDB}"
    
    Write-Host "DB2 environment setup complete!" -ForegroundColor Green
}

Setup-DB2Environment
```

### 2. Database Reset Script
```powershell
# reset-db2-databases.ps1
function Reset-DB2Databases {
    Write-Host "Resetting DB2 databases..." -ForegroundColor Yellow
    
    # Stop and remove containers
    docker-compose -f docker-compose/docker-compose.db2.yml down -v
    
    # Remove volumes
    docker volume rm {projectname}_db2_data -f
    
    # Restart clean environment
    docker-compose -f docker-compose/docker-compose.db2.yml up -d
    
    Write-Host "DB2 databases reset complete!" -ForegroundColor Green
}
```

## Quick Reference - Working Configuration

### Verified Working Setup (Multi-Platform/.NET 8)

#### 1. Project File ({ProjectName}TestApp.csproj) - MANDATORY OS-Conditional Pattern
```xml
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net8.0</TargetFramework>
    <Nullable>enable</Nullable>
    <ImplicitUsings>enable</ImplicitUsings>
  </PropertyGroup>

  <ItemGroup>
    <!-- OS-conditional DB2 packages - MANDATORY for all BFB template projects -->
    <PackageReference Include="Net.IBM.Data.Db2" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Windows'))" />
    <PackageReference Include="Net.IBM.Data.Db2-lnx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('Linux'))" />
    <PackageReference Include="Net.IBM.Data.Db2-osx" Version="8.0.0.200" Condition="$([MSBuild]::IsOSPlatform('OSX'))" />
    
    <PackageReference Include="Microsoft.Extensions.Configuration" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Configuration.Json" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging" Version="9.0.0" />
    <PackageReference Include="Microsoft.Extensions.Logging.Console" Version="9.0.0" />
  </ItemGroup>

  <ItemGroup>
    <None Update="appsettings.json">
      <CopyToOutputDirectory>PreserveNewest</CopyToOutputDirectory>
    </None>
  </ItemGroup>
</Project>
```

#### 2. Configuration (appsettings.json)
```json
{
  "DB2": {
    "ConnectionString": "Server=localhost:50000;Database={PROJDB};UserID=db2inst1;Password=password123;ConnectTimeout=30;",
    "CommandTimeout": 30,
    "MaxRetryAttempts": 3,
    "RetryDelayMilliseconds": 1000
  },
  "Logging": {
    "LogLevel": {
      "Default": "Information"
    }
  }
}
```

#### 3. Program Code Template
```csharp
using System.Globalization;
using IBM.Data.Db2;
using Microsoft.Extensions.Configuration;

// CRITICAL: Set culture for DB2 compatibility
CultureInfo.DefaultThreadCurrentCulture = CultureInfo.InvariantCulture;
CultureInfo.DefaultThreadCurrentUICulture = CultureInfo.InvariantCulture;

var configuration = new ConfigurationBuilder()
    .SetBasePath(Directory.GetCurrentDirectory())
    .AddJsonFile("appsettings.json", optional: false, reloadOnChange: true)
    .Build();

// Use the DB2 section for connection configuration
var db2Settings = new DB2Settings();
configuration.GetSection("DB2").Bind(db2Settings);
var connectionString = db2Settings.ConnectionString;

try
{
    using var connection = new DB2Connection(connectionString);
    await connection.OpenAsync();
    
    using var command = new DB2Command("SELECT TEST_ID, FILE_NAME, FILE_SIZE, CREATED_DATE FROM FILES.TEST_FILES", connection);
    using var reader = await command.ExecuteReaderAsync();
    
    while (await reader.ReadAsync())
    {
        var testId = reader.GetInt64("TEST_ID");
        var fileName = reader.GetString("FILE_NAME");
        var fileSize = reader.GetInt64("FILE_SIZE");
        
        if (!reader.IsDBNull("CREATED_DATE"))
        {
            var createdDate = reader.GetDateTime("CREATED_DATE");
            Console.WriteLine($"ID: {testId}, File: {fileName}, Size: {fileSize}, Created: {createdDate}");
        }
    }
}
catch (Exception ex)
{
    Console.WriteLine($"Error: {ex.Message}");
}

// Simple DB2Settings class for this example
public class DB2Settings
{
    public string ConnectionString { get; set; } = string.Empty;
    public int CommandTimeout { get; set; }
    public int MaxRetryAttempts { get; set; }
    public int RetryDelayMilliseconds { get; set; }
}
```

#### 4. Table Structure Reference
```sql
-- FILES.TEST_FILES table structure (sample for testing)
CREATE TABLE FILES.TEST_FILES (
    TEST_ID BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    FILE_NAME VARCHAR(255) NOT NULL,
    FILE_SIZE BIGINT NOT NULL,
    CREATED_DATE TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (TEST_ID)
);

-- Project-specific table example
CREATE TABLE {PROJSCHEMA}.{PROJECT_ENTITIES} (
    ID BIGINT NOT NULL GENERATED ALWAYS AS IDENTITY (START WITH 1, INCREMENT BY 1),
    NAME VARCHAR(255) NOT NULL,
    DESCRIPTION VARCHAR(1000),
    CREATED_DATE TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (ID)
);
```

#### 5. Docker Commands Reference
```powershell
# Start DB2 container
docker-compose -f docker-compose/docker-compose.infrastructure.yml up -d db2

# Check DB2 health
docker exec bfb-{projectname}-db2 su - db2inst1 -c "db2 connect to BFBTEMPL"

# Create test database and schema
docker exec -it bfb-{projectname}-db2 su - db2inst1
db2 create database {PROJDB}
db2 connect to {PROJDB}
db2 "CREATE SCHEMA {PROJSCHEMA}"
db2 "CREATE SCHEMA FILES"
```

This configuration has been tested and verified to work on Windows with .NET 8 and Docker Desktop.

## Additional Resources

### 1. DB2 Documentation
- [IBM DB2 Knowledge Center](https://www.ibm.com/docs/en/db2/11.5)
- [DB2 Docker Image Documentation](https://hub.docker.com/r/ibmcom/db2)

### 2. SQL Reference
- [DB2 SQL Reference](https://www.ibm.com/docs/en/db2/11.5?topic=reference-sql)
- [DB2 Command Reference](https://www.ibm.com/docs/en/db2/11.5?topic=reference-command)

### 3. Connection Drivers
- **ADO.NET**: Net.IBM.Data.Db2 family (recommended for .NET applications)
- **JDBC**: DB2 JDBC Driver (for Java applications)
- **ODBC**: IBM DB2 ODBC Driver (for native applications)

---

**Note**: This document covers the standard DB2 initialization process for BFB AWSS3Light applications. For production deployments, additional security and performance considerations should be implemented.

## Template Placeholders Reference

When adapting this document for specific BFB projects, replace the following placeholders:

- `{Username}` - Replace with actual Windows username
- `{ProjectName}` - Replace with actual project name (e.g., TevelFilesDownload)
- `{projectname}` - Replace with lowercase project name (e.g., tevelfilesdownload)
- `{PROJDB}` - Replace with project database name (max 8 chars, e.g., TEVELFLS)
- `{PROJSCHEMA}` - Replace with project schema name (e.g., TEVELFILES)
- `{PROJECT_ENTITIES}` - Replace with project-specific entity names

**Example Mapping for TevelFilesDownload:**
- `{ProjectName}` → TevelFilesDownload
- `{projectname}` → tevelfilesdownload
- `{PROJDB}` → TEVELFLS
- `{PROJSCHEMA}` → TEVELFILES
