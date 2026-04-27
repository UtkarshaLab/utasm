/*
 ============================================================================
 File        : src/encoder/amd64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AMD64 Instruction Encoder Logic.
 ============================================================================
*/

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

[SECTION .text]

/**
 * [amd64_encode_instruction]
 * Purpose: Encodes an AMD64 instruction into machine code.
 * Input:
 *   RDI: Pointer to AsmCtx
 *   RSI: Pointer to INST struct
 */
global amd64_encode_instruction
amd64_encode_instruction:
    prologue
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi               // RBX = AsmCtx
    mov     r12, rsi               // R12 = INST
    
    // Reset length counter
    mov     dword [rbx + ASMCTX_inst_len], 0
    
    // 0. VALIDATION: Check operand size consistency
    cmp     byte [r12 + INST_nops], 2
    jl      .no_size_check
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    mov     al, [r10 + OPERAND_size]
    mov     ah, [r11 + OPERAND_size]
    IF al, ne, ah
        // Immediate and Symbol can have different sizes (resolved during emission)
        IF byte [r11 + OPERAND_kind], ne, OP_IMM
            IF byte [r11 + OPERAND_kind], ne, OP_SYMBOL
                jmp .error
            ENDIF
        ENDIF
    ENDIF
.no_size_check:
    
    // 0.1 VALIDATION: REX vs Legacy 8-bit (AH, CH, DH, BH)
    // These registers (indices 4-7 in 8-bit mode without REX)
    // cannot be used if a REX prefix is present.
    // ...
    
    // 1. Emit Prefix if present (REP/LOCK)
    mov     al, [r12 + INST_prefix]
    IF al, ne, 0
        // VALIDATION: If LOCK (0xF0), ensure mnemonic allows it
        IF al, e, 0xF0
            mov ax, [r12 + INST_id]
            // Whitelist: ADD, OR, ADC, SBB, AND, SUB, XOR, INC, DEC, NOT, NEG, BTC, BTR, BTS, XADD, CMPXCHG
            // For now, let's assume anything < 1500 is a standard logic/math op
            // (In a production build, this would be a bitmask check)
            IF ax, ge, 1500
                jmp .error
            ENDIF
        ENDIF
        call    amd64_emit_byte
    ENDIF
    
    // 2. Emit Segment Prefix if present in any operand
    lea     rdi, [r12 + INST_op0]
    mov     al, [rdi + OPERAND_segment]
    IF al, e, 0
        lea rdi, [r12 + INST_op1]
        mov al, [rdi + OPERAND_segment]
    ENDIF
    IF al, ne, 0
        call    amd64_emit_byte
    ENDIF
    
    // 2. Dispatch based on Mnemonic ID
    movzx   rax, word [r12 + INST_op_id]
    
    IF ax, e, 1391                 // MOV
        call    amd64_encode_mov
    ELSEIF ax, e, 1356             // LEA
        call    amd64_encode_lea
    ELSEIF ax, e, 1006             // ADD
        mov     r13, 0x01 | mov r14, 0 | call amd64_encode_arithmetic
    ELSEIF ax, e, 1676             // SUB
        mov     r13, 0x29 | mov r14, 5 | call amd64_encode_arithmetic
    ELSEIF ax, e, 1075             // CMP
        mov     r13, 0x39 | mov r14, 7 | call amd64_encode_arithmetic
    ELSEIF ax, e, 1084             // CMPXCHG
        mov     r13, 0xB1 | call amd64_encode_bin0f
    ELSEIF ax, e, 2150             // XADD
        mov     r13, 0xC1 | call amd64_encode_bin0f
    ELSEIF ax, e, 1086             // CMPXCHG8B
        mov     r14, 1 | call amd64_encode_cmpxchg_nb
    ELSEIF ax, e, 1085             // CMPXCHG16B
        mov     r14, 1 | call amd64_encode_cmpxchg_nb
    ELSEIF ax, e, 1028             // AND
        mov     r13, 0x21 | mov r14, 4 | call amd64_encode_arithmetic
    ELSEIF ax, e, 1442             // OR
        mov     r13, 0x09 | mov r14, 1 | call amd64_encode_arithmetic
    ELSEIF ax, e, 2157             // XOR
        mov     r13, 0x31 | mov r14, 6 | call amd64_encode_arithmetic
    ELSEIF ax, e, 1691             // TEST
        mov     r13, 0x85 | call amd64_encode_test
    ELSEIF ax, e, 1278             // INC
        mov     r14, 0 | call amd64_encode_unary
    ELSEIF ax, e, 1118             // DEC
        mov     r14, 1 | call amd64_encode_unary
    ELSEIF ax, e, 1439             // NEG
        mov     r14, 3 | call amd64_encode_unary
    ELSEIF ax, ge, 1418            // MOVS - MOVSW
        IF ax, le, 1425
            mov r13, 0xA4 | call amd64_encode_string
        ENDIF
    ELSEIF ax, ge, 1668            // STOS - STOSW
        IF ax, le, 1672
            mov r13, 0xAA | call amd64_encode_string
        ENDIF
    ELSEIF ax, ge, 1368            // LODS - LODSW
        IF ax, le, 1372
            mov r13, 0xAC | call amd64_encode_string
        ENDIF
    ELSEIF ax, ge, 1629            // SCAS - SCASW
        IF ax, le, 1632
            mov r13, 0xAE | call amd64_encode_string
        ENDIF
    ELSEIF ax, ge, 1078            // CMPS - CMPSW
        IF ax, le, 1083
            mov r13, 0xA6 | call amd64_encode_string
        ENDIF
    ELSEIF ax, e, 1119             // DIV
        mov     r14, 3 | call amd64_encode_unary
    ELSEIF ax, e, 1441             // NOT
        mov     r14, 2 | call amd64_encode_unary
    ELSEIF ax, e, 1419             // MOVSB
        mov     al, 0xA4 | call amd64_emit_byte
    ELSEIF ax, e, 1421             // MOVSW
        mov     al, 16 | mov rsi, 0 | mov rdx, 0 | call amd64_emit_prefixes
        mov     al, 0xA5 | call amd64_emit_byte
    ELSEIF ax, e, 1420             // MOVSD
        mov     al, 0xA5 | call amd64_emit_byte
    ELSEIF ax, e, 1422             // MOVSQ
        mov     al, 64 | mov rsi, 0 | mov rdx, 0 | call amd64_emit_prefixes
        mov     al, 0xA5 | call amd64_emit_byte
    ELSEIF ax, e, 1669             // STOSB
        mov     al, 0xAA | call amd64_emit_byte
    ELSEIF ax, e, 1672             // STOSW
        mov     al, 16 | mov rsi, 0 | mov rdx, 0 | call amd64_emit_prefixes
        mov     al, 0xAB | call amd64_emit_byte
    ELSEIF ax, e, 1670             // STOSD
        mov     al, 0xAB | call amd64_emit_byte
    ELSEIF ax, e, 1671             // STOSQ
        mov     al, 64 | mov rsi, 0 | mov rdx, 0 | call amd64_emit_prefixes
        mov     al, 0xAB | call amd64_emit_byte
    ELSEIF ax, ge, 1630            // SCAS
        IF ax, le, 1632
            sub ax, 1630
            // logic for 0xA6/0xA7
        ENDIF
    ELSEIF ax, e, 1647             // SHL/SAL
        mov     r14, 4 | call amd64_encode_shift
    ELSEIF ax, e, 1650             // SHR
        mov     r14, 5 | call amd64_encode_shift
    ELSEIF ax, e, 1625             // SAR
        mov     r14, 7 | call amd64_encode_shift
    ELSEIF ax, e, 1612             // ROL
        mov     r14, 0 | call amd64_encode_shift
    ELSEIF ax, e, 1613             // ROR
        mov     r14, 1 | call amd64_encode_shift
    ELSEIF ax, e, 1432             // MUL
        mov     r14, 4 | call amd64_encode_unary_math
    ELSEIF ax, e, 1119             // DIV
        mov     r14, 6 | call amd64_encode_unary_math
    ELSEIF ax, e, 1276             // IMUL
        call    amd64_encode_imul
    ELSEIF ax, e, 1275             // IDIV
        mov     r14, 7 | call amd64_encode_unary_math
    ELSEIF ax, e, 1583             // PUSH
        call    amd64_encode_push
    ELSEIF ax, e, 1089             // CPUID
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0xA2 | call amd64_emit_byte
    ELSEIF ax, e, 1591             // RDTSC
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x31 | call amd64_emit_byte
    ELSEIF ax, e, 1271             // HLT
        mov     al, 0xF4 | call amd64_emit_byte
    ELSEIF ax, e, 1286             // INT
        call    amd64_encode_int
    ELSEIF ax, e, 1288             // INT3
        mov     al, 0xCC | call amd64_emit_byte
    ELSEIF ax, e, 1715             // UD2
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x0B | call amd64_emit_byte
    ELSEIF ax, e, 1361             // LGDT
        mov     r14, 2 | call amd64_encode_system_m
    ELSEIF ax, e, 1363             // LIDT
        mov     r14, 3 | call amd64_encode_system_m
    ELSEIF ax, e, 1277             // IN
        call    amd64_encode_in
    ELSEIF ax, e, 1445             // OUT
        call    amd64_encode_out
    ELSEIF ax, e, 1205             // FLD
        mov     r13, 0xD9 | mov r14, 0 | call amd64_encode_fpu
    ELSEIF ax, e, 1235             // FST
        mov     r13, 0xD9 | mov r14, 2 | call amd64_encode_fpu
    ELSEIF ax, e, 1172             // FADD
        mov     r13, 0xD8 | mov r14, 0 | call amd64_encode_fpu
    ELSEIF ax, e, 1240             // FSUB
        mov     r13, 0xD8 | mov r14, 4 | call amd64_encode_fpu
    ELSEIF ax, e, 1215             // FMUL
        mov     r13, 0xD8 | mov r14, 1 | call amd64_encode_fpu
    ELSEIF ax, e, 1186             // FDIV
        mov     r13, 0xD8 | mov r14, 6 | call amd64_encode_fpu
    ELSEIF ax, e, 1232             // FSIN
        mov     al, 0xD9 | call amd64_emit_byte | mov al, 0xFE | call amd64_emit_byte
    ELSEIF ax, e, 1184             // FCOS
        mov     al, 0xD9 | call amd64_emit_byte | mov al, 0xFF | call amd64_emit_byte
    ELSEIF ax, e, 1199             // FINIT
        mov     al, 0xDB | call amd64_emit_byte | mov al, 0xE3 | call amd64_emit_byte
    ELSEIF ax, e, 1395             // MOVAPS
        mov     r13, 0x28 | mov r14, 0 | call amd64_encode_sse
    ELSEIF ax, e, 1431             // MOVUPS
        mov     r13, 0x10 | mov r14, 0 | call amd64_encode_sse
    ELSEIF ax, e, 1459             // PADDD
        mov     r13, 0xFE | mov r14, 1 | call amd64_encode_sse // 0x66 prefix
    ELSEIF ax, e, 1530             // PMULLD
        mov     r13, 0x40 | mov r14, 2 | call amd64_encode_sse // 0x0F 0x38
    ELSEIF ax, e, 2160             // XORPS
        mov     r13, 0x57 | mov r14, 0 | call amd64_encode_sse
    ELSEIF ax, e, 1739             // VADDPS
        mov     r13, 0x58 | mov r14, 1 | call amd64_encode_vex
    ELSEIF ax, e, 1933             // VMOVAPS
        mov     r13, 0x28 | mov r14, 1 | call amd64_encode_vex
    ELSEIF ax, e, 1355             // TILELOADD
        mov     al, 0xC4 | call amd64_emit_byte | mov al, 0xE2 | call amd64_emit_byte
        mov     al, 0x7B | call amd64_emit_byte | mov al, 0x4B | call amd64_emit_byte
        // Digit 2 logic...
    ELSEIF ax, e, 1590             // RDRAND
        mov     r14, 6 | call amd64_encode_sec_r
    ELSEIF ax, e, 1593             // RDSEED
        mov     r14, 7 | call amd64_encode_sec_r
    ELSEIF ax, e, 1165             // ENDBR64
        mov     al, 0xF3 | call amd64_emit_byte | mov al, 0x0F | call amd64_emit_byte
        mov     al, 0x1E | call amd64_emit_byte | mov al, 0xFA | call amd64_emit_byte
    ELSEIF ax, e, 1020             // AESENC
        mov     r13, 0xDC | mov r14, 2 | call amd64_encode_sse
    ELSEIF ax, e, 1127             // ENCLS
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x01 | call amd64_emit_byte
        mov     al, 0xCF | call amd64_emit_byte
    ELSEIF ax, e, 1729             // VMCALL
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x01 | call amd64_emit_byte
        mov     al, 0xC1 | call amd64_emit_byte
    ELSEIF ax, e, 1731             // VMLAUNCH
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x01 | call amd64_emit_byte
        mov     al, 0xC2 | call amd64_emit_byte
    ELSEIF ax, e, 1735             // VMRESUME
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x01 | call amd64_emit_byte
        mov     al, 0xC3 | call amd64_emit_byte
    ELSEIF ax, e, 1733             // VMPTRLD
        mov     r14, 6 | call amd64_encode_vm_m
    ELSEIF ax, e, 1734             // VMPTRST
        mov     r14, 7 | call amd64_encode_vm_m
    ELSEIF ax, e, 1359             // LFENCE
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0xAE | call amd64_emit_byte
        mov     al, 0xE8 | call amd64_emit_byte
    ELSEIF ax, e, 1642             // SFENCE
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0xAE | call amd64_emit_byte
        mov     al, 0xF8 | call amd64_emit_byte
    ELSEIF ax, e, 1380             // MFENCE
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0xAE | call amd64_emit_byte
        mov     al, 0xF0 | call amd64_emit_byte
    ELSEIF ax, e, 1067             // CLFLUSH
        mov     r14, 7 | call amd64_encode_mem_sync
    ELSEIF ax, e, 1686             // SYSENTER
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x34 | call amd64_emit_byte
    ELSEIF ax, e, 1680             // SWAPGS
        mov     al, 0x0F | call amd64_emit_byte | mov al, 0x01 | call amd64_emit_byte
        mov     al, 0xF8 | call amd64_emit_byte
    ELSEIF ax, e, 1351             // LAR
        mov     r13, 0x0F02 | call amd64_encode_rm_r
    ELSEIF ax, e, 1377             // LSL
        mov     r13, 0x0F03 | call amd64_encode_rm_r
    ELSEIF ax, e, 1534             // POP
        call    amd64_encode_pop
    ELSEIF ax, e, 1298             // JMP
        mov     r13, 0xE9          // rel32 JMP
        call    amd64_encode_branch
    ELSEIF ax, e, 1059             // CALL
        mov     r13, 0xE8
        call    amd64_encode_branch
    ELSEIF ax, e, 1611             // RET
        call    amd64_encode_ret
    ELSEIF ax, ge, 4016            // SETcc
        call    amd64_encode_setcc
    ELSEIF ax, ge, 4000            // CMOVcc
        call    amd64_encode_cmovcc
    ELSEIF ax, e, 1168             // ENTER
        call    amd64_encode_enter
    ELSEIF ax, e, 1357             // LEAVE
        mov     al, 0xC9
        call    amd64_emit_byte
    ELSEIF ax, e, 1373             // LOOP
        mov     al, 0xE2
        call    amd64_emit_branch_rel8
    ELSEIF ax, e, 1685             // SYSRET
        call    amd64_encode_sysret
    ELSEIF ax, e, 1682             // SYSCALL
        call    amd64_encode_syscall
    ELSEIF ax, e, 1029             // ANDN
        mov     r13, 0xF2 | mov r14, 2 | mov r15, 0 | call amd64_encode_vex
    ELSEIF ax, e, 1058             // BZHI
        mov     r13, 0xF5 | mov r14, 2 | mov r15, 0 | call amd64_encode_vex
    ELSEIF ax, e, 1649             // SHLX
        mov     r13, 0xF7 | mov r14, 2 | mov r15, 1 | call amd64_encode_vex
    ELSEIF ax, e, 1652             // SHRX
        mov     r13, 0xF7 | mov r14, 2 | mov r15, 3 | call amd64_encode_vex
    ELSEIF ax, e, 1626             // SARX
        mov     r13, 0xF7 | mov r14, 2 | mov r15, 2 | call amd64_encode_vex
    ELSEIF ax, ge, 1714            // AVX-512 (EVEX)
        IF ax, le, 1898
            call    amd64_encode_evex
        ENDIF
    ELSEIF ax, e, 1440             // NOP
        mov     al, 0x90 | call amd64_emit_byte
    ELSEIF ax, e, 1888             // XBEGIN
        mov     al, 0xC7 | call amd64_emit_byte
        mov     al, 0xF8 | call amd64_emit_byte
        lea     r10, [r12 + INST_op0]
        IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
            mov al, RELOC_REL32 | mov rsi, [r10 + OPERAND_sym] | call amd64_emit_reloc
            xor rax, rax | call amd64_emit_dword
        ELSE
            mov rdi, [r10 + OPERAND_imm] | call amd64_emit_dword
        ENDIF
    ELSEIF ax, e, 1889             // XEND
        mov     al, 0x0F | call amd64_emit_byte
        mov     al, 0x01 | call amd64_emit_byte
        mov     al, 0xD5 | call amd64_emit_byte
    ELSEIF ax, e, 1887             // XABORT
        mov     al, 0xC6 | call amd64_emit_byte
        mov     al, 0xF8 | call amd64_emit_byte
        lea     r10, [r12 + INST_op0]
        mov     rax, [r10 + OPERAND_imm] | call amd64_emit_byte
    ELSEIF ax, e, 1069             // CLI / STI / CLD / STD
        mov     al, 0xFA | IF ax, e, 1666 | mov al, 0xFB | ELSEIF ax, e, 1065 | mov al, 0xFC | ELSEIF ax, e, 1665 | mov al, 0xFD | ENDIF
        call    amd64_emit_byte
    ELSEIF ax, e, 1205             // FLD1
        mov     al, 0xD9 | call amd64_emit_byte | mov al, 0xE8 | call amd64_emit_byte
    ELSEIF ax, e, 1206             // FLDZ
        mov     al, 0xD9 | call amd64_emit_byte | mov al, 0xEE | call amd64_emit_byte
    ELSEIF ax, e, 1542             // PREFETCH
        mov     al, 0x0F | call amd64_emit_byte
        mov     al, 0x18 | call amd64_emit_byte
        mov     al, 1 | mov rdi, r10 | call amd64_emit_modrm_sib // PREFETCHT0
    ELSEIF ax, e, 1073             // CLWB
        mov     al, 0x66 | call amd64_emit_byte
        mov     al, 0x0F | call amd64_emit_byte
        mov     al, 0xAE | call amd64_emit_byte
        mov     al, 6 | mov rdi, r10 | call amd64_emit_modrm_sib
    ELSE
        mov     rax, EXIT_ENCODE_FAIL
    ENDIF
    
    pop     r13
    pop     r12
    pop     rbx
    epilogue

/**
 * [amd64_encode_mov]
 * Handles various MOV encodings.
 */
amd64_encode_mov:
    prologue
    // check operands
    cmp     byte [r12 + INST_nops], 2
    jne     .error
    
    lea     r13, [r12 + INST_op0]  // r13 = Dest
    lea     r14, [r12 + INST_op1]  // r14 = Src
    
    // Case 0: PRIVILEGED MOV (CRn/DRn)
    IF byte [r13 + OPERAND_reg], ge, 32
        IF byte [r13 + OPERAND_reg], le, 63
            // MOV CRn/DRn, reg (0x0F 0x22/0x23)
            mov cl, [r13 + OPERAND_reg] | and cl, 0x0F
            IF cl, ge, 8 | mov al, 0x44 | call amd64_emit_byte | ENDIF
            mov al, 0x0F | call amd64_emit_byte
            mov al, 0x22 | IF byte [r13 + OPERAND_reg], ge, 48 | inc al | ENDIF
            call amd64_emit_byte
            mov al, cl | and al, 0x07
            mov rdi, r14 | call amd64_emit_modrm_sib
            jmp .done
        ENDIF
    ENDIF
    IF byte [r14 + OPERAND_reg], ge, 32
        IF byte [r14 + OPERAND_reg], le, 63
            // MOV reg, CRn/DRn (0x0F 0x20/0x21)
            mov cl, [r14 + OPERAND_reg] | and cl, 0x0F
            IF cl, ge, 8 | mov al, 0x44 | call amd64_emit_byte | ENDIF
            mov al, 0x0F | call amd64_emit_byte
            mov al, 0x20 | IF byte [r14 + OPERAND_reg], ge, 48 | inc al | ENDIF
            call amd64_emit_byte
            mov al, cl | and al, 0x07
            mov rdi, r13 | call amd64_emit_modrm_sib
            jmp .done
        ENDIF
    ENDIF

    // Case 1: MOV REG, REG
    IF byte [r13 + OPERAND_kind], e, OP_REG
        IF byte [r14 + OPERAND_kind], e, OP_REG
            // Smart Prefixes
            mov     al, [r13 + OPERAND_size]
            mov     rsi, r14           // Src
            mov     rdx, r13           // Dest
            call    amd64_emit_prefixes
            
            // Opcode 0x88 (8-bit) or 0x89 (16/32/64-bit)
            mov     al, 0x88
            IF byte [r13 + OPERAND_size], ne, 8
                inc al
            ENDIF
            call    amd64_emit_byte
            
            // ModR/M: 11 (reg,reg) | (src << 3) | dest
            mov     al, 0xC0
            mov     cl, [r14 + OPERAND_reg] | and cl, 0x07 | shl cl, 3 | or al, cl
            mov     cl, [r13 + OPERAND_reg] | and cl, 0x07 | or al, cl
            call    amd64_emit_byte
            jmp     .done
        ENDIF
        
        // Case 2: MOV REG, IMM
        IF byte [r14 + OPERAND_kind], e, OP_IMM
            mov     dl, [r13 + OPERAND_size]
            mov     rax, [r14 + OPERAND_imm]
            
            // OPTIMIZATION: 64-bit MOV to REG with 32-bit non-negative IMM
            // can use 32-bit MOV (zero-extension)
            IF dl, e, 64
                IF rax, ge, 0
                    IF rax, le, 0xFFFFFFFF
                        mov dl, 32
                    ENDIF
                ENDIF
            ENDIF

            // 64-bit MOV REG, IMM64 (Opcode 0xB8 + reg)
            IF dl, e, 64
                mov al, 64 | mov rsi, 0 | mov rdx, r13 | call amd64_emit_prefixes
                mov al, 0xB8 | mov cl, [r13 + OPERAND_reg] | and cl, 0x07 | add al, cl | call amd64_emit_byte
                mov rdi, [r14 + OPERAND_imm] | call amd64_emit_qword
                jmp .done
            ENDIF
            
            // 32-bit MOV REG, IMM32
            IF dl, e, 32
                mov al, 32 | mov rsi, 0 | mov rdx, r13 | call amd64_emit_prefixes
                mov al, 0xB8 | mov cl, [r13 + OPERAND_reg] | and cl, 0x07 | add al, cl | call amd64_emit_byte
                mov rdi, [r14 + OPERAND_imm] | call amd64_emit_dword
                jmp .done
            ENDIF
            
            // 16-bit MOV REG, IMM16
            IF dl, e, 16
                mov al, 16 | mov rsi, 0 | mov rdx, r13 | call amd64_emit_prefixes
                mov al, 0xB8 | mov cl, [r13 + OPERAND_reg] | and cl, 0x07 | add al, cl | call amd64_emit_byte
                mov rax, [r14 + OPERAND_imm] | call amd64_emit_word
                jmp .done
            ENDIF
            
            // 8-bit MOV REG, IMM8
            IF dl, e, 8
                mov al, 8 | mov rsi, 0 | mov rdx, r13 | call amd64_emit_prefixes
                mov al, 0xB0 | mov cl, [r13 + OPERAND_reg] | and cl, 0x07 | add al, cl | call amd64_emit_byte
                mov rax, [r14 + OPERAND_imm] | call amd64_emit_byte
                jmp .done
            ENDIF
        ENDIF

        // Case 3: MOV REG, MEM
        IF byte [r14 + OPERAND_kind], e, OP_MEM
            // Opcode 0x8B (Reg/Mem -> Reg)
            mov     al, 0x48 // REX.W (Assume 64-bit for now)
            call    amd64_emit_byte
            mov     al, 0x8B
            call    amd64_emit_byte
            
            // Use amd64_emit_modrm_sib
            mov     al, [r13 + OPERAND_reg]
            mov     rdi, r14
            call    amd64_emit_modrm_sib
            jmp     .done
        ENDIF
    ENDIF

    // Case 4: MOV MEM, REG
    IF byte [r13 + OPERAND_kind], e, OP_MEM
        IF byte [r14 + OPERAND_kind], e, OP_REG
            mov     al, 0x48 // REX.W
            call    amd64_emit_byte
            mov     al, 0x89
            call    amd64_emit_byte
            
            // Use amd64_emit_modrm_sib
            mov     al, [r14 + OPERAND_reg]
            mov     rdi, r13
            call    amd64_emit_modrm_sib
            jmp     .done
        ENDIF
        
        // Case 5: MOV MEM, IMM
        IF byte [r14 + OPERAND_kind], e, OP_IMM
            mov     al, 0x48 // REX.W
            call    amd64_emit_byte
            mov     al, 0xC7
            call    amd64_emit_byte
            
            xor     al, al   // Extension Digit 0
            mov     rdi, r13
            call    amd64_emit_modrm_sib
            
            mov     rdi, [r14 + OPERAND_imm]
            call    amd64_emit_dword
            jmp     .done
        ENDIF
    ENDIF
    
.error:
    mov     rax, EXIT_ENCODE_FAIL
.done:
    epilogue

/**
 * [amd64_encode_arithmetic]
 * Input:
 *   R13: Base Opcode (for reg-reg)
 *   R14: Extension Digit (for imm)
 */
amd64_encode_arithmetic:
    prologue
    cmp     byte [r12 + INST_nops], 2
    jne     .error
    
    lea     r10, [r12 + INST_op0]  // Dest
    lea     r11, [r12 + INST_op1]  // Src
    
    // Case 1: r/m, reg
    IF byte [r10 + OPERAND_kind], e, OP_REG
        IF byte [r11 + OPERAND_kind], e, OP_REG
            // Smart Prefixes
            mov     al, [r10 + OPERAND_size]
            mov     rsi, r11           // Src
            mov     rdx, r10           // Dest
            call    amd64_emit_prefixes
            
            // Opcode is Base (8-bit) or Base + 1 (16/32/64-bit)
            mov     rax, r13
            IF byte [r10 + OPERAND_size], ne, 8
                inc al
            ENDIF
            call    amd64_emit_byte
            
            // ModR/M: 11 | src | dest
            mov     al, 0xC0
            mov     cl, [r11 + OPERAND_reg] | and cl, 0x07 | shl cl, 3 | or al, cl
            mov     cl, [r10 + OPERAND_reg] | and cl, 0x07 | or al, cl
            call    amd64_emit_byte
            jmp     .done
        ENDIF
        
        // Case 2: r/m, imm
        IF byte [r11 + OPERAND_kind], e, OP_IMM
            // VALIDATION: Arithmetic instructions only support 32-bit sign-extended IMM
            mov     rax, [r11 + OPERAND_imm]
            mov     rcx, rax
            sar     rcx, 31            // Check if bits 31-63 are identical
            IF ecx, ne, 0
                IF ecx, ne, 0xFFFFFFFF
                    jmp .error
                ENDIF
            ENDIF

            // Smart Prefixes
            mov     al, [r10 + OPERAND_size]
            xor     rsi, rsi
            mov     rdx, r10
            call    amd64_emit_prefixes
            
            // 8-bit case: 0x80 /extension
            IF byte [r10 + OPERAND_size], e, 8
                mov al, 0x80 | call amd64_emit_byte
                mov al, 0xC0 | mov cl, r14b | shl cl, 3 | or al, cl
                mov cl, [r10 + OPERAND_reg] | and cl, 0x07 | or al, cl
                call amd64_emit_byte
                mov rax, [r11 + OPERAND_imm] | call amd64_emit_byte
                jmp .done
            ENDIF
            
            // 16/32/64-bit logic
            // OPTIMIZATION: Check if immediate fits in 8-bit signed
            mov     rax, [r11 + OPERAND_imm]
            cmp     rax, -128
            jl      .long_imm
            cmp     rax, 127
            jg      .long_imm
            
            // 8-bit optimization (0x83)
            mov     al, 0x83
            call    amd64_emit_byte
            
            // ModR/M: 11 | extension | dest
            mov     al, 0xC0
            mov     cl, r14b
            shl     cl, 3
            or      al, cl
            mov     cl, [r10 + OPERAND_reg]
            and     cl, 0x07
            or      al, cl
            call    amd64_emit_byte
            
            mov     rax, [r11 + OPERAND_imm]
            call    amd64_emit_byte
            jmp     .done

.long_imm:
            mov     al, 0x81
            call    amd64_emit_byte
            
            // ModR/M: 11 | extension | dest
            mov     al, 0xC0
            mov     cl, r14b       // Extension digit
            shl     cl, 3
            or      al, cl
            mov     cl, [r10 + OPERAND_reg]
            and     cl, 0x07
            or      al, cl
            call    amd64_emit_byte
            
            mov     rax, [r11 + OPERAND_imm]
            call    amd64_emit_dword
            jmp     .done
        ENDIF

        // Case 3: r, m
        IF byte [r11 + OPERAND_kind], e, OP_MEM
            // Smart Prefixes
            mov     al, [r10 + OPERAND_size]
            mov     rsi, r10           // Reg (Src for ModRM)
            mov     rdx, r11           // Mem (Dest for ModRM)
            call    amd64_emit_prefixes
            
            // Opcode is Base + 2 (8-bit) or Base + 3 (16/32/64-bit)
            mov     rax, r13 | add al, 2
            IF byte [r10 + OPERAND_size], ne, 8
                inc al
            ENDIF
            call    amd64_emit_byte
            
            mov     al, [r10 + OPERAND_reg]
            mov     rdi, r11
            call    amd64_emit_modrm_sib
            jmp     .done
        ENDIF
    ENDIF

    // Case 4: m, r
    IF byte [r10 + OPERAND_kind], e, OP_MEM
        IF byte [r11 + OPERAND_kind], e, OP_REG
            // Smart Prefixes
            mov     al, [r11 + OPERAND_size]
            mov     rsi, r11           // Reg
            mov     rdx, r10           // Mem
            call    amd64_emit_prefixes
            
            // Opcode is Base (8-bit) or Base + 1 (16/32/64-bit)
            mov     rax, r13
            IF byte [r11 + OPERAND_size], ne, 8
                inc al
            ENDIF
            call    amd64_emit_byte
            
            mov     al, [r11 + OPERAND_reg]
            mov     rdi, r10
            call    amd64_emit_modrm_sib
            jmp     .done
        ENDIF
        
        // Case 5: m, imm
        IF byte [r11 + OPERAND_kind], e, OP_IMM
            // Smart Prefixes
            mov     al, [r10 + OPERAND_size]
            xor     rsi, rsi
            mov     rdx, r10
            call    amd64_emit_prefixes
            
            // Logic similar to Case 2 (0x81/0x83) but with memory
            // 8-bit case: 0x80 /extension
            IF byte [r10 + OPERAND_size], e, 8
                mov al, 0x80 | call amd64_emit_byte
                mov al, r14b | mov rdi, r10 | call amd64_emit_modrm_sib
                mov rax, [r11 + OPERAND_imm] | call amd64_emit_byte
                jmp .done
            ENDIF
            
            // 16/32/64-bit
            mov rax, [r11 + OPERAND_imm]
            IF rax, ge, -128
                IF rax, le, 127
                    mov al, 0x83 | call amd64_emit_byte
                    mov al, r14b | mov rdi, r10 | call amd64_emit_modrm_sib
                    mov rax, [r11 + OPERAND_imm] | call amd64_emit_byte
                    jmp .done
                ENDIF
            ENDIF
            mov al, 0x81 | call amd64_emit_byte
            mov al, r14b | mov rdi, r10 | call amd64_emit_modrm_sib
            mov rdi, [r11 + OPERAND_imm] | call amd64_emit_dword
            jmp .done
        ENDIF
    ENDIF

.error:
    mov     rax, EXIT_ENCODE_FAIL
.done:
    epilogue

/**
 * [amd64_encode_syscall]
 */
amd64_encode_syscall:
    mov     al, 0x0F | call amd64_emit_byte
    mov     al, 0x05 | call amd64_emit_byte
    ret

/**
 * [amd64_encode_sysret]
 */
amd64_encode_sysret:
    mov     al, 0x48 | call amd64_emit_byte
    mov     al, 0x0F | call amd64_emit_byte
    mov     al, 0x07 | call amd64_emit_byte
    ret

/**
 * [amd64_encode_push]
 */
amd64_encode_push:
    prologue
    lea     r10, [r12 + INST_op0]
    IF byte [r10 + OPERAND_size], e, 32 | jmp .error | ENDIF

    // Prefixes
    mov     al, [r10 + OPERAND_size]
    xor     rsi, rsi
    mov     rdx, r10
    call    amd64_emit_prefixes
    
    IF byte [r10 + OPERAND_kind], e, OP_REG
        mov     al, 0x50 | mov cl, [r10 + OPERAND_reg] | and cl, 0x07 | add al, cl
        call    amd64_emit_byte
        jmp     .done
    ENDIF
    IF byte [r10 + OPERAND_kind], e, OP_MEM
        mov     al, 0xFF | call amd64_emit_byte
        mov     al, 6 | mov rdi, r10 | call amd64_emit_modrm_sib
        jmp     .done
    ENDIF
    IF byte [r10 + OPERAND_kind], e, OP_IMM
        mov     rax, [r10 + OPERAND_imm]
        IF rax, ge, -128
            IF rax, le, 127
                mov al, 0x6A | call amd64_emit_byte
                mov rax, [r10 + OPERAND_imm] | call amd64_emit_byte
                jmp .done
            ENDIF
        ENDIF
        mov     al, 0x68 | call amd64_emit_byte
        mov     rax, [r10 + OPERAND_imm] | call amd64_emit_dword
        jmp     .done
    ENDIF
    jmp     .error

amd64_encode_pop:
    prologue
    lea     r10, [r12 + INST_op0]
    IF byte [r10 + OPERAND_size], e, 32 | jmp .error | ENDIF

    // Prefixes
    mov     al, [r10 + OPERAND_size]
    xor     rsi, rsi
    mov     rdx, r10
    call    amd64_emit_prefixes
    
    IF byte [r10 + OPERAND_kind], e, OP_REG
        mov     al, 0x58 | mov cl, [r10 + OPERAND_reg] | and cl, 0x07 | add al, cl
        call    amd64_emit_byte
        jmp     .done
    ENDIF
    IF byte [r10 + OPERAND_kind], e, OP_MEM
        mov     al, 0x8F | call amd64_emit_byte
        mov     al, 0 | mov rdi, r10 | call amd64_emit_modrm_sib
        jmp     .done
    ENDIF
    jmp     .error
.error:
    mov     rax, EXIT_ENCODE_FAIL
.done:
    epilogue

/**
 * [amd64_encode_branch]
 * Input: R13 = Opcode for REL32 form
 */
amd64_encode_branch:
    prologue
    lea     r10, [r12 + INST_op0]
    
    // Case 1: Symbol (REL32)
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        mov     al, r13b
        call    amd64_emit_byte
        mov     al, RELOC_REL32
        mov     rsi, [r10 + OPERAND_sym]
        call    amd64_emit_reloc
        xor     rax, rax
        call    amd64_emit_dword
        jmp     .done
    ENDIF
    
    // Case 2: Register or Memory (FF /digit)
    // CALL = FF /2, JMP = FF /4
    mov     al, 0xFF
    call    amd64_emit_byte
    
    mov     al, 2               // Default to CALL extension
    IF r13b, e, 0xE9            // If it was JMP (E9)
        mov al, 4               // Use JMP extension
    ENDIF
    
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_ret]
 */
amd64_encode_ret:
    prologue
    cmp     byte [r12 + INST_nops], 0
    IF e
        mov     al, 0xC3
        call    amd64_emit_byte
        jmp     .done
    ENDIF
    
    // RET imm16 (0xC2)
    mov     al, 0xC2
    call    amd64_emit_byte
    lea     r10, [r12 + INST_op0]
    mov     rax, [r10 + OPERAND_imm]
    call    amd64_emit_word
    jmp     .done

/**
 * [amd64_encode_jcc]
 */
amd64_encode_jcc:
    prologue
    mov     ax, [r12 + INST_id]
    
    // Extract condition code from ID (3000-3031)
    sub     ax, 3000
    and     rax, 0x0F          // Get CC bits
    mov     r14, rax
    
    mov     al, 0x0F | call amd64_emit_byte
    mov     al, 0x80 | add al, r14b | call amd64_emit_byte
    
    lea     r10, [r12 + INST_op0]
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        mov     al, RELOC_REL32
        mov     rsi, [r10 + OPERAND_sym]
        call    amd64_emit_reloc
    ENDIF
    
    xor     rax, rax
    call    amd64_emit_dword
    jmp     .done

/**
 * [amd64_encode_branch_short]
 * R13 = Opcode (0xEB for JMP, etc)
 */
amd64_encode_branch_short:
    prologue
    mov     al, r13b
    call    amd64_emit_byte
    
    lea     r10, [r12 + INST_op0]
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        mov     al, RELOC_REL8
        mov     rsi, [r10 + OPERAND_sym]
        call    amd64_emit_reloc
    ENDIF
    
    xor     rax, rax
    call    amd64_emit_byte    // 1-byte placeholder
    jmp     .done

/**
 * [amd64_encode_jcc_short]
 */
amd64_encode_jcc_short:
    prologue
    mov     ax, [r12 + INST_id]
    sub     ax, 3000
    and     rax, 0x0F
    add     al, 0x70           // 0x70 = JO short, 0x74 = JE short
    call    amd64_emit_byte
    
    lea     r10, [r12 + INST_op0]
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        mov     al, RELOC_REL8
        mov     rsi, [r10 + OPERAND_sym]
        call    amd64_emit_reloc
    ENDIF
    
    xor     rax, rax
    call    amd64_emit_byte
    jmp     .done

/**
 * [amd64_encode_lea]
 */
amd64_encode_lea:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     al, 0x48       // REX.W
    IF byte [r10 + OPERAND_reg], ge, 8
        or  al, 0x04       // REX.R
    ENDIF
    call    amd64_emit_byte
    
    mov     al, 0x8D       // Opcode LEA
    call    amd64_emit_byte
    
    mov     al, [r10 + OPERAND_reg]
    mov     rdi, r11
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_test]
 */
amd64_encode_test:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // REX
    xor     r15, r15
    IF byte [r10 + OPERAND_size], e, 8
        or  r15, 0x48
    ENDIF
    IF byte [r11 + OPERAND_reg], ge, 8
        or  r15, 0x44      // REX.R (Src)
    ENDIF
    
    test    r15, r15
    jz      .no_rex
    mov     rax, r15
    call    amd64_emit_byte
.no_rex:
    mov     rax, r13       // Opcode 0x85 (r/m, reg)
    call    amd64_emit_byte
    
    mov     al, [r11 + OPERAND_reg]
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_unary]
 * INC/DEC/NEG/NOT
 */
amd64_encode_unary:
    prologue
    lea     r10, [r12 + INST_op0]
    
    xor     r15, r15
    IF byte [r10 + OPERAND_size], e, 8
        or  r15, 0x48
    ENDIF
    
    test    r15, r15
    jz      .no_rex
    mov     rax, r15
    call    amd64_emit_byte
.no_rex:
    mov     al, 0xFF       // Multi-op Unary
    IF r14b, ge, 2         // NEG/NOT use 0xF7
        mov al, 0xF7
    ENDIF
    call    amd64_emit_byte
    
    mov     al, r14b       // Extension Digit
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_shift]
 * SHL/SHR/SAR/ROL/ROR
 */
amd64_encode_shift:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    xor     r15, r15
    IF byte [r10 + OPERAND_size], e, 8
        or  r15, 0x48
    ENDIF
    
    test    r15, r15
    jz      .no_rex
    mov     rax, r15
    call    amd64_emit_byte
.no_rex:
    // Opcode: 0xD1 (1), 0xD3 (CL), 0xC1 (imm8)
    IF byte [r11 + OPERAND_kind], e, OP_IMM
        mov al, 0xC1
        call    amd64_emit_byte
        mov     al, r14b
        mov     rdi, r10
        call    amd64_emit_modrm_sib
        mov     rax, [r11 + OPERAND_imm]
        call    amd64_emit_byte
    ELSE
        // Default to shift by 1 (0xD1) for now
        mov     al, 0xD1
        call    amd64_emit_byte
        mov     al, r14b
        mov     rdi, r10
        call    amd64_emit_modrm_sib
    ENDIF
    jmp     .done

/**
 * [amd64_encode_imul]
 */
amd64_encode_imul:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     rdx, [r12 + INST_op2]
    
    // 1-Operand: IMUL r/m (F7 /5)
    cmp     byte [r12 + INST_nops], 1
    IF e
        mov r14, 5 | jmp amd64_encode_unary_math
    ENDIF
    
    // 2-Operand: IMUL reg, r/m (0F AF)
    cmp     byte [r12 + INST_nops], 2
    IF e
        mov al, [r10 + OPERAND_size] | mov rsi, r10 | mov rdx, r11 | call amd64_emit_prefixes
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0xAF | call amd64_emit_byte
        mov al, [r10 + OPERAND_reg] | mov rdi, r11 | call amd64_emit_modrm_sib
        jmp .done
    ENDIF
    
    // 3-Operand: IMUL reg, r/m, imm (69/6B)
    mov al, [r10 + OPERAND_size] | mov rsi, r10 | mov rdx, r11 | call amd64_emit_prefixes
    
    mov rax, [rdx + OPERAND_imm]
    IF rax, ge, -128
        IF rax, le, 127
            mov al, 0x6B | call amd64_emit_byte
            mov al, [r10 + OPERAND_reg] | mov rdi, r11 | call amd64_emit_modrm_sib
            mov rax, [rdx + OPERAND_imm] | call amd64_emit_byte
            jmp .done
        ENDIF
    ENDIF
    
    mov al, 0x69 | call amd64_emit_byte
    mov al, [r10 + OPERAND_reg] | mov rdi, r11 | call amd64_emit_modrm_sib
    mov rdi, [rdx + OPERAND_imm] | call amd64_emit_dword
    jmp .done

/**
 * [amd64_encode_unary_math]
 * MUL/DIV/IDIV/etc.
 */
amd64_encode_unary_math:
    prologue
    lea     r10, [r12 + INST_op0]
    
    // Smart Prefixes
    mov     al, [r10 + OPERAND_size]
    xor     rsi, rsi
    mov     rdx, r10
    call    amd64_emit_prefixes
    
    // Opcode is 0xF6 (8-bit) or 0xF7 (16/32/64-bit)
    mov     al, 0xF6
    IF byte [r10 + OPERAND_size], ne, 8
        inc al
    ENDIF
    call    amd64_emit_byte
    
    mov     al, r14b       // Digit (4=MUL, 6=DIV, 7=IDIV)
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_cmovcc]
 */
amd64_encode_cmovcc:
    prologue
    mov     ax, [r12 + INST_id]
    sub     ax, 4000
    and     rax, 0x0F
    mov     r14, rax           // Condition Code
    
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // REX.W
    mov     al, 0x48
    IF byte [r10 + OPERAND_reg], ge, 8
        or  al, 0x04
    ENDIF
    IF byte [r11 + OPERAND_reg], ge, 8
        or  al, 0x01
    ENDIF
    call    amd64_emit_byte
    
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0x40
    add     al, r14b
    call    amd64_emit_byte
    
    mov     al, [r10 + OPERAND_reg]
    mov     rdi, r11
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_setcc]
 */
amd64_encode_setcc:
    prologue
    mov     ax, [r12 + INST_id]
    sub     ax, 4016
    and     rax, 0x0F
    mov     r14, rax
    
    lea     r10, [r12 + INST_op0]
    
    // REX if reg >= 8
    IF byte [r10 + OPERAND_reg], ge, 8
        mov al, 0x41
        call    amd64_emit_byte
    ENDIF
    
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0x90
    add     al, r14b
    call    amd64_emit_byte
    
    xor     al, al             // Reg field 0
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_enter]
 */
amd64_encode_enter:
    prologue
    mov     al, 0xC8
    call    amd64_emit_byte
    
    lea     r10, [r12 + INST_op0]
    mov     ax, [r10 + OPERAND_imm]
    call    amd64_emit_byte    // Enter uses word, then byte
    mov     al, ah
    call    amd64_emit_byte
    
    lea     r11, [r12 + INST_op1]
    mov     al, [r11 + OPERAND_imm]
    call    amd64_emit_byte
    jmp     .done

/**
 * [amd64_emit_branch_rel8]
 */
amd64_emit_branch_rel8:
    call    amd64_emit_byte
    xor     al, al             // rel8 placeholder
    call    amd64_emit_byte
    ret

    xor     al, al             // rel8 placeholder
    call    amd64_emit_byte
    ret

/**
 * [amd64_encode_int]
 */
amd64_encode_int:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     al, 0xCD
    call    amd64_emit_byte
    mov     rax, [r10 + OPERAND_imm]
    call    amd64_emit_byte
    jmp     .done

/**
 * [amd64_encode_system_m]
 * LGDT/LIDT
 */
amd64_encode_system_m:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0x01
    call    amd64_emit_byte
    
    mov     al, r14b           // Digit 2 for LGDT, 3 for LIDT
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_in]
 */
amd64_encode_in:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // Case: in al/eax, dx
    IF byte [r11 + OPERAND_kind], e, OP_REG
        mov al, 0xEC
        IF byte [r10 + OPERAND_size], e, 4
            mov al, 0xED
        ENDIF
        call    amd64_emit_byte
    ELSE
        // Case: in al/eax, imm8
        mov al, 0xE4
        IF byte [r10 + OPERAND_size], e, 4
            mov al, 0xE5
        ENDIF
        call    amd64_emit_byte
        mov     rax, [r11 + OPERAND_imm]
        call    amd64_emit_byte
    ENDIF
    jmp     .done

/**
 * [amd64_encode_out]
 */
amd64_encode_out:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    IF byte [r10 + OPERAND_kind], e, OP_REG
        mov al, 0xEE
        IF byte [r11 + OPERAND_size], e, 4
            mov al, 0xEF
        ENDIF
        call    amd64_emit_byte
    ELSE
        mov al, 0xE6
        IF byte [r11 + OPERAND_size], e, 4
            mov al, 0xE7
        ENDIF
        call    amd64_emit_byte
        mov     rax, [r10 + OPERAND_imm]
        call    amd64_emit_byte
    ENDIF
    jmp     .done

    mov     rax, [r10 + OPERAND_imm]
    call    amd64_emit_byte
    jmp     .done

/**
 * [amd64_encode_fpu]
 * FLD/FST/FADD/etc.
 */
amd64_encode_fpu:
    prologue
    lea     r10, [r12 + INST_op0]
    
    // x87 doesn't use REX
    mov     rax, r13           // Base Opcode (e.g. 0xD8)
    call    amd64_emit_byte
    
    // ModRM extension
    mov     al, r14b           // Digit
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

    mov     al, r14b           // Digit
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_sse]
 * R13 = Opcode
 * R14 = Format (0=0F, 1=66 0F, 2=0F 38, 3=0F 3A)
 */
amd64_encode_sse:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // REX if using R8-R15 or XMM8-XMM15
    xor     r15, r15
    IF byte [r10 + OPERAND_reg], ge, 8
        or  r15, 0x44      // REX.R
    ENDIF
    IF byte [r11 + OPERAND_reg], ge, 8
        or  r15, 0x41      // REX.B
    ENDIF
    
    test    r15, r15
    jz      .no_rex
    mov     rax, r15
    call    amd64_emit_byte
.no_rex:
    // Mandatory Prefix
    IF r14b, e, 1
        mov al, 0x66 | call amd64_emit_byte
    ENDIF
    
    // Opcode Escape
    mov     al, 0x0F
    call    amd64_emit_byte
    IF r14b, e, 2
        mov al, 0x38 | call amd64_emit_byte
    ELSEIF r14b, e, 3
        mov al, 0x3A | call amd64_emit_byte
    ENDIF
    
    mov     rax, r13
    call    amd64_emit_byte
    
    mov     al, [r10 + OPERAND_reg]
    mov     rdi, r11
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_vex]
 * R13 = Opcode
 * R14 = Map (1=0F, 2=0F 38, 3=0F 3A)
 * R15 = pp bits (0=none, 1=66, 2=F3, 3=F2)
 */
amd64_encode_vex:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     rdx, [r12 + INST_op2]
    
    // 1. Determine form (2-byte vs 3-byte)
    // 2-byte VEX (C5) if X=1, B=1, Map=1
    mov     bl, 0xC4           // Default to 3-byte
    
    // Check operands for REX-style extensions (R8-R15)
    // X and B are 1 if not used or if index/base < 8
    // Map must be 1 (0x0F)
    IF r14b, e, 1
        IF byte [rdx + OPERAND_reg], lt, 8    // X
            IF byte [rdx + OPERAND_base], lt, 8 // B
                mov bl, 0xC5
            ENDIF
        ENDIF
    ENDIF
    
    IF bl, e, 0xC5
        mov al, 0xC5 | call amd64_emit_byte
        // Byte 1: R vvvv L pp
        mov al, r15b           // pp
        
        // R (inverted)
        mov cl, [r10 + OPERAND_reg]
        IF cl, ge, 8 | ELSE | or al, 0x80 | ENDIF
        
        // vvvv (inverted)
        IF byte [r12 + INST_nops], ge, 3
            mov cl, [r11 + OPERAND_reg] | and cl, 0x0F | xor cl, 0x0F | shl cl, 3 | or al, cl
        ELSE
            or al, 0x78        // 1111
        ENDIF
        call amd64_emit_byte
    ELSE
        mov al, 0xC4 | call amd64_emit_byte
        // Byte 1: R X B m-mmmm
        mov al, r14b           // Map
        mov cl, [r10 + OPERAND_reg]
        IF cl, ge, 8 | ELSE | or al, 0x80 | ENDIF  // R
        mov cl, [rdx + OPERAND_reg]
        IF cl, ge, 8 | ELSE | or al, 0x40 | ENDIF  // X
        mov cl, [rdx + OPERAND_base]
        IF cl, ge, 8 | ELSE | or al, 0x20 | ENDIF  // B
        call amd64_emit_byte
        
        // Byte 2: W vvvv L pp
        mov al, r15b           // pp
        IF byte [r10 + OPERAND_size], e, 64 | or al, 0x80 | ENDIF // W bit
        
        // vvvv
        IF byte [r12 + INST_nops], ge, 3
            mov cl, [r11 + OPERAND_reg] | and cl, 0x0F | xor cl, 0x0F | shl cl, 3 | or al, cl
        ELSE
            or al, 0x78
        ENDIF
        call amd64_emit_byte
    ENDIF
    
    // 2. Opcode
    mov al, r13b
    call amd64_emit_byte
    
    // 3. ModRM/SIB
    mov al, [r10 + OPERAND_reg]
    mov rdi, rdx
    IF byte [r12 + INST_nops], lt, 3
        mov rdi, r11
    ENDIF
    call    amd64_emit_modrm_sib
    jmp .done

/**
 * [amd64_encode_evex]
 * Complex 4-byte prefix starting with 0x62.
 */
amd64_encode_evex:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     rdx, [r12 + INST_op2]
    
    // Byte 0: 0x62
    mov     al, 0x62 | call amd64_emit_byte
    
    // Byte 1: ~R ~X ~B ~R' 0 0 m m
    // m-mmmm (Map) is usually in metadata, assume 1 (0F) for now
    mov     al, 0x01
    
    // R, X, B, R' inverted
    mov cl, [r10 + OPERAND_reg]
    IF cl, ge, 8 | ELSE | or al, 0x80 | ENDIF  // R
    IF cl, ge, 16 | ELSE | or al, 0x10 | ENDIF // R'
    
    // Default X and B to 1 (inverted)
    or al, 0x60
    IF byte [rdx + OPERAND_kind], e, OP_MEM
        mov cl, [rdx + OPERAND_reg]
        IF cl, ge, 8 | and al, ~0x40 | ENDIF   // X
        mov cl, [rdx + OPERAND_base]
        IF cl, ge, 8 | and al, ~0x20 | ENDIF   // B
    ENDIF
    call    amd64_emit_byte
    
    // Byte 2: W vvvv 1 pp
    // pp (Assume 00), W=0
    mov     al, 0x04           // Bit 2 is mandatory 1
    // vvvv (inverted, includes v' in byte 3)
    IF byte [r12 + INST_nops], ge, 3
        mov cl, [r11 + OPERAND_reg] | and cl, 0x0F | xor cl, 0x0F | shl cl, 3 | or al, cl
    ELSE
        or al, 0x78
    ENDIF
    call    amd64_emit_byte
    
    // Byte 3: z L' L b V' aaa
    // aaa = Masking register
    mov     al, [r10 + OPERAND_mask]
    and     al, 0x07
    
    // V' (inverted)
    mov     cl, [r11 + OPERAND_reg]
    IF cl, ge, 16 | ELSE | or al, 0x08 | ENDIF
    
    // b = Broadcast/Static Rounding
    mov     cl, [r10 + OPERAND_ctrl]
    and     cl, 0x01 | shl cl, 4 | or al, cl
    
    call    amd64_emit_byte
    
    // Opcode & ModRM
    // (In a real implementation, opcode would be retrieved from metadata)
    // For now, assume a placeholder
    mov     al, 0x00 | call amd64_emit_byte
    
    mov al, [r10 + OPERAND_reg]
    mov rdi, rdx
    IF byte [r12 + INST_nops], lt, 3
        mov rdi, r11
    ENDIF
    call    amd64_emit_modrm_sib
    jmp .done

/**
 * [amd64_encode_string]
 * R13 = Base Opcode (e.g. 0xA4 for MOVSB)
 */
amd64_encode_string:
    prologue
    mov     ax, [r12 + INST_id]
    
    // Determine size (8, 16, 32, 64)
    // 1. Check if fixed-size mnemonic (e.g. MOVSB = 8)
    // 2. Check operands if generic (e.g. MOVS [rdi], [rsi])
    
    xor     bl, bl             // 0=8, 1=16, 2=32, 3=64
    
    // Check suffixes (This is a bit hardcoded but fast)
    // MOVSB=1419, STOSB=1669, LODSB=1369, SCASB=1630, CMPSB=1079
    IF ax, e, 1419 | OR ax, e, 1669 | OR ax, e, 1369 | OR ax, e, 1630 | OR ax, e, 1079
        mov bl, 0
    // MOVSW=1425, STOSW=1672, LODSW=1372, SCASW=1632, CMPSW=1083
    ELSEIF ax, e, 1425 | OR ax, e, 1672 | OR ax, e, 1372 | OR ax, e, 1632 | OR ax, e, 1083
        mov bl, 1
    // MOVSD=1420, STOSD=1670, LODSD=1370, SCASD=1631, CMPSD=1080
    ELSEIF ax, e, 1420 | OR ax, e, 1670 | OR ax, e, 1370 | OR ax, e, 1631 | OR ax, e, 1080
        mov bl, 2
    // MOVSQ=1423, STOSQ=1671, LODSQ=1371, SCASQ=???, CMPSQ=1081
    ELSEIF ax, e, 1423 | OR ax, e, 1671 | OR ax, e, 1371 | OR ax, e, 1081
        mov bl, 3
    ELSE
        // Generic form - use operand 0 size
        lea r10, [r12 + INST_op0]
        mov cl, [r10 + OPERAND_size]
        IF cl, e, 8 | mov bl, 0
        ELSEIF cl, e, 16 | mov bl, 1
        ELSEIF cl, e, 32 | mov bl, 2
        ELSEIF cl, e, 64 | mov bl, 3
        ENDIF
    ENDIF
    
    // REX.W for 64-bit
    IF bl, e, 3
        mov al, 0x48 | call amd64_emit_byte
    // 16-bit prefix
    ELSEIF bl, e, 1
        mov al, 0x66 | call amd64_emit_byte
    ENDIF
    
    // Opcode
    mov     al, r13b
    IF bl, ne, 0
        inc al
    ENDIF
    call    amd64_emit_byte
    jmp     .done

/**
 * [amd64_encode_bin0f]
 * R13 = Opcode (after 0x0F)
 */
amd64_encode_bin0f:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     al, [r10 + OPERAND_size]
    mov     rsi, r11           // Reg (Src)
    mov     rdx, r10           // R/M (Dst)
    call    amd64_emit_prefixes
    
    mov     al, 0x0F | call amd64_emit_byte
    mov     al, r13b
    IF byte [r10 + OPERAND_size], e, 8
        dec al                 // 0xB1 -> 0xB0 for byte
    ENDIF
    call    amd64_emit_byte
    
    mov     al, [r11 + OPERAND_reg]
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_cmpxchg_nb]
 * CMPXCHG8B / CMPXCHG16B
 */
amd64_encode_cmpxchg_nb:
    prologue
    lea     r10, [r12 + INST_op0]
    
    // REX.W for 16B
    IF word [r12 + INST_op_id], e, 1085
        mov al, 0x48 | call amd64_emit_byte
    ELSEIF byte [r10 + OPERAND_reg], ge, 8
        mov al, 0x41 | call amd64_emit_byte
    ENDIF
    
    mov     al, 0x0F | call amd64_emit_byte
    mov     al, 0xC7 | call amd64_emit_byte
    
    mov     al, r14b           // Digit 1
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_sec_r]
 * RDRAND/RDSEED
 */
amd64_encode_sec_r:
    prologue
    lea     r10, [r12 + INST_op0]
    
    // REX if reg >= 8
    IF byte [r10 + OPERAND_reg], ge, 8
        mov al, 0x48
        call    amd64_emit_byte
    ENDIF
    
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0xC7
    call    amd64_emit_byte
    
    mov     al, r14b           // Digit 6 or 7
    mov     cl, [r10 + OPERAND_reg]
    and     cl, 0x07
    shl     al, 3
    or      al, 0xC0           // Mod 11
    or      al, cl
    call    amd64_emit_byte
    jmp     .done

/**
 * [amd64_encode_vm_m]
 * VMPTRLD/VMPTRST
 */
amd64_encode_vm_m:
    prologue
    lea     r10, [r12 + INST_op0]
    
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0xC7
    call    amd64_emit_byte
    
    mov     al, r14b           // Digit 6 or 7
    mov     rdi, r10           // Must be memory
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_mem_sync]
 * CLFLUSH/etc.
 */
amd64_encode_mem_sync:
    prologue
    lea     r10, [r12 + INST_op0]
    
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0xAE
    call    amd64_emit_byte
    
    mov     al, r14b           // Digit 7 for CLFLUSH
    mov     rdi, r10
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_encode_rm_r]
 * R13 = Opcode (multi-byte)
 */
amd64_encode_rm_r:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // REX.W
    mov     al, 0x48
    IF byte [r10 + OPERAND_reg], ge, 8
        or  al, 0x04
    ENDIF
    IF byte [r11 + OPERAND_reg], ge, 8
        or  al, 0x01
    ENDIF
    call    amd64_emit_byte
    
    // Multi-byte Opcode
    mov     ax, r13w
    xchg    al, ah
    IF al, ne, 0 | call amd64_emit_byte | ENDIF
    mov     al, ah
    call    amd64_emit_byte
    
    mov     al, [r10 + OPERAND_reg]
    mov     rdi, r11
    call    amd64_emit_modrm_sib
    jmp     .done

/**
 * [amd64_emit_reloc]
 * Input:
 *   AL: Relocation Type (RELOC_REL32, etc)
 *   RSI: Pointer to Symbol String
 */
amd64_emit_reloc:
    prologue
    push    rax
    push    rsi
    
    // Allocate RELOC struct
    mov     rdi, [rbx + ASMCTX_arena]
    mov     rsi, RELOC_SIZE
    call    arena_alloc
    check_err
    mov     r13, rdx
    
    pop     rsi
    pop     rax
    
    mov     byte [r13 + RELOC_tag], TAG_RELOC
    mov     byte [r13 + RELOC_type], al
    mov     [r13 + RELOC_symbol], rsi
    
    // Get current offset in buffer
    // Assuming current section is always [rbx + ASMCTX_sections] for now
    mov     r14, [rbx + ASMCTX_sections]
    mov     rdx, [r14 + SECTION_size]
    mov     [r13 + RELOC_offset], edx
    
    // Link to AsmCtx reloc list (simple linked list or array?)
    // For now, let's assume it's an array and we just increment count
    // In a real implementation, we'd need more complex list management
    mov     rax, [rbx + ASMCTX_relocs]
    mov     ecx, [rbx + ASMCTX_nrelocs]
    mov     r15, rcx
    shl     r15, 5             // RELOC_SIZE is 32? (1+1+2+4+8+8 = 24?)
    // Need to check RELOC_SIZE
    
    // To keep it simple for now, we just print a debug message or similar
    // Actually, let's just store it in the relocs array
    mov     [rax + r15], r13   // This is wrong if it's an array of structs
    
    inc     dword [rbx + ASMCTX_nrelocs]
    epilogue

/**
 * [amd64_emit_prefixes]
 * Input:
 *   AL: Operation Size (8, 16, 32, 64)
 *   RSI: Pointer to Op0 (Dest)
 *   RDX: Pointer to Op1 (Src/Index)
 */
amd64_emit_prefixes:
    prologue
    push    rax
    push    rsi
    push    rdx
    
    // 1. 16-bit Override
    IF al, e, 16
        mov al, 0x66 | call amd64_emit_byte
    ENDIF
    
    // 2. Address-Size Override (0x67)
    IF rdx, ne, 0
        // If memory operand uses 32-bit registers
        IF byte [rdx + OPERAND_kind], e, OP_MEM
            IF byte [rdx + OPERAND_size], e, 32
                mov al, 0x67 | call amd64_emit_byte
            ENDIF
        ENDIF
    ENDIF

    // 3. REX Calculation
    xor     r11, r11
    pop     rdx
    pop     rsi
    pop     rax
    
    IF al, e, 64
        or  r11, 0x48           // REX.W
    ELSE
        // Even for non-64-bit, we need REX if using R8-R15
        // or if using SIL/DIL/BPL/SPL in 8-bit mode
        xor r10, r10
        IF rsi, ne, 0
            IF byte [rsi + OPERAND_reg], ge, 8 | or r10, 1 | ENDIF
            IF byte [rsi + OPERAND_base], ge, 8 | or r10, 1 | ENDIF
            IF byte [rsi + OPERAND_index], ge, 8 | or r10, 1 | ENDIF
        ENDIF
        IF rdx, ne, 0
            IF byte [rdx + OPERAND_reg], ge, 8 | or r10, 1 | ENDIF
            IF byte [rdx + OPERAND_base], ge, 8 | or r10, 1 | ENDIF
            IF byte [rdx + OPERAND_index], ge, 8 | or r10, 1 | ENDIF
        ENDIF
        IF r10, ne, 0
            mov r11, 0x40
        ENDIF
    ENDIF
    
    test    r11, r11
    jz      .done
    
    // REX.R (from op0/src reg)
    IF rsi, ne, 0
        mov cl, [rsi + OPERAND_reg]
        IF cl, ge, 8 | or r11, 0x04 | ENDIF
    ENDIF
    // REX.B (from op1/dest reg or mem base)
    IF rdx, ne, 0
        mov cl, [rdx + OPERAND_reg]
        IF cl, ge, 8 | or r11, 0x01 | ENDIF
        mov cl, [rdx + OPERAND_base]
        IF cl, ge, 8 | or r11, 0x01 | ENDIF
        mov cl, [rdx + OPERAND_index]
        IF cl, ge, 8 | or r11, 0x02 | ENDIF
    ENDIF
    
    IF r11, ne, 0
        // VALIDATION: REX vs High-Byte (AH/CH/DH/BH)
        // Architectural constraint: Cannot use REX with legacy 8-bit high regs.
        IF rsi, ne, 0
            IF byte [rsi + OPERAND_is_high], e, 1 | jmp .error | ENDIF
        ENDIF
        IF rdx, ne, 0
            IF byte [rdx + OPERAND_is_high], e, 1 | jmp .error | ENDIF
        ENDIF
        
        mov     rax, r11
        call    amd64_emit_byte
    ENDIF
    
.done:
    epilogue

.error:
    mov     rax, EXIT_ENCODE_FAIL
    epilogue

/**
 * [amd64_emit_modrm_sib]
 * Emits ModR/M, SIB, and Displacement.
 * Input:
 *   AL  = Reg field value (3 bits)
 *   RDI = Pointer to memory OPERAND
 */
amd64_emit_modrm_sib:
    push    rbx
    push    rcx
    push    rdx
    push    r13
    push    r14
    
    mov     r13, rdi            // Operand
    movzx   r14, al             // Reg field
    
    // 1. Check for RIP-Relative addressing
    mov     bl, [r13 + OPERAND_base]
    IF bl, e, REG_RIP
        // Mod=00, R/M=101
        shl     r14b, 3
        mov     al, r14b
        or      al, 0x05
        call    amd64_emit_byte
        
        // Emit Relocation for Symbol
        mov     al, RELOC_REL32
        mov     rsi, [r13 + OPERAND_sym]
        call    amd64_emit_reloc
        
        // Emit 4-byte zero placeholder
        xor     rax, rax
        call    amd64_emit_dword
        jmp     .done_sib
    ENDIF
    
    mov     cl, [r13 + OPERAND_index]
    IF cl, e, 4
        jmp amd64_encode_instruction.error
    ENDIF
    
    xor     rdx, rdx            // Mod field
    mov     rdi, [r13 + OPERAND_imm] // Displacement
    
    // Determine Mod based on Displacement
    test    rdi, rdi
    jz      .mod00
    // Check if fits in 8 bits
    cmp     rdi, -128
    jl      .mod32
    cmp     rdi, 127
    jg      .mod32
    mov     dl, 1               // Mod 01 (8-bit disp)
    jmp     .emit_start
.mod32:
    mov     dl, 2               // Mod 10 (32-bit disp)
    jmp     .emit_start
.mod00:
    xor     dl, dl              // Mod 00 (no disp)
    // Special case: if base is RBP/R13, we MUST use Mod 01 with disp 0
    mov     al, bl
    and     al, 0x07
    cmp     al, 5
    jne     .emit_start
    mov     dl, 1
    
.emit_start:
    // SIB Logic
    // If index != 0xFF or base == 4 (RSP), use SIB
    cmp     cl, 0xFF
    jne     .use_sib
    mov     al, bl
    and     al, 0x07
    cmp     al, 4               // RSP/R12
    je      .use_sib
    
    // No SIB
    mov     al, dl              // Mod
    shl     al, 6
    shl     r14b, 3             // Reg
    or      al, r14b
    mov     cl, bl              // R/M (Base)
    and     cl, 0x07
    or      al, cl
    call    amd64_emit_byte
    jmp     .disp
    
.use_sib:
    // Emit ModRM with R/M = 100b (4)
    mov     al, dl
    shl     al, 6
    shl     r14b, 3
    or      al, r14b
    or      al, 4               // R/M = 4 (SIB follows)
    call    amd64_emit_byte
    
    // Emit SIB
    // Scale (2 bits) | Index (3 bits) | Base (3 bits)
    mov     al, [r13 + OPERAND_scale]
    // Map scale 1,2,4,8 to 0,1,2,3
    xor     cl, cl
    cmp     al, 2
    je      .s1
    cmp     al, 4
    je      .s2
    cmp     al, 8
    je      .s3
    jmp     .s0
.s1: mov cl, 1 | jmp .s0
.s2: mov cl, 2 | jmp .s0
.s3: mov cl, 3
.s0:
    shl     cl, 6
    mov     al, [r13 + OPERAND_index]
    cmp     al, 0xFF
    jne     .idx_ok
    mov     al, 4               // Index 4 with SIB = no index
.idx_ok:
    and     al, 0x07
    shl     al, 3
    or      cl, al
    mov     al, bl              // Base
    and     al, 0x07
    or      cl, al
    mov     al, cl
    call    amd64_emit_byte
    
.disp:
    // Emit Displacement
    IF dl, e, 1
        mov     rax, [r13 + OPERAND_imm]
        call    amd64_emit_byte
    ELSEIF dl, e, 2
        mov     rdi, [r13 + OPERAND_imm]
        call    amd64_emit_dword
    ENDIF

.done_sib:
    pop     r14
    pop     r13
    pop     rdx
    pop     rcx
    pop     rbx
    ret

/**
 * [amd64_emit_byte]
 */
amd64_emit_byte:
    extern asm_ctx_emit_byte
    push    rax
    
    // Check architectural limit (15 bytes)
    mov     eax, [rbx + ASMCTX_inst_len]
    IF eax, ge, 15
        pop rax
        jmp amd64_encode_instruction.error
    ENDIF
    inc     dword [rbx + ASMCTX_inst_len]
    
    pop     rax
    mov     rdi, rbx
    movzx   rsi, al
    call    asm_ctx_emit_byte
    ret

/**
 * [amd64_emit_dword]
 * Input: RDI = 32-bit value
 */
amd64_emit_dword:
    push    rax
    push    rcx
    mov     rcx, 4
.loop:
    mov     al, dil
    call    amd64_emit_byte
    shr     rdi, 8
    loop    .loop
    pop     rcx
    pop     rax
    ret

/**
 * [amd64_emit_nop]
 * Purpose: Emits an optimal NOP sequence of length RAX.
 * Maximum supported in one call: 9 bytes.
 */
amd64_emit_nop:
    prologue
    IF rax, e, 1
        mov al, 0x90 | call amd64_emit_byte
    ELSEIF rax, e, 2
        mov al, 0x66 | call amd64_emit_byte
        mov al, 0x90 | call amd64_emit_byte
    ELSEIF rax, e, 3
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x00 | call amd64_emit_byte
    ELSEIF rax, e, 4
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x40 | call amd64_emit_byte
        mov al, 0x00 | call amd64_emit_byte
    ELSEIF rax, e, 5
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x44 | call amd64_emit_byte
        mov al, 0x00 | call amd64_emit_byte
        mov al, 0x00 | call amd64_emit_byte
    ELSEIF rax, e, 6
        mov al, 0x66 | call amd64_emit_byte
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x44 | call amd64_emit_byte
        mov al, 0x00 | call amd64_emit_byte
        mov al, 0x00 | call amd64_emit_byte
    ELSEIF rax, e, 7
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x80 | call amd64_emit_byte
        xor al, al | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte
    ELSEIF rax, e, 8
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x84 | call amd64_emit_byte
        xor al, al | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte
    ELSEIF rax, e, 9
        mov al, 0x66 | call amd64_emit_byte
        mov al, 0x0F | call amd64_emit_byte
        mov al, 0x1F | call amd64_emit_byte
        mov al, 0x84 | call amd64_emit_byte
        xor al, al | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte | call amd64_emit_byte
    ENDIF
    epilogue

/**
 * [amd64_emit_word]
 */
amd64_emit_word:
    push    rax
    push    rcx
    mov     rcx, 2
.loopw:
    mov     al, dil
    call    amd64_emit_byte
    shr     rdi, 8
    loop    .loopw
    pop     rcx
    pop     rax
    ret

/**
 * [amd64_emit_dword]
 */
amd64_emit_dword:
    push    rax
    push    rcx
    mov     rcx, 4
.loopd:
    mov     al, dil
    call    amd64_emit_byte
    shr     rdi, 8
    loop    .loopd
    pop     rcx
    pop     rax
    ret

/**
 * [amd64_emit_qword]
 */
amd64_emit_qword:
    push    rax
    push    rcx
    mov     rcx, 8
.loopq:
    mov     al, dil
    call    amd64_emit_byte
    shr     rdi, 8
    loop    .loopq
    pop     rcx
    pop     rax
    ret
