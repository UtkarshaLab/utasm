/*
 ============================================================================
 File        : src/encoder/aarch64.s
 Project     : utasm
 Version     : 0.1.0
 Description : AArch64 Instruction Encoder Logic (Fixed 32-bit).
 ============================================================================
*/

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

[SECTION .text]

/**
 * [aarch64_encode_instruction]
 * Purpose: Encodes an AArch64 instruction into 32-bit machine code.
 * Input:
 *   RDI: Pointer to AsmCtx
 *   RSI: Pointer to INST struct
 * Output:
 *   RAX: OK or Error Code
 */
global aarch64_encode_instruction
aarch64_encode_instruction:
    prologue
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi               // RBX = AsmCtx
    mov     r12, rsi               // R12 = INST
    
    // Reset length counter (AArch64 is always 4 bytes per instruction)
    mov     dword [rbx + ASMCTX_inst_len], 0
    
    // 0. Defensive Validation: Operand Width Parity
    cmp     byte [r12 + INST_nops], 2
    jl      .no_size_check
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    mov     al, [r10 + OPERAND_size]
    mov     ah, [r11 + OPERAND_size]
    IF al, ne, ah
        IF byte [r11 + OPERAND_kind], e, OP_REG
            mov rax, EXIT_INVALID_OPERAND | jmp .done
        ENDIF
    ENDIF
.no_size_check:
    
    // 1. Dispatch based on Mnemonic ID
    movzx   rax, word [r12 + INST_op_id]
    
    IF ax, e, 1391                 // MOV
        call    aarch64_encode_mov
    ELSEIF ax, e, 1006             // ADD
        mov     r13, 0x0B000000 | call aarch64_encode_arithmetic
    ELSEIF ax, e, 1676             // SUB
        mov     r13, 0x4B000000 | call aarch64_encode_arithmetic
    ELSE
        mov     rax, EXIT_ENCODE_FAIL | jmp .done
    ENDIF

.done:
    pop     r13
    pop     r12
    pop     rbx
    epilogue

/**
 * [aarch64_encode_mov]
 */
aarch64_encode_mov:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // Pattern: ORR Rd, XZR, Rm (Register)
    // 32-bit: 0x2A0003E0 | (Rm << 16) | (Rd)
    // 64-bit: 0xAA0003E0 | (Rm << 16) | (Rd)
    
    mov     eax, 0x2A0003E0
    IF byte [r10 + OPERAND_size], e, 8
        or  eax, 0x80000000        // sf=1 (64-bit)
    ENDIF
    
    movzx   ecx, byte [r11 + OPERAND_reg]
    shl     ecx, 16
    or      eax, ecx
    
    movzx   ecx, byte [r10 + OPERAND_reg]
    or      eax, ecx
    
    call    aarch64_emit_dword
    mov     rax, OK
    epilogue

/**
 * [aarch64_encode_arithmetic]
 * R13 = Base Opcode (e.g. 0x0B000000 for ADD)
 */
aarch64_encode_arithmetic:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    // Pattern (Register): op sf 001011 000 Rm 000000 Rn Rd
    mov     eax, r13d
    IF byte [r10 + OPERAND_size], e, 8
        or  eax, 0x80000000        // sf=1
    ENDIF
    
    // Rn (from op0 or op1 depending on form; assume op0 is dest, op1 is src1)
    // ... Simplified: ADD Rd, Rd, Rm
    movzx   ecx, byte [r10 + OPERAND_reg]
    shl     ecx, 5
    or      eax, ecx
    
    movzx   ecx, byte [r11 + OPERAND_reg]
    shl     ecx, 16
    or      eax, ecx
    
    or      eax, [r10 + OPERAND_reg]
    
    call    aarch64_emit_dword
    mov     rax, OK
    epilogue

/**
 * [aarch64_emit_dword]
 */
aarch64_emit_dword:
    extern asm_ctx_emit_byte
    push    rax
    push    rcx
    mov     rcx, 4
.loop:
    movzx   rsi, al
    mov     rdi, rbx
    call    asm_ctx_emit_byte
    shr     rax, 8
    loop    .loop
    
    add     dword [rbx + ASMCTX_inst_len], 4
    pop     rcx
    pop     rax
    ret
