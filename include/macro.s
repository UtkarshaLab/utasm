/*
 ============================================
 File     : include/macro.s
 Project  : utasm
 Version  : 0.0.1
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

// ============================================================================
// STANDARD MACROS
// ============================================================================
// Helper macros for common assembly patterns.
// Based on standard conventions from NASM, FASM, and GAS.
// ============================================================================

// Standard function prologue (AMD64)
%macro prologue 0
    push    rbp
    mov     rbp, rsp
%endmacro

// Standard function epilogue (AMD64)
%macro epilogue 0
    mov     rsp, rbp
    pop     rbp
    ret
%endmacro

// Check for error in rax and jump to .error if non-zero
%macro check_err 0
    test    rax, rax
    jnz     .error
%endmacro

// Check for error in rax and jump to specified label if non-zero
%macro check_err_to 1
    test    rax, rax
    jnz     %1
%endmacro

// Save all volatile registers (AMD64 SysV ABI)
%macro push_volatile 0
    push    rax
    push    rcx
    push    rdx
    push    rsi
    push    rdi
    push    r8
    push    r9
    push    r10
    push    r11
%endmacro

// Restore all volatile registers (AMD64 SysV ABI)
%macro pop_volatile 0
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rax
%endmacro

// Zero-initialize a memory block of fixed size (using qwords)
%macro zero_mem 2
    mov     rdi, %1
    mov     rcx, (%2 / 8)
    xor     rax, rax
    rep stosq
%endmacro

// Verify that a struct has the expected tag
%macro assert_tag 2
    cmp     byte [%1], %2
    jne     .error_tag
%endmacro

// Allocate a struct of given size on the arena
%macro alloc_on_arena 2
    mov     rdi, [rbx + PREP_arena] // assumes rbx = PrepState or similar
    mov     rsi, %2
    call    arena_alloc
    test    rax, rax
    jnz     .error_oom
    mov     %1, rdx
%endmacro
// ---- Bit Manipulation --------------------

// Set a bit (bts)
%macro set_bit 2
    bts     %1, %2
%endmacro

// Clear a bit (btr)
%macro clr_bit 2
    btr     %1, %2
%endmacro

// Toggle a bit (btc)
%macro toggle_bit 2
    btc     %1, %2
%endmacro

// ---- String & Memory (AMD64) -------------

// Copy memory block (rep movsb)
%macro memcpy 3
    mov     rdi, %1
    mov     rsi, %2
    mov     rcx, %3
    rep     movsb
%endmacro

// Fill memory block (rep stosb)
%macro memset 3
    mov     rdi, %1
    mov     al, %2
    mov     rcx, %3
    rep     stosb
%endmacro

// Find string length (repne scasb)
%macro strlen 2
    mov     rdi, %1
    xor     al, al
    mov     rcx, -1
    repne   scasb
    not     rcx
    dec     rcx
    mov     %2, rcx
%endmacro

// ---- Cross-Architecture Helpers ----------

// Architecture-agnostic return
%macro ret_arch 0
    %ifdef ARCH_AARCH64
        ret
    %elif ARCH_RISCV64
        ret
    %else
        ret                     // Default to AMD64 ret
    %endif
%endmacro

// Architecture-agnostic break/trap
%macro trap_arch 0
    %ifdef ARCH_AARCH64
        brk     0
    %elif ARCH_RISCV64
        ebreak
    %else
        int3                    // AMD64 debug trap
    %endif
%endmacro

// ---- Math & Logic ------------------------

// Get absolute value of 64-bit register
%macro abs_64 1
    mov     rax, %1
    sar     rax, 63
    xor     %1, rax
    sub     %1, rax
%endmacro

// Get minimum of two 64-bit registers
%macro min_64 2
    cmp     %1, %2
    cmovg   %1, %2
%endmacro

// Get maximum of two 64-bit registers
%macro max_64 2
    cmp     %1, %2
    cmovl   %1, %2
%endmacro

// ---- High-Level Flow Control -------------
// Uses NASM context stack to manage unique labels.

// IF <reg/mem>, <cond>, <val>
// Example: IF rax, e, 0
%macro IF 3
    %push   if
    cmp     %1, %3
    jn%2    %$else_label
%endmacro

%macro ELSE 0
    %ifctx if
        %push   else
        jmp     %$endif_label
        %$else_label:
    %else
        %error "ELSE without IF"
    %endif
%endmacro

%macro ENDIF 0
    %ifctx else
        %$endif_label:
        %pop    else
        %pop    if
    %elifctx if
        %$else_label:
        %pop    if
    %else
        %error "ENDIF without IF"
    %endif
%endmacro

// WHILE <reg/mem>, <cond>, <val>
%macro WHILE 3
    %push   while
    %$loop_start:
    cmp     %1, %3
    jn%2    %$loop_end
%endmacro

%macro ENDWHILE 0
    %ifctx while
        jmp     %$loop_start
        %$loop_end:
        %pop    while
    %else
        %error "ENDWHILE without WHILE"
    %endif
%endmacro

// ---- Alignment ---------------------------

// Align to 64-byte cache line boundary
%macro align_cache 0
    align   64
%endmacro

// Generic alignment
%macro align_to 1
    align   %1
%endmacro
