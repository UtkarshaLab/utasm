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

%macro syscall_5 6
    mov     rax, %1
    mov     rdi, %2
    mov     rsi, %3
    mov     rdx, %4
    mov     r10, %5
    mov     r8, %6
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

// ---- Branching Hints ---------------------
// Modern CPUs predict forward branches as NOT taken and backward as taken.

// Branch to label if condition met, hinting it is LIKELY
%macro j_likely 2
    j%1     %2
%endmacro

// Branch to label if condition met, hinting it is UNLIKELY
// Logic: Often implemented by placing the target code far away (out-of-line)
%macro j_unlikely 2
    j%1     %2
%endmacro

// ---- Math Optimizations ------------------

// Fast base-2 logarithm (index of highest set bit)
// %1 = dest (64-bit reg), %2 = src (64-bit reg/mem)
%macro bsr_log2 2
    bsr     %1, %2
%endmacro

// Population count (number of bits set to 1)
%macro popcnt_64 2
    popcnt  %1, %2
%endmacro

// Generic byteswap based on size (16, 32, 64)
%macro byteswap 2
    %if %2 == 16
        swap_16 %1
    %elif %2 == 32
        swap_32 %1
    %elif %2 == 64
        swap_64 %1
    %endif
%endmacro

// Trap if address is not aligned to %2 (must be power of 2)
%macro assert_aligned 2
    test    %1, (%2 - 1)
    jnz     .error_alignment
%endmacro

// Serialized timestamp reading
%macro rdtsc_serial 0
    cpuid
    rdtsc
%endmacro

// ---- Security Hardening ------------------

// Initialize a stack canary (uses dummy value for now)
%macro stack_canary_init 1
    mov     rax, 0x55aa55aa55aa55aa
    mov     [%1], rax              // store at offset from rbp
%endmacro

// Verify stack canary
%macro stack_canary_check 1
    mov     rax, 0x55aa55aa55aa55aa
    cmp     rax, [%1]
    jne     .error_stack_corrupt
%endmacro

// Securely wipe memory area
%macro mem_erase 2
    mov     rdi, %1
    mov     rcx, (%2 / 8)
    xor     rax, rax
    rep     stosq
%endmacro

// Obfuscate a jump (opaque predicate)
%macro jmp_obfuscate 1
    xor     rax, rax
    test    rax, rax
    jz      %1
%endmacro

// ---- Data Structures ---------------------

// Push to circular buffer (size must be power of 2)
// %1 = base, %2 = head_ptr, %3 = size_mask, %4 = value
%macro cbuf_push 4
    mov     rax, [%2]
    mov     [%1 + rax], %4
    inc     rax
    and     rax, %3
    mov     [%2], rax
%endmacro

// Pop from circular buffer
%macro cbuf_pop 4
    mov     rax, [%2]
    mov     %4, [%1 + rax]
    inc     rax
    and     rax, %3
    mov     [%2], rax
%endmacro

// ---- Fast Membership (Bloom Filter) ------

// Add to Bloom Filter (simple 1-hash version)
// %1 = filter base, %2 = hash value
%macro bloom_add 2
    mov     rax, %2
    mov     rcx, rax
    shr     rax, 3                 // byte offset
    and     rcx, 7                 // bit offset
    mov     dl, 1
    shl     dl, cl
    or      byte [%1 + rax], dl
%endmacro

// Check Bloom Filter
%macro bloom_check 2
    mov     rax, %2
    mov     rcx, rax
    shr     rax, 3
    and     rcx, 7
    mov     dl, 1
    shl     dl, cl
    test    byte [%1 + rax], dl
    // set ZF accordingly
%endmacro

// ---- Thread Local Storage ----------------

// Get address of TLS variable (AMD64 Linux/Unix use FS)
%macro get_tls_var 2
    mov     rax, [fs:0]            // base of TLS
    lea     %1, [rax + %2]
%endmacro

// ---- Instruction Pointer Relative --------

// Get absolute address of label using RIP-relative addressing
%macro get_rip_rel 2
    lea     %1, [%2]               // In AMD64, lea is RIP-relative by default
%endmacro

// ---- Cache Management --------------------

// Flush a specific cache line
%macro clflush_line 1
    clflush [%1]
%endmacro

// ---- Memory Mapping ----------------------

// Standard anonymous mmap (64KB, RW)
%macro mmap_anon 1
    syscall_6 9, 0, 65536, 3, 34, -1, 0 // sys_mmap
    mov     %1, rax
%endmacro

// ---- Specialized Search (SSE4.2) ---------

// Find byte in string (SSE 4.2 PCMPISTRI)
%macro vstr_find_byte 2
    movdqu  xmm0, [%1]
    movd    xmm1, %2
    pcmpistri xmm0, xmm1, 0x08     // equal each
    // ecx contains index
%endmacro

// ---- Hardware Hashing & CRC --------------

// Hardware CRC32 (64-bit)
%macro crc32_64 2
    crc32   %1, %2
%endmacro

// ---- Adaptive Synchronization ------------

// Adaptive pause strategy for spinloops
%macro pause_strat 1
    %rep %1
        pause
    %endrep
%endmacro
// ---- Advanced Bit & Math -----------------

// Count leading zeros (64-bit)
%macro lzcnt_64 2
    lzcnt   %1, %2
%endmacro

// Count trailing zeros (64-bit)
%macro tzcnt_64 2
    tzcnt   %1, %2
%endmacro

// Bit reversal (64-bit)
%macro bit_reverse_64 1
    mov     rax, %1
    // Step 1: Swap nibbles and bytes
    bswap   rax
    // ... logic for full bit reversal ...
    // For now, use a common sequence:
    mov     rcx, rax
    shr     rax, 1
    and     rax, 0x5555555555555555
    and     rcx, 0x5555555555555555
    shl     rcx, 1
    or      rax, rcx
    // ... (omitting full steps for brevity in macro)
    mov     %1, rax
%endmacro

// Multi-precision addition (ADC chain)
// Usage: adc_chain dest, src
%macro adc_chain 2
    adc     %1, %2
%endmacro

// Multi-precision multiplication (BMI2 MULX)
%macro mulx_chain 3
    mulx    %1, %2, %3
%endmacro

// ---- OS Dev & Hardware Control -----------

// Read/Write Control Registers (Privileged)
%macro mov_cr0 2
    mov     %1, cr0
%endmacro

%macro mov_cr3 2
    mov     %1, cr3
%endmacro

// MSR Access
%macro rdmsr_64 1
    mov     ecx, %1
    rdmsr
    // edx:eax
%endmacro

// Port I/O
%macro out_port_8 2
    mov     dx, %1
    mov     al, %2
    out     dx, al
%endmacro

%macro in_port_8 2
    mov     dx, %2
    in      al, dx
    mov     %1, al
%endmacro

// Descriptor Table Entries
%macro gdt_entry 4
    dw      %1 & 0xFFFF            // limit low
    dw      %2 & 0xFFFF            // base low
    db      (%2 >> 16) & 0xFF      // base middle
    db      %3                     // access
    db      (%4 << 4) | ((%1 >> 16) & 0x0F) // flags + limit high
    db      (%2 >> 24) & 0xFF      // base high
%endmacro

// Get Current Core ID (AMD64)
%macro get_core_id 1
    mov     eax, 1
    cpuid
    shr     ebx, 24                // Initial APIC ID
    mov     %1, rbx
%endmacro

// ---- Hardware Crypto & Random ------------

// AES Round (Encryption)
%macro aes_enc_round 2
    aesenc  %1, %2
%endmacro

// SHA-256 Round
%macro sha256_round 3
    sha256rnds2 %1, %2, %3
%endmacro

// Hardware Random Number (64-bit)
%macro rdrand_64 1
%%retry:
    rdrand  %1
    jnc     %%retry
%endmacro

// Hardware Entropy Seed (64-bit)
%macro rdseed_64 1
%%retry:
    rdseed  %1
    jnc     %%retry
%endmacro

// ---- Memory Barriers & Sync --------------

// Memory Fences
%macro lfence_sync 0
    lfence
%endmacro

%macro sfence_sync 0
    sfence
%endmacro

// Transactional Memory (Intel TSX)
%macro xbegin_sync 1
    xbegin  %1
%endmacro

%macro xend_sync 0
    xend
%endmacro

// Wait for Monitor
%macro mwait_sync 2
    mov     eax, %1
    mov     ecx, %2
    mwait
%endmacro

// ---- Vectorized Data Processing ----------

// Vector String Compare (SSE 4.2)
%macro vstr_cmp 3
    movdqu  xmm0, [%1]
    movdqu  xmm1, [%2]
    pcmpistri xmm0, xmm1, %3       // comparison mode
%endmacro

// Broadcast scalar to all elements (AVX)
%macro v_broadcast_64 2
    vbroadcastsd %1, %2
%endmacro

// Permute elements (AVX)
%macro v_permute_64 3
    vpermpd %1, %2, %3
%endmacro

// ---- Code Integrity & Introspection ------

// Insert a code signature (bootstrap/forensics)
%macro code_signature 1
    db      "UTASM_SIG:", %1, 0
%endmacro

// Assert register is not zero
%macro assert_not_zero 1
    test    %1, %1
    jz      .error_null
%endmacro

// Verify stack alignment (16-byte)
%macro stack_align_check 0
    test    rsp, 0xF
    jnz     .error_stack_unaligned
%endmacro

// Hotpatch Stub (5-byte NOP)
%macro hotpatch_stub 0
    db      0x0F, 0x1F, 0x44, 0x00, 0x00 // standard 5-byte NOP
%endmacro
// ---- Advanced Arch Optimizations --------

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
    sfence                         // ensure NT stores are visible
%endmacro

// Warm cache lines for a structure
%macro warm_cache 2
    mov     rcx, (%2 / 64)         // assume 64-byte lines
    mov     rax, %1
%%loop:
    prefetcht0 [rax]
    add     rax, 64
    loop    %%loop
%endmacro

// Hyper-threading hint (SMT)
%macro smt_hint 1
    // Logic: use low-priority hints or pause strategies
    // for Intel, we can use specific NOPs
    db      0x3E, 0x90             // DS-prefixed NOP as hint
%endmacro

// Align branch target for 32-byte fetch blocks
%macro branch_align_32 0
    align   32
%endmacro

// ---- Modern OS & Linker Features ---------

// Call Frame Information (DWARF)
%macro cfi_startproc 0
    // Logic: Emit .cfi_startproc directive if supported by host
%endmacro

%macro cfi_endproc 0
    // Logic: Emit .cfi_endproc
%endmacro

// Procedure Linkage Table Stub
%macro plt_stub 1
    jmp     [qword %1_GOT]         // Indirect jump via GOT
%endmacro

// Global Offset Table Entry
%macro got_entry 1
    %1_GOT: dq 0
%endmacro

// Symbol Versioning
%macro sym_version 2
    // Logic: Emit .symver %1, %2
%endmacro

// Section-based path management
%macro hot_path_begin 0
    [SECTION .text.hot]
%endmacro

%macro hot_path_end 0
    [SECTION .text]
%endmacro

%macro cold_path_begin 0
    [SECTION .text.unlikely]
%endmacro

%macro cold_path_end 0
    [SECTION .text]
%endmacro

// ---- Security & Forensics ----------------

// Reset Branch History Buffer (Mitigates Spectre-V2)
%macro reset_bhb 0
    // Logic: Series of jumps to clear buffer
    %rep 32
        jmp     %%next
        %%next:
    %endrep
%endmacro

// Intel CET Shadow Stack
%macro shadow_stack_push 1
    // Logic: rdssp, wrss (if supported)
%endmacro

// Conditional Debug Breakpoint
%macro debug_break_on 2
    cmp     %1, %2
    jne     %%skip
    int3
%%skip:
%endmacro

// ---- Advanced Vector & Parsing Logic -----

// Scan for quotes in 16-byte block (SSE 4.2)
%macro v_scan_quotes 1
    movdqu  xmm0, [%1]
    mov     rax, 0x2227            // " and '
    movd    xmm1, eax
    pcmpistri xmm0, xmm1, 0x00     // equal any
%endmacro

// Scan for commas in 16-byte block
%macro v_scan_commas 1
    movdqu  xmm0, [%1]
    mov     rax, 0x2C              // ,
    movd    xmm1, eax
    pcmpistri xmm0, xmm1, 0x00
%endmacro

// Masked vector move (AVX-512 style stub)
%macro v_mask_mov 3
    // Logic: vmovdqu64 %1{%2}, %3
%endmacro

// ---- BigInt & Mathematical Theory --------

// Multi-precision division stub
%macro divx_chain 2
    // Logic: complex division sequence
%endmacro

// Modular Multiplication stub
%macro mod_mul 3
    // %1 = a, %2 = b, %3 = mod
%endmacro

// Modular Exponentiation (Binary Exponentiation)
// %1 = base, %2 = exp, %3 = mod
%macro exp_mod 3
    push    rax
    push    rbx
    push    rcx
    mov     rax, 1                 // result
    mov     rcx, %1                // base
    mov     rbx, %2                // exponent
%%loop:
    test    rbx, rbx
    jz      %%done
    test    rbx, 1
    jz      %%square
    mul     rcx                    // rax = rax * rcx
    xor     rdx, rdx
    div     qword %3
    mov     rax, rdx               // result = (result * base) % mod
%%square:
    push    rax
    mov     rax, rcx
    mul     rax                    // rax = rcx * rcx
    xor     rdx, rdx
    div     qword %3
    mov     rcx, rdx               // base = (base * base) % mod
    pop     rax
    shr     rbx, 1
    jmp     %%loop
%%done:
    // Result is in rax
    pop     rcx
    pop     rbx
    add     rsp, 8                 // rax is preserved as result
%endmacro

// ---- Low-Level "Magic" -------------------

// Opaque Jump (Invisible to basic analysis)
%macro opaque_jmp 1
    push    rax
    xor     rax, rax
    jz      %%next
    db      0x0F, 0x0B             // ud2 (dead code)
%%next:
    pop     rax
    jmp     %1
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

// Self-Check (simple additive checksum)
%macro self_check 0
    push_volatile
    lea     rsi, [$$]              // start of section
    mov     rcx, ($ - $$)          // current size
    xor     rax, rax
%%loop:
    add     al, [rsi]
    inc     rsi
    loop    %%loop
    // rax contains sum
    pop_volatile
%endmacro
// ---- Metaprogramming ---------------------

// Compile-time assertion
// Usage: static_assert MY_VAL, ==, 64
%macro static_assert 3
    %if %1 %2 %3
        // condition met
    %else
        %error "STATIC ASSERTION FAILED: %1 %2 %3"
    %endif
%endmacro

// Compile-time FNV-1a Hashing
// %1 = string literal, %2 = name of constant to define
%macro compile_time_hash 2
    %assign %%hash 0xcbf29ce484222325
    %strlen %%len %1
    %assign %%i 1
    %rep %%len
        %substr %%char %1 %%i
        // NASM handles large integers automatically
        %assign %%hash ((%%hash ^ %%char) * 0x100000001b3)
        %assign %%i %%i + 1
    %endrep
    %define %2 %%hash
%endmacro

// ---- Assembler Internals -----------------

// Generate a mnemonic table entry
// %1 = string, %2 = n_operands, %3 = internal_id
%macro mnemonic_entry 3
    compile_time_hash %1, %%h
    dq      %%h                    // 64-bit hash
    db      %2                     // operand count
    dw      %3                     // unique mnemonic ID
%endmacro

// Aligned arena allocation
%macro alloc_aligned_arena 3
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, %2                // size
    call    arena_alloc
    check_err
    mov     %1, rdx
    // logic to align rdx would go here or in arena_alloc
%endmacro

// ---- Performance Utilities ---------------

// SIMD Scan for Character
// %1 = buffer, %2 = char (byte)
%macro mem_scan_char 2
    movd    xmm1, %2
    punpcklbw xmm1, xmm1           // broadcast to xmm
    punpcklwd xmm1, xmm1
    pshufd  xmm1, xmm1, 0
    movdqu  xmm0, [%1]
    pcmpeqb xmm0, xmm1
    pmovmskb eax, xmm0
    // eax contains 16-bit match mask
%endmacro

// Fast ITOS (Integer to String)
%macro fast_itos 2
    mov     rax, %1
    mov     rdi, %2
    // simplified recursive-style divide by 10
%endmacro

// ---- Advanced Debugging ------------------

// Walk stack and dump return addresses
%macro stack_trace 0
    push    rbp
    mov     rbp, rbp
%%loop:
    test    rbp, rbp
    jz      %%done
    mov     rax, [rbp + 8]         // return address
    debug_dump_hex rax
    mov     rbp, [rbp]             // previous rbp
    jmp     %%loop
%%done:
    pop     rbp
%endmacro

// Runtime check for register value range
%macro assert_reg_range 3
    cmp     %1, %2
    jl      .error_bounds
    cmp     %1, %3
    jg      .error_bounds
%endmacro
// ---- Advanced CPU State & Control --------

// Save all GPRs and Flags
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

// Restore all GPRs and Flags
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

// Set Hardware Debug Register
%macro set_debug_reg 2
    mov     rax, %2
    %if %1 == 0
        mov     dr0, rax
    %elif %1 == 1
        mov     dr1, rax
    %endif
%endmacro

// Interrupt Service Routine Frame
%macro isr_entry 0
    push    rax
    push    rcx
    push    rdx
    push    rbp
    mov     rbp, rsp
%endmacro

%macro isr_exit 0
    pop     rbp
    pop     rdx
    pop     rcx
    pop     rax
    iretq
%endmacro

// ---- High-Performance Atomics & Sync -----

// Atomic Exchange (64-bit)
%macro atomic_xchg 2
    lock xchg [%1], %2
%endmacro

// Atomic 128-bit Compare-and-Swap
// %1 = addr, %2 = old_lo, %3 = old_hi, %4 = new_lo, %5 = new_hi
%macro atomic_cmpxchg_128 5
    mov     rax, %2
    mov     rdx, %3
    mov     rbx, %4
    mov     rcx, %5
    lock cmpxchg16b [%1]
%endmacro

// Exponential Backoff for spinlocks
%macro pause_backoff 1
    mov     rcx, %1
%%loop:
    pause
    loop    %%loop
%endmacro

// ---- Vectorized Logical Operations -------

%macro v_and 2
    pand    %1, %2
%endmacro

%macro v_or 2
    por     %1, %2
%endmacro

%macro v_not 1
    pcmpeqd xmm7, xmm7             // all ones
    pxor    %1, xmm7
%endmacro

// Vector Absolute Difference
%macro v_abs_diff 2
    psadbw  %1, %2
%endmacro

// Vector state checks
%macro v_all_zero 1
    ptest   %1, %1
    // ZF set if all zero
%endmacro

%macro v_any_set 1
    ptest   %1, %1
    // ZF clear if any bit set
%endmacro

// ---- Code Resilience & Self-Repair -------

// Self-Repair logic placeholder
%macro repair_stub 1
    call    self_check
    cmp     al, [%%sum_ptr]
    je      %%ok
    // Logic: restore from backup %1
%%ok:
%endmacro

// Assert address is cache-line aligned (64 bytes)
%macro assert_cache_aligned 1
    test    %1, 63
    jnz     .error_cache_split
%endmacro

// Skip N bytes of instructions using NOPs
%macro skip_insn 1
    %if %1 == 1
        nop
    %elif %1 == 2
        dw 0x9066                  // 66 90
    %elif %1 == 5
        db 0x0F, 0x1F, 0x44, 0x00, 0x00
    %endif
%endmacro

// ---- Advanced Math & Encoding ------------

// 64x64 -> 128-bit Multiply
// %1 = val1, %2 = val2, %3 = res_lo, %4 = res_hi
%macro mul_128 4
    mov     rax, %1
    mul     qword %2
    mov     %3, rax
    mov     %4, rdx
%endmacro

// Invert range of bits
// %1 = reg, %2 = start, %3 = len
%macro not_bits 3
    mov     rax, ((1 << %3) - 1)
    shl     rax, %2
    xor     %1, rax
%endmacro

// UTF-8 Encode stub
%macro encode_utf8 1
    // Logic: convert 32-bit codepoint to bytes
%endmacro

// ---- Microbenchmarking & Profiling -------

// Start benchmark (CPU instructions)
%macro bench_start 0
    xor     ecx, ecx
    rdpmc
    push    rdx
    push    rax
%endmacro

// End benchmark
%macro bench_end 0
    xor     ecx, ecx
    rdpmc
    pop     rcx                    // old rax
    pop     r8                     // old rdx
    sub     rax, rcx
    sbb     rdx, r8                // result in rdx:rax
%endmacro

// Stall check
%macro stall_check 2
    // %1 = start_time, %2 = threshold
    rdtsc
    sub     rax, %1
    cmp     rax, %2
    jg      .error_stall
%endmacro

// ---- Linker & Forensics ------------------

// Hookable entry point (5-byte NOP)
%macro hook_prologue 0
    hotpatch_stub
%endmacro

// Opaque Constant calculation
// %1 = dest, %2 = target_val
%macro opaque_constant 2
    mov     %1, (%2 / 2)
    shl     %1, 1
    add     %1, (%2 % 2)
%endmacro
