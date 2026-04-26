/*
 ============================================================================
 File        : src/arch/aarch64/table.s
 Project     : utasm
 Version     : 0.1.0
 Description : AArch64 Mnemonic and Register Lookup Tables.
 ============================================================================
*/

%include "include/arch/aarch64.s"

[SECTION .rodata]
align 8

global aarch64_mnemonic_table
aarch64_mnemonic_table:
    mnemonic_entry "mov", 2, ARM_OP_MOV
    mnemonic_entry "add", 2, ARM_OP_ADD
    mnemonic_entry "sub", 2, ARM_OP_SUB
    mnemonic_entry "ret", 0, ARM_OP_RET
    mnemonic_entry "b",   1, ARM_OP_B
    mnemonic_entry "bl",  1, ARM_OP_BL
    mnemonic_entry "cmp", 2, ARM_OP_CMP
    mnemonic_entry "eor", 2, ARM_OP_EOR
    mnemonic_entry "ldr", 2, ARM_OP_LDR
    mnemonic_entry "str", 2, ARM_OP_STR
    dq 0

global aarch64_register_table
aarch64_register_table:
    %assign i 0
    %rep 31
        %def str_x x%[i]
        compile_time_hash "x%[i]", H_X%[i]
        dq H_X%[i], (8 << 8) | %[i]
        %assign i i+1
    %endrep
    
    compile_time_hash "xzr", H_XZR
    dq H_XZR, (8 << 8) | 31
    compile_time_hash "sp", H_SP
    dq H_SP, (8 << 8) | 32
    dq 0
