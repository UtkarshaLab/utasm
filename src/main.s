; ============================================
; File     : src/main.s
; Project  : utasm
; Author   : Utkarsha Lab
; License  : Apache-2.0
; Description: Entry point and orchestrator for the utasm assembler.
; ============================================

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

DEFAULT REL

extern arena_init
extern arena_alloc
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
extern error_report

[SECTION .data]
    ; Professional banner for the assembler
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
    global global_arena
    global_arena: resb 64        ; ARENA_SIZE (enough for metadata)
    global global_ctx
    global_ctx:   resb 1024      ; ASMCTX_SIZE

[SECTION .text]
    global _start

_start:
    ; 1. Establish stack frame
    push    rbp
    mov     rbp, rsp

    ; 2. Initialize Arena Allocator (256 MiB reservation)
    mov     rdi, global_arena
    mov     rsi, 0x10000000 ; UTASM_HEAP_SIZE
    call    arena_init
    test    rax, rax
    jnz     .exit_oom

    ; Link arena to context
    mov     rax, global_arena
    mov     [global_ctx + ASMCTX_arena], rax
    mov     byte [global_ctx + ASMCTX_tag], TAG_ASM_CTX

    ; 2.5 Allocate Symbol Hash Table (64k entries * 8 bytes = 512 KiB)
    mov     rdi, global_arena
    mov     rsi, 524288
    call    arena_alloc
    test    rax, rax
    jnz     .exit_oom
    mov     [global_ctx + ASMCTX_symhash], rdx

    ; 3. Parse Command Line Arguments
    mov     rdi, global_ctx
    mov     rsi, [rbp + 8]   ; argc
    lea     rdx, [rbp + 16]  ; argv
    call    cli_parse
    test    rax, rax
    jnz     .show_usage      ; If error or help, show usage

    ; 4. Check if input file provided
    cmp     qword [global_ctx + ASMCTX_input], 0
    je      .show_usage

    ; 5. Compilation Pipeline
    
    ; 5.1 Initialize Relocation Engine
    mov     rdi, global_ctx
    call    reloc_init
    test    rax, rax
    jnz     .exit_error

    ; 5.2 Open and Map Input File
    mov     rdi, [global_ctx + ASMCTX_input]
    mov     rsi, 0 ; O_RDONLY
    xor     rdx, rdx
    call    io_open
    test    rax, rax
    jnz     .exit_io_error
    mov     r12, rdx                         ; r12 = fd
    
    mov     rdi, r12
    call    io_file_size
    mov     r13, rdx                         ; r13 = size
    
    xor     rdi, rdi
    mov     rsi, r13
    mov     rdx, 1 ; PROT_READ
    mov     rcx, 2 ; MAP_PRIVATE
    mov     r8, r12
    xor     r9, r9
    call    io_mmap
    test    rax, rax
    jnz     .exit_io_error
    mov     r14, rdx                         ; r14 = buffer
    
    ; 5.3 Initialize Pipeline Components
    sub     rsp, 1024 ; LEXER_SIZE
    mov     rbx, rsp
    mov     rdi, rbx
    mov     rsi, r14
    mov     rdx, r13
    mov     rcx, [global_ctx + ASMCTX_input]
    mov     r8, global_ctx
    mov     r9, global_arena
    call    lexer_init
    
    sub     rsp, 1024 ; PREP_SIZE
    mov     r15, rsp
    mov     rdi, r15
    mov     rsi, rbx
    mov     rdx, global_ctx
    mov     rcx, global_arena
    call    prep_init
    
    ; 5.4 Main Assembly Loop
.assembly_loop:
    mov     rdi, r15
    call    parser_parse_instruction
    test    rax, rax
    jnz     .error_in_parser
    
    ; Check for EOF (RAX=0, RDX=0)
    test    rdx, rdx
    jz      .emission
    
    mov     r14, rdx                         ; r14 = INST*
    movzx   eax, byte [global_ctx + ASMCTX_target]

    ; Target-specific alignment
    cmp     eax, 1 ; TARGET_AARCH64
    jne     .check_riscv
    mov     rdi, global_ctx
    mov     rsi, 4
    call    asm_ctx_align
    jmp     .encode
.check_riscv:
    cmp     eax, 3 ; TARGET_RISCV64
    jne     .encode
    mov     rdi, global_ctx
    mov     rsi, 2
    call    asm_ctx_align

.encode:
    mov     rdi, global_ctx
    mov     rsi, r14
    movzx   eax, byte [global_ctx + ASMCTX_target]
    
    cmp     eax, 2 ; TARGET_AMD64
    je      .call_amd64
    cmp     eax, 1 ; TARGET_AARCH64
    je      .call_aarch64
    cmp     eax, 3 ; TARGET_RISCV64
    je      .call_riscv64
    jmp     .assembly_loop

.call_amd64:
    call    amd64_encode_instruction
    jmp     .check_enc_err
.call_aarch64:
    call    aarch64_encode_instruction
    jmp     .check_enc_err
.call_riscv64:
    call    riscv64_encode_instruction

.check_enc_err:
    test    rax, rax
    jnz     .exit_error
    jmp     .assembly_loop

.error_in_parser:
    mov     rdi, rax
    call    error_report
    jmp     .exit_error

.emission:
    mov     rdi, global_ctx
    call    linker_run
    test    rax, rax
    jnz     .exit_error

    mov     rax, 60
    mov     rdi, 0
    syscall

.show_usage:
    mov     rdi, 1
    lea     rsi, [msg_banner]
    call    print_str
    lea     rsi, [msg_usage]
    call    print_str
    mov     rax, 60
    mov     rdi, 2
    syscall

.exit_oom:
    mov     rax, 60
    mov     rdi, 125
    syscall

.exit_io_error:
    mov     rax, 60
    mov     rdi, 3
    syscall

.exit_error:
    mov     rax, 60
    mov     rdi, 1
    syscall

global print_str
print_str:
    push    rbx
    push    rdi
    push    rsi
    mov     rdi, rsi
    call    str_len
    mov     rdx, rax
    mov     rax, 1
    pop     rsi
    pop     rdi
    syscall
    pop     rbx
    ret
