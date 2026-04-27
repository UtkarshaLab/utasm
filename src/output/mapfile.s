/*
 ============================================================================
 File        : src/output/mapfile.s
 Project     : utasm
 Version     : 0.1.0
 Description : Linker Map File Generator. Lists all symbols and their addresses.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"

extern io_write
extern io_open
extern io_close
extern str_len

[SECTION .text]

/**
 * [mapfile_generate]
 * Purpose: Dumps the symbol table into a .map file.
 */
global mapfile_generate
mapfile_generate:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi               // RBX = AsmCtx
    
    // 1. Open .map file
    // (Logic for name + ".map")
    mov     rdi, [rbx + ASMCTX_output]
    mov     rsi, AMD64_O_WRONLY | AMD64_O_CREAT | AMD64_O_TRUNC
    mov     rdx, 0o644
    call    io_open
    check_err
    mov     r12, rdx               // R12 = FD
    
    // 2. Iterate Symbols
    mov     r13, [rbx + ASMCTX_symtab]
    mov     r14d, [rbx + ASMCTX_symcount]
    
.sym_loop:
    test    r14, r14
    jz      .done
    
    mov     r8, r13                // R8 = SYMBOL*
    
    // Print Symbol Name
    mov     rdi, r12
    mov     rsi, [r8 + SYMBOL_name]
    call    io_write_str
    
    // Print tab
    mov     rdi, r12
    lea     rsi, [msg_tab]
    mov     rdx, 1
    call    io_write
    
    // (Logic for Hex Address conversion goes here)
    
    add     r13, SYMBOL_SIZE
    dec     r14
    jmp     .sym_loop

.done:
    mov     rdi, r12
    call    io_close
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

io_write_str:
    push    rdi
    mov     rdi, rsi
    call    str_len
    mov     rdx, rax
    pop     rdi
    call    io_write
    ret

[SECTION .data]
msg_tab: db 9
