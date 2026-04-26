/*
 ============================================================================
 File        : include/arch/aarch64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AArch64 Architecture Constants and Register IDs.
 ============================================================================
*/

// ---- 64-bit GPRs (X0-X30, XZR) -----------
%assign i 0
%rep 31
    %def REG_X%[i]          %[i]
    %assign i i+1
%endrep

%def REG_XZR                31
%def REG_SP                 32

// ---- Mnemonic IDs (AArch64 Specific) -----
%def ARM_OP_MOV             100
%def ARM_OP_ADD             101
%def ARM_OP_SUB             102
%def ARM_OP_RET             103
%def ARM_OP_B               104
%def ARM_OP_BL              105
%def ARM_OP_CMP             106
%def ARM_OP_EOR             107
%def ARM_OP_LDR             108
%def ARM_OP_STR             109
