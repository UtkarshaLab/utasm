/*
 ============================================================================
 File        : include/arch/riscv64.s
 Project     : utasm
 Version     : 0.1.0
 Description : RISC-V 64-bit Architecture Constants and Register IDs.
 ============================================================================
*/

// ---- 64-bit GPRs (x0-x31) ----------------
%assign i 0
%rep 32
    %def REG_X%[i]          %[i]
    %assign i i+1
%endrep

// ---- ABI Names ---------------------------
%def REG_ZERO               0
%def REG_RA                 1
%def REG_SP                 2
%def REG_GP                 3
%def REG_TP                 4
%def REG_T0                 5
%def REG_T1                 6
%def REG_T2                 7
%def REG_S0                 8
%def REG_FP                 8
%def REG_S1                 9
%def REG_A0                 10
%def REG_A1                 11

// ---- Mnemonic IDs (RISC-V Specific) ------
%def RV_OP_ADD              200
%def RV_OP_SUB              201
%def RV_OP_ADDI             202
%def RV_OP_LD               203
%def RV_OP_SD               204
%def RV_OP_BEQ              205
%def RV_OP_JAL              206
%def RV_OP_LI               207
