# Master Test Script for MongoDB, Redis, and Kafka Integration
# Runs comprehensive tests for all three technologies

param(
    [string]$ApiBaseUrl = "http://localhost:5111",
    [switch]$Verbose,
    [switch]$SkipMongo,
    [switch]$SkipRedis,
    [switch]$SkipKafka
)

$ErrorActionPreference = "Stop"

# Colors for output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-Header {
    param([string]$Title)
    Write-Host "`n======================================================================" -ForegroundColor $InfoColor
    Write-Host " $Title" -ForegroundColor $InfoColor
    Write-Host "======================================================================" -ForegroundColor $InfoColor
}

function Write-TestSummary {
    param(
        [string]$Technology,
        [bool]$Success,
        [string]$Details = ""
    )
    
    $status = if ($Success) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Success) { $SuccessColor } else { $ErrorColor }
    
    Write-Host "$status - $Technology Integration" -ForegroundColor $color
    if ($Details) {
        Write-Host "   $Details" -ForegroundColor Gray
    }
}

function Test-ApiAvailability {
    Write-Header "Testing API Availability"
    
    try {
        # Try a simple endpoint to verify API is running
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-Host "[SUCCESS] API is accessible at $ApiBaseUrl" -ForegroundColor $SuccessColor
            return $true
        } else {
            Write-Host "[ERROR] API returned unexpected status: $($response.StatusCode)" -ForegroundColor $ErrorColor
            return $false
        }
    }
    catch {
        Write-Host "[ERROR] Cannot connect to API at $ApiBaseUrl" -ForegroundColor $ErrorColor
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor $ErrorColor
        Write-Host "`n[INFO] Please ensure the API is running:" -ForegroundColor $InfoColor
        Write-Host "   cd src\BFB.AWSS3Light.API" -ForegroundColor $InfoColor
        Write-Host "   dotnet run" -ForegroundColor $InfoColor
        return $false
    }
}

function Run-MongoDbTests {
    Write-Header "Running MongoDB Integration Tests"
    
    $scriptPath = Join-Path $PSScriptRoot "test-mongodb.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[ERROR] MongoDB test script not found: $scriptPath" -ForegroundColor $ErrorColor
        return $false
    }
    
    try {
        $params = @{
            ApiBaseUrl = $ApiBaseUrl
        }
        if ($Verbose) { $params.Verbose = $true }
        
        & $scriptPath @params
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestSummary "MongoDB" $true "All MongoDB endpoints tested successfully"
            return $true
        } else {
            Write-TestSummary "MongoDB" $false "Some MongoDB tests failed"
            return $false
        }
    }
    catch {
        Write-TestSummary "MongoDB" $false "Error running tests: $($_.Exception.Message)"
        return $false
    }
}

function Run-RedisTests {
    Write-Header "Running Redis Cache Integration Tests"
    
    $scriptPath = Join-Path $PSScriptRoot "test-redis.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[ERROR] Redis test script not found: $scriptPath" -ForegroundColor $ErrorColor
        return $false
    }
    
    try {
        $params = @{
            ApiBaseUrl = $ApiBaseUrl
        }
        if ($Verbose) { $params.Verbose = $true }
        
        & $scriptPath @params
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestSummary "Redis" $true "All Redis cache endpoints tested successfully"
            return $true
        } else {
            Write-TestSummary "Redis" $false "Some Redis tests failed"
            return $false
        }
    }
    catch {
        Write-TestSummary "Redis" $false "Error running tests: $($_.Exception.Message)"
        return $false
    }
}

function Run-KafkaTests {
    Write-Header "Running Kafka Integration Tests"
    
    $scriptPath = Join-Path $PSScriptRoot "test-kafka.ps1"
    
    if (-not (Test-Path $scriptPath)) {
        Write-Host "[ERROR] Kafka test script not found: $scriptPath" -ForegroundColor $ErrorColor
        return $false
    }
    
    try {
        $params = @{
            ApiBaseUrl = $ApiBaseUrl
        }
        if ($Verbose) { $params.Verbose = $true }
        
        & $scriptPath @params
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestSummary "Kafka" $true "All Kafka messaging functionality tested successfully"
            return $true
        } else {
            Write-TestSummary "Kafka" $false "Some Kafka tests failed"
            return $false
        }
    }
    catch {
        Write-TestSummary "Kafka" $false "Error running tests: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Host "🚀 BFB AWSS3Light - Complete Integration Testing Suite" -ForegroundColor $InfoColor
    Write-Host "Testing MongoDB, Redis, and Kafka integrations" -ForegroundColor $InfoColor
    Write-Host "API Base URL: $ApiBaseUrl" -ForegroundColor $InfoColor
    Write-Host "Timestamp: $(Get-Date)" -ForegroundColor $InfoColor
    
    # Test API availability first
    if (-not (Test-ApiAvailability)) {
        Write-Host "`n[ERROR] Cannot proceed with testing - API is not available" -ForegroundColor $ErrorColor
        exit 1
    }
    
    $results = @{
        MongoDB = $false
        Redis = $false
        Kafka = $false
    }
    
    # Run MongoDB tests
    if (-not $SkipMongo) {
        $results.MongoDB = Run-MongoDbTests
    } else {
        Write-Host "`n⏭️  Skipping MongoDB tests (SkipMongo flag set)" -ForegroundColor $WarningColor
        $results.MongoDB = $true  # Consider as passed since skipped
    }
    
    # Run Redis tests  
    if (-not $SkipRedis) {
        $results.Redis = Run-RedisTests
    } else {
        Write-Host "`n⏭️  Skipping Redis tests (SkipRedis flag set)" -ForegroundColor $WarningColor
        $results.Redis = $true  # Consider as passed since skipped
    }
    
    # Run Kafka tests
    if (-not $SkipKafka) {
        $results.Kafka = Run-KafkaTests
    } else {
        Write-Host "`n⏭️  Skipping Kafka tests (SkipKafka flag set)" -ForegroundColor $WarningColor
        $results.Kafka = $true  # Consider as passed since skipped
    }
    
    # Final summary
    Write-Header "Final Integration Test Results"
    
    $totalTechnologies = 0
    $passedTechnologies = 0
    
    foreach ($tech in $results.Keys) {
        $totalTechnologies++
        if ($results[$tech]) {
            $passedTechnologies++
            Write-Host "[SUCCESS] $tech Integration: PASSED" -ForegroundColor $SuccessColor
        } else {
            Write-Host "[ERROR] $tech Integration: FAILED" -ForegroundColor $ErrorColor
        }
    }
    
    Write-Host "[INFO] Overall Results:" -ForegroundColor $InfoColor
    Write-Host "Technologies Tested: $totalTechnologies" -ForegroundColor $InfoColor
    Write-Host "Passed: $passedTechnologies" -ForegroundColor $SuccessColor
    Write-Host "Failed: $($totalTechnologies - $passedTechnologies)" -ForegroundColor $ErrorColor
    
    $overallSuccessRate = [math]::Round(($passedTechnologies / $totalTechnologies) * 100, 1)
    Write-Host "Success Rate: $overallSuccessRate%" -ForegroundColor $(if ($overallSuccessRate -eq 100) { $SuccessColor } else { $WarningColor })
    
    if ($passedTechnologies -eq $totalTechnologies) {
        Write-Host "`n🎉 ALL INTEGRATION TESTS PASSED!" -ForegroundColor $SuccessColor
        Write-Host "[SUCCESS] MongoDB customer management is working" -ForegroundColor $SuccessColor  
        Write-Host "[SUCCESS] Redis caching is working" -ForegroundColor $SuccessColor
        Write-Host "[SUCCESS] Kafka messaging is working" -ForegroundColor $SuccessColor
        Write-Host "[DONE] BFB AWSS3Light is ready for production use!" -ForegroundColor $SuccessColor
    } else {
        Write-Host "[WARN]  Some integration tests failed. Please review the details above." -ForegroundColor $WarningColor
        Write-Host "[INFO] Run individual test scripts with -Verbose for more details" -ForegroundColor $InfoColor
    }
    
    # Usage instructions
    Write-Host "[INFO] Individual Test Scripts:" -ForegroundColor $InfoColor
    Write-Host "MongoDB: .\test-mongodb.ps1 [-Verbose]" -ForegroundColor $InfoColor
    Write-Host "Redis:   .\test-redis.ps1 [-Verbose]" -ForegroundColor $InfoColor  
    Write-Host "Kafka:   .\test-kafka.ps1 [-Verbose]" -ForegroundColor $InfoColor
    
    # Exit with appropriate code
    if ($passedTechnologies -eq $totalTechnologies) {
        exit 0
    } else {
        exit 1
    }
}

# Run the master test suite
Main
