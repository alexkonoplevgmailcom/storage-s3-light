# MongoDB API Endpoint Testing Script
# Tests all MongoDB customer management endpoints

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
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers" -Method GET -TimeoutSec 10
        if ($response.StatusCode -eq 200) {
            Write-TestResult "API Connection" $true "API is accessible"
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

function Test-GetAllCustomers {
    Write-Header "Testing GET All Customers"
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers" -Method GET
        $customers = $response.Content | ConvertFrom-Json
        
        Write-TestResult "GET All Customers" $true "Retrieved $($customers.Count) customers"
        
        if ($Verbose -and $customers.Count -gt 0) {
            Write-Host "Sample customer:" -ForegroundColor Gray
            $customers[0] | ConvertTo-Json | Write-Host -ForegroundColor Gray
        }
        
        return $customers
    }
    catch {
        Write-TestResult "GET All Customers" $false "Error: $($_.Exception.Message)"
        return @()
    }
}

function Test-CreateCustomer {
    Write-Header "Testing POST Create Customer"
    
    $timestamp = Get-Date -Format "HHmmss"
    $testCustomer = @{
        Email = "test.customer.$timestamp@example.com"
        FirstName = "Test"
        LastName = "Customer"
        PhoneNumber = "+1-555-$timestamp"
        InitialBalance = 1000.00
    }
    
    try {
        $body = $testCustomer | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers" -Method POST -Body $body -ContentType "application/json"
        
        if ($response.StatusCode -eq 201) {
            $createdCustomer = $response.Content | ConvertFrom-Json
            Write-TestResult "POST Create Customer" $true "Customer created with ID: $($createdCustomer.Id)"
            
            if ($Verbose) {
                Write-Host "Created customer details:" -ForegroundColor Gray
                $createdCustomer | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $createdCustomer
        } else {
            Write-TestResult "POST Create Customer" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "POST Create Customer" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-GetCustomerById {
    param($CustomerId)
    
    Write-Header "Testing GET Customer by ID"
    
    if (-not $CustomerId) {
        Write-TestResult "GET Customer by ID" $false "No customer ID provided"
        return $null
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers/$CustomerId" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $customer = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Customer by ID" $true "Retrieved customer: $($customer.Email)"
            
            if ($Verbose) {
                Write-Host "Customer details:" -ForegroundColor Gray
                $customer | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $customer
        } else {
            Write-TestResult "GET Customer by ID" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "GET Customer by ID" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-CreateTransaction {
    param($CustomerId)
    
    Write-Header "Testing POST Create Transaction"
    
    if (-not $CustomerId) {
        Write-TestResult "POST Create Transaction" $false "No customer ID provided"
        return $null
    }
    
    $testTransaction = @{
        CustomerId = $CustomerId
        Amount = 150.00
        Type = 1  # Deposit
        Description = "Test deposit transaction"
    }
    
    try {
        $body = $testTransaction | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers/$CustomerId/transactions" -Method POST -Body $body -ContentType "application/json"
        
        if ($response.StatusCode -eq 201) {
            $transaction = $response.Content | ConvertFrom-Json
            Write-TestResult "POST Create Transaction" $true "Transaction created with ID: $($transaction.Id)"
            
            if ($Verbose) {
                Write-Host "Transaction details:" -ForegroundColor Gray
                $transaction | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $transaction
        } else {
            Write-TestResult "POST Create Transaction" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "POST Create Transaction" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-GetCustomerTransactions {
    param($CustomerId)
    
    Write-Header "Testing GET Customer Transactions"
    
    if (-not $CustomerId) {
        Write-TestResult "GET Customer Transactions" $false "No customer ID provided"
        return @()
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers/$CustomerId/transactions" -Method GET
        
        if ($response.StatusCode -eq 200) {
            $transactions = $response.Content | ConvertFrom-Json
            Write-TestResult "GET Customer Transactions" $true "Retrieved $($transactions.Count) transactions"
            
            if ($Verbose -and $transactions.Count -gt 0) {
                Write-Host "Transaction details:" -ForegroundColor Gray
                $transactions | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $transactions
        } else {
            Write-TestResult "GET Customer Transactions" $false "Unexpected status code: $($response.StatusCode)"
            return @()
        }
    }
    catch {
        Write-TestResult "GET Customer Transactions" $false "Error: $($_.Exception.Message)"
        return @()
    }
}

function Test-UpdateCustomer {
    param($Customer)
    
    Write-Header "Testing PUT Update Customer"
    
    if (-not $Customer) {
        Write-TestResult "PUT Update Customer" $false "No customer provided"
        return $null
    }
    
    $updateData = @{
        Id = $Customer.Id
        FirstName = $Customer.FirstName
        LastName = "Updated"
        PhoneNumber = $Customer.PhoneNumber
    }
    
    try {
        $body = $updateData | ConvertTo-Json
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers/$($Customer.Id)" -Method PUT -Body $body -ContentType "application/json"
        
        if ($response.StatusCode -eq 200) {
            $updatedCustomer = $response.Content | ConvertFrom-Json
            Write-TestResult "PUT Update Customer" $true "Customer updated successfully"
            
            if ($Verbose) {
                Write-Host "Updated customer details:" -ForegroundColor Gray
                $updatedCustomer | ConvertTo-Json | Write-Host -ForegroundColor Gray
            }
            
            return $updatedCustomer
        } else {
            Write-TestResult "PUT Update Customer" $false "Unexpected status code: $($response.StatusCode)"
            return $null
        }
    }
    catch {
        Write-TestResult "PUT Update Customer" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-DeleteCustomer {
    param($CustomerId)
    
    Write-Header "Testing DELETE Customer"
    
    if (-not $CustomerId) {
        Write-TestResult "DELETE Customer" $false "No customer ID provided"
        return $false
    }
    
    try {
        $response = Invoke-WebRequest -Uri "$ApiBaseUrl/api/mongo/MongoCustomers/$CustomerId" -Method DELETE
        
        if ($response.StatusCode -eq 204) {
            Write-TestResult "DELETE Customer" $true "Customer deactivated successfully"
            return $true
        } else {
            Write-TestResult "DELETE Customer" $false "Unexpected status code: $($response.StatusCode)"
            return $false
        }
    }
    catch {
        Write-TestResult "DELETE Customer" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Host "[INFO] MongoDB API Endpoint Testing" -ForegroundColor $InfoColor
    Write-Host "Testing MongoDB customer management endpoints" -ForegroundColor $InfoColor
    Write-Host "API Base URL: $ApiBaseUrl" -ForegroundColor $InfoColor
    
    $totalTests = 0
    $passedTests = 0
    
    # Test API connection
    if (-not (Test-ApiConnection)) {
        Write-Host "`n[ERROR] Cannot connect to API. Ensure the API is running at $ApiBaseUrl" -ForegroundColor $ErrorColor
        exit 1
    }
    $totalTests++; $passedTests++
    
    # Test GET all customers
    $existingCustomers = Test-GetAllCustomers
    $totalTests++
    if ($existingCustomers -ne $null) { $passedTests++ }
    
    # Test CREATE customer
    $newCustomer = Test-CreateCustomer
    $totalTests++
    if ($newCustomer) { $passedTests++ }
    
    # Test GET customer by ID
    if ($newCustomer) {
        $retrievedCustomer = Test-GetCustomerById -CustomerId $newCustomer.Id
        $totalTests++
        if ($retrievedCustomer) { $passedTests++ }
        
        # Test CREATE transaction
        $transaction = Test-CreateTransaction -CustomerId $newCustomer.Id
        $totalTests++
        if ($transaction) { $passedTests++ }
        
        # Test GET customer transactions
        $transactions = Test-GetCustomerTransactions -CustomerId $newCustomer.Id
        $totalTests++
        if ($transactions -ne $null) { $passedTests++ }
        
        # Test UPDATE customer
        $updatedCustomer = Test-UpdateCustomer -Customer $newCustomer
        $totalTests++
        if ($updatedCustomer) { $passedTests++ }
        
        # Test DELETE customer
        $deleted = Test-DeleteCustomer -CustomerId $newCustomer.Id
        $totalTests++
        if ($deleted) { $passedTests++ }
    }
    
    # Summary
    Write-Header "Test Summary"
    Write-Host "Total Tests: $totalTests" -ForegroundColor $InfoColor
    Write-Host "Passed: $passedTests" -ForegroundColor $SuccessColor
    Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor $ErrorColor
    
    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { $SuccessColor } else { $WarningColor })
    
    if ($passedTests -eq $totalTests) {
        Write-Host "`n[SUCCESS] All MongoDB tests passed! MongoDB integration is working perfectly." -ForegroundColor $SuccessColor
    } else {
        Write-Host "`n[WARNING] Some MongoDB tests failed. Check the details above." -ForegroundColor $WarningColor
    }
}

# Run the tests
Main
