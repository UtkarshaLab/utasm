#!/bin/bash
# ============================================================================
# File        : scripts/test.sh
# Project     : utasm
# Description : Sovereign Test Harness for instruction suite validation.
#               Executes the utasm compiler against all payloads in tests/.
# ============================================================================

set -e

echo "[+] Initiating UtkarshaLab Sovereign Test Harness..."

UTASM_BIN="build/gen1/utasm"

if [ ! -f "$UTASM_BIN" ]; then
    echo "[-] CRITICAL ERROR: utasm Gen1 binary not found. Run bootstrap.sh first."
    exit 1
fi

mkdir -p build/tests
FAILED=0
PASSED=0

echo "[+] Executing Test Matrix..."

for test_file in tests/*.s; do
    basename=$(basename "$test_file" .s)
    echo -n "    [*] Assembling $basename... "
    
    # We compile the test payload to an ELF64 relocatable object
    if $UTASM_BIN -f elf64 "$test_file" -o "build/tests/$basename.o" > /dev/null 2>&1; then
        echo "OK"
        ((PASSED++))
    else
        echo "FAILED"
        ((FAILED++))
        # Rerun without silencing to display the strict error formatting
        $UTASM_BIN -f elf64 "$test_file" -o "build/tests/$basename.o" || true
    fi
done

echo "============================================================================"
echo "    SOVEREIGN TEST RESULTS: $PASSED Passed | $FAILED Failed"
echo "============================================================================"

if [ $FAILED -ne 0 ]; then
    echo "[-] VALIDATION FAILED: Architectural instability detected in encoder."
    exit 1
else
    echo "[+] VALIDATION SUCCESSFUL: Absolute architectural parity achieved."
    exit 0
fi
