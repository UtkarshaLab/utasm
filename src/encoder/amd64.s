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
    
    movzx   rax, word [r12 + INST_op_id]
    
    // Dispatch based on Mnemonic ID
    IF ax, e, 1391                 // MOV
        call    amd64_encode_mov
    ELSEIF ax, e, 1682             // SYSCALL
        call    amd64_encode_syscall
    ELSEIF ax, e, 1440             // NOP
        mov     al, 0x90
        call    amd64_emit_byte
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
    
    // Case 1: MOV REG, REG
    IF byte [r13 + OPERAND_kind], e, OP_REG
        IF byte [r14 + OPERAND_kind], e, OP_REG
            // Handle REX if 64-bit or extended
            mov     dl, [r13 + OPERAND_size]
            mov     cl, [r14 + OPERAND_size]
            
            // REX logic: 0x40 | (W << 3) | (R << 2) | (X << 1) | B
            xor     r15, r15
            IF dl, e, 8
                or  r15, 0x48      // REX.W
            ENDIF
            
            mov     al, [r14 + OPERAND_reg] // Src is 'Reg' field of ModRM (R)
            IF al, ge, 8
                or  r15, 0x44      // REX.R
            ENDIF
            
            mov     al, [r13 + OPERAND_reg] // Dest is 'R/M' field of ModRM (B)
            IF al, ge, 8
                or  r15, 0x41      // REX.B
            ENDIF
            
            // Emit REX if necessary
            test    r15, r15
            jz      .no_rex
            mov     rax, r15
            call    amd64_emit_byte
.no_rex:
            // Opcode 0x89 (Reg -> Reg/Mem)
            mov     al, 0x89
            call    amd64_emit_byte
            
            // ModR/M: 11 (reg,reg) | (src << 3) | dest
            mov     al, 0xC0
            mov     cl, [r14 + OPERAND_reg]
            and     cl, 0x07       // Mask bits 3-7 for ModRM
            shl     cl, 3
            or      al, cl
            
            mov     cl, [r13 + OPERAND_reg]
            and     cl, 0x07
            or      al, cl
            
            call    amd64_emit_byte
            jmp     .done
        ENDIF
        
        // Case 2: MOV REG, IMM
        IF byte [r14 + OPERAND_kind], e, OP_IMM
            mov     dl, [r13 + OPERAND_size]
            
            // For 64-bit MOV REG, IMM64: Opcode 0xB8 + reg
            IF dl, e, 8
                // REX.W
                xor     r15, r15
                mov     al, 0x48
                mov     cl, [r13 + OPERAND_reg]
                IF cl, ge, 8
                    or  al, 0x01   // REX.B
                ENDIF
                call    amd64_emit_byte
                
                mov     al, 0xB8
                and     cl, 0x07
                add     al, cl
                call    amd64_emit_byte
                
                // Emit 8 bytes of immediate
                mov     rdi, [r14 + OPERAND_imm]
                call    amd64_emit_qword
                jmp     .done
            ENDIF
            
            // For 32-bit: Opcode 0xB8 + reg
            mov     al, 0xB8
            mov     cl, [r13 + OPERAND_reg]
            add     al, cl
            call    amd64_emit_byte
            mov     rdi, [r14 + OPERAND_imm]
            call    amd64_emit_dword
            jmp     .done
        ENDIF

        // Case 3: MOV REG, MEM
        IF byte [r14 + OPERAND_kind], e, OP_MEM
            // Opcode 0x8B (Reg/Mem -> Reg)
            mov     al, 0x48 // REX.W (Assume 64-bit for now)
            call    amd64_emit_byte
            mov     al, 0x8B
            call    amd64_emit_byte
            
            // ModR/M: 00 (no disp) or 10 (32-bit disp)
            // For [rax], it's 0x00
            mov     al, [r13 + OPERAND_reg]
            shl     al, 3
            or      al, [r14 + OPERAND_base]
            call    amd64_emit_byte
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
            
            mov     al, [r14 + OPERAND_reg]
            shl     al, 3
            or      al, [r13 + OPERAND_base]
            call    amd64_emit_byte
            jmp     .done
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
    mov     al, 0x0F
    call    amd64_emit_byte
    mov     al, 0x05
    call    amd64_emit_byte
    ret

/**
 * [amd64_emit_byte]
 */
amd64_emit_byte:
    extern asm_ctx_emit_byte
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
 * [amd64_emit_qword]
 * Input: RDI = 64-bit value
 */
amd64_emit_qword:
    push    rax
    push    rcx
    mov     rcx, 8
.loop:
    mov     al, dil
    call    amd64_emit_byte
    shr     rdi, 8
    loop    .loop
    pop     rcx
    pop     rax
    ret
