# Redis Cache API Endpoint Testing Script
# Tests all Redis caching endpoints

param(
    [string]$ApiBaseUrl = "http://localhost:5111",
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"

# Colors for output
$SuccessColor = "Green"
$ErrorColor = "Red"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-TestResult {
    param(
        [string]$TestName,
        [bool]$Success,
        [string]$Details = ""
    )
    
    $status = if ($Success) { "[PASS]" } else { "[FAIL]" }
    $color = if ($Success) { $SuccessColor } else { $ErrorColor }
    
    Write-Host "$status - $TestName" -ForegroundColor $color
    if ($Details -and ($Verbose -or -not $Success)) {
        Write-Host "   Details: $Details" -ForegroundColor Gray
    }
}

function Write-Header {
    param([string]$Title)
    Write-Host "`n===========================================" -ForegroundColor $InfoColor
    Write-Host " $Title" -ForegroundColor $InfoColor
    Write-Host "===========================================" -ForegroundColor $InfoColor
}

function Test-ApiConnection {
    Write-Header "Testing API Connection"
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-TestResult "API Connection" $true "Redis Cache API is accessible"
            return $true
        } else {
            Write-TestResult "API Connection" $false "Unexpected status code: $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-TestResult "API Connection" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-GetAllCacheItems {
    Write-Header "Testing GET All Cache Items"
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache" -Method GET
        $cacheItems = $response.Content | ConvertFrom-Json
        
        Write-TestResult "GET All Cache Items" $true "Retrieved $($cacheItems.Count) cache items"
        
        if ($Verbose -and $cacheItems.Count -gt 0) {
            Write-Host "Sample cache item:" -ForegroundColor Gray
            $cacheItems[0] | ConvertTo-Json | Write-Host -ForegroundColor Gray
        }
        
        return $cacheItems
    }
    catch {
        Write-TestResult "GET All Cache Items" $false "Error: $($_.Exception.Message)"
        return @()
    }
}

function Test-CreateCacheItem {
    Write-Header "Testing POST Create Cache Item"
    
    $timestamp = Get-Date -Format "HHmmss"
    $testCacheItem = @{
        Key = "test-key-$timestamp"
        Value = "Test cache value created at $(Get-Date)"
        TtlSeconds = 300
        Tags = "test,automated,session-$timestamp"
    }
    
    try {
        $body = $testCacheItem | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache" -Method POST -Body $body -ContentType "application/json"
        
        if ($response.StatusCode -eq 201) {
            $createdItem = $response.Content | ConvertFrom-Json
            Write-TestResult "POST Create Cache Item" $true "Cache item created with key: $($createdItem.Key)"
            
            if ($Verbose) {
                Write-Host "Created cache item details:" -ForegroundColor Gray
                $createdItem | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $createdItem
        } else {
            Write-TestResult "POST Create Cache Item" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "POST Create Cache Item" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-GetCacheItemByKey {
    param($CacheKey)
    
    Write-Header "Testing GET Cache Item by Key"
    
    if (-not $CacheKey) {
        Write-TestResult "GET Cache Item by Key" $false "No cache key provided"
        return $null
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/$CacheKey" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $cacheItem = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Cache Item by Key" $true "Retrieved cache item: $($cacheItem.Key)"
            
            if ($Verbose) {
                Write-Host "Cache item details:" -ForegroundColor Gray
                $cacheItem | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $cacheItem
        } else {
            Write-TestResult "GET Cache Item by Key" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "GET Cache Item by Key" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-GetCacheItemById {
    param($CacheId)
    
    Write-Header "Testing GET Cache Item by ID"
    
    if (-not $CacheId) {
        Write-TestResult "GET Cache Item by ID" $false "No cache ID provided"
        return $null
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/id/$CacheId" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $cacheItem = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Cache Item by ID" $true "Retrieved cache item by ID: $($cacheItem.Id)"
            
            if ($Verbose) {
                Write-Host "Cache item details:" -ForegroundColor Gray
                $cacheItem | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $cacheItem
        } else {
            Write-TestResult "GET Cache Item by ID" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "GET Cache Item by ID" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-GetCacheItemsByTag {
    param($Tag)
    
    Write-Header "Testing GET Cache Items by Tag"
    
    if (-not $Tag) {
        Write-TestResult "GET Cache Items by Tag" $false "No tag provided"
        return @()
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/tag/$Tag" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $cacheItems = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Cache Items by Tag" $true "Retrieved $($cacheItems.Count) items with tag '$Tag'"
            
            if ($Verbose -and $cacheItems.Count -gt 0) {
                Write-Host "Tagged cache items:" -ForegroundColor Gray
                $cacheItems | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $cacheItems
        } else {
            Write-TestResult "GET Cache Items by Tag" $false "Unexpected status code: $($response.StatusCode)"
            return @()
        }
    }
    catch {
        Write-TestResult "GET Cache Items by Tag" $false "Error: $($_.Exception.Message)"
        return @()
    }
}

function Test-CheckCacheItemExists {
    param($CacheKey)
    
    Write-Header "Testing GET Cache Item Exists"
    
    if (-not $CacheKey) {
        Write-TestResult "GET Cache Item Exists" $false "No cache key provided"
        return $false
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/$CacheKey/exists" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $exists = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Cache Item Exists" $true "Cache key exists: $exists"
            return $exists
        } else {
            Write-TestResult "GET Cache Item Exists" $false "Unexpected status code: $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-TestResult "GET Cache Item Exists" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-GetCacheStats {
    Write-Header "Testing GET Cache Statistics"
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/stats" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $stats = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Cache Statistics" $true "Retrieved cache statistics"
            
            if ($Verbose) {
                Write-Host "Cache statistics:" -ForegroundColor Gray
                $stats | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $stats
        } else {
            Write-TestResult "GET Cache Statistics" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "GET Cache Statistics" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-ExtendCacheTtl {
    param($CacheKey, $TtlSeconds = 600)
    
    Write-Header "Testing PUT Extend Cache TTL"
    
    if (-not $CacheKey) {
        Write-TestResult "PUT Extend Cache TTL" $false "No cache key provided"
        return $false
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/$CacheKey/extend-ttl/$TtlSeconds" -Method PUT
        
        if ($response.StatusCode -eq 200) {
            $result = $response.Content | ConvertFrom-Json
            Write-TestResult "PUT Extend Cache TTL" $true "TTL extended successfully: $result"
            return $result
        } else {
            Write-TestResult "PUT Extend Cache TTL" $false "Unexpected status code: $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-TestResult "PUT Extend Cache TTL" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-DeleteCacheItem {
    param($CacheKey)
    
    Write-Header "Testing DELETE Cache Item"
    
    if (-not $CacheKey) {
        Write-TestResult "DELETE Cache Item" $false "No cache key provided"
        return $false
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/$CacheKey" -Method DELETE
        
        if ($response.StatusCode -eq 204) {
            Write-TestResult "DELETE Cache Item" $true "Cache item deleted successfully"
            return $true
        } else {
            Write-TestResult "DELETE Cache Item" $false "Unexpected status code: $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-TestResult "DELETE Cache Item" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-ClearExpiredItems {
    Write-Header "Testing DELETE Clear Expired Items"
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/RedisCache/clear/expired" -Method DELETE
        
        if ($response.StatusCode -eq 200) {
            $clearedCount = $response.Content | ConvertFrom-Json
            Write-TestResult "DELETE Clear Expired Items" $true "Cleared $clearedCount expired items"
            return $clearedCount
        } else {
            Write-TestResult "DELETE Clear Expired Items" $false "Unexpected status code: $($response.StatusCode)"
            return 0
        }
    }
    catch {
        Write-TestResult "DELETE Clear Expired Items" $false "Error: $($_.Exception.Message)"
        return 0
    }
}

# Main execution
function Main {
    Write-Host "[INFO] Redis Cache API Endpoint Testing" -ForegroundColor $InfoColor
    Write-Host "Testing Redis caching endpoints" -ForegroundColor $InfoColor
    Write-Host "API Base URL: $ApiBaseUrl" -ForegroundColor $InfoColor
    
    $totalTests = 0
    $passedTests = 0
    
    # Test API connection
    if (-not (Test-ApiConnection)) {
        Write-Host "[ERROR] Cannot connect to Redis Cache API. Ensure the API is running at $ApiBaseUrl" -ForegroundColor $ErrorColor
        exit 1
    }
    $totalTests++; $passedTests++
    
    # Test GET all cache items
    $existingItems = Test-GetAllCacheItems
    $totalTests++
    if ($null -ne $existingItems) { $passedTests++ }
    
    # Test CREATE cache item
    $newCacheItem = Test-CreateCacheItem
    $totalTests++
    if ($newCacheItem) { $passedTests++ }
    
    # Test GET cache item by key
    if ($newCacheItem) {
        $retrievedByKey = Test-GetCacheItemByKey -CacheKey $newCacheItem.Key
        $totalTests++
        if ($retrievedByKey) { $passedTests++ }
        
        # Test GET cache item by ID
        $retrievedById = Test-GetCacheItemById -CacheId $newCacheItem.Id
        $totalTests++
        if ($retrievedById) { $passedTests++ }
        
        # Test GET cache items by tag
        $taggedItems = Test-GetCacheItemsByTag -Tag "test"
        $totalTests++
        if ($null -ne $taggedItems) { $passedTests++ }
        
        # Test CHECK cache item exists
        $exists = Test-CheckCacheItemExists -CacheKey $newCacheItem.Key
        $totalTests++
        if ($exists) { $passedTests++ }
        
        # Test EXTEND cache TTL
        $ttlExtended = Test-ExtendCacheTtl -CacheKey $newCacheItem.Key -TtlSeconds 600
        $totalTests++
        if ($ttlExtended) { $passedTests++ }
        
        # Test DELETE cache item
        $deleted = Test-DeleteCacheItem -CacheKey $newCacheItem.Key
        $totalTests++
        if ($deleted) { $passedTests++ }
    }
    
    # Test GET cache statistics
    $stats = Test-GetCacheStats
    $totalTests++
    if ($stats) { $passedTests++ }
    
    # Test CLEAR expired items
    $clearedCount = Test-ClearExpiredItems
    $totalTests++
    if ($clearedCount -ge 0) { $passedTests++ }
    
    # Summary
    Write-Header "Test Summary"
    Write-Host "Total Tests: $totalTests" -ForegroundColor $InfoColor
    Write-Host "Passed: $passedTests" -ForegroundColor $SuccessColor
    Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor $ErrorColor
    
    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { $SuccessColor } else { $WarningColor })
    
    if ($passedTests -eq $totalTests) {
        Write-Host "`n[SUCCESS] All Redis tests passed! Redis Cache integration is working perfectly." -ForegroundColor $SuccessColor
    } else {
        Write-Host "`n[WARNING] Some Redis tests failed. Check the details above." -ForegroundColor $WarningColor
    }
}

# Run the tests
Main
