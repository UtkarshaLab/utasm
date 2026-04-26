/*
 ============================================================================
 File        : src/core/parser.s
 Project     : utasm
 Version     : 0.1.0
 Description : Industrial Instruction Parser and SIB Addressing Engine.
 ============================================================================
*/

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

[SECTION .text]

/**
 * [parser_parse_instruction]
 * Purpose: Parses a single assembly instruction and constructs an Instruction struct.
 * Parameters:
 *   RBX: [in] Pointer to PrepState (Preprocessor state)
 * Output:
 *   RAX: [out] EXIT_OK on success, error code on failure.
 *   RDX: [out] Pointer to the populated Instruction struct (allocated in arena).
 * Clobbers: RAX, RCX, RDX, RDI, RSI, R8-R15
 */
global parser_parse_instruction
parser_parse_instruction:
    prologue
    
    // Allocate instruction container in the arena
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, INST_SIZE
    call    arena_alloc
    check_err
    mov     r15, rdx                // R15 = Persistent Instruction pointer
    mov     byte [r15 + INST_tag], TAG_INSTRUCTION
    
    // 1. Retrieve the Mnemonic Token
    call    preprocessor_next_token
    check_err
    mov     r12, rax                // R12 = Token pointer
    
    // Handle end-of-stream and empty lines
    mov     al, [r12 + TOKEN_kind]
    IF al, e, TOK_EOF
        xor     rax, rax
        epilogue
    ENDIF
    IF al, e, TOK_NEWLINE
        xor     rax, rax
        epilogue
    ENDIF

    // Validate that the first token is an identifier
    IF al, ne, TOK_IDENT
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    // 2. Mnemonic Identification (FNV-1a Lookup)
    mov     rsi, [r12 + TOKEN_value]
    hash_fnv1a_64 rsi, r13          // R13 = Mnemonic Hash
    
    mov     rdi, r13
    call    parser_lookup_mnemonic
    test    rax, rax
    jz      .unknown_mnemonic
    
    mov     [r15 + INST_op_id], ax  // Commit Mnemonic ID
    
    // 3. Operand Parsing Loop
    xor     r14, r14                // R14 = Zero-based operand index
.operand_loop:
    call    parser_parse_operand
    test    rax, rax
    jnz     .error
    
    // Copy the parsed Operand struct into the Instruction container
    mov     rax, OPERAND_SIZE
    mul     r14
    lea     rdi, [r15 + INST_op0 + rax]
    mov     rsi, rdx                // RDX = Result from parser_parse_operand
    mov     rcx, OPERAND_SIZE
    rep     movsb
    
    inc     r14
    mov     [r15 + INST_nops], r14b
    
    // Check for comma delimiter to proceed to next operand
    call    preprocessor_peek_token
    mov     al, [rax + TOKEN_kind]
    IF al, e, TOK_COMMA
        call    preprocessor_next_token // Consume the comma
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
 * Purpose: Parses a single register, immediate, or memory reference.
 * Output: 
 *   RDX: [out] Pointer to an Operand struct in the arena.
 */
parser_parse_operand:
    prologue
    
    // Allocate local Operand storage
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, OPERAND_SIZE
    call    arena_alloc
    check_err
    mov     r12, rdx                // R12 = Operand pointer
    mov     byte [r12 + OPERAND_tag], TAG_OPERAND
    
    call    preprocessor_next_token
    mov     r13, rax                // R13 = Token pointer
    
    mov     al, [r13 + TOKEN_kind]
    
    // Case 1: Identifier (Register or Symbol)
    IF al, e, TOK_IDENT
        mov     rsi, [r13 + TOKEN_value]
        call    parser_is_register
        IF rax, ne, ERR
            // It is a valid architectural register
            mov     byte [r12 + OPERAND_kind], OP_REG
            mov     byte [r12 + OPERAND_reg], al
            mov     byte [r12 + OPERAND_size], ah // AH holds the encoded size from the table
        ELSE
            // It is a symbolic label reference
            mov     byte [r12 + OPERAND_kind], OP_SYMBOL
            mov     rax, [r13 + TOKEN_value]
            mov     [r12 + OPERAND_sym], rax
        ENDIF
        jmp     .success
    ENDIF
    
    // Case 2: Numeric Literal (Immediate)
    IF al, e, TOK_NUMBER
        mov     byte [r12 + OPERAND_kind], OP_IMM
        mov     rsi, [r13 + TOKEN_value]
        call    str_to_int
        mov     [r12 + OPERAND_imm], rax
        jmp     .success
    ENDIF
    
    // Case 3: Memory Reference [SIB]
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
 * [parser_parse_mem_operand]
 * Purpose: Advanced SIB Parser for [base + index*scale + displacement].
 * Parameters:
 *   R12: [in/out] Pointer to the current Operand struct.
 */
parser_parse_mem_operand:
    prologue
    mov     byte [r12 + OPERAND_kind], OP_MEM
    
    // 1. Identify Base Register or Displacement
    call    preprocessor_peek_token
    mov     al, [rax + TOKEN_kind]
    
    IF al, e, TOK_NUMBER
        // Displacement only or Displacement-start
        call    preprocessor_next_token
        mov     rsi, [rax + TOKEN_value]
        call    str_to_int
        mov     [r12 + OPERAND_imm], rax
    ELSEIF al, e, TOK_IDENT
        // Base Register
        call    preprocessor_next_token
        mov     rsi, [rax + TOKEN_value]
        call    parser_is_register
        IF rax, e, ERR
            mov     rax, EXIT_INVALID_REG
            jmp     .error
        ENDIF
        mov     [r12 + OPERAND_base], al
    ENDIF
    
    // 2. Parse Offset Chain (+/- index*scale +/- disp)
.offset_chain:
    call    preprocessor_peek_token
    mov     r13, rax                // R13 = Peeked Token
    mov     al, [r13 + TOKEN_kind]
    
    IF al, e, TOK_PLUS
        call    preprocessor_next_token // Consume '+'
        mov     r14, 1                  // R14 = Sign (positive)
    ELSEIF al, e, TOK_MINUS
        call    preprocessor_next_token // Consume '-'
        mov     r14, -1                 // R14 = Sign (negative)
    ELSE
        jmp     .finalize
    ENDIF
    
    call    preprocessor_next_token // Get component
    mov     r13, rax
    mov     al, [r13 + TOKEN_kind]
    
    IF al, e, TOK_IDENT
        // Index Register
        mov     rsi, [r13 + TOKEN_value]
        call    parser_is_register
        IF rax, e, ERR
            mov     rax, EXIT_INVALID_REG
            jmp     .error
        ENDIF
        mov     [r12 + OPERAND_index], al
        
        // Check for Scaling (* 1/2/4/8)
        call    preprocessor_peek_token
        IF byte [rax + TOKEN_kind], e, TOK_STAR
            call    preprocessor_next_token // Consume '*'
            call    preprocessor_next_token // Get scale factor
            mov     rsi, [rax + TOKEN_value]
            call    str_to_int
            mov     [r12 + OPERAND_scale], al
        ENDIF
    ELSEIF al, e, TOK_NUMBER
        // Displacement
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
    // 3. Finalize Memory Reference
    call    preprocessor_next_token
    IF byte [rax + TOKEN_kind], ne, TOK_RBRACKET
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    mov     rax, OK
    epilogue

.error:
    epilogue

/**
 * [parser_is_register]
 * Purpose: Validates a string as an architectural register and returns metadata.
 * Output:
 *   AL:  Register Architectural ID (0-15)
 *   AH:  Size Code (1, 2, 4, 8)
 *   RAX: ERR if not found.
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
    mov     rax, [rdi + 8]          // Low byte = ID, High byte = Size
    epilogue

.not_found:
    mov     rax, ERR
    epilogue

/**
 * [parser_lookup_mnemonic]
 * Purpose: Maps a hashed identifier to an internal operation ID.
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
    // ---- 64-bit GPR Matrix ----
    compile_time_hash "rax", H_RAX
    dq H_RAX, (8 << 8) | REG_RAX
    compile_time_hash "rcx", H_RCX
    dq H_RCX, (8 << 8) | REG_RCX
    compile_time_hash "rdx", H_RDX
    dq H_RDX, (8 << 8) | REG_RDX
    compile_time_hash "rbx", H_RBX
    dq H_RBX, (8 << 8) | REG_RBX
    compile_time_hash "rsi", H_RSI
    dq H_RSI, (8 << 8) | REG_RSI
    compile_time_hash "rdi", H_RDI
    dq H_RDI, (8 << 8) | REG_RDI
    compile_time_hash "rsp", H_RSP
    dq H_RSP, (8 << 8) | REG_RSP
    compile_time_hash "rbp", H_RBP
    dq H_RBP, (8 << 8) | REG_RBP
    compile_time_hash "r8",  H_R8
    dq H_R8,  (8 << 8) | REG_R8
    compile_time_hash "r9",  H_R9
    dq H_R9,  (8 << 8) | REG_R9
    compile_time_hash "r10", H_R10
    dq H_R10, (8 << 8) | REG_R10
    compile_time_hash "r11", H_R11
    dq H_R11, (8 << 8) | REG_R11
    compile_time_hash "r12", H_R12
    dq H_R12, (8 << 8) | REG_R12
    compile_time_hash "r13", H_R13
    dq H_R13, (8 << 8) | REG_R13
    compile_time_hash "r14", H_R14
    dq H_R14, (8 << 8) | REG_R14
    compile_time_hash "r15", H_R15
    dq H_R15, (8 << 8) | REG_R15

    // ---- 32-bit GPR Matrix ----
    compile_time_hash "eax", H_EAX
    dq H_EAX, (4 << 8) | REG_RAX
    compile_time_hash "ecx", H_ECX
    dq H_ECX, (4 << 8) | REG_RCX
    compile_time_hash "edx", H_EDX
    dq H_EDX, (4 << 8) | REG_RDX
    compile_time_hash "ebx", H_EBX
    dq H_EBX, (4 << 8) | REG_RBX
    compile_time_hash "esi", H_ESI
    dq H_ESI, (4 << 8) | REG_RSI
    compile_time_hash "edi", H_EDI
    dq H_EDI, (4 << 8) | REG_RDI
    compile_time_hash "esp", H_ESP
    dq H_ESP, (4 << 8) | REG_RSP
    compile_time_hash "ebp", H_EBP
    dq H_EBP, (4 << 8) | REG_RBP

    // ---- 16-bit GPR Matrix ----
    compile_time_hash "ax", H_AX
    dq H_AX, (2 << 8) | REG_RAX
    compile_time_hash "cx", H_CX
    dq H_CX, (2 << 8) | REG_RCX
    compile_time_hash "dx", H_DX
    dq H_DX, (2 << 8) | REG_RDX
    compile_time_hash "bx", H_BX
    dq H_BX, (2 << 8) | REG_RBX

    // ---- 8-bit GPR Matrix ----
    compile_time_hash "al", H_AL
    dq H_AL, (1 << 8) | REG_RAX
    compile_time_hash "cl", H_CL
    dq H_CL, (1 << 8) | REG_RCX
    compile_time_hash "dl", H_DL
    dq H_DL, (1 << 8) | REG_RDX
    compile_time_hash "bl", H_BL
    dq H_BL, (1 << 8) | REG_RBX

    dq 0

mnemonic_table:
    mnemonic_entry "mov", 2, OP_MOV
    mnemonic_entry "add", 2, OP_ADD
    mnemonic_entry "sub", 2, OP_SUB
    mnemonic_entry "ret", 0, OP_RET
    dq 0
