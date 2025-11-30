#!/bin/bash

# Interactive test helper for hw1shell

# Try to find hw1shell in different locations
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
    echo "Please compile it first with 'make' in ex1 directory"
    exit 1
fi

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================"
echo "  hw1shell Interactive Test Helper"
echo -e "======================================${NC}"
echo "Using shell at: $SHELL_PATH"
echo ""

show_menu() {
    echo ""
    echo -e "${YELLOW}Select a test scenario:${NC}"
    echo "1. Test basic commands (echo, ls, pwd)"
    echo "2. Test cd command"
    echo "3. Test jobs command"
    echo "4. Test single background job"
    echo "5. Test multiple background jobs (2)"
    echo "6. Test maximum background jobs (4)"
    echo "7. Test background job overflow (5 jobs)"
    echo "8. Test background job completion"
    echo "9. Test invalid commands"
    echo "10. Test mixed foreground and background"
    echo "11. Launch shell for manual testing"
    echo "0. Exit"
    echo ""
    echo -n "Enter choice: "
}

test_basic_commands() {
    echo -e "${GREEN}Testing basic commands...${NC}"
    echo "Commands to try: echo hello, ls, pwd, exit"
    echo ""
    echo -e "echo hello world\nls\npwd\nexit" | "$SHELL_PATH"
}

test_cd() {
    echo -e "${GREEN}Testing cd command...${NC}"
    echo "Will test: cd /tmp, pwd, cd .., pwd, cd invalid"
    echo ""
    echo -e "pwd\ncd /tmp\npwd\ncd ..\npwd\ncd /nonexistent\nexit" | "$SHELL_PATH"
}

test_jobs() {
    echo -e "${GREEN}Testing jobs command...${NC}"
    echo "Will test: jobs (empty), start background job, jobs (with job)"
    echo ""
    echo -e "jobs\nsleep 3 &\njobs\nexit" | "$SHELL_PATH"
}

test_single_bg() {
    echo -e "${GREEN}Testing single background job...${NC}"
    echo "Will start sleep 2 in background and exit"
    echo ""
    echo -e "sleep 2 &\nexit" | "$SHELL_PATH"
}

test_multiple_bg() {
    echo -e "${GREEN}Testing 2 background jobs...${NC}"
    echo "Will start 2 sleep jobs in background"
    echo ""
    echo -e "sleep 3 &\nsleep 3 &\njobs\nexit" | "$SHELL_PATH"
}

test_max_bg() {
    echo -e "${GREEN}Testing 4 background jobs (maximum)...${NC}"
    echo "Will start 4 sleep jobs in background"
    echo ""
    echo -e "sleep 5 &\nsleep 5 &\nsleep 5 &\nsleep 5 &\njobs\nexit" | "$SHELL_PATH"
}

test_overflow_bg() {
    echo -e "${GREEN}Testing 5 background jobs (overflow)...${NC}"
    echo "Will try to start 5 sleep jobs (should reject 5th)"
    echo ""
    echo -e "sleep 10 &\nsleep 10 &\nsleep 10 &\nsleep 10 &\nsleep 10 &\njobs\nexit" | "$SHELL_PATH"
}

test_bg_completion() {
    echo -e "${GREEN}Testing background job completion...${NC}"
    echo "Will start sleep 1 in background, wait, then check if reaped"
    echo ""
    echo -e "sleep 1 &\nsleep 2\necho done\nexit" | "$SHELL_PATH"
}

test_invalid() {
    echo -e "${GREEN}Testing invalid commands...${NC}"
    echo "Will test: invalid_command, cd (no args), cd a b c"
    echo ""
    echo -e "invalid_command_xyz\ncd\ncd /tmp /var\nexit" | "$SHELL_PATH"
}

test_mixed() {
    echo -e "${GREEN}Testing mixed foreground and background...${NC}"
    echo "Will run: echo fg, sleep 3 &, echo fg2, jobs"
    echo ""
    echo -e "echo foreground1\nsleep 3 &\necho foreground2\njobs\nexit" | "$SHELL_PATH"
}

manual_test() {
    echo -e "${GREEN}Launching shell for manual testing...${NC}"
    echo "Type 'exit' when done"
    echo ""
    "$SHELL_PATH"
}

# Main loop
while true; do
    show_menu
    read choice
    
    case $choice in
        1) test_basic_commands ;;
        2) test_cd ;;
        3) test_jobs ;;
        4) test_single_bg ;;
        5) test_multiple_bg ;;
        6) test_max_bg ;;
        7) test_overflow_bg ;;
        8) test_bg_completion ;;
        9) test_invalid ;;
        10) test_mixed ;;
        11) manual_test ;;
        0) echo "Exiting..."; exit 0 ;;
        *) echo -e "${RED}Invalid choice${NC}" ;;
    esac
    
    echo ""
    echo -e "${BLUE}Press Enter to continue...${NC}"
    read
done
