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
    mov     r12, [rbx + ASMCTX_curr_sec]
    test    r12, r12
    jz      .try_first_section
    
    jmp     .check_cap

.try_first_section:
    mov     r12, [rbx + ASMCTX_sections]
    mov     r12, [r12]             // Get first SECTION*
    test    r12, r12
    jz      .no_section

.check_cap:
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
    // 1. Calculate new capacity (current * 2)
    mov     rax, [r12 + SECTION_cap]
    shl     rax, 1
    IF rax, e, 0 | mov rax, 65536 | ENDIF // Default 64KB
    mov     r13, rax               // r13 = new cap
    
    // 2. Map new buffer
    // io_mmap(NULL, size, PROT_RW, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
    xor     rdi, rdi
    mov     rsi, r13
    mov     rdx, PROT_READ | PROT_WRITE
    mov     rcx, MAP_PRIVATE | MAP_ANONYMOUS
    mov     r8, -1
    xor     r9, r9
    call    io_mmap
    IF rax, ne, EXIT_OK
        jmp .done
    ENDIF
    mov     r14, rdx               // r14 = new buffer ptr
    
    // 3. Copy old data
    mov     rdi, r14
    mov     rsi, [r12 + SECTION_data]
    mov     rcx, [r12 + SECTION_size]
    rep movsb
    
    // 4. Unmap old buffer
    mov     rdi, [r12 + SECTION_data]
    mov     rsi, [r12 + SECTION_cap]
    call    io_munmap
    
    // 5. Update section struct
    mov     [r12 + SECTION_data], r14
    mov     [r12 + SECTION_cap], r13
    
    jmp     .write

.done:
    pop     r12
    pop     rbx
    epilogue

/**
 * [asm_ctx_create_section]
 * Purpose: Creates a new section and adds it to the context.
 */
/**
 * [asm_ctx_create_section]
 * Purpose: Creates a new section and adds it to the context.
 * Input:
 *   RDI: Pointer to AsmCtx
 *   RSI: Section Name (Pointer)
 *   RDX: Section Type (SEC_*)
 * Output:
 *   RAX: EXIT_OK or error
 *   RDX: Pointer to new SECTION
 */
global asm_ctx_create_section
asm_ctx_create_section:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi               // RBX = AsmCtx
    mov     r12, rsi               // R12 = Name
    mov     r13, rdx               // R13 = Type
    
    // 1. Allocate SECTION struct from Arena
    mov     rdi, [rbx + ASMCTX_arena]
    mov     rsi, SECTION_SIZE
    mov     rdx, TAG_SECTION
    call    arena_alloc_struct
    check_err
    mov     r14, rdx               // R14 = SECTION*
    
    // 2. Initialize metadata
    mov     [r14 + SECTION_name], r12
    mov     byte [r14 + SECTION_type], r13b
    mov     qword [r14 + SECTION_cap], 65536 // Initial 64KB
    
    // 3. Allocate initial buffer
    xor     rdi, rdi
    mov     rsi, 65536
    mov     rdx, PROT_READ | PROT_WRITE
    mov     rcx, MAP_PRIVATE | MAP_ANONYMOUS
    mov     r8, -1
    xor     r9, r9
    call    io_mmap
    check_err
    mov     [r14 + SECTION_data], rdx
    
    // 4. Add to AsmCtx section array
    // (Simplified: for now we just handle a fixed array or linked list)
    mov     rax, [rbx + ASMCTX_sections]
    movzx   ecx, word [rbx + ASMCTX_seccount]
    mov     [rax + rcx*8], r14
    inc     word [rbx + ASMCTX_seccount]
    
    mov     rax, EXIT_OK
    mov     rdx, r14
    
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

/**
 * [asm_ctx_emit_dword]
 * Purpose: Appends 4 bytes to the active section's buffer.
 */
global asm_ctx_emit_dword
asm_ctx_emit_dword:
    prologue
    push    rbx
    push    r12
    mov     rbx, rdi
    mov     r12, rsi               // the dword
    
    // Emit 4 bytes
    mov     rdi, rbx
    mov     rsi, r12
    call    asm_ctx_emit_byte
    mov     rdi, rbx
    mov     rsi, r12
    shr     rsi, 8
    call    asm_ctx_emit_byte
    mov     rdi, rbx
    mov     rsi, r12
    shr     rsi, 16
    call    asm_ctx_emit_byte
    mov     rdi, rbx
    mov     rsi, r12
    shr     rsi, 24
    call    asm_ctx_emit_byte
    
    pop     r12
    pop     rbx
    epilogue

/**
 * [asm_ctx_align]
 * Purpose: Pads current section with zeros until requested alignment is met.
 * Input:
 *   RDI: Pointer to AsmCtx
 *   RSI: Alignment boundary (e.g., 4, 8, 16)
 */
global asm_ctx_align
asm_ctx_align:
    prologue
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi
    mov     r12, rsi
    
    // Get current size
    mov     r8, [rbx + ASMCTX_sections]
    mov     r9, [r8]               // SECTION*
    mov     rax, [r9 + SECTION_size]
    
    // Calculate padding: (align - (size % align)) % align
    xor     rdx, rdx
    div     r12                    // RDX = size % align
    test    rdx, rdx
    jz      .done_align                  // Already aligned
    
    mov     r13, r12
    sub     r13, rdx               // R13 = padding needed
    
.pad_loop:
    test    r13, r13
    jz      .done_align
    mov     rdi, rbx
    xor     rsi, rsi
    call    asm_ctx_emit_byte
    dec     r13
    jmp     .pad_loop

/**
 * [asm_ctx_emit_word]
 * Purpose: Appends 2 bytes (16-bit) to the active section.
 */
global asm_ctx_emit_word
asm_ctx_emit_word:
    prologue
    push    rbx
    push    r12
    mov     rbx, rdi
    mov     r12, rsi
    
    mov     rdi, rbx
    mov     rsi, r12
    call    asm_ctx_emit_byte
    mov     rdi, rbx
    mov     rsi, r12
    shr     rsi, 8
    call    asm_ctx_emit_byte
    
    pop     r12
    pop     rbx
    epilogue

/**
 * [asm_ctx_emit_qword]
 * Purpose: Appends 8 bytes (64-bit) to the active section.
 */
global asm_ctx_emit_qword
asm_ctx_emit_qword:
    prologue
    push    rbx
    push    r12
    mov     rbx, rdi
    mov     r12, rsi
    
    mov     rdi, rbx
    mov     rsi, r12
    call    asm_ctx_emit_dword
    mov     rdi, rbx
    mov     rsi, r12
    shr     rsi, 32
    call    asm_ctx_emit_dword
    
    pop     r12
    pop     rbx
    epilogue

/**
 * [asm_ctx_emit_string]
 * Purpose: Appends a null-terminated string to the active section.
 * Input:
 *   RDI: Pointer to AsmCtx
 *   RSI: Pointer to null-terminated string
 */
global asm_ctx_emit_string
asm_ctx_emit_string:
    prologue
    push    rbx
    push    r12
    mov     rbx, rdi
    mov     r12, rsi
    
.loop:
    movzx   rsi, byte [r12]
    test    sil, sil
    jz      .done
    mov     rdi, rbx
    call    asm_ctx_emit_byte
    inc     r12
    jmp     .loop
    
.done:
    pop     r12
    pop     rbx
    epilogue
