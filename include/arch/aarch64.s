/*
 ============================================================================
 File        : include/arch/aarch64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AArch64 Architecture Constants and Register IDs.
               Aligned with src/isa/aarch64.s IDs.
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
// These must match the IDs in src/isa/aarch64.s exactly.
%def ID_AARCH64_ABS         2000
%def ID_AARCH64_ADCLB       2001
%def ID_AARCH64_ADCLT       2002
%def ID_AARCH64_ADD         2003
%def ID_AARCH64_ADR         2020
%def ID_AARCH64_ADRP        2650
%def ID_AARCH64_AND         2027
%def ID_AARCH64_ANDS        2029
%def ID_AARCH64_ASR         2031
%def ID_AARCH64_B           2034
%def ID_AARCH64_BIC         2076
%def ID_AARCH64_BICS        2077
%def ID_AARCH64_BL          2080
%def ID_AARCH64_BLR         2081
%def ID_AARCH64_BR          2083
%def ID_AARCH64_CBNZ        2098
%def ID_AARCH64_CBZ         2099
%def ID_AARCH64_CMP         2108
%def ID_AARCH64_EON         2140
%def ID_AARCH64_EOR         2141
%def ID_AARCH64_LDP         2241
%def ID_AARCH64_LDR         2246
%def ID_AARCH64_LSL         2308
%def ID_AARCH64_LSR         2309
%def ID_AARCH64_MOV         2324
%def ID_AARCH64_MOVK        2325
%def ID_AARCH64_MOVN        2326
%def ID_AARCH64_MOVZ        2327
%def ID_AARCH64_NOP         2347
%def ID_AARCH64_ORN         2356
%def ID_AARCH64_ORR         2357
%def ID_AARCH64_RET         2451
%def ID_AARCH64_ROR         2461
%def ID_AARCH64_STP         2549
%def ID_AARCH64_STR         2554
%def ID_AARCH64_SUB         2569
%def ID_AARCH64_SUBS        2571
%def ID_AARCH64_SVC         2576
%def ID_AARCH64_TBNZ        2583
%def ID_AARCH64_TBZ         2584
%def ID_AARCH64_TST         2602
%def ID_AARCH64_MRS         2328
%def ID_AARCH64_MSR         2330
%def ID_AARCH64_DSB         2133
%def ID_AARCH64_DMB         2131
%def ID_AARCH64_ISB         2228
%def ID_AARCH64_WFI         2617
%def ID_AARCH64_HLT         2176
%def ID_AARCH64_UBFM        2605
%def ID_AARCH64_SBFM        2501
%def ID_AARCH64_BFM         2074

/**
 * [define_mnemonic]
 * Purpose: AArch64-specific wrapper for the global mnemonic_entry macro.
 */
%macro define_mnemonic 3
    mnemonic_entry %1, %2, %3
%endmacro
