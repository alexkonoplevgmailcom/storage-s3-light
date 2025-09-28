param(
    [Parameter(Mandatory = $false)]
    [switch]$StartOracle
)

$ErrorActionPreference = "Stop"
$apiUrl = "http://localhost:5111"
$TestColor = "Magenta"
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$HeaderColor = "Yellow"
$WarningColor = "DarkYellow"

# Track test results
$testsPassed = 0
$testsFailed = 0

function Stop-DotnetProcesses {
    Write-Host "Stopping any running dotnet processes..." -ForegroundColor $InfoColor
    Stop-Process -Name "dotnet" -Force -ErrorAction SilentlyContinue
}

function Test-Prerequisites {
    Write-Host "Checking Oracle container status..." -ForegroundColor $InfoColor
    
    $containerStatus = docker ps --filter "name=oracle-db" --format "{{.Status}}"
    
    if (-not $containerStatus) {
        if ($StartOracle) {
            Write-Host "Oracle container not running. Starting it now..." -ForegroundColor $WarningColor
            & "$PSScriptRoot/manage-oracle.ps1" start
            Start-Sleep -Seconds 5
            return $true
        }
        else {
            Write-Host "Oracle container is not running! Use -StartOracle flag or run ./manage-oracle.ps1 start from the scripts/powershell directory" -ForegroundColor $ErrorColor
            return $false
        }
    }
    
    Write-Host "Oracle database is running." -ForegroundColor $SuccessColor
    return $true
}

function Build-Solution {
    Write-Host "`n========== Building Solution ==========" -ForegroundColor $HeaderColor
    
    Push-Location -Path "$PSScriptRoot/../.."
    dotnet build | Out-Host
    
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Build failed! Please fix the errors and try again." -ForegroundColor $ErrorColor
        Pop-Location
        return $false
    }
    
    Write-Host "Build completed successfully." -ForegroundColor $SuccessColor
    Pop-Location
    return $true
}

function Start-ApiApplication {
    Write-Host "`n========== Starting API Application ==========" -ForegroundColor $HeaderColor
    
    # Use a PowerShell job to run the API in background
    $job = Start-Job -ScriptBlock {
        param($workingDir)
        Set-Location $workingDir
        dotnet run
    } -ArgumentList "$PSScriptRoot/../../src/BFB.AWSS3Light.API"
    
    # Wait for the API to start
    Write-Host "Waiting for API to start..." -ForegroundColor $InfoColor
    Start-Sleep -Seconds 10
    
    # Check if API is running
    $isRunning = $false
    $retryCount = 0
    $maxRetries = 5
      while (-not $isRunning -and $retryCount -lt $maxRetries) {
        try {
            $healthCheck = Invoke-WebRequest -Uri "$apiUrl/health/ready" -Method GET -UseBasicParsing
            if ($healthCheck.StatusCode -eq 200) {
                $isRunning = $true
                Write-Host "API has started successfully." -ForegroundColor $SuccessColor
            }
        }
        catch {
            $retryCount++
            if ($retryCount -ge $maxRetries) {
                Write-Host "Failed to start the API after multiple attempts." -ForegroundColor $ErrorColor
                return $false
            }
            
            Write-Host "API not ready yet. Retrying in 5 seconds... (Attempt $retryCount of $maxRetries)" -ForegroundColor $WarningColor
            Start-Sleep -Seconds 5
        }
    }
    
    return $isRunning
}

function Test-BankTellerAPI {
    Write-Host "`n========== Testing Bank Teller API ==========" -ForegroundColor $HeaderColor
    
    # Test #1: Health Check
    Write-Host "`n--- Test #1: Health Check ---" -ForegroundColor $TestColor
    try {        $response = Invoke-WebRequest -Uri "$apiUrl/health/ready" -Method GET -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            Write-Host "✅ Health check passed!" -ForegroundColor $SuccessColor
            $script:testsPassed++
        }
        else {
            Write-Host "❌ Health check failed with status code: $($response.StatusCode)" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "❌ Health check failed: $_" -ForegroundColor $ErrorColor
        $script:testsFailed++
    }
    
    # Generate random bank ID for testing
    $bankId = Get-Random -Minimum 1000 -Maximum 9999
    $testTellerId = 0
    
    # Test #2: Create Bank Teller
    Write-Host "`n--- Test #2: Create Bank Teller ---" -ForegroundColor $TestColor
    $newTeller = @{
        BankId = $bankId
        FirstName = "John"
        LastName = "Doe"
        BadgeNumber = "T$(Get-Random -Minimum 1000 -Maximum 9999)"
        HireDate = (Get-Date).AddYears(-1).ToString("yyyy-MM-dd")
        IsActive = $true
        Position = "Cashier"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers" -Method POST -Body $newTeller -ContentType "application/json" -UseBasicParsing
        if ($response.StatusCode -eq 201) {
            $teller = $response.Content | ConvertFrom-Json
            $testTellerId = $teller.id
            Write-Host "✅ Bank teller created with ID: $testTellerId" -ForegroundColor $SuccessColor
            Write-Host "   First Name: $($teller.firstName)" -ForegroundColor $InfoColor
            Write-Host "   Last Name: $($teller.lastName)" -ForegroundColor $InfoColor
            Write-Host "   Badge Number: $($teller.badgeNumber)" -ForegroundColor $InfoColor
            $script:testsPassed++
        }
        else {
            Write-Host "❌ Failed to create bank teller. Status: $($response.StatusCode)" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "❌ Failed to create bank teller: $_" -ForegroundColor $ErrorColor
        $script:testsFailed++
    }
    
    # Test #3: Get Bank Teller by ID
    if ($testTellerId -gt 0) {
        Write-Host "`n--- Test #3: Get Bank Teller by ID ---" -ForegroundColor $TestColor
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers/$testTellerId" -Method GET -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $teller = $response.Content | ConvertFrom-Json
                Write-Host "✅ Retrieved bank teller by ID: $testTellerId" -ForegroundColor $SuccessColor
                Write-Host "   First Name: $($teller.firstName)" -ForegroundColor $InfoColor
                Write-Host "   Last Name: $($teller.lastName)" -ForegroundColor $InfoColor
                $script:testsPassed++
            }
            else {
                Write-Host "❌ Failed to retrieve bank teller. Status: $($response.StatusCode)" -ForegroundColor $ErrorColor
                $script:testsFailed++
            }
        }
        catch {
            Write-Host "❌ Failed to retrieve bank teller: $_" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    
    # Test #4: Get Bank Tellers by Bank ID
    Write-Host "`n--- Test #4: Get Bank Tellers by Bank ID ---" -ForegroundColor $TestColor
    try {
        $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers/bank/$bankId" -Method GET -UseBasicParsing
        if ($response.StatusCode -eq 200) {
            $tellers = $response.Content | ConvertFrom-Json
            Write-Host "✅ Retrieved bank tellers for Bank ID $bankId. Count: $($tellers.Count)" -ForegroundColor $SuccessColor
            $script:testsPassed++
        }
        else {
            Write-Host "❌ Failed to retrieve bank tellers by bank ID. Status: $($response.StatusCode)" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    catch {
        Write-Host "❌ Failed to retrieve bank tellers by bank ID: $_" -ForegroundColor $ErrorColor
        $script:testsFailed++
    }
    
    # Test #5: Update Bank Teller
    if ($testTellerId -gt 0) {
        Write-Host "`n--- Test #5: Update Bank Teller ---" -ForegroundColor $TestColor
        $updatedTeller = @{
            Id = $testTellerId
            BankId = $bankId
            FirstName = "Jane"
            LastName = "Smith"
            BadgeNumber = "T$(Get-Random -Minimum 1000 -Maximum 9999)"
            HireDate = (Get-Date).AddYears(-2).ToString("yyyy-MM-dd")
            IsActive = $true
            Position = "Head Cashier"
        } | ConvertTo-Json
        
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers/$testTellerId" -Method PUT -Body $updatedTeller -ContentType "application/json" -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $teller = $response.Content | ConvertFrom-Json
                Write-Host "✅ Updated bank teller with ID: $testTellerId" -ForegroundColor $SuccessColor
                Write-Host "   Updated First Name: $($teller.firstName)" -ForegroundColor $InfoColor
                Write-Host "   Updated Last Name: $($teller.lastName)" -ForegroundColor $InfoColor
                Write-Host "   Updated Position: $($teller.position)" -ForegroundColor $InfoColor
                $script:testsPassed++
            }
            else {
                Write-Host "❌ Failed to update bank teller. Status: $($response.StatusCode)" -ForegroundColor $ErrorColor
                $script:testsFailed++
            }
        }
        catch {
            Write-Host "❌ Failed to update bank teller: $_" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    
    # Test #6: Validation Test - Future Hire Date (Should Fail)
    Write-Host "`n--- Test #6: Validation Test - Future Hire Date (Should Fail) ---" -ForegroundColor $TestColor
    $invalidTeller = @{
        BankId = $bankId
        FirstName = "Invalid"
        LastName = "User"
        BadgeNumber = "T$(Get-Random -Minimum 1000 -Maximum 9999)"
        HireDate = (Get-Date).AddYears(1).ToString("yyyy-MM-dd")  # Future date
        IsActive = $true
        Position = "Teller"
    } | ConvertTo-Json
    
    try {
        $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers" -Method POST -Body $invalidTeller -ContentType "application/json" -UseBasicParsing -ErrorAction SilentlyContinue
        if ($response.StatusCode -eq 400) {
            Write-Host "✅ Validation correctly rejected future hire date" -ForegroundColor $SuccessColor
            $script:testsPassed++
        }
        else {
            Write-Host "❌ Validation should have rejected future hire date but didn't" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    catch {
        if ($_.Exception.Response.StatusCode -eq 400) {
            Write-Host "✅ Validation correctly rejected future hire date" -ForegroundColor $SuccessColor
            $script:testsPassed++
        }
        else {
            Write-Host "❌ Unexpected error during validation test: $_" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    
    # Test #7: Validation Test - Duplicate Badge Number (Should Fail)
    # First, get the badge number of an existing teller
    if ($testTellerId -gt 0) {
        Write-Host "`n--- Test #7: Validation Test - Duplicate Badge Number (Should Fail) ---" -ForegroundColor $TestColor
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers/$testTellerId" -Method GET -UseBasicParsing
            if ($response.StatusCode -eq 200) {
                $teller = $response.Content | ConvertFrom-Json
                $duplicateBadgeNumber = $teller.badgeNumber
                
                # Now try to create a new teller with the same badge number
                $duplicateTeller = @{
                    BankId = $bankId
                    FirstName = "Duplicate"
                    LastName = "User"
                    BadgeNumber = $duplicateBadgeNumber
                    HireDate = (Get-Date).AddYears(-1).ToString("yyyy-MM-dd")
                    IsActive = $true
                    Position = "Teller"
                } | ConvertTo-Json
                
                try {
                    $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers" -Method POST -Body $duplicateTeller -ContentType "application/json" -UseBasicParsing -ErrorAction SilentlyContinue
                    if ($response.StatusCode -eq 409) {
                        Write-Host "✅ Validation correctly rejected duplicate badge number" -ForegroundColor $SuccessColor
                        $script:testsPassed++
                    }
                    else {
                        Write-Host "❌ Validation should have rejected duplicate badge number but didn't" -ForegroundColor $ErrorColor
                        $script:testsFailed++
                    }
                }
                catch {
                    if ($_.Exception.Response.StatusCode -eq 409) {
                        Write-Host "✅ Validation correctly rejected duplicate badge number" -ForegroundColor $SuccessColor
                        $script:testsPassed++
                    }
                    else {
                        Write-Host "❌ Unexpected error during duplicate badge validation: $_" -ForegroundColor $ErrorColor
                        $script:testsFailed++
                    }
                }
            }
            else {
                Write-Host "❌ Failed to get teller for duplicate badge test. Status: $($response.StatusCode)" -ForegroundColor $ErrorColor
                $script:testsFailed++
            }
        }
        catch {
            Write-Host "❌ Failed to get teller for duplicate badge test: $_" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
    
    # Test #8: Delete Bank Teller
    if ($testTellerId -gt 0) {
        Write-Host "`n--- Test #8: Delete Bank Teller ---" -ForegroundColor $TestColor
        try {
            $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers/$testTellerId" -Method DELETE -UseBasicParsing
            if ($response.StatusCode -eq 204) {
                Write-Host "✅ Deleted bank teller with ID: $testTellerId" -ForegroundColor $SuccessColor
                $script:testsPassed++
                
                # Verify deletion by trying to get the deleted teller (should fail)
                try {
                    $response = Invoke-WebRequest -Uri "$apiUrl/api/oracle/banktellers/$testTellerId" -Method GET -UseBasicParsing -ErrorAction SilentlyContinue
                    if ($response.StatusCode -eq 404) {
                        Write-Host "✅ Verified deletion - teller no longer exists" -ForegroundColor $SuccessColor
                        $script:testsPassed++
                    }
                    else {
                        Write-Host "❌ Teller still exists after deletion" -ForegroundColor $ErrorColor
                        $script:testsFailed++
                    }
                }
                catch {
                    if ($_.Exception.Response.StatusCode -eq 404) {
                        Write-Host "✅ Verified deletion - teller no longer exists" -ForegroundColor $SuccessColor
                        $script:testsPassed++
                    }
                    else {
                        Write-Host "❌ Unexpected error when verifying deletion: $_" -ForegroundColor $ErrorColor
                        $script:testsFailed++
                    }
                }
            }
            else {
                Write-Host "❌ Failed to delete bank teller. Status: $($response.StatusCode)" -ForegroundColor $ErrorColor
                $script:testsFailed++
            }
        }
        catch {
            Write-Host "❌ Failed to delete bank teller: $_" -ForegroundColor $ErrorColor
            $script:testsFailed++
        }
    }
}

function Show-TestSummary {
    Write-Host "`n========== Test Summary ==========" -ForegroundColor $HeaderColor
    Write-Host "Tests Passed: $testsPassed" -ForegroundColor $SuccessColor
    Write-Host "Tests Failed: $testsFailed" -ForegroundColor $ErrorColor
    
    if ($testsFailed -eq 0) {
        Write-Host "`nAll tests passed successfully! ✨" -ForegroundColor $SuccessColor
    }
    else {
        Write-Host "`nSome tests failed. Please check the log above for details." -ForegroundColor $ErrorColor
    }
}

# Main execution flow
Write-Host "========== Oracle Bank Tellers API Test ==========" -ForegroundColor $HeaderColor

# Stop any existing dotnet processes
Stop-DotnetProcesses

# Check prerequisites
if (-not (Test-Prerequisites)) {
    exit 1
}

# Build solution
if (-not (Build-Solution)) {
    exit 1
}

# Start API application
if (-not (Start-ApiApplication)) {
    Write-Host "Failed to start API application. Exiting..." -ForegroundColor $ErrorColor
    exit 1
}

# Run tests
Test-BankTellerAPI

# Show test summary
Show-TestSummary

# Clean up
Stop-DotnetProcesses
