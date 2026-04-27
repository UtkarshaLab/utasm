/*
 ============================================================================
 File        : src/core/parser.s
 Project     : utasm
 Version     : 0.1.0
 Description : Multi-Architecture Instruction Parser and Dispatch System.
 ============================================================================
*/

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

[SECTION .text]

/**
 * [parser_parse_instruction]
 * Purpose: Parses an instruction and dispatches to the correct architectural table.
 * Parameters:
 *   RBX: [in] Pointer to PrepState
 */
global parser_parse_instruction
parser_parse_instruction:
    prologue
    
    // Allocate instruction container
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, INST_SIZE
    call    arena_alloc
    check_err
    mov     r15, rdx
    mov     byte [r15 + INST_tag], TAG_INSTRUCTION
    
    // 1. Resolve architectural tables based on context
    call    parser_get_arch_tables
    mov     r11, rax                // R11 = Mnemonic Table
    mov     r10, rdx                // R10 = Register Table
    
    // 2. Get mnemonic token
.get_mnemonic:
    call    preprocessor_next_token
    check_err
    mov     r12, rdx
    
    mov     al, [r12 + TOKEN_kind]
    IF al, e, TOK_EOF
        xor     rax, rax
        epilogue
    ENDIF
    IF al, e, TOK_NEWLINE
        xor     rax, rax
        epilogue
    ENDIF

    IF al, ne, TOK_IDENT
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    // 3. Lookup Mnemonic
    mov     rsi, [r12 + TOKEN_value]
    
    // Check for prefixes
    call    parser_check_prefix
    test    rax, rax
    jz      .lookup_mnemonic
    
    mov     byte [r15 + INST_prefix], al
    jmp     .get_mnemonic           // Get the actual mnemonic after prefix

.lookup_mnemonic:
    mov     rsi, [r12 + TOKEN_value]
    hash_fnv1a_64 rsi, r13
    
    mov     rdi, r13
    mov     rsi, r11                // Current Arch Mnemonic Table
    call    parser_lookup_mnemonic
    test    rax, rax
    jz      .unknown_mnemonic
    
    mov     [r15 + INST_op_id], ax
    
    // 4. Operand Parsing Loop
    xor     r14, r14
.operand_loop:
    call    parser_parse_operand
    test    rax, rax
    jnz     .error
    
    mov     rax, OPERAND_SIZE
    mul     r14
    lea     rdi, [r15 + INST_op0 + rax]
    mov     rsi, rdx
    mov     rcx, OPERAND_SIZE
    rep     movsb
    
    inc     r14
    mov     [r15 + INST_nops], r14b
    
    call    preprocessor_peek_token
    IF byte [rdx + TOKEN_kind], e, TOK_COMMA
        call    preprocessor_next_token
        jmp     .operand_loop
    ENDIF
    
    mov     rax, OK
    mov     rdx, r15
    epilogue

.unknown_mnemonic:
    mov     rax, EXIT_UNKNOWN_INSTR
    epilogue

.error:
    epilogue

/**
 * [parser_parse_operand]
 * Purpose: Parses an operand using the current architectural register table.
 */
parser_parse_operand:
    prologue
    
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, OPERAND_SIZE
    call    arena_alloc
    check_err
    mov     r12, rdx
    mov     byte [r12 + OPERAND_tag], TAG_OPERAND
    
    call    preprocessor_next_token
    mov     r13, rdx
    
    mov     al, [r13 + TOKEN_kind]
    
    IF al, e, TOK_IDENT
        mov     rsi, [r13 + TOKEN_value]
        mov     rdi, r10                // R10 preserved from parser_parse_instruction
        call    parser_is_register
        IF rax, ne, ERR
            mov     byte [r12 + OPERAND_kind], OP_REG
            mov     byte [r12 + OPERAND_reg], al
            mov     byte [r12 + OPERAND_size], ah
        ELSE
            mov     byte [r12 + OPERAND_kind], OP_SYMBOL
            mov     rax, [r13 + TOKEN_value]
            mov     [r12 + OPERAND_sym], rax
        ENDIF
        jmp     .success
    ENDIF
    
    IF al, e, TOK_NUMBER
        mov     byte [r12 + OPERAND_kind], OP_IMM
        mov     rsi, [r13 + TOKEN_value]
        call    str_to_int
        mov     [r12 + OPERAND_imm], rax
        jmp     .success
    ENDIF
    
    IF al, e, TOK_LBRACKET
        call    parser_parse_mem_operand
        check_err
        jmp     .success
    ENDIF
    
    mov     rax, EXIT_INVALID_OPERAND
    epilogue

.success:
    mov     rax, OK
    mov     rdx, r12
    epilogue

/**
 * [parser_get_arch_tables]
 * Purpose: Resolves mnemonic and register tables based on AsmCtx target.
 * Output:
 *   RAX: Mnemonic Table Pointer
 *   RDX: Register Table Pointer
 */
parser_get_arch_tables:
    prologue
    mov     rax, [rbx + PREP_ctx]
    movzx   rcx, byte [rax + ASMCTX_target]
    
    IF cl, e, TARGET_AMD64
        extern amd64_mnemonic_table
        extern amd64_register_table
        lea     rax, [amd64_mnemonic_table]
        lea     rdx, [amd64_register_table]
    ELSEIF cl, e, TARGET_AARCH64
        extern mnemonic_table_aarch64
        extern aarch64_register_table
        lea     rax, [mnemonic_table_aarch64]
        lea     rdx, [aarch64_register_table]
    ELSEIF cl, e, TARGET_RISCV64
        extern mnemonic_table_riscv64
        extern riscv64_register_table
        lea     rax, [mnemonic_table_riscv64]
        lea     rdx, [riscv64_register_table]
    ELSE
        xor     rax, rax
        xor     rdx, rdx
    ENDIF
    epilogue

/**
 * [parser_parse_mem_operand]
 * Purpose: Technical SIB Parser.
 */
parser_parse_mem_operand:
    prologue
    mov     byte [r12 + OPERAND_kind], OP_MEM
    
    call    preprocessor_peek_token
    mov     al, [rdx + TOKEN_kind]
    
    IF al, e, TOK_NUMBER
        call    preprocessor_next_token
        mov     rsi, [rdx + TOKEN_value]
        call    str_to_int
        mov     [r12 + OPERAND_imm], rax
    ELSEIF al, e, TOK_IDENT
        call    preprocessor_next_token
        mov     rsi, [rdx + TOKEN_value]
        mov     rdi, r10                // Use active register table
        call    parser_is_register
        IF rax, e, ERR
            mov     rax, EXIT_INVALID_REG
            jmp     .error
        ENDIF
        mov     [r12 + OPERAND_base], al
    ENDIF
    
.offset_chain:
    call    preprocessor_peek_token
    mov     r13, rdx
    mov     al, [r13 + TOKEN_kind]
    
    IF al, e, TOK_PLUS
        call    preprocessor_next_token
        mov     r14, 1
    ELSEIF al, e, TOK_MINUS
        call    preprocessor_next_token
        check_err
        mov     r14, -1
    ELSE
        jmp     .finalize
    ENDIF
    
    call    preprocessor_next_token
    check_err
    mov     r13, rdx
    mov     al, [r13 + TOKEN_kind]
    
    IF al, e, TOK_IDENT
        mov     rsi, [r13 + TOKEN_value]
        mov     rdi, r10
        call    parser_is_register
        IF rax, e, ERR
            mov     rax, EXIT_INVALID_REG
            jmp     .error
        ENDIF
        mov     [r12 + OPERAND_index], al
        
        call    preprocessor_peek_token
        IF byte [rdx + TOKEN_kind], e, TOK_STAR
            call    preprocessor_next_token
            call    preprocessor_next_token
            mov     rsi, [rdx + TOKEN_value]
            call    str_to_int
            mov     [r12 + OPERAND_scale], al
        ENDIF
    ELSEIF al, e, TOK_NUMBER
        mov     rsi, [r13 + TOKEN_value]
        call    str_to_int
        IF r14, e, -1
            sub     [r12 + OPERAND_imm], rax
        ELSE
            add     [r12 + OPERAND_imm], rax
        ENDIF
    ENDIF
    jmp     .offset_chain

.finalize:
    call    preprocessor_next_token
    IF byte [rdx + TOKEN_kind], ne, TOK_RBRACKET
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    mov     rax, OK
    epilogue

.error:
    epilogue

/**
 * [parser_is_register]
 * Input: RSI = String, RDI = Table Pointer
 */
parser_is_register:
    prologue
    hash_fnv1a_64 rsi, r13
.loop:
    mov     rax, [rdi]
    test    rax, rax
    jz      .not_found
    cmp     rax, r13
    je      .found
    add     rdi, 16
    jmp     .loop

.found:
    mov     rax, [rdi + 8]
    epilogue

.not_found:
    mov     rax, ERR
    epilogue

/**
 * [parser_lookup_mnemonic]
 * Input: RDI = Hash, RSI = Table Pointer
 */
parser_lookup_mnemonic:
    prologue
.loop:
    mov     rax, [rsi]
    test    rax, rax
    jz      .not_found
    cmp     rax, rdi
    je      .found
    add     rsi, 16
    jmp     .loop

.found:
    movzx   rax, word [rsi + 8]
    epilogue

.not_found:
    xor     rax, rax
    epilogue

/**
 * [parser_check_prefix]
 * Input: RSI = String pointer
 * Output: AL = Prefix byte or 0
 */
parser_check_prefix:
    prologue
    extern str_compare
    mov     rdi, rsi
    
    lea     rsi, [str_rep]
    call    str_compare
    IF rax, e, 0 | mov al, 0xF3 | epilogue | ENDIF
    
    lea     rsi, [str_repe]
    call    str_compare
    IF rax, e, 0 | mov al, 0xF3 | epilogue | ENDIF
    
    lea     rsi, [str_repne]
    call    str_compare
    IF rax, e, 0 | mov al, 0xF2 | epilogue | ENDIF
    
    lea     rsi, [str_lock]
    call    str_compare
    IF rax, e, 0 | mov al, 0xF0 | epilogue | ENDIF
    
    xor     rax, rax
    epilogue

[SECTION .rodata]
str_rep:    db "rep", 0
str_repe:   db "repe", 0
str_repne:  db "repne", 0
str_lock:   db "lock", 0
