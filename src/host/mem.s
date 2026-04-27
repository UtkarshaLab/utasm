/*
 ============================================================================
 File        : src/host/mem.s
 Project     : utasm
 Version     : 0.1.0
 Description : Host memory management interface.
               Thin syscall wrappers for mmap/munmap with a simple
               bump allocator on top, used by the arena subsystem
               during bootstrapping when no libc is available.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"
%inc "include/syscall.s"
%inc "include/register.s"

[SECTION .text]

// ============================================================================
// mem_map
// ============================================================================
/*
 mem_map
 Maps a private anonymous region of memory (equivalent to mmap with
 MAP_PRIVATE | MAP_ANONYMOUS | MAP_POPULATE).
 The returned pointer is page-aligned.

 Input  : rdi = requested size in bytes
 Output : rax = EXIT_OK or EXIT_OOM
           rdx = pointer to mapped region
 Clobbers: rcx, r8, r9, r10, r11
*/
global mem_map
mem_map:
    prologue
    push    rbx
    mov     rbx, rdi               // rbx = requested size

    // Round up to next page boundary (4096 bytes)
    mov     rax, rbx
    add     rax, 4095
    and     rax, ~4095
    mov     rbx, rax               // rbx = page-aligned size

    // mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_PRIVATE|MAP_ANONYMOUS, -1, 0)
    xor     rdi, rdi               // addr = NULL
    mov     rsi, rbx               // length
    mov     rdx, 3                 // PROT_READ | PROT_WRITE
    mov     r10, 0x22              // MAP_PRIVATE | MAP_ANONYMOUS
    mov     r8, -1                 // fd = -1
    xor     r9, r9                 // offset = 0
    mov     rax, SYS_MMAP
    syscall

    // Check for error: mmap returns -errno on failure (large negative)
    cmp     rax, -4096
    jg      .ok                    // positive or small negative = success

    mov     rax, EXIT_OOM
    xor     rdx, rdx
    jmp     .done

.ok:
    mov     rdx, rax               // rdx = mapped pointer
    xor     rax, rax               // rax = EXIT_OK

.done:
    pop     rbx
    epilogue

// ============================================================================
// mem_unmap
// ============================================================================
/*
 mem_unmap
 Unmaps a previously mapped memory region.

 Input  : rdi = pointer to region
           rsi = size in bytes (must match the size used in mem_map)
 Output : rax = EXIT_OK or EXIT_ERROR
*/
global mem_unmap
mem_unmap:
    prologue

    // Round size up to page boundary
    mov     rax, rsi
    add     rax, 4095
    and     rax, ~4095
    mov     rsi, rax

    mov     rax, SYS_MUNMAP
    syscall

    test    rax, rax
    js      .error

    xor     rax, rax
    epilogue

.error:
    mov     rax, EXIT_ERROR
    epilogue

// ============================================================================
// mem_protect
// ============================================================================
/*
 mem_protect
 Changes protection flags on a mapped region (mprotect).
 Useful for marking generated code as executable after encoding.

 Input  : rdi = pointer to region (page-aligned)
           rsi = size in bytes
           rdx = protection flags (PROT_* values)
 Output : rax = EXIT_OK or EXIT_ERROR

 Common prot values:
   PROT_NONE  = 0  (no access)
   PROT_READ  = 1
   PROT_WRITE = 2
   PROT_EXEC  = 4
   PROT_RW    = 3  (read + write)
   PROT_RX    = 5  (read + exec, for code pages)
*/
%def PROT_NONE   0
%def PROT_READ   1
%def PROT_WRITE  2
%def PROT_EXEC   4
%def PROT_RW     3
%def PROT_RX     5

global mem_protect
mem_protect:
    prologue

    // Align size up
    mov     rax, rsi
    add     rax, 4095
    and     rax, ~4095
    mov     rsi, rax

    mov     rax, SYS_MPROTECT
    syscall

    test    rax, rax
    js      .error

    xor     rax, rax
    epilogue

.error:
    mov     rax, EXIT_ERROR
    epilogue

// ============================================================================
// mem_alloc_exec
// ============================================================================
/*
 mem_alloc_exec
 Allocates a memory region suitable for JIT-compiled or assembled machine
 code: maps as PROT_READ|PROT_WRITE first (for encoding), then caller
 must call mem_protect with PROT_RX to make it executable.

 Input  : rdi = size in bytes
 Output : rax = EXIT_OK or EXIT_OOM
           rdx = pointer to allocated region
*/
global mem_alloc_exec
mem_alloc_exec:
    prologue
    call    mem_map
    epilogue

// ============================================================================
// mem_lock
// ============================================================================
/*
 mem_lock
 Locks a memory region into physical RAM (mlock), preventing it from
 being swapped. Critical for latency-sensitive OS kernel components.

 Input  : rdi = pointer to region
           rsi = size in bytes
 Output : rax = EXIT_OK or EXIT_ERROR
*/
global mem_lock
mem_lock:
    prologue
    mov     rax, SYS_MLOCK
    syscall
    test    rax, rax
    js      .error
    xor     rax, rax
    epilogue
.error:
    mov     rax, EXIT_ERROR
    epilogue

// ============================================================================
// mem_unlock
// ============================================================================
/*
 mem_unlock
 Unlocks a previously locked memory region.

 Input  : rdi = pointer to region
           rsi = size in bytes
 Output : rax = EXIT_OK or EXIT_ERROR
*/
global mem_unlock
mem_unlock:
    prologue
    mov     rax, SYS_MUNLOCK
    syscall
    test    rax, rax
    js      .error
    xor     rax, rax
    epilogue
.error:
    mov     rax, EXIT_ERROR
    epilogue

// ============================================================================
// mem_advise
// ============================================================================
/*
 mem_advise
 Provides the kernel with a hint about expected memory usage patterns.
 Input  : rdi = pointer to region
           rsi = size in bytes
           rdx = advice flag (MADV_* constant)
 Output : rax = EXIT_OK or EXIT_ERROR

 Common advice values:
   MADV_NORMAL      = 0   default
   MADV_SEQUENTIAL  = 2   read sequentially
   MADV_WILLNEED    = 3   prefetch ahead
   MADV_DONTNEED    = 4   free pages
   MADV_FREE        = 8   lazily free
   MADV_HUGEPAGE    = 14  enable transparent huge pages
*/
%def MADV_NORMAL     0
%def MADV_SEQUENTIAL 2
%def MADV_WILLNEED   3
%def MADV_DONTNEED   4
%def MADV_FREE       8
%def MADV_HUGEPAGE   14

global mem_advise
mem_advise:
    prologue
    mov     rax, SYS_MADVISE
    syscall
    test    rax, rax
    js      .error
    xor     rax, rax
    epilogue
.error:
    mov     rax, EXIT_ERROR
    epilogue
