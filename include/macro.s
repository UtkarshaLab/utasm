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

// ---- Diagnostics & Debugging -------------

// Print a literal string to stderr (bootstrap-only)
%macro debug_print_str 1
    [SECTION .rodata]
    %%str: db %1, 10, 0
    %%len: equ $ - %%str
    [SECTION .text]
    mov     rdi, 2                 // stderr
    lea     rsi, [%%str]
    mov     rdx, %%len
    call    io_write
%endmacro

// Dump a 64-bit register in hex to stderr
%macro debug_dump_hex 1
    push_volatile
    mov     rdi, %1
    call    error_uint_to_hex      // assumes this utility exists or similar
    pop_volatile
%endmacro

// ---- Atomic Operations (x86_64) ----------

// Atomic increment of a 64-bit memory location
%macro atomic_inc_64 1
    lock inc qword [%1]
%endmacro

// Atomic add to a 64-bit memory location
%macro atomic_add_64 2
    lock add qword [%1], %2
%endmacro

// ---- Local Variables (Stack) -------------

// Start a local variable block
%macro locals_start 0
    %push   locals
    %assign %$base_offset 0
%endmacro

// Define a local variable on the stack
// Usage: local_var my_var, 8
%macro local_var 2
    %assign %$base_offset %$base_offset + %2
    %define %1 [rbp - %$base_offset]
%endmacro

// End a local variable block and reserve space
%macro locals_end 0
    sub     rsp, %$base_offset
    %pop    locals
%endmacro

// ---- Profiling ---------------------------

// Read CPU timestamp counter into rdx:rax
%macro start_timer 0
    cpuid                          // serialize
    rdtsc
    push    rdx
    push    rax
%endmacro

// Stop timer and calculate delta in rax
%macro stop_timer 0
    rdtscp
    pop     rcx                    // old rax
    pop     r8                     // old rdx
    sub     rax, rcx
    sbb     rdx, r8                // rdx:rax = delta cycles
%endmacro

// ---- Automated Struct Definitions --------

// Start a struct definition
%macro struc 1
    %push   struc
    %define %$struc_name %1
    %assign %$offset 0
%endmacro

// Define a field within a struct
%macro field 2
    %def %{$struc_name}_%1 %$offset
    %assign %$offset %$offset + %2
%endmacro

// End a struct definition
%macro endstruc 0
    %def %{$struc_name}_SIZE %$offset
    %pop    struc
%endmacro

// ---- VTable (OO) Helpers -----------------

// Start a virtual method table
%macro vtable_begin 1
    [SECTION .rodata]
    align   8
    %1:
%endmacro

// Add a method pointer to the vtable
%macro vmethod 1
    dq      %1
%endmacro

// End the vtable
%macro vtable_end 0
    [SECTION .text]
%endmacro

// ---- Exception Handling (TRY/CATCH) ------

// Start a try block
%macro try 0
    %push   try
    // Logic: we'd need a jump buffer, but for now we'll 
    // use a context-based error brancher.
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

// Throw an error code
%macro throw 1
    mov     rax, %1
    jmp     %$error_label
%endmacro

// ---- Endianness Conversion ---------------

// Swap bytes in 16-bit register
%macro swap_16 1
    xchg    %h1, %l1               // e.g. xchg ah, al
%endmacro

// Swap bytes in 32-bit register
%macro swap_32 1
    bswap   %1
%endmacro

// Swap bytes in 64-bit register
%macro swap_64 1
    bswap   %1
%endmacro

// ---- Bitfield Operations -----------------

// Extract bitfield: dest, src, start_bit, num_bits
%macro extract_bits 4
    mov     %1, %2
    if %3, ne, 0
        shr     %1, %3
    endif
    and     %1, ((1 << %4) - 1)
%endmacro

// Insert bitfield: dest, val, start_bit, num_bits
%macro insert_bits 4
    push    rax
    mov     rax, ((1 << %4) - 1)
    and     %2, rax                // mask value
    shl     rax, %3                // mask to position
    not     rax
    and     %1, rax                // clear dest bits
    mov     rax, %2
    shl     rax, %3
    or      %1, rax                // insert bits
    pop     rax
%endmacro

// ---- SIMD Abstractions (AMD64/SSE) -------

// Move 128-bit aligned
%macro v_mov 2
    movaps  %1, %2
%endmacro

// Vector XOR
%macro v_xor 2
    pxor    %1, %2
%endmacro

// ---- Synchronization (Spinlocks) ---------

// Acquire a spinlock (32-bit memory)
%macro spin_lock 1
%%retry:
    lock bts dword [%1], 0
    jc      %%retry
%endmacro

// Release a spinlock
%macro spin_unlock 1
    lock btr dword [%1], 0
%endmacro

// ---- Lookup Table Helpers ----------------

// Define a jump table entry
%macro jt_entry 1
    dq      %1
%endmacro

// Define a named jump table
%macro jump_table 1
    [SECTION .rodata]
    align   8
    %1:
%endmacro

%macro jump_table_end 0
    [SECTION .text]
%endmacro

// ---- Fast Hashing (FNV-1a) ---------------

// Hash a null-terminated string into a 64-bit register
// Usage: hash_fnv1a_64 rsi, r8
%macro hash_fnv1a_64 2
    mov     rax, 0xcbf29ce484222325 // offset basis
    mov     rcx, %1
%%loop:
    movzx   rdx, byte [rcx]
    test    rdx, rdx
    jz      %%done
    xor     rax, rdx
    mov     r11, 0x100000001b3      // fnv prime
    mul     r11
    inc     rcx
    jmp     %%loop
%%done:
    mov     %2, rax
%endmacro

// ---- Unified Syscall Suite (AMD64) -------

%macro syscall_0 1
    mov     rax, %1
    syscall
%endmacro

%macro syscall_1 2
    mov     rax, %1
    mov     rdi, %2
    syscall
%endmacro

%macro syscall_2 3
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    syscall
%endmacro

%macro syscall_3 4
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    mov     rdx, %4
    syscall
%endmacro

%macro syscall_4 5
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    mov     rdx, %4
    mov     r10, %5                // Syscall ABI uses r10 for 4th arg
    syscall
%endmacro

// ---- Unit Testing Helpers ----------------

%macro test_begin 1
    [SECTION .rodata]
    %%name: db %1, 0
    [SECTION .text]
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

// ---- SMC & Cache Safeties ----------------

// Flush instruction cache (AMD64 is usually coherent, but good practice)
%macro icache_flush 0
    wbinvd                         // Privileged, but used in some kernels
    // Alternative: mfencing
    mfence
%endmacro
// ---- Advanced Memory Pool Helpers -------

// Save current arena pointer (checkpoint)
%macro push_alloc 0
    %push   arena
    mov     r10, [rbx + PREP_arena] // assumes rbx = PrepState or similar
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
// ---- Software Prefetching ----------------

// Prefetch data into all cache levels (T0 hint)
%macro prefetch_read 1
    prefetcht0 [%1]
%endmacro

// Prefetch data into L2 and higher (T1 hint)
%macro prefetch_read_l2 1
    prefetcht1 [%1]
%endmacro

// Prefetch data for intended write (AMD64/BMI)
%macro prefetch_write 1
    prefetchw [%1]
%endmacro

// ---- AMD64 Red Zone Management -----------
// Red Zone is 128 bytes below RSP that is safe to use without adjusting RSP.

// Store a 64-bit value into the Red Zone at given offset
%macro rz_store 2
    mov     [rsp - %2], %1
%endmacro

// Load a 64-bit value from the Red Zone
%macro rz_load 2
    mov     %1, [rsp - %2]
%endmacro

// Secure the Red Zone (use before calling other functions)
%macro rz_secure 0
    sub     rsp, 128
%endmacro

// Release the Red Zone
%macro rz_release 0
    add     rsp, 128
%endmacro

// ---- Data Serialization ------------------

// Encode a 64-bit value to LEB128 (Variable Length Integer)
// Input: %1 = value, %2 = dest buffer pointer
// Output: %2 is advanced by the number of bytes written
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

// ---- Hardware Feature Detection ----------

// Verify if CPU supports a specific feature bit
// %1 = leaf (eax), %2 = reg (ecx/edx), %3 = bit
%macro require_cpu_feature 3
    mov     eax, %1
    xor     ecx, ecx
    cpuid
    bt      %2, %3
    jnc     .error_cpu_feature
%endmacro

// ---- Coroutines & Context Switching ------

// Save current context and switch to another stack
// %1 = addr to save current RSP, %2 = addr to load next RSP
%macro switch_context 2
    push    rbp
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     [%1], rsp              // save current stack top
    mov     rsp, [%2]              // load new stack top
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    pop     rbp
%endmacro

// ---- Instruction Scheduling & Hints ------

// Align a branch target for optimal fetch (typically 16 or 32 bytes)
%macro align_branch 1
    align   %1, db 0x90            // fill with NOPs
%endmacro

// Hint that the CPU should expect a loop (REP NOP / PAUSE)
%macro cpu_relax 0
    pause
%endmacro

// Serialize instruction stream
%macro serialize 0
    cpuid
%endmacro
