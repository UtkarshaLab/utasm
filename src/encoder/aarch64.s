/*
 ============================================================================
 File        : src/encoder/aarch64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AArch64 instruction encoder. Encodes parsed INST structs
               into 32-bit fixed-width AArch64 machine code words.
               Implementation mirrors the scale and robustness of amd64.s.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"
%inc "include/arch/aarch64.s"

[SECTION .text]

// ============================================================================
// aarch64_encode_instruction
// ============================================================================
/*
 aarch64_encode_instruction
 Top-level dispatcher for AArch64 instruction encoding.

 Input  : rdi = AsmCtx*
           rsi = INST*
 Output : rax = EXIT_OK or EXIT_ENCODE_FAIL
*/
global aarch64_encode_instruction
aarch64_encode_instruction:
    prologue
    push    rbx
    push    r12
    push    r13

    mov     rbx, rdi               // RBX = AsmCtx
    mov     r12, rsi               // R12 = INST*

    // Reset length counter (AArch64 is always 4 bytes per instruction)
    mov     dword [rbx + ASMCTX_inst_len], 4

    movzx   eax, word [r12 + INST_op_id]

    // ---- Arithmetic & Logical (Register) ----
    IF eax, e, ID_AARCH64_ADD
        mov     r13d, 0x8B000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_SUB
        mov     r13d, 0xCB000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_AND
        mov     r13d, 0x8A000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ORR
        mov     r13d, 0xAA000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_EOR
        mov     r13d, 0xCA000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ANDS
        mov     r13d, 0xEA000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_BIC
        mov     r13d, 0x8A200000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ORN
        mov     r13d, 0xAA200000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_EON
        mov     r13d, 0xCA200000 | call aarch64_encode_dp_reg

    // ---- Arithmetic & Logical (Immediate) ----
    // (Handled within dp_reg if op2 is immediate, but often distinct opcodes)
    // For AArch64, ADD/SUB immediate uses a different format.

    // ---- Movement ----
    ELSEIF eax, e, ID_AARCH64_MOV
        call    aarch64_encode_mov
    ELSEIF eax, e, ID_AARCH64_MOVZ
        mov     r13d, 0xD2800000 | call aarch64_encode_mov_wide
    ELSEIF eax, e, ID_AARCH64_MOVN
        mov     r13d, 0x92800000 | call aarch64_encode_mov_wide
    ELSEIF eax, e, ID_AARCH64_MOVK
        mov     r13d, 0xF2800000 | call aarch64_encode_mov_wide

    // ---- Comparison ----
    ELSEIF eax, e, ID_AARCH64_CMP
        call    aarch64_encode_cmp
    ELSEIF eax, e, ID_AARCH64_TST
        call    aarch64_encode_tst

    // ---- Branches ----
    ELSEIF eax, e, ID_AARCH64_B
        call    aarch64_encode_branch
    ELSEIF eax, e, ID_AARCH64_BL
        mov     r13d, 0x94000000 | call aarch64_encode_branch_link
    ELSEIF eax, e, ID_AARCH64_BR
        mov     r13d, 0xD61F0000 | call aarch64_encode_branch_reg
    ELSEIF eax, e, ID_AARCH64_BLR
        mov     r13d, 0xD63F0000 | call aarch64_encode_branch_reg
    ELSEIF eax, e, ID_AARCH64_RET
        call    aarch64_encode_ret
    ELSEIF eax, e, ID_AARCH64_CBZ
        mov     r13d, 0x34000000 | call aarch64_encode_comp_branch
    ELSEIF eax, e, ID_AARCH64_CBNZ
        mov     r13d, 0x35000000 | call aarch64_encode_comp_branch

    // ---- Load / Store ----
    ELSEIF eax, e, ID_AARCH64_LDR
        call    aarch64_encode_ldr
    ELSEIF eax, e, ID_AARCH64_STR
        call    aarch64_encode_str
    ELSEIF eax, e, ID_AARCH64_LDP
        mov     r13d, 1 | call aarch64_encode_ldst_pair
    ELSEIF eax, e, ID_AARCH64_STP
        mov     r13d, 0 | call aarch64_encode_ldst_pair

    // ---- Misc ----
    ELSEIF eax, e, ID_AARCH64_NOP
        mov     edi, 0xD503201F | call aarch64_emit_word
    ELSEIF eax, e, ID_AARCH64_SVC
        call    aarch64_encode_svc
    ELSE
        mov     rax, EXIT_ENCODE_FAIL
        jmp     .done
    ENDIF

    xor     rax, rax

.done:
    pop     r13
    pop     r12
    pop     rbx
    epilogue

// ============================================================================
// Internal Helpers & Encoders
// ============================================================================

aarch64_emit_word:
    prologue
    // Write 4 bytes to current section
    mov     rdx, rdi               // instruction word
    mov     rdi, rbx               // AsmCtx
    mov     rsi, [r12 + INST_section]
    extern  asmctx_emit_dword
    call    asmctx_emit_dword
    epilogue

// ---- aarch64_encode_dp_reg ----
// Covers ADD, SUB, AND, ORR, EOR, etc. (Shifted register)
// Format: sf | op | 0 | shift | 0 | Rm | imm6 | Rn | Rd
aarch64_encode_dp_reg:
    prologue
    lea     r10, [r12 + INST_op0]  // Rd
    lea     r11, [r12 + INST_op1]  // Rn
    lea     r9,  [r12 + INST_op2]  // Rm or Imm

    mov     eax, r13d              // base opcode

    // sf bit (64-bit vs 32-bit)
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000
    ENDIF

    movzx   edi, byte [r10 + OPERAND_reg]   // Rd
    or      eax, edi

    movzx   edi, byte [r11 + OPERAND_reg]   // Rn
    shl     edi, 5
    or      eax, edi

    // Check if op2 is register or immediate
    IF byte [r9 + OPERAND_kind], e, OP_REG
        movzx   edi, byte [r9 + OPERAND_reg] // Rm
        shl     edi, 16
        or      eax, edi
        // TODO: Handle shift (LSL, LSR, ASR)
    ELSEIF byte [r9 + OPERAND_kind], e, OP_IMM
        // ADD/SUB (immediate) uses different format: sf | op | 1 | sh | imm12 | Rn | Rd
        // We detect this and adjust the opcode base
        and     eax, 0x7FFFFFFF // clear high bit temporarily
        IF eax, e, 0x0B000000  // ADD
            mov eax, 0x11000000
        ELSEIF eax, e, 0x4B000000 // SUB
            mov eax, 0x51000000
        ENDIF
        // Restore sf
        IF byte [r10 + OPERAND_size], e, 8
            or      eax, 0x80000000
        ENDIF
        
        mov     edi, [r9 + OPERAND_imm]
        and     edi, 0xFFF
        shl     edi, 10
        or      eax, edi
    ENDIF

    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_mov ----
aarch64_encode_mov:
    prologue
    lea     r9, [r12 + INST_op1]
    IF byte [r9 + OPERAND_kind], e, OP_IMM
        mov     r13d, 0xD2800000 // MOVZ base
        call    aarch64_encode_mov_wide
    ELSE
        // MOV Rd, Rn  =>  ORR Rd, XZR, Rn
        mov     r13d, 0xAA000000
        // We simulate ORR Rd, XZR, Rn by forcing Rn to be XZR (31) or something
        // Actually ORR Rd, XZR, Rm is: sf | 0101010 | 00 | Rm | 000000 | 11111 | Rd
        // Let's just call dp_reg with special setup?
        // Simpler: hardcode it
        lea     r10, [r12 + INST_op0]
        lea     r11, [r12 + INST_op1]
        mov     eax, 0x2A0003E0 // ORR (32-bit) with Rn=WZR
        IF byte [r10 + OPERAND_size], e, 8
            or  eax, 0x80000000
        ENDIF
        movzx   edi, byte [r10 + OPERAND_reg]
        or      eax, edi
        movzx   edi, byte [r11 + OPERAND_reg]
        shl     edi, 16
        or      eax, edi
        mov     rdi, rax
        call    aarch64_emit_word
    ENDIF
    epilogue

// ---- aarch64_encode_mov_wide ----
// MOVZ, MOVN, MOVK
aarch64_encode_mov_wide:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, r13d
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    and     edi, 0xFFFF
    shl     edi, 5
    or      eax, edi
    
    // TODO: Handle shift (LSL #16, #32, #48)
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_branch ----
aarch64_encode_branch:
    prologue
    lea     r10, [r12 + INST_op0]
    // B label => 0x14000000 | (imm26 >> 2)
    mov     eax, 0x14000000
    mov     edi, [r10 + OPERAND_imm]
    sar     edi, 2
    and     edi, 0x03FFFFFF
    or      eax, edi
    
    // If operand is a symbol, record relocation
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx               // AsmCtx
        mov     rsi, [r12 + INST_offset] // current instr offset
        mov     rdx, [r10 + OPERAND_value] // sym name
        xor     rcx, rcx               // addend
        mov     r8, R_AARCH64_JMP26
        extern  reloc_record
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_branch_link ----
aarch64_encode_branch_link:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     eax, r13d
    mov     edi, [r10 + OPERAND_imm]
    sar     edi, 2
    and     edi, 0x03FFFFFF
    or      eax, edi
    
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx               // AsmCtx
        mov     rsi, [r12 + INST_offset] // offset
        mov     rdx, [r10 + OPERAND_value] // sym name
        xor     rcx, rcx               // addend
        mov     r8, R_AARCH64_CALL26
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_branch_reg ----
aarch64_encode_branch_reg:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 5
    or      eax, edi
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_comp_branch ----
aarch64_encode_comp_branch:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, r13d
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    sar     edi, 2
    and     edi, 0x7FFFF
    shl     edi, 5
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_ret ----
aarch64_encode_ret:
    prologue
    // RET {Xn} => 0xD65F0000 | (Rn << 5)
    mov     eax, 0xD65F0000
    IF byte [r12 + INST_nops], e, 0
        or      eax, (30 << 5) // default to X30 (LR)
    ELSE
        lea     r10, [r12 + INST_op0]
        movzx   edi, byte [r10 + OPERAND_reg]
        shl     edi, 5
        or      eax, edi
    ENDIF
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_ldr / str ----
aarch64_encode_ldr:
    prologue
    mov     r13d, 0xB9400000 // LDR (unsigned immediate) 32-bit
    call    aarch64_encode_ldst
    epilogue

aarch64_encode_str:
    prologue
    mov     r13d, 0xB9000000 // STR (unsigned immediate) 32-bit
    call    aarch64_encode_ldst
    epilogue

aarch64_encode_ldst:
    prologue
    lea     r10, [r12 + INST_op0] // Rt
    lea     r11, [r12 + INST_op1] // [Rn, #imm]
    
    mov     eax, r13d
    
    // Size bits [31:30]
    // 00=8, 01=16, 10=32, 11=64
    mov     cl, [r10 + OPERAND_size]
    IF cl, e, 8
        or      eax, 0xC0000000
    ELSEIF cl, e, 4
        or      eax, 0x80000000
    ELSEIF cl, e, 2
        or      eax, 0x40000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    movzx   edi, byte [r11 + OPERAND_base]
    shl     edi, 5
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    // Unsigned offset is scaled by size
    IF cl, e, 8
        shr     edi, 3
    ELSEIF cl, e, 4
        shr     edi, 2
    ELSEIF cl, e, 2
        shr     edi, 1
    ENDIF
    and     edi, 0xFFF
    shl     edi, 10
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_ldst_pair ----
aarch64_encode_ldst_pair:
    prologue
    // LDP/STP Xt1, Xt2, [Xn, #imm]
    // Format: opc | 101 | V | L | imm7 | Rt2 | Rn | Rt1
    lea     r10, [r12 + INST_op0] // Rt1
    lea     r11, [r12 + INST_op1] // Rt2
    lea     r9,  [r12 + INST_op2] // [Rn, #imm]
    
    mov     eax, 0x28000000
    IF r13d, e, 1
        or      eax, 0x00400000 // L bit
    ENDIF
    
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000 // opc=10
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 10
    or      eax, edi
    movzx   edi, byte [r9 + OPERAND_base]
    shl     edi, 5
    or      eax, edi
    
    mov     edi, [r9 + OPERAND_imm]
    // imm7 is scaled by size
    IF byte [r10 + OPERAND_size], e, 8
        sar     edi, 3
    ELSE
        sar     edi, 2
    ENDIF
    and     edi, 0x7F
    shl     edi, 15
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_cmp / tst ----
aarch64_encode_cmp:
    prologue
    // CMP Xn, Xm => SUBS XZR, Xn, Xm
    // CMP Xn, #imm => SUBS XZR, Xn, #imm
    // We modify the INST struct in-place or simulate it
    mov     byte [r12 + INST_op0 + OPERAND_reg], 31 // XZR
    mov     r13d, 0x6B000000 // SUBS base
    call    aarch64_encode_dp_reg
    epilogue

aarch64_encode_tst:
    prologue
    // TST Xn, Xm => ANDS XZR, Xn, Xm
    mov     byte [r12 + INST_op0 + OPERAND_reg], 31 // XZR
    mov     r13d, 0x6A000000 // ANDS base
    call    aarch64_encode_dp_reg
    epilogue

// ---- aarch64_encode_svc ----
aarch64_encode_svc:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     eax, 0xD4000001
    IF byte [r12 + INST_nops], ne, 0
        mov     edi, [r10 + OPERAND_imm]
        and     edi, 0xFFFF
        shl     edi, 5
        or      eax, edi
    ENDIF
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue
