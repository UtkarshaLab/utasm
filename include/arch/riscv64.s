/*
 ============================================================================
 File        : include/arch/riscv64.s
 Project     : utasm
 Version     : 0.1.0
 Description : RISC-V 64-bit Architecture Constants and Register IDs.
               Aligned with src/isa/riscv64.s IDs.
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
// These must match the IDs in src/isa/riscv64.s exactly.
%def ID_RV_ADD              3000
%def ID_RV_ADDI             3001
%def ID_RV_ADDIW            3002
%def ID_RV_ADDW             3003
%def ID_RV_AND              3022
%def ID_RV_ANDI             3023
%def ID_RV_AUIPC            3025
%def ID_RV_BEQ              3026
%def ID_RV_BGE              3027
%def ID_RV_BGEU             3028
%def ID_RV_BGT              3029
%def ID_RV_BGTU             3030
%def ID_RV_BLE              3031
%def ID_RV_BLEU             3032
%def ID_RV_BLT              3033
%def ID_RV_BLTU             3034
%def ID_RV_BNE              3035
%def ID_RV_DIV              3097
%def ID_RV_DIVU             3099
%def ID_RV_DIVUW            3100
%def ID_RV_DIVW             3101
%def ID_RV_JAL              3201
%def ID_RV_JALR             3202
%def ID_RV_LB               3206
%def ID_RV_LBU              3207
%def ID_RV_LD               3208
%def ID_RV_LH               3210
%def ID_RV_LHU              3211
%def ID_RV_LI               3213
%def ID_RV_LUI              3219
%def ID_RV_LW               3220
%def ID_RV_LWU              3221
%def ID_RV_MUL              3245
%def ID_RV_MULH             3246
%def ID_RV_MULHSU           3247
%def ID_RV_MULHU            3248
%def ID_RV_MULW             3249
%def ID_RV_OR               3257
%def ID_RV_ORI              3258
%def ID_RV_REM              3305
%def ID_RV_REMU             3306
%def ID_RV_REMUW            3307
%def ID_RV_REMW             3308
%def ID_RV_SB               3327
%def ID_RV_SD               3328
%def ID_RV_SH               3340
%def ID_RV_SLL              3348
%def ID_RV_SLLI             3349
%def ID_RV_SLLIW            3350
%def ID_RV_SLLW             3351
%def ID_RV_SLT              3352
%def ID_RV_SLTI             3353
%def ID_RV_SLTIU            3354
%def ID_RV_SLTU             3355
%def ID_RV_SRA              3361
%def ID_RV_SRAI             3362
%def ID_RV_SRAIW            3363
%def ID_RV_SRAW             3364
%def ID_RV_SRL              3365
%def ID_RV_SRLI             3366
%def ID_RV_SRLIW            3367
%def ID_RV_SRLW             3368
%def ID_RV_SUB              3370
%def ID_RV_SUBW             3371
%def ID_RV_SW               3372
%def ID_RV_XOR              3775
%def ID_RV_CSRRW            3091
%def ID_RV_CSRRS            3089
%def ID_RV_CSRRC            3087
%def ID_RV_CSRRWI           3092
%def ID_RV_CSRRSI           3090
%def ID_RV_CSRRCI           3088
%def ID_RV_FADD_S           3128
%def ID_RV_FADD_D           3129
%def ID_RV_FSUB_S           3177
%def ID_RV_FSUB_D           3178
%def ID_RV_FMUL_S           3161
%def ID_RV_FMUL_D           3162
%def ID_RV_FDIV_S           3156
%def ID_RV_FDIV_D           3157
%def ID_RV_XORI             3776
