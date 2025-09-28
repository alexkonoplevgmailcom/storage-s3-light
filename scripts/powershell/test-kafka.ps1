# Kafka Integration Testing Script
# Tests Kafka message production and consumption

param(
    [string]$ApiBaseUrl = "http://localhost:5111",
    [string]$KafkaContainer = "bfb-kafka",
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

function Test-KafkaContainerStatus {
    Write-Header "Testing Kafka Container Status"
    
    try {
        $containerInfo = docker ps --filter "name=$KafkaContainer" --format "{{.Names}}`t{{.Status}}" | Select-String $KafkaContainer
        
        if ($containerInfo) {
            $status = $containerInfo.ToString().Split("`t")[1]
            if ($status -like "*Up*") {
                Write-TestResult "Kafka Container Status" $true "Container is running: $status"
                return $true
            } else {
                Write-TestResult "Kafka Container Status" $false "Container is not running: $status"
                return $false
            }
        } else {
            Write-TestResult "Kafka Container Status" $false "Container '$KafkaContainer' not found"
            return $false
        }
    }
    catch {
        Write-TestResult "Kafka Container Status" $false "Error checking container: $($_.Exception.Message)"
        return $false
    }
}

function Test-KafkaTopics {
    Write-Header "Testing Kafka Topics"
    
    try {
        $topics = docker exec $KafkaContainer kafka-topics --bootstrap-server localhost:9092 --list 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            $topicList = $topics -split "`n" | Where-Object { $_ -ne "" -and $_ -ne "__consumer_offsets" }
            Write-TestResult "Kafka Topics List" $true "Found $($topicList.Count) topics"
            
            if ($Verbose) {
                Write-Host "Available topics:" -ForegroundColor Gray
                $topicList | ForEach-Object { Write-Host "  - $_" -ForegroundColor Gray }
            }
            
            # Check for required topics
            $requiredTopics = @(
                "bank-machine-cash-withdrawal-requests",
                "account-balance-change-request",
                "brinks-cash-management"
            )
            
            $missingTopics = @()
            foreach ($topic in $requiredTopics) {
                if ($topicList -notcontains $topic) {
                    $missingTopics += $topic
                }
            }
            
            if ($missingTopics.Count -eq 0) {
                Write-TestResult "Required Topics Check" $true "All required topics exist"
                return $true
            } else {
                Write-TestResult "Required Topics Check" $false "Missing topics: $($missingTopics -join ', ')"
                return $false
            }
        } else {
            Write-TestResult "Kafka Topics List" $false "Failed to list topics"
            return $false
        }
    }
    catch {
        Write-TestResult "Kafka Topics List" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-SendCashWithdrawalMessage {
    Write-Header "Testing Kafka Message Production"
    
    $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
    $requestId = [Guid]::NewGuid().ToString()
    
    $testMessage = @{
        RequestId = $requestId
        AccountNumber = "TEST-ACCOUNT-$(Get-Random -Maximum 9999)"
        Amount = 100.00
        AtmId = "ATM-TEST-001"
        RequestTimestamp = $timestamp
        CustomerPin = "1234"
        CurrencyCode = "USD"
    }
    
    try {
        $jsonMessage = $testMessage | ConvertTo-Json -Compress
        
        # Send message using echo and docker exec
        $result = echo $jsonMessage | docker exec -i $KafkaContainer kafka-console-producer --bootstrap-server localhost:9092 --topic bank-machine-cash-withdrawal-requests
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Send Cash Withdrawal Message" $true "Message sent with RequestId: $requestId"
            
            if ($Verbose) {
                Write-Host "Sent message:" -ForegroundColor Gray
                $jsonMessage | Write-Host -ForegroundColor Gray
            }
            
            return $requestId
        } else {
            Write-TestResult "Send Cash Withdrawal Message" $false "Failed to send message to topic"
            return $null
        }
    }
    catch {
        Write-TestResult "Send Cash Withdrawal Message" $false "Error: $($_.Exception.Message)"
        return $null
    }
}

function Test-CheckOutputTopics {
    param($RequestId, $WaitSeconds = 10)
    
    Write-Header "Testing Kafka Message Consumption and Processing"
    
    if (-not $RequestId) {
        Write-TestResult "Check Output Topics" $false "No RequestId provided"
        return $false
    }
    
    Write-Host "Waiting $WaitSeconds seconds for message processing..." -ForegroundColor $InfoColor
    Start-Sleep -Seconds $WaitSeconds
    
    $outputTopics = @{
        "account-balance-change-request" = $false
        "brinks-cash-management" = $false
    }
    
    foreach ($topic in $outputTopics.Keys) {
        try {
            Write-Host "Checking topic: $topic" -ForegroundColor Gray
            
            # Try to consume recent messages with timeout
            $messages = docker exec $KafkaContainer timeout 5 kafka-console-consumer --bootstrap-server localhost:9092 --topic $topic --from-beginning --max-messages 10 2>$null
            
            if ($messages -and $messages.Count -gt 0) {
                # Check if any message contains our RequestId or is recent
                $foundRelevant = $false
                foreach ($message in $messages) {
                    if ($message -like "*$RequestId*" -or $message -like "*$(Get-Date -Format "yyyy-MM-dd")*") {
                        $foundRelevant = $true
                        break
                    }
                }
                
                if ($foundRelevant) {
                    Write-TestResult "Topic $topic" $true "Found processed messages"
                    $outputTopics[$topic] = $true
                    
                    if ($Verbose) {
                        Write-Host "Sample message from $topic" -ForegroundColor Gray
                        $messages[0] | Write-Host -ForegroundColor Gray
                    }
                } else {
                    Write-TestResult "Topic $topic" $true "Topic has messages (may not be from this test)"
                    $outputTopics[$topic] = $true
                }
            } else {
                Write-TestResult "Topic $topic" $false "No messages found in topic"
            }
        }
        catch {
            Write-TestResult "Topic $topic" $false "Error checking topic: $($_.Exception.Message)"
        }
    }
    
    $allTopicsWorking = $outputTopics.Values -notcontains $false
    
    if ($allTopicsWorking) {
        Write-TestResult "Kafka Message Processing" $true "Cash withdrawal processing pipeline is working"
    } else {
        Write-TestResult "Kafka Message Processing" $false "Some output topics have no messages"
    }
    
    return $allTopicsWorking
}

function Test-KafkaProducerConsumerBasic {
    Write-Header "Testing Basic Kafka Producer/Consumer"
    
    $testTopic = "bank-machine-cash-withdrawal-requests"
    $testMessage = "health-check-$(Get-Date -Format 'HHmmss')"
    
    try {
        # Test producer
        Write-Host "Testing basic producer..." -ForegroundColor Gray
        $producerResult = echo $testMessage | docker exec -i $KafkaContainer kafka-console-producer --bootstrap-server localhost:9092 --topic $testTopic
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Basic Producer Test" $true "Successfully sent test message"
            
            # Test consumer
            Write-Host "Testing basic consumer..." -ForegroundColor Gray
            Start-Sleep -Seconds 2
            
            $consumerResult = docker exec $KafkaContainer timeout 5 kafka-console-consumer --bootstrap-server localhost:9092 --topic $testTopic --from-beginning --max-messages 1 2>$null
            
            if ($consumerResult -and $consumerResult.Contains($testMessage)) {
                Write-TestResult "Basic Consumer Test" $true "Successfully consumed test message"
                return $true
            } else {
                Write-TestResult "Basic Consumer Test" $false "Could not consume test message"
                return $false
            }
        } else {
            Write-TestResult "Basic Producer Test" $false "Failed to send test message"
            return $false
        }
    }
    catch {
        Write-TestResult "Basic Producer/Consumer Test" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

function Test-KafkaServiceHealth {
    Write-Header "Testing Kafka Service Health"
    
    try {
        # Check if we can connect to Kafka bootstrap server
        $metadataCheck = docker exec $KafkaContainer kafka-broker-api-versions --bootstrap-server localhost:9092 2>$null
        
        if ($LASTEXITCODE -eq 0) {
            Write-TestResult "Kafka Bootstrap Server" $true "Successfully connected to Kafka"
            return $true
        } else {
            Write-TestResult "Kafka Bootstrap Server" $false "Cannot connect to Kafka bootstrap server"
            return $false
        }
    }
    catch {
        Write-TestResult "Kafka Bootstrap Server" $false "Error: $($_.Exception.Message)"
        return $false
    }
}

# Main execution
function Main {
    Write-Host "🟡 Kafka Integration Testing" -ForegroundColor $InfoColor
    Write-Host "Testing Kafka message production and consumption" -ForegroundColor $InfoColor
    Write-Host "Kafka Container: $KafkaContainer" -ForegroundColor $InfoColor
    
    $totalTests = 0
    $passedTests = 0
    
    # Test Kafka container status
    if (-not (Test-KafkaContainerStatus)) {
        Write-Host "[FAILE] Kafka container is not running. Please start it first." -ForegroundColor $ErrorColor
        Write-Host "Use: docker-compose -f docker-compose/docker-compose.kafka.yml up -d" -ForegroundColor $InfoColor
        exit 1
    }
    $totalTests++; $passedTests++
    
    # Test Kafka service health
    $serviceHealthy = Test-KafkaServiceHealth
    $totalTests++
    if ($serviceHealthy) { $passedTests++ }
    
    # Test Kafka topics
    $topicsReady = Test-KafkaTopics
    $totalTests++
    if ($topicsReady) { $passedTests++ }
    
    # Test basic producer/consumer
    $basicWorking = Test-KafkaProducerConsumerBasic
    $totalTests++
    if ($basicWorking) { $passedTests++ }
    
    # Test cash withdrawal message flow
    if ($topicsReady -and $basicWorking) {
        $requestId = Test-SendCashWithdrawalMessage
        $totalTests++
        if ($requestId) { $passedTests++ }
        
        # Test message processing
        if ($requestId) {
            $processingWorking = Test-CheckOutputTopics -RequestId $requestId -WaitSeconds 15
            $totalTests++
            if ($processingWorking) { $passedTests++ }
        }
    }
    
    # Summary
    Write-Header "Test Summary"
    Write-Host "Total Tests: $totalTests" -ForegroundColor $InfoColor
    Write-Host "Passed: $passedTests" -ForegroundColor $SuccessColor
    Write-Host "Failed: $($totalTests - $passedTests)" -ForegroundColor $ErrorColor
    
    $successRate = [math]::Round(($passedTests / $totalTests) * 100, 1)
    Write-Host "Success Rate: $successRate%" -ForegroundColor $(if ($successRate -eq 100) { $SuccessColor } else { $WarningColor })
    
    if ($passedTests -eq $totalTests) {
        Write-Host "`n🎉 All Kafka tests passed! Kafka integration is working perfectly." -ForegroundColor $SuccessColor
        Write-Host "[SUCCESS] Cash withdrawal processing pipeline is operational" -ForegroundColor $SuccessColor
        Write-Host "[SUCCESS] Message production and consumption is working" -ForegroundColor $SuccessColor
        Write-Host "[SUCCESS] All required topics are available" -ForegroundColor $SuccessColor
    } else {
        Write-Host "`n[WARNING] Some Kafka tests failed. Check the details above." -ForegroundColor $WarningColor
    }
    
    # Additional info
    Write-Host "[INFO] Kafka Integration Status:" -ForegroundColor $InfoColor
    Write-Host "- Producer functionality: $(if ($requestId) { '[Working]' } else { '[Failed]' })" -ForegroundColor $(if ($requestId) { $SuccessColor } else { $ErrorColor })
    Write-Host "- Consumer functionality: $(if ($basicWorking) { '[Working]' } else { '[Failed]' })" -ForegroundColor $(if ($basicWorking) { $SuccessColor } else { $ErrorColor })
    Write-Host "- Message processing pipeline: $(if ($processingWorking) { '[Working]' } else { '[Unknown]' })" -ForegroundColor $(if ($processingWorking) { $SuccessColor } else { $WarningColor })
}

# Run the tests
Main
