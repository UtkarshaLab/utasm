%ifndef MACRO_S
%define MACRO_S

;
; ============================================
; File     : include/macro.s
; Project  : utasm
; Author   : Utkarsha Lab
; License  : Apache-2.0
; Description: Standard utility macro library for utasm.
; ============================================
;

; ============================================================================
; 1. SYSTEM & CONTEXT MANAGEMENT
; ============================================================================

;*
; * [prologue]
; * Purpose: Establish a standard AMD64 function stack frame.
; * Clobbers: RBP
; ;
%macro prologue 0
    push    rbp
    mov     rbp, rsp
    and     rsp, -16               ; 16-byte alignment
%endmacro

%macro epilogue 0
    mov     rsp, rbp
    pop     rbp
    ret
%endmacro

;*
; * [push_volatile]
; * Purpose: Save all volatile registers as defined by the AMD64 SysV ABI.
; * Used before calling functions where state must be preserved.
; ;
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

;*
; * [pop_volatile]
; * Purpose: Restore all volatile registers as defined by the AMD64 SysV ABI.
; ;
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

;*
; * [save_context]
; * Purpose: Save the complete CPU state, including all GPRs and EFLAGS.
; ;
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

;*
; * [restore_context]
; * Purpose: Restore the complete CPU state saved by save_context.
; ;
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

;*
; * [switch_context]
; * Purpose: Perform a thread/coroutine context switch by swapping stack pointers.
; * Parameters:
; *   %1: [mem64] Location to save the current RSP
; *   %2: [mem64] Location of the next task's RSP
; ;
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

;*
; * [locals_start]
; * Purpose: Initialize a block for named local stack variables.
; ;
%macro locals_start 0
    %push   locals
    %assign %$base_offset 0
%endmacro

;*
; * [local_var]
; * Purpose: Define a named local variable at an offset from RBP.
; * Parameters:
; *   %1: [name] Variable name
; *   %2: [imm] Size in bytes
; ;
%macro local_var 2
    %assign %$base_offset %$base_offset + %2
    %define %1 [rbp - %$base_offset]
%endmacro

;*
; * [locals_end]
; * Purpose: Reserve the calculated stack space for all defined locals.
; ;
%macro locals_end 0
    sub     rsp, %$base_offset
    %pop    locals
%endmacro

;*
; * [try] / [catch] / [endtry]
; * Purpose: Structured exception handling via context-based labels.
; * Usage:
; *   try
; *     call do_risky_work
; *     check_err
; *   catch
; *     call handle_error
; *   endtry
; ;
%macro try 0
    %push   try
%endmacro

%macro catch 0
    jmp     %$done_label
    %$error_label:
    %ifctx try
    %push   catch
    %endif
%endmacro

%macro endtry 0
    %$done_label:
    %ifctx catch
    %pop    catch
    %endif
    %ifctx try
    %pop    try
    %endif
%endmacro

;*
; * [throw]
; * Purpose: Signal an error and branch to the nearest 'catch' block.
; * Parameters:
; *   %1: [imm/reg] Error code to place in RAX
; ;
%macro throw 1
    mov     rax, %1
    jmp     %$error_label
%endmacro

; ============================================================================
; 2. ERROR HANDLING & ASSERTIONS
; ============================================================================

;*
; * [check_err]
; * Purpose: Branch to .error if RAX is non-zero (standard error convention).
; ;
%macro check_err 0
    test    rax, rax
    jnz     .error
%endmacro

;*
; * [check_err_to]
; * Purpose: Branch to a specific label if RAX is non-zero.
; ;
%macro check_err_to 1
    test    rax, rax
    jnz     %1
%endmacro

;*
; * [assert_tag]
; * Purpose: Verify that a structure at [%1] has the expected byte tag %2.
; ;
%macro assert_tag 2
    cmp     byte [%1], %2
    jne     .error_tag
%endmacro

;*
; * [assert_aligned]
; * Purpose: Trap if address in %1 is not aligned to %2 bytes.
; * %2 must be a power of two.
; ;
%macro assert_aligned 2
    test    %1, (%2 - 1)
    jnz     .error_alignment
%endmacro

;*
; * [assert_cache_aligned]
; * Purpose: Trap if address is not on a 64-byte cache line boundary.
; ;
%macro assert_cache_aligned 1
    test    %1, 63
    jnz     .error_cache_split
%endmacro

;*
; * [assert_not_zero]
; * Purpose: Trap if the value in %1 is zero (NULL check).
; ;
%macro assert_not_zero 1
    test    %1, %1
    jz      .error_null
%endmacro

;*
; * [assert_reg_range]
; * Purpose: Trap if %1 is not within the inclusive range [%2, %3].
; ;
%macro assert_reg_range 3
    cmp     %1, %2
    jl      .error_bounds
    cmp     %1, %3
    jg      .error_bounds
%endmacro

;*
; * [stack_align_check]
; * Purpose: Verify that the RSP is 16-byte aligned (required for SSE/ABI).
; ;
%macro stack_align_check 0
    test    rsp, 0xF
    jnz     .error_stack_unaligned
%endmacro

; ============================================================================
; 3. FLOW CONTROL (STRUCTURED)
; ============================================================================

; Global counter for unique IF block IDs (regular identifier, survives %push/%pop)
%assign __if_id 0

;*
; * [IF] / [ELSEIF] / [ELSE] / [ENDIF]
; * Purpose: Structured conditional branching.
; * Each IF block gets a unique ID. Branch labels are regular local labels.
; ;
%macro IF 3-4
    %assign __if_id __if_id + 1
    %push if
    %assign %$uid __if_id
    %assign %$branch 0
    %if %0 == 4
        cmp %1, %4
    %else
        cmp %1, %3
    %endif

    %ifidni %2, ==
        jne .if_%$uid_else_%$branch
    %elifidni %2, =
        jne .if_%$uid_else_%$branch
    %elifidni %2, !=
        je .if_%$uid_else_%$branch
    %elifidni %2, <>
        je .if_%$uid_else_%$branch
    %elifidni %2, e
        jne .if_%$uid_else_%$branch
    %elifidni %2, ne
        je .if_%$uid_else_%$branch
    %elifidni %2, g
        jng .if_%$uid_else_%$branch
    %elifidni %2, ge
        jnge .if_%$uid_else_%$branch
    %elifidni %2, l
        jnl .if_%$uid_else_%$branch
    %elifidni %2, le
        jnle .if_%$uid_else_%$branch
    %elifidni %2, a
        jna .if_%$uid_else_%$branch
    %elifidni %2, ae
        jnae .if_%$uid_else_%$branch
    %elifidni %2, b
        jnb .if_%$uid_else_%$branch
    %elifidni %2, be
        jnbe .if_%$uid_else_%$branch
    %elifidni %2, z
        jnz .if_%$uid_else_%$branch
    %elifidni %2, nz
        jz .if_%$uid_else_%$branch
    %else
        jn%+ %2 .if_%$uid_else_%$branch
    %endif
%endmacro

%macro ELSEIF 3-4
    %assign %%ok 0
    %ifctx if
        %assign %%ok 1
    %elifctx elseif
        %assign %%ok 1
    %endif

    %if %%ok
        jmp .if_%$uid_endif
        .if_%$uid_else_%$branch:
        %assign %%next_branch %$branch + 1
        %pop
        %push elseif
        %assign %$uid __if_id
        %assign %$branch %%next_branch
        %if %0 == 4
            cmp %1, %4
        %else
            cmp %1, %3
        %endif

        %ifidni %2, ==
            jne .if_%$uid_else_%$branch
        %elifidni %2, =
            jne .if_%$uid_else_%$branch
        %elifidni %2, !=
            je .if_%$uid_else_%$branch
        %elifidni %2, <>
            je .if_%$uid_else_%$branch
        %elifidni %2, e
            jne .if_%$uid_else_%$branch
        %elifidni %2, ne
            je .if_%$uid_else_%$branch
        %elifidni %2, g
            jng .if_%$uid_else_%$branch
        %elifidni %2, ge
            jnge .if_%$uid_else_%$branch
        %elifidni %2, l
            jnl .if_%$uid_else_%$branch
        %elifidni %2, le
            jnle .if_%$uid_else_%$branch
        %elifidni %2, a
            jna .if_%$uid_else_%$branch
        %elifidni %2, ae
            jnae .if_%$uid_else_%$branch
        %elifidni %2, b
            jnb .if_%$uid_else_%$branch
        %elifidni %2, be
            jnbe .if_%$uid_else_%$branch
        %elifidni %2, z
            jnz .if_%$uid_else_%$branch
        %elifidni %2, nz
            jz .if_%$uid_else_%$branch
        %else
            jn%+ %2 .if_%$uid_else_%$branch
        %endif
    %else
        %error "ELSEIF without IF"
    %endif
%endmacro

%macro ELSE 0
    %assign %%ok 0
    %ifctx if
        %assign %%ok 1
    %elifctx elseif
        %assign %%ok 1
    %endif

    %if %%ok
        jmp .if_%$uid_endif
        .if_%$uid_else_%$branch:
        %pop
        %push else
        %assign %$uid __if_id
        %assign %$branch %$branch + 1
    %else
        %error "ELSE without IF"
    %endif
%endmacro

%macro ENDIF 0
    %ifctx if
        .if_%$uid_else_%$branch:
        .if_%$uid_endif:
        %pop
    %elifctx elseif
        .if_%$uid_else_%$branch:
        .if_%$uid_endif:
        %pop
    %elifctx else
        .if_%$uid_endif:
        %pop
    %else
        %error "ENDIF without IF"
    %endif
%endmacro

;*
; * [WHILE] / [ENDWHILE]
; * Purpose: Structured loop control.
; * Usage: WHILE rcx, ne, 0 ... ENDWHILE
; ;
%macro WHILE 3-4
    %push   while
    %$loop_start:
    %if %0 == 4
        cmp     %1, %4
    %else
        cmp     %1, %3
    %endif
    
    %ifidni %2, ==
        jne %$loop_end
    %elifidni %2, =
        jne %$loop_end
    %elifidni %2, !=
        je  %$loop_end
    %elifidni %2, <>
        je  %$loop_end
    %elifidni %2, e
        jne %$loop_end
    %elifidni %2, ne
        je  %$loop_end
    %else
        jn%+ %2 %$loop_end
    %endif
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

;*
; * [j_likely] / [j_unlikely]
; * Purpose: Hints to the CPU (and maintainer) about branch probability.
; ;
%macro j_likely 2
    j%1     %2
%endmacro

%macro j_unlikely 2
    j%1     %2
%endmacro

; ============================================================================
; 4. MEMORY & DATA STRUCTURES
; ============================================================================

;*
; * [zero_mem]
; * Purpose: Fast zero-initialization of memory using REP STOSQ.
; * Parameters:
; *   %1: [reg] Pointer to memory
; *   %2: [imm] Size in bytes (must be multiple of 8)
; ;
%macro zero_mem 2
    mov     rdi, %1
    mov     rcx, (%2 / 8)
    xor     rax, rax
    rep     stosq
%endmacro

;*
; * [alloc_on_arena]
; * Purpose: Allocate memory from the global arena.
; * Parameters:
; *   %1: [out] Register to receive the pointer
; *   %2: [in] Size in bytes
; ;
%macro alloc_on_arena 2
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, %2
    call    arena_alloc
    test    rax, rax
    jnz     .error_oom
    mov     %1, rdx
%endmacro

;*
; * [alloc_aligned_arena]
; * Purpose: Allocate memory from the arena with forced alignment.
; ;
%macro alloc_aligned_arena 3
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, %2
    call    arena_alloc
    check_err
    mov     %1, rdx
%endmacro

;*
; * [push_alloc] / [pop_alloc]
; * Purpose: Checkpoint and restore arena allocation pointers.
; * Useful for temporary allocations in nested parser logic.
; ;
%macro push_alloc 0
    %push   arena
    mov     r10, [rbx + PREP_arena]
    push    qword [r10 + ARENA_ptr]
%endmacro

%macro pop_alloc 0
    %ifctx arena
        mov     r10, [rbx + PREP_arena]
        pop     qword [r10 + ARENA_ptr]
    %pop    arena
    %else
    %error "pop_alloc without push_alloc"
    %endif
%endmacro

;*
; * [struc] / [field] / [endstruc]
; * Purpose: Automatic calculation of structure offsets and total size.
; ;
%undef struc
%macro struc 1
    %push   struc
    %define %$struc_name %1
    %assign %$offset 0
%endmacro

%macro field 2
    %define %%fname %$struc_name %+ _ %+ %1
    %%fname equ %$offset
    %assign %$offset %$offset + %2
%endmacro

%undef endstruc
%macro endstruc 0
    %define %%sname %$struc_name %+ _SIZE
    %%sname equ %$offset
    %pop    struc
%endmacro

;*
; * [vtable_begin] / [vmethod] / [vtable_end]
; * Purpose: Define a Virtual Method Table in .rodata.
; ;
%macro vtable_begin 1
    [SECTION .rodata]
    align   8
    %1:
%endmacro

%macro vmethod 1
    dq      %1
%endmacro

%macro vtable_end 0
    [SECTION .text]
%endmacro

;*
; * [cbuf_push] / [cbuf_pop]
; * Purpose: Low-latency operations on a power-of-two circular buffer.
; ;
%macro cbuf_push 4
    mov     rax, [%2]
    mov     [%1 + rax], %4
    inc     rax
    and     rax, %3
    mov     [%2], rax
%endmacro

%macro cbuf_pop 4
    mov     rax, [%2]
    mov     %4, [%1 + rax]
    inc     rax
    and     rax, %3
    mov     [%2], rax
%endmacro

;*
; * [bloom_add] / [bloom_check]
; * Purpose: Fast membership test kernel for Bloom Filters.
; ;
%macro bloom_add 2
    mov     rax, %2
    mov     rcx, rax
    shr     rax, 3
    and     rcx, 7
    mov     dl, 1
    shl     dl, cl
    or      byte [%1 + rax], dl
%endmacro

%macro bloom_check 2
    mov     rax, %2
    mov     rcx, rax
    shr     rax, 3
    and     rcx, 7
    mov     dl, 1
    shl     dl, cl
    test    byte [%1 + rax], dl
%endmacro

;*
; * [jump_table] / [jt_entry] / [jump_table_end]
; * Purpose: Construct optimized jump tables for opcode dispatch.
; ;
%macro jt_entry 1
    dq      %1
%endmacro

%macro jump_table 1
    [SECTION .rodata]
    align   8
    %1:
%endmacro

%macro jump_table_end 0
    [SECTION .text]
%endmacro

; ============================================================================
; 5. STRING & BUFFER OPERATIONS
; ============================================================================

;*
; * [memcpy]
; * Purpose: Standard memory copy.
; ;
%macro memcpy 3
    mov     rdi, %1
    mov     rsi, %2
    mov     rcx, %3
    rep     movsb
%endmacro

;*
; * [memcpy_nt]
; * Purpose: Non-Temporal memory copy. Bypasses cache to prevent pollution.
; * Requirement: Source and Dest should be aligned for best performance.
; ;
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

;*
; * [memset]
; * Purpose: Fill a memory buffer with a specific byte value.
; ;
%macro memset 3
    mov     rdi, %1
    mov     al, %2
    mov     rcx, %3
    rep     stosb
%endmacro

;*
; * [strlen]
; * Purpose: Calculate the length of a null-terminated string.
; * Output: %2 = length in bytes.
; ;
%macro strlen 2
    mov     rdi, %1
    xor     al, al
    mov     rcx, -1
    repne   scasb
    not     rcx
    dec     rcx
    mov     %2, rcx
%endmacro

;*
; * [encode_leb128]
; * Purpose: Encode a 64-bit integer into DWARF-standard Variable Length LEB128.
; * Parameters:
; *   %1: [reg] Source value
; *   %2: [out] Dest pointer (advanced after write)
; ;
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

;*
; * [swap_16/32/64]
; * Purpose: Endianness conversion via byte swapping.
; ;
%macro swap_16 1
    xchg    %h1, %l1
%endmacro

%macro swap_32 1
    bswap   %1
%endmacro

%macro swap_64 1
    bswap   %1
%endmacro

; ============================================================================
; 6. BITWISE & MATHEMATICAL OPERATIONS
; ============================================================================

;*
; * [set_bit] / [clr_bit] / [toggle_bit]
; * Purpose: Single-bit manipulation kernels.
; ;
%macro set_bit 2
    bts     %1, %2
%endmacro

%macro clr_bit 2
    btr     %1, %2
%endmacro

%macro toggle_bit 2
    btc     %1, %2
%endmacro

;*
; * [extract_bits]
; * Purpose: Retrieve a bitfield from a 64-bit source.
; * Parameters: dest, src, start_bit, length
; ;
%macro extract_bits 4
    mov     %1, %2
    %if %3 != 0
        shr     %1, %3
    %endif
    and     %1, ((1 << %4) - 1)
%endmacro

%endif ; MACRO_S
