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
    // ---- Data Transfer ----
    mnemonic_entry "mov", 2, OP_MOV
    mnemonic_entry "movsx", 2, 17
    mnemonic_entry "movzx", 2, 18
    mnemonic_entry "xchg", 2, 19
    mnemonic_entry "lea", 2, OP_LEA
    mnemonic_entry "push", 1, OP_PUSH
    mnemonic_entry "pop", 1, OP_POP
    
    // ---- Arithmetic ----
    mnemonic_entry "add", 2, OP_ADD
    mnemonic_entry "sub", 2, OP_SUB
    mnemonic_entry "adc", 2, 20
    mnemonic_entry "sbb", 2, 21
    mnemonic_entry "mul", 1, 22
    mnemonic_entry "imul", 2, 23
    mnemonic_entry "div", 1, 24
    mnemonic_entry "idiv", 1, 25
    mnemonic_entry "inc", 1, OP_INC
    mnemonic_entry "dec", 1, OP_DEC
    mnemonic_entry "neg", 1, 26
    
    // ---- Logic ----
    mnemonic_entry "and", 2, 27
    mnemonic_entry "or", 2, 28
    mnemonic_entry "xor", 2, OP_XOR
    mnemonic_entry "not", 1, 29
    mnemonic_entry "shl", 2, 30
    mnemonic_entry "shr", 2, 31
    mnemonic_entry "sal", 2, 32
    mnemonic_entry "sar", 2, 33
    mnemonic_entry "rol", 2, 34
    mnemonic_entry "ror", 2, 35
    
    // ---- Comparison & Control ----
    mnemonic_entry "cmp", 2, OP_CMP
    mnemonic_entry "test", 2, 36
    mnemonic_entry "jmp", 1, OP_JMP
    mnemonic_entry "call", 1, OP_CALL
    mnemonic_entry "ret", 0, OP_RET
    
    // ---- Jcc (Jump on Condition) ----
    mnemonic_entry "je", 1, 37
    mnemonic_entry "jne", 1, 38
    mnemonic_entry "jz", 1, 39
    mnemonic_entry "jnz", 1, 40
    mnemonic_entry "jg", 1, 41
    mnemonic_entry "jge", 1, 42
    mnemonic_entry "jl", 1, 43
    mnemonic_entry "jle", 1, 44
    mnemonic_entry "ja", 1, 45
    mnemonic_entry "jae", 1, 46
    mnemonic_entry "jb", 1, 47
    mnemonic_entry "jbe", 1, 48
    mnemonic_entry "js", 1, 49
    mnemonic_entry "jns", 1, 50
    mnemonic_entry "jo", 1, 51
    mnemonic_entry "jno", 1, 52
    mnemonic_entry "jc", 1, 53
    mnemonic_entry "jnc", 1, 54
    
    // ---- Misc ----
    mnemonic_entry "nop", 0, OP_NOP
    mnemonic_entry "int", 1, 55
    mnemonic_entry "int3", 0, OP_INT3
    mnemonic_entry "hlt", 0, 56
    mnemonic_entry "syscall", 0, OP_SYSCALL
    mnemonic_entry "sysret", 0, 57
    mnemonic_entry "cpuid", 0, 58
    mnemonic_entry "clc", 0, 59
    mnemonic_entry "stc", 0, 60
    mnemonic_entry "cli", 0, 61
    mnemonic_entry "sti", 0, 62
    
    // ---- SSE/AVX Essentials ----
    mnemonic_entry "movaps", 2, 100
    mnemonic_entry "movups", 2, 101
    mnemonic_entry "addps", 2, 102
    mnemonic_entry "subps", 2, 103
    mnemonic_entry "mulps", 2, 104
    mnemonic_entry "divps", 2, 105
    mnemonic_entry "addss", 2, 106
    mnemonic_entry "subss", 2, 107
    mnemonic_entry "mulss", 2, 108
    mnemonic_entry "divss", 2, 109
    mnemonic_entry "xorps", 2, 110
    mnemonic_entry "andps", 2, 111
    mnemonic_entry "orps", 2, 112
    
    dq 0

global amd64_register_table
amd64_register_table:
    // ---- 64-bit GPRs ----
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

    // ---- 32-bit GPRs ----
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
    
    // ---- 16-bit GPRs ----
    compile_time_hash "ax", H_AX
    dq H_AX, (2 << 8) | REG_RAX
    compile_time_hash "cx", H_CX
    dq H_CX, (2 << 8) | REG_RCX
    compile_time_hash "dx", H_DX
    dq H_DX, (2 << 8) | REG_RDX
    compile_time_hash "bx", H_BX
    dq H_BX, (2 << 8) | REG_RBX
    
    // ---- 8-bit GPRs ----
    compile_time_hash "al", H_AL
    dq H_AL, (1 << 8) | REG_RAX
    compile_time_hash "cl", H_CL
    dq H_CL, (1 << 8) | REG_RCX
    compile_time_hash "dl", H_DL
    dq H_DL, (1 << 8) | REG_RDX
    compile_time_hash "bl", H_BL
    dq H_BL, (1 << 8) | REG_RBX

    // ---- SIMD (XMM) ----
    %assign i 0
    %rep 16
        compile_time_hash "xmm%[i]", H_XMM%[i]
        dq H_XMM%[i], (16 << 8) | (16 + %[i])
        %assign i i+1
    %endrep

    // ---- Control Registers ----
    compile_time_hash "cr0", H_CR0
    dq H_CR0, (8 << 8) | 100
    compile_time_hash "cr2", H_CR2
    dq H_CR2, (8 << 8) | 101
    compile_time_hash "cr3", H_CR3
    dq H_CR3, (8 << 8) | 102
    compile_time_hash "cr4", H_CR4
    dq H_CR4, (8 << 8) | 103

    // ---- Segments ----
    compile_time_hash "cs", H_CS
    dq H_CS, (2 << 8) | REG_CS
    compile_time_hash "ds", H_DS
    dq H_DS, (2 << 8) | REG_DS
    compile_time_hash "es", H_ES
    dq H_ES, (2 << 8) | REG_ES
    compile_time_hash "fs", H_FS
    dq H_FS, (2 << 8) | REG_FS
    compile_time_hash "gs", H_GS
    dq H_GS, (2 << 8) | REG_GS
    compile_time_hash "ss", H_SS
    dq H_SS, (2 << 8) | REG_SS

    dq 0
