/*
 ============================================================================
 File        : src/core/parser.s
 Project     : utasm
 Version     : 0.1.0
 Description : Instruction Parser and Mnemonic Dispatcher.
 ============================================================================
*/

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

[SECTION .text]

/**
 * [parser_parse_instruction]
 * Purpose: Parses a single assembly instruction from the token stream.
 * Parameters:
 *   RBX: [in] Pointer to PrepState (Preprocessor state)
 * Output:
 *   RAX: [out] 0 on success, error code on failure.
 *   RDX: [out] Pointer to filled Instruction struct (in arena)
 */
global parser_parse_instruction
parser_parse_instruction:
    prologue
    
    // Allocate instruction struct on arena
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, INST_SIZE
    call    arena_alloc
    check_err
    mov     r15, rdx                // R15 = Instruction pointer
    mov     byte [r15 + INST_tag], TAG_INSTRUCTION
    
    // 1. Get the first token (Mnemonic)
    call    preprocessor_next_token
    check_err
    mov     r12, rax                // R12 = Token pointer
    
    // If EOF or Newline, return OK (empty line)
    mov     al, [r12 + TOKEN_kind]
    IF al, e, TOK_EOF
        xor     rax, rax
        epilogue
    ENDIF
    IF al, e, TOK_NEWLINE
        xor     rax, rax
        epilogue
    ENDIF

    // Must be an identifier for a mnemonic
    IF al, ne, TOK_IDENT
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    // 2. Identify mnemonic
    mov     rsi, [r12 + TOKEN_value]
    hash_fnv1a_64 rsi, r13          // R13 = Hash
    
    mov     rdi, r13
    call    parser_lookup_mnemonic
    test    rax, rax
    jz      .unknown_mnemonic
    
    mov     [r15 + INST_op_id], ax  // Store mnemonic ID
    
    // 3. Parse operands
    xor     r14, r14                // R14 = Operand count
.operand_loop:
    call    parser_parse_operand
    test    rax, rax
    jnz     .error
    
    // Copy operand to instruction struct
    // Offset = INST_op0 + (r14 * OPERAND_SIZE)
    mov     rax, OPERAND_SIZE
    mul     r14
    lea     rdi, [r15 + INST_op0 + rax]
    mov     rsi, rdx                // RDX = Result of parser_parse_operand
    mov     rcx, OPERAND_SIZE
    rep     movsb
    
    inc     r14
    mov     [r15 + INST_nops], r14b
    
    // Check for comma or end of line
    call    preprocessor_peek_token
    mov     al, [rax + TOKEN_kind]
    IF al, e, TOK_COMMA
        call    preprocessor_next_token // consume comma
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
 * Purpose: Parses a single operand (Reg, Imm, Mem).
 * Output: RDX = Pointer to Operand struct in arena.
 */
parser_parse_operand:
    prologue
    
    // Allocate operand struct
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, OPERAND_SIZE
    call    arena_alloc
    check_err
    mov     r12, rdx                // R12 = Operand pointer
    mov     byte [r12 + OPERAND_tag], TAG_OPERAND
    
    call    preprocessor_next_token
    mov     r13, rax                // R13 = Token pointer
    
    mov     al, [r13 + TOKEN_kind]
    
    // Register or Symbol?
    IF al, e, TOK_IDENT
        mov     rsi, [r13 + TOKEN_value]
        call    parser_is_register
        IF rax, ne, ERR
            mov     byte [r12 + OPERAND_kind], OP_REG
            mov     byte [r12 + OPERAND_reg], al
            mov     byte [r12 + OPERAND_size], 8 // Default to 64-bit
        ELSE
            mov     byte [r12 + OPERAND_kind], OP_SYMBOL
            mov     rax, [r13 + TOKEN_value]
            mov     [r12 + OPERAND_sym], rax
        ENDIF
        jmp     .success
    ENDIF
    
    // Immediate?
    IF al, e, TOK_NUMBER
        mov     byte [r12 + OPERAND_kind], OP_IMM
        mov     rsi, [r13 + TOKEN_value]
        call    str_to_int
        mov     [r12 + OPERAND_imm], rax
        jmp     .success
    ENDIF
    
    // Memory?
    IF al, e, TOK_LBRACKET
        call    parser_parse_mem_operand
        // ... (Simplified for now)
        jmp     .success
    ENDIF
    
    mov     rax, EXIT_INVALID_OPERAND
    epilogue

.success:
    mov     rax, OK
    mov     rdx, r12
    epilogue

/**
 * [parser_is_register]
 * Input: RSI = String pointer
 * Output: RAX = Register ID or ERR
 */
parser_is_register:
    prologue
    hash_fnv1a_64 rsi, r13
    
    lea     rdi, [register_table]
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
 * [parser_parse_mem_operand]
 * Purpose: Parses memory reference operand in format [base + index*scale + disp].
 */
parser_parse_mem_operand:
    prologue
    
    // 1. Get base register
    call    preprocessor_next_token
    mov     r13, rax
    
    mov     al, [r13 + TOKEN_kind]
    IF al, ne, TOK_IDENT
        mov     rax, EXIT_INVALID_ADDR
        jmp     .error
    ENDIF
    
    mov     rsi, [r13 + TOKEN_value]
    call    parser_is_register
    IF rax, e, ERR
        mov     rax, EXIT_INVALID_REG
        jmp     .error
    ENDIF
    
    mov     byte [r12 + OPERAND_kind], OP_MEM
    mov     byte [r12 + OPERAND_base], al
    
    // 2. Expect closing bracket
    call    preprocessor_next_token
    mov     al, [rax + TOKEN_kind]
    IF al, ne, TOK_RBRACKET
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    mov     rax, OK
    epilogue

.error:
    epilogue

/**
 * [parser_lookup_mnemonic]
 * Input: RDI = Hash
 * Output: RAX = Mnemonic ID or 0
 */
parser_lookup_mnemonic:
    prologue
    lea     rsi, [mnemonic_table]
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

[SECTION .rodata]
align 8
register_table:
    // Hashes for rax, rcx, rdx, rbx, rsp, rbp, rsi, rdi
    // Calculated at compile-time via compile_time_hash macro
    compile_time_hash "rax", H_RAX
    dq H_RAX, REG_RAX
    compile_time_hash "rcx", H_RCX
    dq H_RCX, REG_RCX
    compile_time_hash "rdx", H_RDX
    dq H_RDX, REG_RDX
    compile_time_hash "rbx", H_RBX
    dq H_RBX, REG_RBX
    compile_time_hash "rsi", H_RSI
    dq H_RSI, REG_RSI
    compile_time_hash "rdi", H_RDI
    dq H_RDI, REG_RDI
    compile_time_hash "rsp", H_RSP
    dq H_RSP, REG_RSP
    compile_time_hash "rbp", H_RBP
    dq H_RBP, REG_RBP
    dq 0

mnemonic_table:
    mnemonic_entry "mov", 2, OP_MOV
    mnemonic_entry "add", 2, OP_ADD
    mnemonic_entry "sub", 2, OP_SUB
    mnemonic_entry "ret", 0, OP_RET
    dq 0
