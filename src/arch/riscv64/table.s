/*
 ============================================================================
 File        : src/arch/riscv64/table.s
 Project     : utasm
 Version     : 0.1.0
 Description : RISC-V 64-bit Mnemonic and Register Lookup Tables.
 ============================================================================
*/

%include "include/arch/riscv64.s"

[SECTION .rodata]
align 8

global riscv64_mnemonic_table
riscv64_mnemonic_table:
    mnemonic_entry "add",  3, RV_OP_ADD
    mnemonic_entry "sub",  3, RV_OP_SUB
    mnemonic_entry "addi", 3, RV_OP_ADDI
    mnemonic_entry "ld",   2, RV_OP_LD
    mnemonic_entry "sd",   2, RV_OP_SD
    mnemonic_entry "beq",  3, RV_OP_BEQ
    mnemonic_entry "jal",  2, RV_OP_JAL
    mnemonic_entry "li",   2, RV_OP_LI
    dq 0

global riscv64_register_table
riscv64_register_table:
    %assign i 0
    %rep 32
        compile_time_hash "x%[i]", H_X%[i]
        dq H_X%[i], (8 << 8) | %[i]
        %assign i i+1
    %endrep

    // ABI Aliases
    compile_time_hash "zero", H_ZERO
    dq H_ZERO, (8 << 8) | 0
    compile_time_hash "ra",   H_RA
    dq H_RA,   (8 << 8) | 1
    compile_time_hash "sp",   H_SP_RV
    dq H_SP_RV, (8 << 8) | 2
    dq 0
