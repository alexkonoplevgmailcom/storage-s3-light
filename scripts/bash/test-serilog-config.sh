#!/bin/bash

#
# Serilog Configuration Test Script (Bash version)
# Tests Serilog logging configuration and functionality in the BFB Template
# Usage: ./test-serilog-config.sh
#

echo "=== Serilog Configuration Test ==="
echo "Testing Serilog logging configuration"

# Test configuration
API_URL="http://localhost:5111"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR/../.."
LOG_DIRECTORY="$PROJECT_ROOT/logs"
PASSED=0
FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

write_test_result() {
    local test_name="$1"
    local success="$2"
    local details="$3"
    
    if [ "$success" = "true" ]; then
        echo -e "${GREEN}✅ $test_name${NC}"
        ((PASSED++))
    else
        echo -e "${RED}❌ $test_name${NC}"
        if [ -n "$details" ]; then
            echo -e "   ${YELLOW}Details: $details${NC}"
        fi
        ((FAILED++))
    fi
}

test_serilog_configuration() {
    echo -e "\n${CYAN}Checking Serilog configuration files...${NC}"
    
    local config_files=(
        "$PROJECT_ROOT/src/BFB.Template.API/appsettings.json"
        "$PROJECT_ROOT/src/BFB.Template.API/appsettings.Development.json"
    )
    
    for config_file in "${config_files[@]}"; do
        local filename=$(basename "$config_file")
        
        if [ -f "$config_file" ]; then
            if grep -q '"Serilog"' "$config_file"; then
                write_test_result "Serilog Config in $filename" "true" "Configuration found"
            else
                write_test_result "Serilog Config in $filename" "false" "No Serilog configuration found"
            fi
        else
            write_test_result "Serilog Config in $filename" "false" "Configuration file not found"
        fi
    done
}

test_log_directory() {
    echo -e "\n${CYAN}Checking log directory...${NC}"
    
    if [ -d "$LOG_DIRECTORY" ]; then
        write_test_result "Log Directory Exists" "true" "Path: $LOG_DIRECTORY"
        
        # Check for log files
        local log_count=$(find "$LOG_DIRECTORY" -name "*.log" -type f 2>/dev/null | wc -l)
        
        if [ "$log_count" -gt 0 ]; then
            write_test_result "Log Files Present" "true" "Found $log_count log file(s)"
            
            # Check the most recent log file
            local latest_log=$(find "$LOG_DIRECTORY" -name "*.log" -type f -printf '%T@ %p\n' 2>/dev/null | sort -rn | head -1 | cut -d' ' -f2-)
            
            if [ -n "$latest_log" ]; then
                local log_age=$(($(date +%s) - $(stat -c %Y "$latest_log" 2>/dev/null || echo 0)))
                local hours_age=$((log_age / 3600))
                
                if [ "$hours_age" -lt 24 ]; then
                    write_test_result "Recent Log Activity" "true" "Latest log: $(basename "$latest_log"), Age: ${hours_age} hours"
                else
                    write_test_result "Recent Log Activity" "false" "Latest log is older than 24 hours"
                fi
            fi
        else
            write_test_result "Log Files Present" "false" "No log files found"
        fi
    else
        write_test_result "Log Directory Exists" "false" "Log directory not found: $LOG_DIRECTORY"
    fi
}

test_api_logging() {
    echo -e "\n${CYAN}Testing API logging...${NC}"
    
    # Check if curl is available
    if ! command -v curl &> /dev/null; then
        write_test_result "API Request for Logging" "false" "curl command not found"
        return
    fi
    
    # Make a test request to generate log entries
    local response_code=$(curl -s -o /dev/null -w "%{http_code}" -m 10 "$API_URL/health" 2>/dev/null)
    
    if [ "$response_code" = "200" ]; then
        write_test_result "API Request for Logging" "true" "Status: $response_code"
        
        # Wait a moment for logs to be written
        sleep 2
        
        # Check if new log entries were created
        if [ -d "$LOG_DIRECTORY" ]; then
            local recent_logs=$(find "$LOG_DIRECTORY" -name "*.log" -type f -newermt '5 minutes ago' 2>/dev/null)
            if [ -n "$recent_logs" ]; then
                write_test_result "Log Entry Generation" "true" "Recent log activity detected"
            else
                write_test_result "Log Entry Generation" "false" "No recent log activity"
            fi
        fi
    else
        write_test_result "API Request for Logging" "false" "HTTP Status: $response_code"
    fi
}

test_log_levels() {
    echo -e "\n${CYAN}Checking log level configuration...${NC}"
    
    local appsettings_path="$PROJECT_ROOT/src/BFB.Template.API/appsettings.json"
    
    if [ -f "$appsettings_path" ]; then
        if grep -q '"MinimumLevel"' "$appsettings_path"; then
            local min_level=$(grep -A 5 '"MinimumLevel"' "$appsettings_path" | grep '"Default"' | sed 's/.*"Default"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/')
            write_test_result "Minimum Log Level" "true" "Level: $min_level"
            
            if grep -q '"Override"' "$appsettings_path"; then
                write_test_result "Log Level Overrides" "true" "Override configuration found"
            else
                write_test_result "Log Level Overrides" "false" "No log level overrides configured"
            fi
        else
            write_test_result "Minimum Log Level" "false" "No minimum log level configured"
        fi
    else
        write_test_result "Log Level Configuration" "false" "appsettings.json not found"
    fi
}

show_test_summary() {
    echo -e "\n${CYAN}=== Serilog Test Summary ===${NC}"
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    
    if [ "$FAILED" -eq 0 ]; then
        echo -e "\n${GREEN}🎉 All Serilog tests passed!${NC}"
    else
        echo -e "\n${YELLOW}⚠️  Some Serilog tests failed. Check the results above.${NC}"
    fi
    
    echo -e "\n${CYAN}To view logs:${NC}"
    echo -e "- Log directory: $LOG_DIRECTORY"
    echo -e "- Recent logs: find '$LOG_DIRECTORY' -name '*.log' -type f | xargs ls -lt"
}

# Main execution
main() {
    test_serilog_configuration
    test_log_directory
    test_log_levels
    test_api_logging
    show_test_summary
}

# Run main function
main "$@"
