/*
 ============================================================================
 File        : src/arch/aarch64/table.s
 Project     : utasm
 Version     : 0.1.0
 Description : Technical AArch64 Mnemonic and Register Lookup Tables.
 ============================================================================
*/

%include "include/arch/aarch64.s"

[SECTION .rodata]
align 8

global aarch64_mnemonic_table
aarch64_mnemonic_table:
    // ---- Data Processing (Arithmetic) ----
    mnemonic_entry "add",  3, ARM_OP_ADD
    mnemonic_entry "sub",  3, ARM_OP_SUB
    mnemonic_entry "adds", 3, 110
    mnemonic_entry "subs", 3, 111
    mnemonic_entry "mul",  3, 112
    mnemonic_entry "sdiv", 3, 113
    mnemonic_entry "udiv", 3, 114
    mnemonic_entry "madd", 4, 115
    mnemonic_entry "msub", 4, 116
    
    // ---- Data Processing (Logical) ----
    mnemonic_entry "and",  3, 117
    mnemonic_entry "orr",  3, 118
    mnemonic_entry "eor",  3, ARM_OP_EOR
    mnemonic_entry "ands", 3, 119
    mnemonic_entry "bic",  3, 120
    mnemonic_entry "mvn",  2, 121
    
    // ---- Data Processing (Shift/Rotate) ----
    mnemonic_entry "lsl",  3, 122
    mnemonic_entry "lsr",  3, 123
    mnemonic_entry "asr",  3, 124
    mnemonic_entry "ror",  3, 125
    
    // ---- Branching ----
    mnemonic_entry "b",    1, ARM_OP_B
    mnemonic_entry "bl",   1, ARM_OP_BL
    mnemonic_entry "br",   1, 126
    mnemonic_entry "blr",  1, 127
    mnemonic_entry "ret",  1, ARM_OP_RET
    mnemonic_entry "cbz",  2, 128
    mnemonic_entry "cbnz", 2, 129
    mnemonic_entry "tbz",  3, 130
    mnemonic_entry "tbnz", 3, 131
    
    // ---- Conditional Branch (B.cc) ----
    mnemonic_entry "b.eq", 1, 132
    mnemonic_entry "b.ne", 1, 133
    mnemonic_entry "b.cs", 1, 134
    mnemonic_entry "b.cc", 1, 135
    mnemonic_entry "b.mi", 1, 136
    mnemonic_entry "b.pl", 1, 137
    mnemonic_entry "b.vs", 1, 138
    mnemonic_entry "b.vc", 1, 139
    mnemonic_entry "b.hi", 1, 140
    mnemonic_entry "b.ls", 1, 141
    mnemonic_entry "b.ge", 1, 142
    mnemonic_entry "b.lt", 1, 143
    mnemonic_entry "b.gt", 1, 144
    mnemonic_entry "b.le", 1, 145
    
    // ---- Memory ----
    mnemonic_entry "ldr",  2, ARM_OP_LDR
    mnemonic_entry "str",  2, ARM_OP_STR
    mnemonic_entry "ldp",  3, 146
    mnemonic_entry "stp",  3, 147
    mnemonic_entry "ldur", 2, 148
    mnemonic_entry "stur", 2, 149
    mnemonic_entry "adr",  2, 150
    mnemonic_entry "adrp", 2, 151
    
    // ---- Comparison ----
    mnemonic_entry "cmp",  2, ARM_OP_CMP
    mnemonic_entry "cmn",  2, 152
    mnemonic_entry "tst",  2, 153
    
    // ---- Misc ----
    mnemonic_entry "mov",  2, ARM_OP_MOV
    mnemonic_entry "nop",  0, 154
    mnemonic_entry "svc",  1, 155
    mnemonic_entry "mrs",  2, 156
    mnemonic_entry "msr",  2, 157
    mnemonic_entry "isb",  0, 158
    mnemonic_entry "dsb",  1, 159
    mnemonic_entry "dmb",  1, 160
    
    dq 0

global aarch64_register_table
aarch64_register_table:
    // ---- 64-bit GPRs (X0-X30) ----
    %assign i 0
    %rep 31
        compile_time_hash "x%[i]", H_X%[i]
        dq H_X%[i], (8 << 8) | %[i]
        %assign i i+1
    %endrep
    
    // ---- 32-bit GPRs (W0-W30) ----
    %assign i 0
    %rep 31
        compile_time_hash "w%[i]", H_W%[i]
        dq H_W%[i], (4 << 8) | %[i]
        %assign i i+1
    %endrep

    // ---- Floating Point / Vector (V0-V31) ----
    %assign i 0
    %rep 32
        compile_time_hash "v%[i]", H_V%[i]
        dq H_V%[i], (16 << 8) | (64 + %[i])
        %assign i i+1
    %endrep

    // ---- Special ----
    compile_time_hash "xzr", H_XZR
    dq H_XZR, (8 << 8) | 31
    compile_time_hash "wzr", H_WZR
    dq H_WZR, (4 << 8) | 31
    compile_time_hash "sp",  H_SP
    dq H_SP,  (8 << 8) | 32
    compile_time_hash "pc",  H_PC
    dq H_PC,  (8 << 8) | 33
    
    dq 0
