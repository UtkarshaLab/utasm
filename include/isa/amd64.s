/*
 ============================================================================
 File        : include/arch/amd64.s
 Project     : utasm
 Version     : 0.1.0
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

// ---- SIMD Registers (XMM) ----------------
%def REG_XMM0               16
%def REG_XMM1               17
%def REG_XMM2               18
%def REG_XMM3               19
%def REG_XMM4               20
%def REG_XMM5               21
%def REG_XMM6               22
%def REG_XMM7               23

// ---- Segment Registers -------------------
%def REG_CS                 24
%def REG_DS                 25
%def REG_ES                 26
%def REG_FS                 27
%def REG_GS                 28
%def REG_SS                 29

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
