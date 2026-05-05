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
    align 64
    global global_arena
    global_arena: resb ARENA_SIZE
    resb 1024 ; SAFETY PADDING
    global global_ctx
    global_ctx:   resb ASMCTX_SIZE
    resb 1024 ; SAFETY PADDING
    global global_lexer
    global_lexer: resb LEXER_SIZE
    resb 1024 ; SAFETY PADDING
    global global_prep
    global_prep:  resb PREP_SIZE
    resb 1024 ; SAFETY PADDING

[SECTION .text]
    global _start

_start:
    ; 1. Establish stack frame
    push    rbp
    mov     rbp, rsp

    ; 2. Initialize Arena Allocator (256 MiB reservation)
    lea     rdi, [rel global_arena]
    mov     rsi, 0x10000000 ; UTASM_HEAP_SIZE
    call    arena_init
    test    rax, rax
    jnz     .exit_oom

    ; Link arena to context
    lea     r8, [rel global_ctx]
    lea     rax, [rel global_arena]
    mov     [r8 + ASMCTX_arena], rax
    mov     byte [r8 + ASMCTX_tag], TAG_ASM_CTX

    ; 2.5 Allocate Symbol Hash Table (64k entries * 8 bytes = 512 KiB)
    lea     rdi, [rel global_arena]
    mov     rsi, 524288
    call    arena_alloc
    test    rax, rax
    jnz     .exit_oom
    lea     r8, [rel global_ctx]
    mov     [r8 + ASMCTX_symhash], rdx

    ; 3. Parse Command Line Arguments
    lea     rdi, [rel global_ctx]
    mov     rsi, [rbp + 8]   ; argc
    lea     rdx, [rbp + 16]  ; argv
    call    cli_parse
    test    rax, rax
    jnz     .show_usage      ; If error or help, show usage

    ; 4. Check if input file provided
    lea     r8, [rel global_ctx]
    cmp     qword [r8 + ASMCTX_input], 0
    je      .show_usage

    ; 5. Compilation Pipeline
    
    ; 5.1 Initialize Relocation Engine
    lea     rdi, [rel global_ctx]
    call    reloc_init
    test    rax, rax
    jnz     .exit_error

    ; 5.2 Open and Map Input File
    lea     r8, [rel global_ctx]
    mov     rdi, [r8 + ASMCTX_input]
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
    lea     rdi, [rel global_lexer]
    mov     rsi, r14                         ; rsi = buffer pointer
    mov     rdx, r13                         ; rdx = file size
    lea     r8,  [rel global_ctx]
    mov     rcx, [r8 + ASMCTX_input]         ; rcx = filename string
    lea     r9,  [rel global_arena]
    call    lexer_init
    
    lea     rdi, [rel global_prep]
    lea     rsi, [rel global_lexer]
    lea     rdx, [rel global_ctx]
    lea     rcx, [rel global_arena]
    call    prep_init
    
    ; 5.4 Main Assembly Loop
.assembly_loop:
    lea     rdi, [rel global_prep]
    call    parser_parse_instruction
    test    rax, rax
    jnz     .error_in_parser
    
    ; Check for EOF (RAX=0, RDX=0)
    test    rdx, rdx
    jz      .emission
    
    mov     r14, rdx                         ; r14 = INST*
    lea     r8,  [rel global_ctx]
    movzx   eax, byte [r8 + ASMCTX_target]

    ; Target-specific alignment
    cmp     eax, 1 ; TARGET_AARCH64
    jne     .check_riscv
    lea     rdi, [rel global_ctx]
    mov     rsi, 4
    call    asm_ctx_align
    jmp     .encode
.check_riscv:
    cmp     eax, 3 ; TARGET_RISCV64
    jne     .encode
    lea     rdi, [rel global_ctx]
    mov     rsi, 2
    call    asm_ctx_align

.encode:
    lea     rdi, [rel global_ctx]
    lea     r8, [rel global_ctx]
    movzx   eax, byte [r8 + ASMCTX_target]
    
    cmp     eax, 2 ; TARGET_AMD64
    je      .call_amd64
    cmp     eax, 1 ; TARGET_AARCH64
    je      .call_aarch64
    cmp     eax, 3 ; TARGET_RISCV64
    je      .call_riscv64
    jmp     .assembly_loop

.call_amd64:
    lea     rdi, [rel global_ctx]
    mov     rsi, r14
    call    amd64_encode_instruction
    jmp     .check_enc_err
.call_aarch64:
    lea     rdi, [rel global_ctx]
    call    aarch64_encode_instruction
    jmp     .check_enc_err
.call_riscv64:
    call    riscv64_encode_instruction

.check_enc_err:
    test    rax, rax
    jnz     .exit_error
    jmp     .assembly_loop

.error_in_parser:
    ; Error already reported by parser, just exit
    jmp     .exit_error

.emission:
    lea     rdi, [rel global_ctx]
    call    linker_run
    test    rax, rax
    jnz     .exit_error

    xor     rax, rax
    pop     rbp
    ret

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
