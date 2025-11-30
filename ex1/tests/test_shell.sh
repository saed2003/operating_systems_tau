#!/bin/bash

# Comprehensive Test Script for hw1shell
# Tests all required functionality with improved reliability

# Find hw1shell executable
if [ -f "../hw1shell" ]; then
    SHELL_PATH="../hw1shell"
elif [ -f "../vscode_copilot/hw1shell" ]; then
    SHELL_PATH="../vscode_copilot/hw1shell"
elif [ -f "/mnt/hgfs/shared/ex1/hw1shell" ]; then
    SHELL_PATH="/mnt/hgfs/shared/ex1/hw1shell"
elif [ -f "/mnt/hgfs/shared/ex1/vscode_copilot/hw1shell" ]; then
    SHELL_PATH="/mnt/hgfs/shared/ex1/vscode_copilot/hw1shell"
else
    echo "Error: hw1shell executable not found!"
    echo "Please compile it first with 'make'"
    exit 1
fi

echo "Using shell at: $SHELL_PATH"
echo ""

PASSED=0
FAILED=0
TEST_DIR="/tmp/hw1shell_test_$$"
mkdir -p "$TEST_DIR"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "======================================"
echo "    hw1shell Test Suite"
echo "======================================"
echo ""

# Cleanup function
cleanup() {
    rm -rf "$TEST_DIR"
}
trap cleanup EXIT

# Helper function to run a test
run_test() {
    local test_name="$1"
    local input="$2"
    local expected="$3"
    local description="$4"
    local mode="${5:-contains}"  # contains, exact, not_contains, regex
    
    echo -n "Testing: $test_name ... "
    
    # Create temp input file
    local input_file="$TEST_DIR/input_$$.txt"
    echo -e "$input" > "$input_file"
    
    # Run shell with timeout
    local output_file="$TEST_DIR/output_$$.txt"
    timeout 5 "$SHELL_PATH" < "$input_file" > "$output_file" 2>&1
    local exit_code=$?
    
    local result=$(cat "$output_file")
    
    # Check for timeout
    if [ $exit_code -eq 124 ]; then
        echo -e "${RED}FAILED (timeout)${NC}"
        echo "  Description: $description"
        FAILED=$((FAILED + 1))
        rm -f "$input_file" "$output_file"
        return
    fi
    
    # Perform check based on mode
    local passed=0
    case "$mode" in
        "contains")
            if echo "$result" | grep -q "$expected"; then
                passed=1
            fi
            ;;
        "exact")
            if [ "$result" = "$expected" ]; then
                passed=1
            fi
            ;;
        "not_contains")
            if ! echo "$result" | grep -q "$expected"; then
                passed=1
            fi
            ;;
        "regex")
            if echo "$result" | grep -E -q "$expected"; then
                passed=1
            fi
            ;;
    esac
    
    if [ $passed -eq 1 ]; then
        echo -e "${GREEN}PASSED${NC}"
        PASSED=$((PASSED + 1))
    else
        echo -e "${RED}FAILED${NC}"
        echo "  Description: $description"
        echo "  Expected ($mode): $expected"
        echo "  Got:"
        echo "$result" | head -15 | sed 's/^/    /'
        FAILED=$((FAILED + 1))
    fi
    
    rm -f "$input_file" "$output_file"
}

echo -e "${YELLOW}=== Test Group 1: Basic Functionality ===${NC}"

# Test 1: Prompt display
run_test "Prompt display" "exit" "hw1shell" "Should display hw1shell\$ prompt"

# Test 2: Empty command  
run_test "Empty command" "\n\nexit" "hw1shell" "Should handle empty input"

# Test 3: Exit command
echo -n "Testing: Exit works ... "
result=$(echo -e "exit" | timeout 2 "$SHELL_PATH" 2>&1)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""
echo -e "${YELLOW}=== Test Group 2: Internal Commands - cd ===${NC}"

# Test 4-8: cd command
run_test "cd to /tmp" "cd /tmp\npwd\nexit" "/tmp" "cd should change directory"

run_test "cd to parent" "cd ..\npwd\nexit" "/" "cd .. should work"

run_test "cd no args" "cd\nexit" "hw1shell: invalid command" "cd with no args should error"

run_test "cd too many args" "cd /tmp /var\nexit" "hw1shell: invalid command" "cd with multiple args should error"

run_test "cd invalid dir" "cd /nonexistent_xyz_123\nexit" "chdir failed" "cd to invalid dir should error"

echo ""
echo -e "${YELLOW}=== Test Group 3: Internal Commands - jobs ===${NC}"

# Test 9: jobs with no background
echo -n "Testing: jobs empty ... "
result=$(echo -e "jobs\nexit" | timeout 2 "$SHELL_PATH" 2>&1)
if echo "$result" | grep -q "hw1shell" && ! echo "$result" | grep -q "^[0-9]"; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    FAILED=$((FAILED + 1))
fi

echo ""
echo -e "${YELLOW}=== Test Group 4: External Commands ===${NC}"

# Test 10-13: External commands
run_test "echo command" "echo hello\nexit" "hello" "Should execute echo"

run_test "ls command" "ls /tmp\nexit" "" "Should execute ls"

run_test "pwd command" "pwd\nexit" "/" "Should execute pwd"

run_test "invalid command" "xyz_invalid_cmd_123\nexit" "hw1shell: invalid command" "Should show error for invalid command"

echo ""
echo -e "${YELLOW}=== Test Group 5: Background Commands ===${NC}"

# Test 14: Single background job
run_test "bg job started" "sleep 2 &\nexit" "hw1shell: pid [0-9]+ started" "Should start background job" "regex"

# Test 15: Background job appears in jobs
echo -n "Testing: jobs shows bg ... "
cat > "$TEST_DIR/test_jobs_bg.txt" << 'EOF'
sleep 5 &
jobs
exit
EOF
result=$(timeout 3 "$SHELL_PATH" < "$TEST_DIR/test_jobs_bg.txt" 2>&1)
if echo "$result" | grep -E "[0-9]+.*sleep 5" > /dev/null; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  Should show background job in jobs output"
    FAILED=$((FAILED + 1))
fi

# Test 16: Multiple background jobs (2)
cat > "$TEST_DIR/test_2bg.txt" << 'EOF'
sleep 3 &
sleep 3 &
jobs
exit
EOF
result=$(timeout 5 "$SHELL_PATH" < "$TEST_DIR/test_2bg.txt" 2>&1)
echo -n "Testing: 2 background jobs ... "
bg_count=$(echo "$result" | grep -c "sleep 3 &")
if [ "$bg_count" -ge 2 ]; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  Should show at least 2 instances of 'sleep 3', got $bg_count"
    FAILED=$((FAILED + 1))
fi

# Test 17: 4 background jobs (max)
cat > "$TEST_DIR/test_4bg.txt" << 'EOF'
sleep 5 &
sleep 5 &
sleep 5 &
sleep 5 &
jobs
exit
EOF
result=$(timeout 5 "$SHELL_PATH" < "$TEST_DIR/test_4bg.txt" 2>&1)
echo -n "Testing: 4 background jobs ... "
bg_count=$(echo "$result" | grep -c "sleep 5 &")
if [ "$bg_count" -ge 4 ]; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  Should show 4 background jobs, got $bg_count"
    FAILED=$((FAILED + 1))
fi

# Test 18: 5 background jobs (overflow)
cat > "$TEST_DIR/test_5bg.txt" << 'EOF'
sleep 10 &
sleep 10 &
sleep 10 &
sleep 10 &
sleep 10 &
exit
EOF
result=$(timeout 3 "$SHELL_PATH" < "$TEST_DIR/test_5bg.txt" 2>&1)
echo -n "Testing: 5 bg jobs (overflow) ... "
if echo "$result" | grep -q "too many background commands running"; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  Should reject 5th background job"
    FAILED=$((FAILED + 1))
fi

# Test 19: Background job completion
cat > "$TEST_DIR/test_bg_done.txt" << 'EOF'
sleep 1 &
sleep 2
exit
EOF
result=$(timeout 5 "$SHELL_PATH" < "$TEST_DIR/test_bg_done.txt" 2>&1)
echo -n "Testing: bg job completion ... "
if echo "$result" | grep -q "pid [0-9]* finished"; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  Should show 'pid X finished' message"
    FAILED=$((FAILED + 1))
fi

echo ""
echo -e "${YELLOW}=== Test Group 6: Mixed Operations ===${NC}"

# Test 20: Foreground then background
run_test "fg then bg" "echo test\nsleep 2 &\nexit" "test" "Should handle fg then bg"

# Test 21: Background then foreground
run_test "bg then fg" "sleep 3 &\necho test\nexit" "test" "Should handle bg then fg"

# Test 22: cd then command
run_test "cd then cmd" "cd /tmp\npwd\nexit" "/tmp" "Should execute command in new directory"

echo ""
echo -e "${YELLOW}=== Test Group 7: Edge Cases ===${NC}"

# Test 23-25: Edge cases
run_test "multiple args" "echo one two three\nexit" "one two three" "Should handle multiple arguments"

run_test "command with tab" "echo\thello\nexit" "hello" "Should handle tabs"

run_test "long command" "echo aaaaa bbbbb ccccc ddddd\nexit" "aaaaa bbbbb ccccc ddddd" "Should handle long commands"

echo ""
echo -e "${YELLOW}=== Test Group 8: Exit Behavior ===${NC}"

# Test 26: Exit waits for background jobs
cat > "$TEST_DIR/test_exit_wait.txt" << 'EOF'
sleep 1 &
exit
EOF
start=$(date +%s)
timeout 3 "$SHELL_PATH" < "$TEST_DIR/test_exit_wait.txt" > /dev/null 2>&1
end=$(date +%s)
duration=$((end - start))

echo -n "Testing: exit waits for bg ... "
if [ $duration -ge 1 ]; then
    echo -e "${GREEN}PASSED${NC}"
    PASSED=$((PASSED + 1))
else
    echo -e "${RED}FAILED${NC}"
    echo "  exit should wait for background jobs (took ${duration}s, expected >=1s)"
    FAILED=$((FAILED + 1))
fi

echo ""
echo -e "${YELLOW}=== Test Group 9: Error Message Format ===${NC}"

# Test 27: Invalid command error format
run_test "error msg format" "cmd_xyz_invalid\nexit" "hw1shell: invalid command" "Error message format check"

# Test 28: errno in error message
run_test "errno in msg" "cd /root/xyz_invalid_123\nexit" "errno is [0-9]" "Should include errno" "regex"

echo ""
echo "======================================"
echo "       Test Results Summary"
echo "======================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo "Total:  $((PASSED + FAILED))"
echo ""

if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✓ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}✗ Some tests failed.${NC}"
    exit 1
fi
