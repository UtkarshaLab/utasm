/*
 ============================================
 File     : src/main.s
 Project  : utasm
 Version  : 0.1.0
 Author   : Utkarsha Lab
 License  : Apache-2.0
 Description: Entry point and orchestrator for the utasm assembler.
 ============================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"

extern arena_init
extern cli_parse
extern str_len

[SECTION .data]
    // Professional banner for the assembler
    msg_banner:
        db 0x1B, "[1;36m", "UTASM", 0x1B, "[0m", " - The Sovereign Assembler Kernel", 0x0A
        db "Version 0.1.0 (Millennial Inversion)", 0x0A, 0
    
    msg_usage:
        db 0x0A, 0x1B, "[1;33m", "USAGE:", 0x1B, "[0m", " utasm [options] <input.s>", 0x0A
        db 0x0A, 0x1B, "[1;32m", "OPTIONS:", 0x1B, "[0m", 0x0A
        db "  -o <file>    Specify output filename (default: out.bin)", 0x0A
        db "  -f <format>  Output format: elf64, bin (default: elf64)", 0x0A
        db "  -a <arch>    Target architecture: amd64, aarch64, riscv64", 0x0A
        db "  -v           Enable verbose diagnostic logging", 0x0A
        db "  --help       Show this professional assistance screen", 0x0A, 0

[SECTION .bss]
    align 8
    global_arena: resb ARENA_SIZE
    global_ctx:   resb ASMCTX_SIZE

[SECTION .text]
    global _start

_start:
    // 1. Establish stack frame
    // In _start, [rsp] is argc, [rsp+8] is argv[0]
    push    rbp
    mov     rbp, rsp

    // 2. Clear context and arena structures
    zero_mem global_ctx, ASMCTX_SIZE
    zero_mem global_arena, ARENA_SIZE

    // 3. Initialize Arena Allocator (256 MiB reservation)
    mov     rdi, global_arena
    mov     rsi, UTASM_HEAP_SIZE
    call    arena_init
    test    rax, rax
    jnz     .exit_oom

    // Link arena to context
    mov     [global_ctx + ASMCTX_arena], global_arena
    mov     byte [global_ctx + ASMCTX_tag], TAG_ASM_CTX

    // 4. Parse Command Line Arguments
    // After 'push rbp', [rbp+8] = argc, [rbp+16] = argv[0]
    mov     rdi, global_ctx
    mov     rsi, [rbp + 8]   // argc
    lea     rdx, [rbp + 16]  // argv
    call    cli_parse
    test    rax, rax
    jnz     .show_usage      // If error or help, show usage

    // 5. Check if input file provided
    cmp     qword [global_ctx + ASMCTX_input], 0
    je      .show_usage

    // 6. TODO: Compilation Pipeline
    // call lexer_init
    // call preprocessor_run
    // call parser_run
    // call encoder_run
    // call linker_run

    // 7. Normal Exit
    mov     rax, AMD64_SYS_EXIT
    mov     rdi, EXIT_OK
    syscall

.show_usage:
    mov     rdi, STDOUT_FILENO
    lea     rsi, [msg_banner]
    call    print_str
    lea     rsi, [msg_usage]
    call    print_str
    
    mov     rax, AMD64_SYS_EXIT
    mov     rdi, EXIT_USAGE
    syscall

.exit_oom:
    mov     rax, AMD64_SYS_EXIT
    mov     rdi, EXIT_OOM
    syscall

// Helper: print_str (null-terminated)
// rdi = fd, rsi = str
print_str:
    push    rbx
    push    rdi
    push    rsi
    
    mov     rdi, rsi
    call    str_len
    mov     rdx, rax        // rdx = length
    
    mov     rax, AMD64_SYS_WRITE
    pop     rsi             // rsi = buffer
    pop     rdi             // rdi = fd
    syscall
    
    pop     rbx
    ret
