/*
 ============================================================================
 File        : include/arch/amd64.s
 Project     : utasm
 Description : AMD64 Architecture Constants and Register IDs.
 ============================================================================
*/

// ---- 64-bit GPRs -------------------------
%def REG_RAX                0
%def REG_RCX                1
%def REG_RDX                2
%def REG_RBX                3
%def REG_RSP                4
%def REG_RBP                5
%def REG_RSI                6
%def REG_RDI                7
%def REG_R8                 8
%def REG_R9                 9
%def REG_R10                10
%def REG_R11                11
%def REG_R12                12
%def REG_R13                13
%def REG_R14                14
%def REG_R15                15

// ---- SIMD Registers (XMM/YMM/ZMM) --------
%def REG_ZMM0               80
%def REG_ZMM1               81
%def REG_ZMM2               82
%def REG_ZMM3               83
%def REG_ZMM4               84
%def REG_ZMM5               85
%def REG_ZMM6               86
%def REG_ZMM7               87
%assign i 8
%rep 24
    %def REG_ZMM%[i] 80+%[i]
    %assign i i+1
%endrep

// ---- Segment Registers -------------------
%def REG_CS                 24
%def REG_DS                 25
%def REG_ES                 26
%def REG_FS                 27
%def REG_GS                 28
%def REG_SS                 29

// ---- Control Registers (CR0-CR15) --------
%assign i 0
%rep 16
    %def REG_CR%[i] 32+%[i]
    %assign i i+1
%endrep

// ---- Debug Registers (DR0-DR15) ----------
%assign i 0
%rep 16
    %def REG_DR%[i] 48+%[i]
    %assign i i+1
%endrep

// ---- FPU Stack (ST0-ST7) -----------------
%assign i 0
%rep 8
    %def REG_ST%[i] 64+%[i]
    %assign i i+1
%endrep

// ---- Opmask Registers (K0-K7) ------------
%assign i 0
%rep 8
    %def REG_K%[i] 72+%[i]
    %assign i i+1
%endrep

// ---- Mnemonic IDs (AMD64 Specific) -------
%def OP_MOV                 1
%def OP_ADD                 2
%def OP_SUB                 3
%def OP_RET                 4
%def OP_JMP                 5
%def OP_CALL                6
%def OP_CMP                 7
%def OP_XOR                 8
%def OP_LEA                 9
%def OP_PUSH                10
%def OP_POP                 11
%def OP_INC                 12
%def OP_DEC                 13
%def OP_NOP                 14
%def OP_INT3                15
%def OP_SYSCALL             16
%def ID_VADDPS              3000
%def ID_VMOVUPS              3001
%def ID_VXORPS              3002
