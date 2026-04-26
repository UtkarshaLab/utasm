/*
 ============================================
 File     : include/macro.s
 Project  : utasm
 Version  : 0.0.1
 Author   : Utkarsha Lab
 License  : Apache-2.0
 Description: Standard utility macro library for utasm.
 ============================================
*/

// ============================================================================
// 1. FUNCTION & CONTEXT MANAGEMENT
// ============================================================================

// Function prologue: save RBP and set new frame
%macro prologue 0
    push    rbp
    mov     rbp, rsp
%endmacro

// Function epilogue: restore RBP and return
%macro epilogue 0
    mov     rsp, rbp
    pop     rbp
    ret
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

// Save full CPU state (GPRs + Flags)
%macro save_context 0
    pushfq
    push    rax
    push    rbx
    push    rcx
    push    rdx
    push    rsi
    push    rdi
    push    rbp
    push    r8
    push    r9
    push    r10
    push    r11
    push    r12
    push    r13
    push    r14
    push    r15
%endmacro

// Restore full CPU state (GPRs + Flags)
%macro restore_context 0
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     r11
    pop     r10
    pop     r9
    pop     r8
    pop     rbp
    pop     rdi
    pop     rsi
    pop     rdx
    pop     rcx
    pop     rbx
    pop     rax
    popfq
%endmacro

// Context switch: swap stack pointers
// %1 = save current RSP, %2 = load next RSP
%macro switch_context 2
    push    rbp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     [%1], rsp
    mov     rsp, [%2]
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
%endmacro

// ============================================================================
// 2. ERROR HANDLING & ASSERTIONS
// ============================================================================

// Branch to .error if RAX is non-zero
%macro check_err 0
    test    rax, rax
    jnz     .error
%endmacro

// Branch to %1 if RAX is non-zero
%macro check_err_to 1
    test    rax, rax
    jnz     %1
%endmacro

// Verify struct tag at [%1]
%macro assert_tag 2
    cmp     byte [%1], %2
    jne     .error_tag
%endmacro

// Trap if address %1 is not aligned to %2
%macro assert_aligned 2
    test    %1, (%2 - 1)
    jnz     .error_alignment
%endmacro

// Trap if address %1 is not cache-aligned (64 bytes)
%macro assert_cache_aligned 1
    test    %1, 63
    jnz     .error_cache_split
%endmacro

// Trap if register %1 is zero
%macro assert_not_zero 1
    test    %1, %1
    jz      .error_null
%endmacro

// Trap if %1 is outside range [%2, %3]
%macro assert_reg_range 3
    cmp     %1, %2
    jl      .error_bounds
    cmp     %1, %3
    jg      .error_bounds
%endmacro

// Verify 16-byte stack alignment
%macro stack_align_check 0
    test    rsp, 0xF
    jnz     .error_stack_unaligned
%endmacro

// ============================================================================
// 3. FLOW CONTROL (STRUCTURED)
// ============================================================================

// IF <val1>, <cond>, <val2>
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

// WHILE <val1>, <cond>, <val2>
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

// ============================================================================
// 4. MEMORY & DATA STRUCTURES
// ============================================================================

// Zero memory block: %1=ptr, %2=size (bytes)
%macro zero_mem 2
    mov     rdi, %1
    mov     rcx, (%2 / 8)
    xor     rax, rax
    rep stosq
%endmacro

// Allocate memory on current arena: %1=dest_reg, %2=size
%macro alloc_on_arena 2
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, %2
    call    arena_alloc
    test    rax, rax
    jnz     .error_oom
    mov     %1, rdx
%endmacro

// Save current arena pointer (checkpoint)
%macro push_alloc 0
    %push   arena
    mov     r10, [rbx + PREP_arena]
    push    qword [r10 + ARENA_ptr]
%endmacro

// Restore arena pointer to last checkpoint
%macro pop_alloc 0
    %ifctx arena
        mov     r10, [rbx + PREP_arena]
        pop     qword [r10 + ARENA_ptr]
        %pop    arena
    %else
        %error "pop_alloc without push_alloc"
    %endif
%endmacro

// Define structure layout
%macro struc 1
    %push   struc
    %define %$struc_name %1
    %assign %$offset 0
%endmacro

%macro field 2
    %def %{$struc_name}_%1 %$offset
    %assign %$offset %$offset + %2
%endmacro

%macro endstruc 0
    %def %{$struc_name}_SIZE %$offset
    %pop    struc
%endmacro

// Circular Buffer: Push
%macro cbuf_push 4
    mov     rax, [%2]
    mov     [%1 + rax], %4
    inc     rax
    and     rax, %3                // mask must be (size-1)
    mov     [%2], rax
%endmacro

// Circular Buffer: Pop
%macro cbuf_pop 4
    mov     rax, [%2]
    mov     %4, [%1 + rax]
    inc     rax
    and     rax, %3
    mov     [%2], rax
%endmacro

// Bloom Filter: Add
%macro bloom_add 2
    mov     rax, %2
    mov     rcx, rax
    shr     rax, 3
    and     rcx, 7
    mov     dl, 1
    shl     dl, cl
    or      byte [%1 + rax], dl
%endmacro

// Bloom Filter: Check
%macro bloom_check 2
    mov     rax, %2
    mov     rcx, rax
    shr     rax, 3
    and     rcx, 7
    mov     dl, 1
    shl     dl, cl
    test    byte [%1 + rax], dl
%endmacro

// ============================================================================
// 5. STRING & BUFFER OPERATIONS
// ============================================================================

// Memory copy: %1=dest, %2=src, %3=len
%macro memcpy 3
    mov     rdi, %1
    mov     rsi, %2
    mov     rcx, %3
    rep     movsb
%endmacro

// Non-temporal memory copy (bypasses cache)
%macro memcpy_nt 3
    mov     rdi, %1
    mov     rsi, %2
    mov     rcx, (%3 / 8)
%%loop:
    mov     rax, [rsi]
    movnti  [rdi], rax
    add     rsi, 8
    add     rdi, 8
    loop    %%loop
    sfence
%endmacro

// Memory fill: %1=ptr, %2=val, %3=len
%macro memset 3
    mov     rdi, %1
    mov     al, %2
    mov     rcx, %3
    rep     stosb
%endmacro

// String length: %1=ptr, %2=dest_reg
%macro strlen 2
    mov     rdi, %1
    xor     al, al
    mov     rcx, -1
    repne   scasb
    not     rcx
    dec     rcx
    mov     %2, rcx
%endmacro

// LEB128 Encoding (Variable Length Integer)
%macro encode_leb128 2
    mov     rax, %1
    mov     rdi, %2
%%loop:
    mov     dl, al
    and     dl, 0x7F
    shr     rax, 7
    jz      %%done
    or      dl, 0x80
    mov     [rdi], dl
    inc     rdi
    jmp     %%loop
%%done:
    mov     [rdi], dl
    inc     rdi
    mov     %2, rdi
%endmacro

// ============================================================================
// 6. BITWISE & MATHEMATICAL OPERATIONS
// ============================================================================

%macro set_bit 2
    bts     %1, %2
%endmacro

%macro clr_bit 2
    btr     %1, %2
%endmacro

%macro toggle_bit 2
    btc     %1, %2
%endmacro

// Extract bitfield: %1=dest, %2=src, %3=start, %4=len
%macro extract_bits 4
    mov     %1, %2
    if %3, ne, 0
        shr     %1, %3
    endif
    and     %1, ((1 << %4) - 1)
%endmacro

// Insert bitfield: %1=dest, %2=val, %3=start, %4=len
%macro insert_bits 4
    push    rax
    mov     rax, ((1 << %4) - 1)
    and     %2, rax
    shl     rax, %3
    not     rax
    and     %1, rax
    mov     rax, %2
    shl     rax, %3
    or      %1, rax
    pop     rax
%endmacro

// Bit reversal (64-bit)
%macro bit_reverse_64 1
    mov     rax, %1
    bswap   rax
    mov     rcx, rax
    shr     rax, 1
    and     rax, 0x5555555555555555
    and     rcx, 0x5555555555555555
    shl     rcx, 1
    or      rax, rcx
    mov     %1, rax
%endmacro

// Population count (set bits)
%macro popcnt_64 2
    popcnt  %1, %2
%endmacro

// Leading/Trailing zeros
%macro lzcnt_64 2
    lzcnt   %1, %2
%endmacro

%macro tzcnt_64 2
    tzcnt   %1, %2
%endmacro

// Abs/Min/Max (64-bit)
%macro abs_64 1
    mov     rax, %1
    sar     rax, 63
    xor     %1, rax
    sub     %1, rax
%endmacro

%macro min_64 2
    cmp     %1, %2
    cmovg   %1, %2
%endmacro

%macro max_64 2
    cmp     %1, %2
    cmovl   %1, %2
%endmacro

// 64x64 -> 128-bit Multiply
%macro mul_128 4
    mov     rax, %1
    mul     qword %2
    mov     %3, rax
    mov     %4, rdx
%endmacro

// Modular Exponentiation
%macro exp_mod 3
    push    rax
    push    rbx
    push    rcx
    mov     rax, 1
    mov     rcx, %1
    mov     rbx, %2
%%loop:
    test    rbx, rbx
    jz      %%done
    test    rbx, 1
    jz      %%square
    mul     rcx
    xor     rdx, rdx
    div     qword %3
    mov     rax, rdx
%%square:
    push    rax
    mov     rax, rcx
    mul     rax
    xor     rdx, rdx
    div     qword %3
    mov     rcx, rdx
    pop     rax
    shr     rbx, 1
    jmp     %%loop
%%done:
    pop     rcx
    pop     rbx
    add     rsp, 8
%endmacro

// Runtime FNV-1a Hash
%macro hash_fnv1a_64 2
    mov     rax, 0xcbf29ce484222325
    mov     rcx, %1
%%loop:
    movzx   rdx, byte [rcx]
    test    rdx, rdx
    jz      %%done
    xor     rax, rdx
    mov     r11, 0x100000001b3
    mul     r11
    inc     rcx
    jmp     %%loop
%%done:
    mov     %2, rax
%endmacro

// ============================================================================
// 7. ATOMICS & SYNCHRONIZATION
// ============================================================================

%macro atomic_inc_64 1
    lock inc qword [%1]
%endmacro

%macro atomic_add_64 2
    lock add qword [%1], %2
%endmacro

%macro atomic_xchg 2
    lock xchg [%1], %2
%endmacro

%macro atomic_cmpxchg_128 5
    mov     rax, %2
    mov     rdx, %3
    mov     rbx, %4
    mov     rcx, %5
    lock cmpxchg16b [%1]
%endmacro

%macro spin_lock 1
%%retry:
    lock bts dword [%1], 0
    jc      %%retry
%endmacro

%macro spin_unlock 1
    lock btr dword [%1], 0
%endmacro

%macro pause_backoff 1
    mov     rcx, %1
%%loop:
    pause
    loop    %%loop
%endmacro

// ============================================================================
// 8. ARCHITECTURE & HARDWARE CONTROL
// ============================================================================

// CPU Feature Detection
%macro require_cpu_feature 3
    mov     eax, %1
    xor     ecx, ecx
    cpuid
    bt      %2, %3
    jnc     .error_cpu_feature
%endmacro

// Control Registers
%macro mov_cr0 2
    mov     %1, cr0
%endmacro

%macro mov_cr3 2
    mov     %1, cr3
%endmacro

// Cache Management
%macro prefetch_read 1
    prefetcht0 [%1]
%endmacro

%macro clflush_line 1
    clflush [%1]
%endmacro

%macro icache_flush 0
    mfence
%endmacro

// Memory Fences
%macro lfence_sync 0
    lfence
%endmacro

%macro sfence_sync 0
    sfence
%endmacro

// ============================================================================
// 9. VECTOR OPERATIONS (SIMD)
// ============================================================================

%macro v_mov 2
    movaps  %1, %2
%endmacro

%macro v_xor 2
    pxor    %1, %2
%endmacro

%macro v_scan_quotes 1
    movdqu  xmm0, [%1]
    mov     rax, 0x2227
    movd    xmm1, eax
    pcmpistri xmm0, xmm1, 0x00
%endmacro

// ============================================================================
// 10. SYSTEM CALLS (AMD64)
// ============================================================================

%macro syscall_0 1
    mov     rax, %1
    syscall
%endmacro

%macro syscall_1 2
    mov     rax, %1
    mov     rdi, %2
    syscall
%endmacro

%macro syscall_4 5
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    mov     rdx, %4
    mov     r10, %5
    syscall
%endmacro

%macro syscall_6 7
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    mov     rdx, %4
    mov     r10, %5
    mov     r8, %6
    mov     r9, %7
    syscall
%endmacro

// ============================================================================
// 11. DIAGNOSTICS & TESTING
// ============================================================================

%macro debug_print_str 1
    [SECTION .rodata]
    %%str: db %1, 10, 0
    %%len: equ $ - %%str
    [SECTION .text]
    mov     rdi, 2
    lea     rsi, [%%str]
    mov     rdx, %%len
    call    io_write
%endmacro

%macro test_begin 1
    debug_print_str "TEST: "
    debug_print_str %1
%endmacro

%macro assert_eq 2
    cmp     %1, %2
    je      %%ok
    debug_print_str "ASSERTION FAILED!"
    trap_arch
%%ok:
%endmacro

%macro stack_trace 0
    push    rbp
    mov     rbp, rbp
%%loop:
    test    rbp, rbp
    jz      %%done
    mov     rax, [rbp + 8]
    debug_dump_hex rax
    mov     rbp, [rbp]
    jmp     %%loop
%%done:
    pop     rbp
%endmacro

// ============================================================================
// 12. METAPROGRAMMING & INTERNALS
// ============================================================================

%macro static_assert 3
    %if %1 %2 %3
        // ok
    %else
        %error "STATIC ASSERTION FAILED: %1 %2 %3"
    %endif
%endmacro

%macro compile_time_hash 2
    %assign %%hash 0xcbf29ce484222325
    %strlen %%len %1
    %assign %%i 1
    %rep %%len
        %substr %%char %1 %%i
        %assign %%hash ((%%hash ^ %%char) * 0x100000001b3)
        %assign %%i %%i + 1
    %endrep
    %define %2 %%hash
%endmacro

%macro mnemonic_entry 3
    compile_time_hash %1, %%h
    dq      %%h
    db      %2
    dw      %3
%endmacro

// Preprocessor-time register check
%macro is_reg_64 1
    %assign %%is_reg 0
    %ifidni %1, rax
        %assign %%is_reg 1
    %elifidni %1, rbx
        %assign %%is_reg 1
    %elifidni %1, rcx
        %assign %%is_reg 1
    %elifidni %1, rdx
        %assign %%is_reg 1
    %elifidni %1, rsi
        %assign %%is_reg 1
    %elifidni %1, rdi
        %assign %%is_reg 1
    %elifidni %1, rbp
        %assign %%is_reg 1
    %elifidni %1, rsp
        %assign %%is_reg 1
    %elifidni %1, r8
        %assign %%is_reg 1
    %elifidni %1, r9
        %assign %%is_reg 1
    %elifidni %1, r10
        %assign %%is_reg 1
    %elifidni %1, r11
        %assign %%is_reg 1
    %elifidni %1, r12
        %assign %%is_reg 1
    %elifidni %1, r13
        %assign %%is_reg 1
    %elifidni %1, r14
        %assign %%is_reg 1
    %elifidni %1, r15
        %assign %%is_reg 1
    %endif
    %if %%is_reg == 0
        %error "Expected 64-bit register, got: %1"
    %endif
%endmacro
