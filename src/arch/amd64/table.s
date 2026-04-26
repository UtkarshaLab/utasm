/*
 ============================================================================
 File        : src/arch/amd64/table.s
 Project     : utasm
 Version     : 0.1.0
 Description : AMD64 Mnemonic and Register Lookup Tables.
 ============================================================================
*/

%include "include/arch/amd64.s"

[SECTION .rodata]
align 8

global amd64_mnemonic_table
amd64_mnemonic_table:
    mnemonic_entry "mov", 2, OP_MOV
    mnemonic_entry "add", 2, OP_ADD
    mnemonic_entry "sub", 2, OP_SUB
    mnemonic_entry "ret", 0, OP_RET
    mnemonic_entry "jmp", 1, OP_JMP
    mnemonic_entry "call", 1, OP_CALL
    mnemonic_entry "cmp", 2, OP_CMP
    mnemonic_entry "xor", 2, OP_XOR
    mnemonic_entry "lea", 2, OP_LEA
    mnemonic_entry "push", 1, OP_PUSH
    mnemonic_entry "pop", 1, OP_POP
    mnemonic_entry "inc", 1, OP_INC
    mnemonic_entry "dec", 1, OP_DEC
    mnemonic_entry "nop", 0, OP_NOP
    mnemonic_entry "int3", 0, OP_INT3
    mnemonic_entry "syscall", 0, OP_SYSCALL
    dq 0

global amd64_register_table
amd64_register_table:
    // ---- 64-bit ----
    compile_time_hash "rax", H_RAX
    dq H_RAX, (8 << 8) | REG_RAX
    compile_time_hash "rcx", H_RCX
    dq H_RCX, (8 << 8) | REG_RCX
    compile_time_hash "rdx", H_RDX
    dq H_RDX, (8 << 8) | REG_RDX
    compile_time_hash "rbx", H_RBX
    dq H_RBX, (8 << 8) | REG_RBX
    compile_time_hash "rsp", H_RSP
    dq H_RSP, (8 << 8) | REG_RSP
    compile_time_hash "rbp", H_RBP
    dq H_RBP, (8 << 8) | REG_RBP
    compile_time_hash "rsi", H_RSI
    dq H_RSI, (8 << 8) | REG_RSI
    compile_time_hash "rdi", H_RDI
    dq H_RDI, (8 << 8) | REG_RDI
    compile_time_hash "r8",  H_R8
    dq H_R8,  (8 << 8) | REG_R8
    compile_time_hash "r9",  H_R9
    dq H_R9,  (8 << 8) | REG_R9
    compile_time_hash "r10", H_R10
    dq H_R10, (8 << 8) | REG_R10
    compile_time_hash "r11", H_R11
    dq H_R11, (8 << 8) | REG_R11
    compile_time_hash "r12", H_R12
    dq H_R12, (8 << 8) | REG_R12
    compile_time_hash "r13", H_R13
    dq H_R13, (8 << 8) | REG_R13
    compile_time_hash "r14", H_R14
    dq H_R14, (8 << 8) | REG_R14
    compile_time_hash "r15", H_R15
    dq H_R15, (8 << 8) | REG_R15

    // ---- 32-bit ----
    compile_time_hash "eax", H_EAX
    dq H_EAX, (4 << 8) | REG_RAX
    compile_time_hash "ecx", H_ECX
    dq H_ECX, (4 << 8) | REG_RCX
    compile_time_hash "edx", H_EDX
    dq H_EDX, (4 << 8) | REG_RDX
    compile_time_hash "ebx", H_EBX
    dq H_EBX, (4 << 8) | REG_RBX
    compile_time_hash "esi", H_ESI
    dq H_ESI, (4 << 8) | REG_RSI
    compile_time_hash "edi", H_EDI
    dq H_EDI, (4 << 8) | REG_RDI
    compile_time_hash "esp", H_ESP
    dq H_ESP, (4 << 8) | REG_RSP
    compile_time_hash "ebp", H_EBP
    dq H_EBP, (4 << 8) | REG_RBP

    // ---- SIMD (XMM) ----
    compile_time_hash "xmm0", H_XMM0
    dq H_XMM0, (16 << 8) | REG_XMM0
    compile_time_hash "xmm1", H_XMM1
    dq H_XMM1, (16 << 8) | REG_XMM1
    compile_time_hash "xmm2", H_XMM2
    dq H_XMM2, (16 << 8) | REG_XMM2
    compile_time_hash "xmm3", H_XMM3
    dq H_XMM3, (16 << 8) | REG_XMM3

    // ---- Segments ----
    compile_time_hash "cs", H_CS
    dq H_CS, (2 << 8) | REG_CS
    compile_time_hash "ds", H_DS
    dq H_DS, (2 << 8) | REG_DS
    compile_time_hash "fs", H_FS
    dq H_FS, (2 << 8) | REG_FS
    compile_time_hash "gs", H_GS
    dq H_GS, (2 << 8) | REG_GS

    dq 0
