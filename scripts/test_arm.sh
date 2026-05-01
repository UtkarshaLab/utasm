#!/bin/bash
# ============================================================================
# File        : scripts/test_arm.sh
# Project     : utasm
# Description : ARM-compatible Test Harness (via QEMU emulation)
# ============================================================================

set -e

# ANSI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' 
BOLD='\033[1m'

echo -e "${BOLD}[+] Initiating ARM-Compatible Test Harness...${NC}"

# Check for QEMU
if ! command -v qemu-x86_64-static &> /dev/null && ! command -v qemu-x86_64 &> /dev/null; then
    echo -e "${RED}[-] ERROR: qemu-x86_64 not found.${NC}"
    exit 1
fi
QEMU_EXEC=$(command -v qemu-x86_64-static || command -v qemu-x86_64)

UTASM_BIN="build/gen1/utasm"
if [ ! -f "$UTASM_BIN" ]; then
    echo -e "${RED}[-] ERROR: utasm Gen1 binary not found. Run bootstrap_arm.sh first.${NC}"
    exit 1
fi

# Wrap the binary in QEMU for ARM host
RUN_UTASM="$QEMU_EXEC ./$UTASM_BIN"

mkdir -p build/tests
FAILED=0
PASSED=0
TOTAL=0

test_files=$(find tests -name "*.s")

for test_file in $test_files; do
    ((TOTAL++))
    basename=$(basename "$test_file" .s)
    arch="amd64"
    if [[ "$test_file" == *"aarch64"* ]]; then arch="aarch64"; 
    elif [[ "$test_file" == *"riscv64"* ]]; then arch="riscv64"; 
    elif [[ "$test_file" == *"amd64"* ]]; then arch="amd64"; fi

    echo -n "    [*] [$arch] Assembling $basename... "
    
    is_executable=0
    if [[ "$basename" == "hello_"* ]]; then is_executable=1; fi

    set +e
    if [ $is_executable -eq 1 ]; then
        $RUN_UTASM -arch "$arch" -f elf64 --standalone "$test_file" -o "build/tests/$basename" > /dev/null 2>&1
    else
        $RUN_UTASM -arch "$arch" -f elf64 "$test_file" -o "build/tests/$basename.o" > /dev/null 2>&1
    fi
    exit_code=$?
    set -e

    if [ $exit_code -eq 0 ]; then
        if [ $is_executable -eq 1 ]; then
            echo -n "Running... "
            runner=""
            if [ "$arch" == "aarch64" ]; then
                # Native run on ARM server if arch matches!
                runner="" 
            elif [ "$arch" == "riscv64" ]; then
                runner="qemu-riscv64"
            elif [ "$arch" == "amd64" ]; then
                runner="$QEMU_EXEC"
            fi
            
            set +e
            if [ -n "$runner" ]; then
                $runner "./build/tests/$basename" > /dev/null 2>&1
            else
                "./build/tests/$basename" > /dev/null 2>&1
            fi
            run_exit_code=$?
            set -e
            
            if [ $run_exit_code -eq 0 ]; then
                echo -e "${GREEN}OK${NC}"; ((PASSED++))
            else
                echo -e "${RED}EXECUTION FAILED${NC}"; ((FAILED++))
            fi
        else
            echo -e "${GREEN}OK${NC}"; ((PASSED++))
        fi
    else
        echo -e "${RED}FAILED${NC}"; ((FAILED++))
    fi
done

echo "============================================================================"
echo -e "    ${BOLD}ARM TEST RESULTS: ${GREEN}$PASSED Passed${NC} | ${RED}$FAILED Failed${NC} | ${BOLD}Total: $TOTAL${NC}"
echo "============================================================================"
