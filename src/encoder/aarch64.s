/*
 ============================================================================
 File        : src/encoder/aarch64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AArch64 instruction encoder. Encodes parsed INST structs
               into 32-bit fixed-width AArch64 machine code words.
               All AArch64 instructions are exactly 4 bytes, little-endian.
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
 Reads the INST struct and emits 4 bytes into the current section buffer.

 Input  : rdi = AsmCtx*
           rsi = INST*
 Output : rax = EXIT_OK or EXIT_ENCODE_FAIL
*/
global aarch64_encode_instruction
aarch64_encode_instruction:
    prologue
    push    r12
    push    r13

    mov     r12, rdi               // r12 = AsmCtx
    mov     r13, rsi               // r13 = INST*

    movzx   eax, word [r13 + INST_op_id]

    // ---- Data Processing — Register ----
    IF eax, e, 100                 // MOV (register)
        call    aarch64_encode_mov_reg
    ELSEIF eax, e, 101             // ADD
        mov     r14d, 0x8B000000   // ADD X_,X_,X_ base encoding
        call    aarch64_encode_dp3
    ELSEIF eax, e, 102             // SUB
        mov     r14d, 0xCB000000
        call    aarch64_encode_dp3
    ELSEIF eax, e, 107             // EOR
        mov     r14d, 0xCA000000
        call    aarch64_encode_dp3
    ELSEIF eax, e, 106             // CMP (SUBS to XZR)
        call    aarch64_encode_cmp
    // ---- Branches ----
    ELSEIF eax, e, 104             // B
        call    aarch64_encode_b
    ELSEIF eax, e, 105             // BL
        call    aarch64_encode_bl
    ELSEIF eax, e, 103             // RET
        call    aarch64_encode_ret
    // ---- Load / Store ----
    ELSEIF eax, e, 108             // LDR
        call    aarch64_encode_ldr
    ELSEIF eax, e, 109             // STR
        call    aarch64_encode_str
    ELSE
        mov     rax, EXIT_ENCODE_FAIL
        jmp     .done
    ENDIF

.done:
    pop     r13
    pop     r12
    epilogue

// ============================================================================
// Internal Helpers
// ============================================================================

// ---- aarch64_emit_word ----------------------------------
/*
 Writes 4 bytes (one instruction word) to the current output section.
 Input  : r12 = AsmCtx, edi = 32-bit instruction word
*/
aarch64_emit_word:
    prologue
    // Write 4 bytes to .text section buffer
    mov     rdi, r12
    mov     rsi, SEC_TEXT
    call    asmctx_get_section
    check_err

    mov     r10, rdx               // SECTION*
    mov     r11, [r10 + SECTION_size]
    lea     rdi, [r10 + SECTION_data + r11]  // next write pos
    mov     dword [rdi], edi
    add     qword [r10 + SECTION_size], 4
    xor     rax, rax
    epilogue

// ---- aarch64_encode_mov_reg ----------------------------
// MOV Xd, Xn  =>  ORR Xd, XZR, Xn  (0xAA0003E0 | Rd | Rn<<16)
aarch64_encode_mov_reg:
    prologue
    lea     r10, [r13 + INST_op0]
    lea     r11, [r13 + INST_op1]

    movzx   edi, byte [r10 + OPERAND_reg]    // Rd
    movzx   ecx, byte [r11 + OPERAND_reg]    // Rn
    mov     eax, 0xAA0003E0
    or      eax, edi                          // | Rd
    shl     ecx, 16
    or      eax, ecx                          // | Rn<<16

    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_dp3 --------------------------------
// Generic 3-register data processing: OP Xd, Xn, Xm
// r14d = base opcode (ADD/SUB/EOR etc.)
aarch64_encode_dp3:
    prologue
    lea     r10, [r13 + INST_op0]
    lea     r11, [r13 + INST_op1]
    lea     r9,  [r13 + INST_op2]

    movzx   edi, byte [r10 + OPERAND_reg]    // Rd
    movzx   ecx, byte [r11 + OPERAND_reg]    // Rn
    movzx   edx, byte [r9  + OPERAND_reg]    // Rm

    mov     eax, r14d
    or      eax, edi                          // | Rd
    shl     ecx, 5
    or      eax, ecx                          // | Rn<<5
    shl     edx, 16
    or      eax, edx                          // | Rm<<16

    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_cmp --------------------------------
// CMP Xn, Xm  =>  SUBS XZR, Xn, Xm (0xEB00001F)
aarch64_encode_cmp:
    prologue
    lea     r11, [r13 + INST_op0]
    lea     r9,  [r13 + INST_op1]

    movzx   ecx, byte [r11 + OPERAND_reg]    // Rn
    movzx   edx, byte [r9  + OPERAND_reg]    // Rm

    mov     eax, 0xEB00001F                   // SUBS XZR,...
    shl     ecx, 5
    or      eax, ecx
    shl     edx, 16
    or      eax, edx

    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_b ----------------------------------
// B <label>  =>  0x14000000 | (imm26 >> 2)
aarch64_encode_b:
    prologue
    lea     r10, [r13 + INST_op0]
    mov     rdi, [r10 + OPERAND_imm]         // branch target offset

    sar     rdi, 2                            // divide by 4
    and     edi, 0x3FFFFFF                    // mask to 26 bits
    or      edi, 0x14000000
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_bl ---------------------------------
// BL <label>  =>  0x94000000 | imm26
aarch64_encode_bl:
    prologue
    lea     r10, [r13 + INST_op0]
    mov     rdi, [r10 + OPERAND_imm]

    sar     rdi, 2
    and     edi, 0x3FFFFFF
    or      edi, 0x94000000
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_ret --------------------------------
// RET  =>  0xD65F03C0  (RET X30)
aarch64_encode_ret:
    prologue
    mov     edi, 0xD65F03C0
    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_ldr --------------------------------
// LDR Xt, [Xn, #imm]  =>  0xF9400000 | Xt | Xn<<5 | (imm/8)<<10
aarch64_encode_ldr:
    prologue
    lea     r10, [r13 + INST_op0]   // Xt
    lea     r11, [r13 + INST_op1]   // [Xn, #imm]

    movzx   edi, byte [r10 + OPERAND_reg]
    movzx   ecx, byte [r11 + OPERAND_base]
    mov     edx, [r11 + OPERAND_imm]

    sar     edx, 3                   // divide by 8 (scaled offset)
    and     edx, 0xFFF
    shl     edx, 10

    mov     eax, 0xF9400000
    or      eax, edi
    shl     ecx, 5
    or      eax, ecx
    or      eax, edx

    call    aarch64_emit_word
    epilogue

// ---- aarch64_encode_str --------------------------------
// STR Xt, [Xn, #imm]  =>  0xF9000000 | Xt | Xn<<5 | (imm/8)<<10
aarch64_encode_str:
    prologue
    lea     r10, [r13 + INST_op0]
    lea     r11, [r13 + INST_op1]

    movzx   edi, byte [r10 + OPERAND_reg]
    movzx   ecx, byte [r11 + OPERAND_base]
    mov     edx, [r11 + OPERAND_imm]

    sar     edx, 3
    and     edx, 0xFFF
    shl     edx, 10

    mov     eax, 0xF9000000
    or      eax, edi
    shl     ecx, 5
    or      eax, ecx
    or      eax, edx

    call    aarch64_emit_word
    epilogue
