#!/bin/bash
# ============================================================================
# File        : scripts/test.sh
# Project     : utasm
# Description : Sovereign Test Harness for instruction suite validation.
#               Executes the utasm compiler against all payloads in tests/.
# ============================================================================

set -e

# ANSI Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color
BOLD='\033[1m'

echo -e "${BOLD}[+] Initiating UtkarshaLab Sovereign Test Harness...${NC}"

UTASM_BIN="build/gen1/utasm"

if [ ! -f "$UTASM_BIN" ]; then
    echo -e "${RED}[-] CRITICAL ERROR: utasm Gen1 binary not found. Run bootstrap.sh first.${NC}"
    exit 1
fi

mkdir -p build/tests
FAILED=0
PASSED=0
TOTAL=0

echo -e "${BOLD}[+] Executing Global Test Matrix...${NC}"

# Use find to get all .s files recursively in tests/
test_files=$(find tests -name "*.s")

for test_file in $test_files; do
    ((TOTAL++))
    basename=$(basename "$test_file" .s)
    dirname=$(dirname "$test_file")
    arch="amd64" # Default
    
    # Simple architecture detection based on directory
    if [[ "$test_file" == *"aarch64"* ]]; then
        arch="aarch64"
    elif [[ "$test_file" == *"riscv64"* ]]; then
        arch="riscv64"
    elif [[ "$test_file" == *"amd64"* ]]; then
        arch="amd64"
    fi

    echo -n "    [*] [$arch] Assembling $basename... "
    
    # We compile the test payload to an ELF64 relocatable object
    # Force the machine type if detected
    if $UTASM_BIN -m "$arch" -f elf64 "$test_file" -o "build/tests/$basename.o" > /dev/null 2>&1; then
        echo -e "${GREEN}OK${NC}"
        ((PASSED++))
    else
        echo -e "${RED}FAILED${NC}"
        ((FAILED++))
        echo -e "${RED}    [!] Diagnostic Output for $test_file:${NC}"
        # Rerun without silencing to display the strict error formatting
        $UTASM_BIN -m "$arch" -f elf64 "$test_file" -o "build/tests/$basename.o" || true
    fi
done

echo "============================================================================"
echo -e "    ${BOLD}SOVEREIGN TEST RESULTS: ${GREEN}$PASSED Passed${NC} | ${RED}$FAILED Failed${NC} | ${BOLD}Total: $TOTAL${NC}"
echo "============================================================================"

if [ $FAILED -ne 0 ]; then
    echo -e "${RED}[-] VALIDATION FAILED: Architectural instability detected in encoder.${NC}"
    exit 1
else
    echo -e "${GREEN}[+] VALIDATION SUCCESSFUL: Absolute architectural parity achieved.${NC}"
    exit 0
fi
