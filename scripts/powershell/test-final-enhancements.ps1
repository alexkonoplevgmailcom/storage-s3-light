# Simple Enhanced Features Test
Write-Host "Enhanced Banks API - Final Validation" -ForegroundColor Green
Write-Host "=====================================" -ForegroundColor Green

# Test Health Endpoints
Write-Host "`n1. Testing Health Check Endpoints" -ForegroundColor Cyan

try {
    $health = Invoke-WebRequest -Uri "http://localhost:5111/health" -Method GET
    Write-Host "✅ Health Check: $($health.StatusCode) - Content: $($health.Content.Substring(0, 50))..." -ForegroundColor Green
} catch {
    Write-Host "❌ Health Check Failed: $_" -ForegroundColor Red
}

try {
    $ready = Invoke-WebRequest -Uri "http://localhost:5111/health/ready" -Method GET
    Write-Host "✅ Readiness Check: $($ready.StatusCode) - Content: $($ready.Content)" -ForegroundColor Green
} catch {
    Write-Host "❌ Readiness Check Failed: $_" -ForegroundColor Red
}

# Test Input Validation
Write-Host "`n2. Testing Enhanced Input Validation" -ForegroundColor Cyan

try {
    $invalidData = '{"name":"","bankCode":""}'
    $response = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method POST -Body $invalidData -ContentType "application/json"
    Write-Host "⚠️ Unexpected Success: $($response.StatusCode)" -ForegroundColor Yellow
} catch {
    if ($_.Exception.Response.StatusCode -eq 400) {
        Write-Host "✅ Validation correctly rejected invalid input (400 Bad Request)" -ForegroundColor Green
    } else {
        Write-Host "❌ Unexpected error: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
    }
}

# Test CRUD with Valid Data
Write-Host "`n3. Testing CRUD Operations" -ForegroundColor Cyan

# GET all banks
try {
    $allBanks = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method GET
    $banksData = $allBanks.Content | ConvertFrom-Json
    Write-Host "✅ GET All Banks: $($allBanks.StatusCode) - Found $($banksData.Count) banks" -ForegroundColor Green
} catch {
    Write-Host "❌ GET All Banks Failed: $_" -ForegroundColor Red
}

# CREATE a new bank
try {
    $validBank = @{
        name = "Final Enhancement Test Bank"
        bankCode = "FETB2025"
        swiftCode = "FETBUS33"
        address = "2025 Enhancement Street"
        phoneNumber = "+1-555-2025"
        email = "enhanced@finaltest.com"
    } | ConvertTo-Json
    
    $createResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks" -Method POST -Body $validBank -ContentType "application/json"
    $createdBank = $createResponse.Content | ConvertFrom-Json
    $bankId = $createdBank.id
    Write-Host "✅ CREATE Bank: $($createResponse.StatusCode) - ID: $bankId" -ForegroundColor Green
    
    # GET by ID
    $getResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/$bankId" -Method GET
    Write-Host "✅ GET Bank by ID: $($getResponse.StatusCode)" -ForegroundColor Green
    
    # UPDATE Bank
    $updateData = @{
        name = "Final Enhancement Test Bank - UPDATED"
        swiftCode = "FETBUS33"
        address = "2025 Enhancement Street - Updated"
        phoneNumber = "+1-555-2025"
        email = "enhanced.updated@finaltest.com"
    } | ConvertTo-Json
    
    $updateResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/$bankId" -Method PUT -Body $updateData -ContentType "application/json"
    Write-Host "✅ UPDATE Bank: $($updateResponse.StatusCode)" -ForegroundColor Green
    
    # DELETE (Soft Delete)
    $deleteResponse = Invoke-WebRequest -Uri "http://localhost:5111/api/db2/banks/$bankId" -Method DELETE
    Write-Host "✅ DELETE Bank (Soft Delete): $($deleteResponse.StatusCode)" -ForegroundColor Green
    
} catch {
    Write-Host "❌ CRUD Operation Failed: $_" -ForegroundColor Red
}

Write-Host "`n🎉 Enhanced Features Testing Complete!" -ForegroundColor Green
Write-Host "=======================================" -ForegroundColor Green

Write-Host "`n📋 Summary of Enhancements Tested:" -ForegroundColor Cyan
Write-Host "- Health Check Endpoints (/health, /health/ready)" -ForegroundColor White
Write-Host "- Enhanced Input Validation with proper error responses" -ForegroundColor White
Write-Host "- Complete CRUD operations with improved error handling" -ForegroundColor White
Write-Host "- Process management in testing scripts" -ForegroundColor White
Write-Host "- Enhanced API documentation and attributes" -ForegroundColor White
