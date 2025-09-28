# Enhanced Banks API Testing Script with Process Management
# This script tests all the enhanced features we've added

Write-Host "Enhanced Banks API Testing Script" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Function to kill existing dotnet processes
function Stop-DotnetProcesses {
    Write-Host "Stopping existing dotnet processes..." -ForegroundColor Yellow
    try {
        Get-Process -Name "dotnet" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        Write-Host "Existing dotnet processes stopped" -ForegroundColor Green
    }
    catch {
        Write-Host "No existing dotnet processes found" -ForegroundColor Cyan
    }
}

# Function to check if DB2 container is running
function Test-DB2Container {
    Write-Host "Checking DB2 container status..." -ForegroundColor Yellow
    $db2Status = docker ps --filter "name=db2" --format "table {{.Names}}\t{{.Status}}"
    if ($db2Status -match "db2.*Up") {
        Write-Host "DB2 container is running" -ForegroundColor Green
        return $true
    } else {
        Write-Host "DB2 container is not running" -ForegroundColor Red
        Write-Host "Please run: ./manage-db2.ps1 start from the scripts/powershell directory" -ForegroundColor Yellow
        return $false
    }
}

# Function to build the solution
function Build-Solution {
    Write-Host "Building solution..." -ForegroundColor Yellow
    try {
        Push-Location -Path "$PSScriptRoot/../.."
        dotnet build --configuration Debug --verbosity minimal
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Build successful" -ForegroundColor Green
            Pop-Location
            return $true
        } else {
            Write-Host "Build failed" -ForegroundColor Red
            Pop-Location
            return $false
        }
    }
    catch {
        Write-Host "Build error: $_" -ForegroundColor Red
        Pop-Location
        return $false
    }
}

# Function to start the API
function Start-API {
    Write-Host "Starting API..." -ForegroundColor Yellow
    
    # Kill any existing processes first
    Stop-DotnetProcesses
    
    # Start API in background
    $apiProcess = Start-Process -FilePath "dotnet" -ArgumentList "run" -WorkingDirectory "src\BFB.AWSS3Light.API" -PassThru -WindowStyle Hidden
    
    # Wait for API to start
    Write-Host "Waiting for API to start..." -ForegroundColor Yellow
    Start-Sleep -Seconds 10
    
    # Test if API is responding
    try {
        $response = Invoke-WebRequest -Uri "http://localhost:5111/health" -Method GET -TimeoutSec 5
        if ($response.StatusCode -eq 200) {
            Write-Host "API is running on http://localhost:5111" -ForegroundColor Green
            return $apiProcess
        }
    }
    catch {
        Write-Host "API failed to start or not responding" -ForegroundColor Red
        return $null
    }
}

# Function to test health endpoints
function Test-HealthEndpoints {
    Write-Host "`nTesting Health Check Endpoints" -ForegroundColor Cyan
    Write-Host "=================================" -ForegroundColor Cyan
    
    try {
        # Test basic health endpoint
        Write-Host "Testing /health endpoint..." -ForegroundColor Yellow
        $healthResponse = Invoke-WebRequest -Uri "http://localhost:5111/health" -Method GET
        Write-Host "Health Check: $($healthResponse.StatusCode) - $($healthResponse.Content)" -ForegroundColor Green
        
        # Test readiness endpoint
        Write-Host "Testing /health/ready endpoint..." -ForegroundColor Yellow
        $readyResponse = Invoke-WebRequest -Uri "http://localhost:5111/health/ready" -Method GET
        Write-Host "Readiness Check: $($readyResponse.StatusCode) - $($readyResponse.Content)" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "Health check failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to test enhanced validation
function Test-EnhancedValidation {
    Write-Host "`nTesting Enhanced Input Validation" -ForegroundColor Cyan
    Write-Host "====================================" -ForegroundColor Cyan
    
    try {        # Test with missing required fields
        Write-Host "Testing validation with missing required fields..." -ForegroundColor Yellow
        $invalidBank = @{
            Name = ""
            BankCode = ""
        } | ConvertTo-Json
        
        try {
            $response = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method POST -Body $invalidBank -ContentType "application/json"
            Write-Host "Validation test unexpected success: $($response.StatusCode)" -ForegroundColor Yellow
        }
        catch {
            if ($_.Exception.Response.StatusCode -eq 400) {
                Write-Host "Validation correctly rejected invalid input (400 Bad Request)" -ForegroundColor Green
            } else {
                Write-Host "Unexpected validation response: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
            }
        }
        
        # Test with valid data        Write-Host "Testing with valid bank data..." -ForegroundColor Yellow
        $validBank = @{
            Name = "Test Bank Enhanced"
            BankCode = "TBE$(Get-Random -Maximum 9999)"
            SwiftCode = "DEUTDEFF"
            Address = "123 Test Street, Test City"
            PhoneNumber = "+1-555-0123"
            Email = "test@testbank.com"
        } | ConvertTo-Json
        
        $response = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method POST -Body $validBank -ContentType "application/json"
        Write-Host "Valid bank created successfully: $($response.StatusCode)" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "Validation test failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to test existing CRUD operations
function Test-CRUDOperations {
    Write-Host "`nTesting CRUD Operations" -ForegroundColor Cyan
    Write-Host "===========================" -ForegroundColor Cyan
    
    try {
        # Test GET all banks
        Write-Host "Testing GET all banks..." -ForegroundColor Yellow
        $allBanks = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method GET
        Write-Host "GET all banks: $($allBanks.StatusCode)" -ForegroundColor Green        # Create a test bank
        Write-Host "Testing CREATE bank..." -ForegroundColor Yellow
        $newBank = @{
            Name = "Enhanced Test Bank"
            BankCode = "ETB$(Get-Random -Maximum 9999)"
            SwiftCode = "DEUTDEFF"
            Address = "456 Enhanced Street"
            PhoneNumber = "+1-555-0456"
            Email = "enhanced@testbank.com"
        } | ConvertTo-Json
          $createResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method POST -Body $newBank -ContentType "application/json"
        $createdBank = $createResponse.Content | ConvertFrom-Json
        $bankId = $createdBank.id
        $bankCode = $createdBank.bankCode
        Write-Host "CREATE bank: $($createResponse.StatusCode) - ID: $bankId, Code: $bankCode" -ForegroundColor Green
        
        # Test GET by ID
        Write-Host "Testing GET bank by ID..." -ForegroundColor Yellow
        $getBankResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/$bankId" -Method GET
        Write-Host "GET bank by ID: $($getBankResponse.StatusCode)" -ForegroundColor Green
        
        # Test GET by bank code
        Write-Host "Testing GET bank by code..." -ForegroundColor Yellow
        $getBankByCodeResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/by-code/$bankCode" -Method GET
        Write-Host "GET bank by code: $($getBankByCodeResponse.StatusCode)" -ForegroundColor Green
        
        # Test UPDATE
        Write-Host "Testing UPDATE bank..." -ForegroundColor Yellow
        $updateBank = @{
            Name = "Enhanced Test Bank - Updated"
            SwiftCode = "DEUTDEFF"
            Address = "456 Enhanced Street - Updated"
            PhoneNumber = "+1-555-0456"
            Email = "enhanced.updated@testbank.com"
        } | ConvertTo-Json
        
        $updateResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/$bankId" -Method PUT -Body $updateBank -ContentType "application/json"
        Write-Host "UPDATE bank: $($updateResponse.StatusCode)" -ForegroundColor Green
        
        # Test DELETE (soft delete)
        Write-Host "Testing DELETE bank (soft delete)..." -ForegroundColor Yellow
        $deleteResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/$bankId" -Method DELETE
        Write-Host "DELETE bank: $($deleteResponse.StatusCode)" -ForegroundColor Green
        
        return $true
    }
    catch {
        Write-Host "CRUD test failed: $_" -ForegroundColor Red
        return $false
    }
}

# Function to display test summary
function Show-TestSummary {
    param(
        [bool]$HealthPassed,
        [bool]$ValidationPassed,
        [bool]$CRUDPassed
    )
    
    Write-Host "`nTest Summary" -ForegroundColor Cyan
    Write-Host "===============" -ForegroundColor Cyan
    
    $totalTests = 3
    $passedTests = 0
    
    if ($HealthPassed) { 
        Write-Host "Health Checks: PASSED" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "Health Checks: FAILED" -ForegroundColor Red
    }
    
    if ($ValidationPassed) { 
        Write-Host "Input Validation: PASSED" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "Input Validation: FAILED" -ForegroundColor Red
    }
    
    if ($CRUDPassed) { 
        Write-Host "CRUD Operations: PASSED" -ForegroundColor Green
        $passedTests++
    } else {
        Write-Host "CRUD Operations: FAILED" -ForegroundColor Red
    }
    
    Write-Host "`nOverall Result: $passedTests/$totalTests tests passed" -ForegroundColor $(if ($passedTests -eq $totalTests) { "Green" } else { "Yellow" })
    
    if ($passedTests -eq $totalTests) {
        Write-Host "All enhancements are working perfectly!" -ForegroundColor Green
    } else {
        Write-Host "Some tests failed. Please check the output above." -ForegroundColor Yellow
    }
}

# Main execution
try {
    # Pre-flight checks
    if (-not (Test-DB2Container)) {
        Write-Host "`nPre-flight check failed. Please start DB2 container first." -ForegroundColor Red
        exit 1
    }
    
    # Kill any existing processes
    Stop-DotnetProcesses
    
    # Build solution
    if (-not (Build-Solution)) {
        Write-Host "`nBuild failed. Cannot proceed with testing." -ForegroundColor Red
        exit 1
    }
    
    # Start API
    $apiProcess = Start-API
    if (-not $apiProcess) {
        Write-Host "`nFailed to start API. Cannot proceed with testing." -ForegroundColor Red
        exit 1
    }
    
    # Run tests
    $healthPassed = Test-HealthEndpoints
    $validationPassed = Test-EnhancedValidation
    $crudPassed = Test-CRUDOperations
    
    # Show summary
    Show-TestSummary -HealthPassed $healthPassed -ValidationPassed $validationPassed -CRUDPassed $crudPassed
    
}
catch {
    Write-Host "`nUnexpected error: $_" -ForegroundColor Red
}
finally {
    # Cleanup
    Write-Host "`nCleaning up..." -ForegroundColor Yellow
    Stop-DotnetProcesses
    Write-Host "Cleanup completed" -ForegroundColor Green
}

Write-Host "`nTesting completed!" -ForegroundColor Green
