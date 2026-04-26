/*
 ============================================================================
 File        : src/arch/riscv64/table.s
 Project     : utasm
 Version     : 0.1.0
 Description : Technical RISC-V 64-bit Mnemonic and Register Lookup Tables.
 ============================================================================
*/

%include "include/arch/riscv64.s"

[SECTION .rodata]
align 8

global riscv64_mnemonic_table
riscv64_mnemonic_table:
    // ---- RV64I Base Integer ----
    mnemonic_entry "add",   3, RV_OP_ADD
    mnemonic_entry "sub",   3, RV_OP_SUB
    mnemonic_entry "addi",  3, RV_OP_ADDI
    mnemonic_entry "slt",   3, 210
    mnemonic_entry "sltu",  3, 211
    mnemonic_entry "xor",   3, 212
    mnemonic_entry "or",    3, 213
    mnemonic_entry "and",   3, 214
    mnemonic_entry "sll",   3, 215
    mnemonic_entry "srl",   3, 216
    mnemonic_entry "sra",   3, 217
    mnemonic_entry "slti",  3, 218
    mnemonic_entry "sltui", 3, 219
    mnemonic_entry "xori",  3, 220
    mnemonic_entry "ori",   3, 221
    mnemonic_entry "andi",  3, 222
    mnemonic_entry "slli",  3, 223
    mnemonic_entry "srli",  3, 224
    mnemonic_entry "srai",  3, 225
    mnemonic_entry "lui",   2, 226
    mnemonic_entry "auipc", 2, 227
    
    // ---- RV64I Control Transfer ----
    mnemonic_entry "jal",   2, RV_OP_JAL
    mnemonic_entry "jalr",  3, 228
    mnemonic_entry "beq",   3, RV_OP_BEQ
    mnemonic_entry "bne",   3, 229
    mnemonic_entry "blt",   3, 230
    mnemonic_entry "bge",   3, 231
    mnemonic_entry "bltu",  3, 232
    mnemonic_entry "bgeu",  3, 233
    
    // ---- RV64I Load/Store ----
    mnemonic_entry "lb",    2, 234
    mnemonic_entry "lh",    2, 235
    mnemonic_entry "lw",    2, 236
    mnemonic_entry "ld",    2, RV_OP_LD
    mnemonic_entry "lbu",   2, 237
    mnemonic_entry "lhu",   2, 238
    mnemonic_entry "lwu",   2, 239
    mnemonic_entry "sb",    2, 240
    mnemonic_entry "sh",    2, 241
    mnemonic_entry "sw",    2, 242
    mnemonic_entry "sd",    2, RV_OP_SD
    
    // ---- RV64M Multiply/Divide ----
    mnemonic_entry "mul",    3, 243
    mnemonic_entry "mulh",   3, 244
    mnemonic_entry "mulhsu", 3, 245
    mnemonic_entry "mulhu",  3, 246
    mnemonic_entry "div",    3, 247
    mnemonic_entry "divu",   3, 248
    mnemonic_entry "rem",    3, 249
    mnemonic_entry "remu",   3, 250
    
    // ---- Misc ----
    mnemonic_entry "li",      2, RV_OP_LI
    mnemonic_entry "la",      2, 251
    mnemonic_entry "nop",     0, 252
    mnemonic_entry "ecall",   0, 253
    mnemonic_entry "ebreak",  0, 254
    mnemonic_entry "fence",   0, 255
    
    dq 0

global riscv64_register_table
riscv64_register_table:
    // ---- Core Registers (x0-x31) ----
    %assign i 0
    %rep 32
        compile_time_hash "x%[i]", H_X%[i]
        dq H_X%[i], (8 << 8) | %[i]
        %assign i i+1
    %endrep

    // ---- ABI Names ----
    compile_time_hash "zero", H_ZERO
    dq H_ZERO, (8 << 8) | 0
    compile_time_hash "ra",   H_RA
    dq H_RA,   (8 << 8) | 1
    compile_time_hash "sp",   H_SP_RV
    dq H_SP_RV, (8 << 8) | 2
    compile_time_hash "gp",   H_GP
    dq H_GP,   (8 << 8) | 3
    compile_time_hash "tp",   H_TP
    dq H_TP,   (8 << 8) | 4
    
    %assign i 0
    %rep 3
        compile_time_hash "t%[i]", H_T%[i]
        dq H_T%[i], (8 << 8) | (5 + %[i])
        %assign i i+1
    %endrep
    
    compile_time_hash "s0", H_S0
    dq H_S0, (8 << 8) | 8
    compile_time_hash "fp", H_FP_RV
    dq H_FP_RV, (8 << 8) | 8
    compile_time_hash "s1", H_S1
    dq H_S1, (8 << 8) | 9
    
    %assign i 0
    %rep 8
        compile_time_hash "a%[i]", H_A%[i]
        dq H_A%[i], (8 << 8) | (10 + %[i])
        %assign i i+1
    %endrep

    // ---- Floating Point (f0-f31) ----
    %assign i 0
    %rep 32
        compile_time_hash "f%[i]", H_F%[i]
        dq H_F%[i], (8 << 8) | (64 + %[i])
        %assign i i+1
    %endrep

    dq 0
