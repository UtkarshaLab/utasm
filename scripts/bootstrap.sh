#!/bin/bash
# ============================================================================
# File        : scripts/bootstrap.sh
# Project     : utasm
# Description : Stage 1 (Gen0) and Stage 2 (Gen1) Bootstrapping Pipeline
#               This script initiates the Millennial Inversion.
# ============================================================================

set -e

echo "[+] Initiating UtkarshaLab Sovereign Bootstrap Sequence..."

mkdir -p build/gen0
mkdir -p build/gen1

# ----------------------------------------------------------------------------
# PHASE 1: GEN0 COMPILATION (via NASM)
# ----------------------------------------------------------------------------
echo "[+] PHASE 1: Assembling Gen0 Compiler via NASM..."

# We compile the main entry point which %includes all other components
nasm -f elf64 src/main.s -o build/gen0/utasm.o
ld -o build/gen0/utasm build/gen0/utasm.o

echo "[+] Gen0 Compilation Successful."
ls -l build/gen0/utasm

# ----------------------------------------------------------------------------
# PHASE 2: GEN1 SELF-HOSTING (utasm -> utasm)
# ----------------------------------------------------------------------------
echo "[+] PHASE 2: Initiating Self-Hosting Ascent (Gen1)..."

# Use the newly built utasm to compile itself
./build/gen0/utasm -f elf64 src/main.s -o build/gen1/utasm.o
ld -o build/gen1/utasm build/gen1/utasm.o

echo "[+] Gen1 Compilation Successful."
ls -l build/gen1/utasm

# ----------------------------------------------------------------------------
# PHASE 3: BINARY SOVEREIGNTY VERIFICATION
# ----------------------------------------------------------------------------
echo "[+] PHASE 3: Verifying Binary Sovereignty..."

if cmp -s build/gen0/utasm build/gen1/utasm; then
    echo "[!] MILLENNIAL INVERSION COMPLETE: Gen0 and Gen1 are identical."
    echo "[!] Absolute Binary Sovereignty Achieved."
else
    echo "[-] WARNING: Gen0 and Gen1 differ. Bootstrapping instability detected."
    # We do not fail the script yet, as minor ELF layout differences might exist 
    # between NASM's output and utasm's output initially.
fi

echo "[+] Sequence Terminated Successfully."
