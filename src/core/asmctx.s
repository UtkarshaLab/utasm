/*
 ============================================================================
 File        : src/core/asmctx.s
 Project     : utasm
 Version     : 0.1.0
 Description : Assembly Context and Section Management.
 ============================================================================
*/

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

[SECTION .text]

/**
 * [asm_ctx_emit_byte]
 * Purpose: Appends a single byte to the active section's buffer.
 * Input:
 *   RDI: Pointer to AsmCtx
 *   RSI: Byte to emit (SIL)
 */
global asm_ctx_emit_byte
asm_ctx_emit_byte:
    prologue
    push    rbx
    push    r12
    
    mov     rbx, rdi               // RBX = AsmCtx
    
    // 1. Get current section
    // For now, we assume the first section is active
    // We should later add a 'current_section' field to ASMCTX
    mov     r12, [rbx + ASMCTX_sections]
    test    r12, r12
    jz      .no_section
    
    // 2. Check capacity
    mov     rax, [r12 + SECTION_size]
    cmp     rax, [r12 + SECTION_cap]
    jae     .grow_section
    
.write:
    mov     rdx, [r12 + SECTION_data]
    add     rdx, rax
    mov     [rdx], sil
    
    inc     rax
    mov     [r12 + SECTION_size], rax
    
    pop     r12
    pop     rbx
    epilogue

.no_section:
    mov     rax, EXIT_INTERNAL
    pop     r12
    pop     rbx
    epilogue

.grow_section:
    // TODO: Implement section buffer growth
    // For now, just error out if we hit capacity
    mov     rax, EXIT_OOM
    pop     r12
    pop     rbx
    epilogue

/**
 * [asm_ctx_create_section]
 * Purpose: Creates a new section and adds it to the context.
 */
global asm_ctx_create_section
asm_ctx_create_section:
    prologue
    // ... Implementation for section creation ...
    epilogue
