/*
 ============================================
 File     : src/core/symbol.s
 Project  : utasm
 Version  : 0.1.0
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

%inc "include/constant.s"
%inc "include/type.s"

// ============================================================================
// SYMBOL TABLE
// ============================================================================
// Manages the registration and lookup of labels, constants, and macros.
// Currently implements a linear search (bootstrap-grade).
// Will be upgraded to a hash table for production performance.
//
// Calling convention (AMD64):
//   args  : rdi, rsi, rdx, rcx, r8, r9
//   return: rax = error code, rdx = result
//   callee saved: rbx, r12-r15, rbp
// ============================================================================

[SECTION .text]

// ---- symbol_init ------------------------
/*
 symbol_init
 Initialises the symbol table within an AsmCtx.
 Input    : rdi = pointer to AsmCtx
 Output   : rax = EXIT_OK or error code
*/
global symbol_init
symbol_init:
    push    rbx
    mov     rbx, rdi               // rbx = AsmCtx

    // Allocate initial symbol table (e.g. 1024 symbols)
    mov     rdi, [rbx + ASMCTX_arena]
    mov     rsi, SYMBOL_SIZE
    imul    rsi, MAX_SYMBOL       // MAX_SYMBOL defined in constant.s
    call    arena_alloc
    test    rax, rax
    jnz     .error

    mov     [rbx + ASMCTX_symtab], rdx
    mov     dword [rbx + ASMCTX_symcount], 0
    xor     rax, rax
    pop     rbx
    ret

.error:
    pop     rbx
    ret

// ---- symbol_add -------------------------
/*
 symbol_add
 Adds a new symbol to the table.
 Input    : rdi = pointer to AsmCtx
            rsi = pointer to Symbol (template)
 Output   : rax = EXIT_OK or EXIT_SYMBOL_EXISTS
            rdx = pointer to the stored Symbol
*/
global symbol_add
symbol_add:
    push    rbx
    push    r12
    push    r13
    mov     rbx, rdi               // rbx = AsmCtx
    mov     r12, rsi               // r12 = source symbol

    // 1. Check if it already exists
    mov     rdi, rbx
    mov     rsi, [r12 + SYMBOL_name]
    call    symbol_find
    test    rax, rax
    jz      .exists

    // 2. Check for overflow
    mov     eax, [rbx + ASMCTX_symcount]
    cmp     eax, MAX_SYMBOL
    jge     .error_full

    // 3. Copy symbol into table
    mov     r13, [rbx + ASMCTX_symtab]
    movzx   rax, ax
    imul    rax, SYMBOL_SIZE
    add     r13, rax               // r13 = dest symbol pointer

    // copy fields (48 bytes = 6 qwords)
    mov     rdi, r13
    mov     rsi, r12
    mov     rcx, 6
    rep movsq

    // 4. Increment count
    inc     dword [rbx + ASMCTX_symcount]

    mov     rdx, r13               // return pointer to stored symbol
    xor     rax, rax               // EXIT_OK
    jmp     .done

.exists:
    mov     rax, EXIT_DUP_SYMBOL
    mov     rdx, r12
    jmp     .done

.error_full:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx

.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- symbol_find ------------------------
/*
 symbol_find
 Searches for a symbol by name.
 Input    : rdi = pointer to AsmCtx
            rsi = pointer to name string (null-terminated)
 Output   : rax = EXIT_OK (found) or EXIT_SYMBOL_NOT_FOUND
            rdx = pointer to Symbol (if found)
*/
global symbol_find
symbol_find:
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     rbx, rdi               // rbx = AsmCtx
    mov     r12, rsi               // r12 = name to find
    mov     r13, [rbx + ASMCTX_symtab]
    mov     r14d, [rbx + ASMCTX_symcount]

    test    r13, r13
    jz      .not_found

.loop:
    test    r14d, r14d
    jz      .not_found

    mov     rdi, [r13 + SYMBOL_name]
    mov     rsi, r12
    call    str_cmp
    test    rax, rax
    jz      .found

    add     r13, SYMBOL_SIZE
    dec     r14d
    jmp     .loop

.found:
    mov     rdx, r13               // return pointer
    xor     rax, rax               // EXIT_OK
    jmp     .done

.not_found:
    mov     rax, EXIT_UNDEF_SYMBOL
    xor     rdx, rdx

.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
