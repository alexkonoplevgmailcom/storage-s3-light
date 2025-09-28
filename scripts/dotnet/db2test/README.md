# DB2 Test Console Application

This console application tests DB2 connectivity using the BFB.AWSS3Light.DataAccess.DB2 project.

## Purpose

- Test DB2 database connectivity
- Validate DB2 health checks
- Test DB2 repository operations
- Verify dependency injection configuration

## Prerequisites

1. **Docker DB2 Container Running**:
   ```powershell
   # Start DB2 container
   docker-compose -f ../../../docker-compose/docker-compose.db2.yml up -d
   
   # Verify container is healthy
   docker ps --filter "name=bfb-awss3light-db2"
   ```

2. **DB2 Database Setup**:
   - Default database: `BFBTEMPL`
   - User: `db2inst1`
   - Password: `password123`
   - Port: `50000`

## Building the Application

```powershell
# Navigate to the test project directory
cd C:\Users\FIBI\Repos\dotnet\bfb-awss3light-ng\scripts\dotnet\db2test

# Restore NuGet packages
dotnet restore

# Build the application
dotnet build

# Run the application (optional)
dotnet run
```

## Configuration

The application uses `appsettings.json` with the following DB2 configuration:

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

## What It Tests

1. **DB2 Health Check**: Tests basic DB2 connectivity using the health check component
2. **Repository Resolution**: Verifies that DB2 repository can be resolved from DI container
3. **Repository Operations**: Tests actual database operations through the repository pattern

## Expected Output

```
=== BFB AWSS3Light DB2 Connectivity Test ===

🔍 Testing DB2 Health Check...
✅ DB2 Health Check: PASSED

🔍 Testing DB2 Repository Operations...
✅ DB2 Bank Repository: Successfully resolved from DI
✅ DB2 Repository Connection: SUCCESSFUL

=== DB2 Connectivity Test Completed Successfully ===
```

## Features

- **OS-Conditional NuGet Packages**: Uses the mandatory OS-conditional DB2 package pattern
- **Proper Culture Settings**: Sets invariant culture for DB2 compatibility
- **Dependency Injection**: Uses the same DI pattern as the main BFB AWSS3Light project
- **Comprehensive Logging**: Includes detailed logging for troubleshooting
- **Error Handling**: Proper exception handling with detailed error messages

## Project References

- `BFB.AWSS3Light.DataAccess.DB2`: Main DB2 data access project
- `BFB.AWSS3Light.Abstractions`: Contains interfaces and entities

## NuGet Packages

- **DB2 Drivers**: OS-conditional Net.IBM.Data.Db2 packages
- **Configuration**: Microsoft.Extensions.Configuration (.NET 8)
- **Logging**: Microsoft.Extensions.Logging (.NET 8)
- **Dependency Injection**: Microsoft.Extensions.DependencyInjection (.NET 8)
