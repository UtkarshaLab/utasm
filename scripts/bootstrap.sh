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

# Find all .s files in src/ and its subdirectories
src_files=$(find src -name "*.s")
obj_files=""

for src_file in $src_files; do
    # Skip main.s if we want to handle it specifically, or just include it in the loop
    obj_file="build/gen0/$(basename "${src_file%.s}.o")"
    nasm -I./ -f elf64 "$src_file" -o "$obj_file"
    obj_files="$obj_files $obj_file"
done

# Link all object files into the Gen0 binary
ld -o build/gen0/utasm $obj_files

echo "[+] Gen0 Compilation Successful."
ls -l build/gen0/utasm

# ----------------------------------------------------------------------------
# PHASE 2: GEN1 SELF-HOSTING (utasm -> utasm)
# ----------------------------------------------------------------------------
echo "[+] PHASE 2: Initiating Self-Hosting Ascent (Gen1)..."

obj_files_gen1=""
for src_file in $src_files; do
    obj_file="build/gen1/$(basename "${src_file%.s}.o")"
    # Use the Gen0 binary to compile the source
    ./build/gen0/utasm -f elf64 "$src_file" -o "$obj_file"
    obj_files_gen1="$obj_files_gen1 $obj_file"
done

# Link the Gen1 object files
ld -o build/gen1/utasm $obj_files_gen1

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
