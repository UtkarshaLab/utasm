;
; ============================================================================
; File        : include/arch/aarch64.s
; Project     : utasm
; Description : AArch64 Architecture Constants and Register IDs.
               Aligned with src/isa/aarch64.s IDs.
; ============================================================================
;

; ---- 64-bit GPRs (X0-X30, XZR) -----------
%assign i 0
%rep 31
    %define REG_X%[i]          %[i]
    %assign i i+1
%endrep

%define REG_XZR                31
%define REG_SP                 32

; ---- Shift Types -------------------------
%define SHIFT_LSL              0
%define SHIFT_LSR              1
%define SHIFT_ASR              2
%define SHIFT_ROR              3

; ---- Mnemonic IDs (AArch64 Specific) -----
; These must match the IDs in src/isa/aarch64.s exactly.
%define ID_AARCH64_ABS         2000
%define ID_AARCH64_ADCLB       2001
%define ID_AARCH64_ADCLT       2002
%define ID_AARCH64_ADD         2003
%define ID_AARCH64_ADR         2020
%define ID_AARCH64_ADRP        2650
%define ID_AARCH64_AND         2027
%define ID_AARCH64_ANDS        2029
%define ID_AARCH64_ASR         2031
%define ID_AARCH64_B           2034
%define ID_AARCH64_BIC         2076
%define ID_AARCH64_BICS        2077
%define ID_AARCH64_BL          2080
%define ID_AARCH64_BLR         2081
%define ID_AARCH64_BR          2083
%define ID_AARCH64_CBNZ        2098
%define ID_AARCH64_CBZ         2099
%define ID_AARCH64_CMP         2108
%define ID_AARCH64_EON         2140
%define ID_AARCH64_EOR         2141
%define ID_AARCH64_LDP         2241
%define ID_AARCH64_LDR         2246
%define ID_AARCH64_LSL         2308
%define ID_AARCH64_LSR         2309
%define ID_AARCH64_MOV         2324
%define ID_AARCH64_MOVK        2325
%define ID_AARCH64_MOVN        2326
%define ID_AARCH64_MOVZ        2327
%define ID_AARCH64_NOP         2347
%define ID_AARCH64_ORN         2356
%define ID_AARCH64_ORR         2357
%define ID_AARCH64_RET         2451
%define ID_AARCH64_ROR         2461
%define ID_AARCH64_STP         2549
%define ID_AARCH64_STR         2554
%define ID_AARCH64_SUB         2569
%define ID_AARCH64_SUBS        2571
%define ID_AARCH64_SVC         2576
%define ID_AARCH64_TBNZ        2583
%define ID_AARCH64_TBZ         2584
%define ID_AARCH64_TST         2602
%define ID_AARCH64_MRS         2328
%define ID_AARCH64_MSR         2330
%define ID_AARCH64_DSB         2133
%define ID_AARCH64_DMB         2131
%define ID_AARCH64_ISB         2228
%define ID_AARCH64_WFI         2617
%define ID_AARCH64_HLT         2176
%define ID_AARCH64_UBFM        2605
%define ID_AARCH64_SBFM        2501
%define ID_AARCH64_BFM         2074
%define ID_AARCH64_ADD_V       2800
%define ID_AARCH64_SUB_V       2801
%define ID_AARCH64_AND_V       2802
%define ID_AARCH64_ORR_V       2803
%define ID_AARCH64_EOR_V       2804

;*
; * [def_mnc]
; * Purpose: AArch64-specific wrapper for the global mnemonic_entry macro.
; ;
%macro def_mnc 3
    mnemonic_entry %1, %2, %3
%endmacro
