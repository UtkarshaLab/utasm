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
extern io_open
extern io_file_size
extern io_mmap
extern lexer_init
extern prep_init
extern parser_parse_instruction
extern amd64_encode_instruction
extern aarch64_encode_instruction
extern riscv64_encode_instruction
extern elf64_emit
extern binary_emit
extern reloc_init
extern linker_run
extern listing_generate
extern mapfile_generate
extern asm_ctx_align

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
    mov     rax, global_arena
    mov     [global_ctx + ASMCTX_arena], rax
    mov     byte [global_ctx + ASMCTX_tag], TAG_ASM_CTX

    // 3.5 Allocate Symbol Hash Table (64k entries * 8 bytes = 512 KiB)
    mov     rdi, global_arena
    mov     rsi, (65536 * 8)
    call    arena_alloc
    test    rax, rax
    jnz     .exit_oom
    mov     [global_ctx + ASMCTX_symhash], rdx
    // arena_alloc already zeroes if it's fresh, but we could explicitly zero_mem if needed.

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

    // 6. Compilation Pipeline
    
    // 6.1 Initialize Relocation Engine
    mov     rdi, global_ctx
    call    reloc_init
    check_err

    // 6.2 Open and Map Input File
    mov     rdi, [global_ctx + ASMCTX_input] // Filename from CLI
    mov     rsi, AMD64_O_RDONLY
    xor     rdx, rdx
    call    io_open
    test    rax, rax
    jnz     .exit_io_error
    mov     r12, rdx                         // r12 = fd
    
    mov     rdi, r12
    call    io_file_size
    mov     r13, rdx                         // r13 = size
    
    xor     rdi, rdi
    mov     rsi, r13
    mov     rdx, PROT_READ
    mov     rcx, MAP_PRIVATE
    mov     r8, r12
    xor     r9, r9
    call    io_mmap
    test    rax, rax
    jnz     .exit_io_error
    mov     r14, rdx                         // r14 = buffer
    
    // 6.3 Initialize Pipeline Components
    // Lexer
    sub     rsp, LEXER_SIZE
    mov     rbx, rsp                         // rbx = LexerState
    mov     rdi, rbx
    mov     rsi, r14                         // buffer
    mov     rdx, r13                         // size
    mov     rcx, [global_ctx + ASMCTX_input] // filename
    mov     r9, global_ctx
    mov     r10, global_arena
    call    lexer_init
    
    // Preprocessor
    sub     rsp, PREP_SIZE
    mov     r15, rsp                         // r15 = PrepState
    mov     rdi, r15
    mov     rsi, rbx                         // LexerState
    mov     rdx, global_ctx
    mov     rcx, global_arena
    call    prep_init
    
    // 6.3.1 Start Benchmark
    rdtsc
    shl     rdx, 32
    or      rax, rdx
    mov     [global_ctx + ASMCTX_perf_start], rax

    // 6.4 Main Assembly Loop
.assembly_loop:
    mov     rdi, r15                         // PrepState
    call    parser_parse_instruction
    test    rax, rax
    jnz     .error_in_parser
    
    // Check for EOF (RAX=0, RDX=0)
    test    rdx, rdx
    jz      .emission
    
    mov     r14, rdx                         // r14 = INST*
    movzx   eax, byte [global_ctx + ASMCTX_target]
    
    // ---- 1. Alignment Guard (RISC / Fixed-width) ----
    IF eax, e, TARGET_AARCH64
        mov     rdi, global_ctx
        mov     rsi, 4
        call    asm_ctx_align
    ELSEIF eax, e, TARGET_RISCV64
        mov     rdi, global_ctx
        mov     rsi, 2                 // Allow 2-byte (C-extension)
        call    asm_ctx_align
    ENDIF

    // ---- 2. Offset Stamping (CRITICAL FOR RELOCS) ----
    mov     rdi, [global_ctx + ASMCTX_curr_sec]
    test    rdi, rdi
    IF z | mov rdi, [global_ctx + ASMCTX_sections] | mov rdi, [rdi] | ENDIF
    mov     rax, [rdi + SECTION_size]
    mov     [r14 + INST_offset], rax
    
    // ---- 3. Encoding Dispatch ----
    mov     rdi, global_ctx
    mov     rsi, r14
    movzx   eax, byte [global_ctx + ASMCTX_target]
    
    IF eax, e, TARGET_AMD64
        call    amd64_encode_instruction
    ELSEIF eax, e, TARGET_AARCH64
        call    aarch64_encode_instruction
    ELSEIF eax, e, TARGET_RISCV64
        call    riscv64_encode_instruction
    ENDIF
    check_err
    
    jmp     .assembly_loop

.error_in_parser:
    // Handle real errors here
    mov     rdi, rax
    call    error_report
    jmp     .exit_error

.loop_check:
    cmp     rax, EXIT_OK
    je      .emission
    // If it's EOF, we proceed to emission
    // (Assuming parser returns specific code for EOF, or check Lexer)
    // For now, assume any non-zero RAX is "Done" or "Error"
    
.emission:
    // 6.5 Emission Phase
    mov     rdi, global_ctx
    call    linker_run
    check_err

    // 6.6 Diagnostic Phase (Optional)
    mov     rax, [global_ctx + ASMCTX_flags]
    test    rax, CTX_FLAG_LISTING
    jz      .check_map
    mov     rdi, global_ctx
    call    listing_generate

.check_map:
    // Logic for map file...
    // (We will expand this as needed)

    // 7. Normal Exit
    rdtsc
    shl     rdx, 32
    or      rax, rdx
    mov     r8, [global_ctx + ASMCTX_perf_start]
    sub     rax, r8                         // rax = total cycles
    
    // For now, we just exit, but we've recorded the data.
    // In a future pass, we'll implement a 'print_uint64' to show it.
    
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

.exit_io_error:
    mov     rax, AMD64_SYS_EXIT
    mov     rdi, EXIT_FILE_NOT_FOUND
    syscall

.exit_error:
    mov     rax, AMD64_SYS_EXIT
    mov     rdi, EXIT_ERROR
    syscall
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
