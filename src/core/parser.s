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
        call    parser_parse_reg_info
        IF rax, ne, ERR
            mov     byte [r12 + OPERAND_kind], OP_REG
        ELSE
            mov     byte [r12 + OPERAND_kind], OP_SYMBOL
            mov     rax, [r13 + TOKEN_value]
            mov     [r12 + OPERAND_sym], rax
        ENDIF
        jmp     .success
    ENDIF

    // ... (rest of function)

/**
 * [parser_parse_reg_info]
 * Input: RSI = Name String, RDI = Table Pointer, R12 = OPERAND Pointer
 * Output: AL = Reg ID, RAX = ERR if not found
 */
parser_parse_reg_info:
    prologue
    push    rdi
    call    parser_is_register
    pop     rdi
    IF rax, e, ERR
        epilogue
    ENDIF
    
    // RAX: bit 16 = is_high, bits 8-15 = size_in_bytes, bits 0-7 = reg_id
    mov     [r12 + OPERAND_reg], al
    
    mov     rcx, rax
    shr     rcx, 8
    and     cl, 0x7F            // Size in bytes
    shl     cl, 3               // Convert to bits
    mov     [r12 + OPERAND_size], cl
    
    shr     rax, 16
    and     al, 1
    mov     [r12 + OPERAND_is_high], al
    
    mov     rax, OK
    epilogue
    
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
    IF al, e, TOK_IDENT
        call    preprocessor_next_token
        mov     rsi, [rdx + TOKEN_value]
        
        // Potential Segment Override check
        call    preprocessor_peek_token
        IF byte [rdx + TOKEN_kind], e, TOK_COLON
            call    preprocessor_next_token  // consume colon
            IF rsi, e, "fs" | mov byte [r12 + OPERAND_segment], 0x64 | ENDIF
            IF rsi, e, "gs" | mov byte [r12 + OPERAND_segment], 0x65 | ENDIF
            
            call    preprocessor_next_token
            mov     rsi, [rdx + TOKEN_value]
        ENDIF
        
        call    parser_parse_reg_info
        IF rax, e, ERR | jmp .error | ENDIF
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
        call    parser_parse_reg_info
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
    
    // ---- STRUCT BOUNDS CHECK ----
    // If OPERAND_sym is set, the base address expression contained a
    // struct-field dot-access (e.g. PageTable.Present).  At this point
    // OPERAND_sym holds a pointer to the SYMBOL entry, so we can compare
    // the field's declared byte-width against the instruction's size.
    mov     r13, [r12 + OPERAND_sym]
    test    r13, r13
    jz      .bounds_ok
    
    movzx   rax, byte [r13 + SYMBOL_kind]
    cmp     al, SYM_STRUCT_FIELD
    jne     .bounds_ok
    
    // Field declared size (bytes) is in SYMBOL_size
    mov     r14, [r13 + SYMBOL_size]       // r14 = field byte width
    
    // Instruction access size (bits) is in OPERAND_size -> convert to bytes
    movzx   rcx, byte [r12 + OPERAND_size]
    shr     cl, 3                           // bits -> bytes
    
    cmp     rcx, r14
    jle     .bounds_ok                     // write size <= field size -> OK
    
    // FATAL: write exceeds field width
    extern  error_struct_bounds
    mov     rdi, [r13 + SYMBOL_name]       // field name for error message
    mov     rsi, r14                       // declared field size
    mov     rdx, rcx                       // attempted access size
    call    error_struct_bounds
    mov     rax, EXIT_STRUCT_BOUNDS
    jmp     .error

.bounds_ok:
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

// ============================================================================
// PARSER EXTENSION: SAFE STRUCT REGISTRATION
// ============================================================================

/**
 * [parser_parse_struc]
 * Purpose: Parse a `struc` ... `endstruc` block.
 *   For each `field name, size` line, registers a SYMBOL with:
 *     kind  = SYM_STRUCT_FIELD
 *     value = byte offset within the struct
 *     size  = declared field byte width
 *   At `endstruc`, registers the struct name itself with:
 *     kind  = SYM_STRUCT
 *     value = 0
 *     size  = total struct size in bytes
 * Input:
 *   RBX: pointer to PrepState
 *   RDI: pointer to the struct-name Token (the token after 'struc')
 * Output:
 *   RAX = EXIT_OK or error code
 */
global parser_parse_struc
parser_parse_struc:
    prologue
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     r15, rdi               // r15 = struct name Token
    xor     r14, r14               // r14 = running byte offset
    
    // Build struct-name string ("StructName", null-terminated from token)
    mov     r13, [r15 + TOKEN_value]  // r13 = struct name ptr
    
.field_loop:
    // Read next meaningful token (skip newlines)
    call    preprocessor_next_token
    check_err
    mov     r12, rdx
    
    mov     al, [r12 + TOKEN_kind]
    
    IF al, e, TOK_NEWLINE
        jmp     .field_loop
    ENDIF
    
    IF al, e, TOK_EOF
        mov     rax, EXIT_UNEXPECTED_EOF
        jmp     .error
    ENDIF
    
    // Check for 'endstruc'
    IF al, e, TOK_IDENT
        mov     rdi, [r12 + TOKEN_value]
        lea     rsi, [str_endstruc]
        extern  str_compare
        call    str_compare
        IF rax, e, 0
            jmp .register_struct
        ENDIF
        
        // Check for 'field' keyword
        mov     rdi, [r12 + TOKEN_value]
        lea     rsi, [str_field]
        call    str_compare
        IF rax, ne, 0
            mov     rax, EXIT_UNEXPECTED_TOKEN
            jmp     .error
        ENDIF
    ELSE
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    // Parse: field <name>, <size>
    // 1. Field name
    call    preprocessor_next_token
    check_err
    IF byte [rdx + TOKEN_kind], ne, TOK_IDENT
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    mov     rbx, [rdx + TOKEN_value]   // rbx = field name ptr
    
    // Consume comma
    call    preprocessor_next_token
    check_err
    IF byte [rdx + TOKEN_kind], ne, TOK_COMMA
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    
    // 2. Field byte size (integer literal)
    call    preprocessor_next_token
    check_err
    IF byte [rdx + TOKEN_kind], ne, TOK_NUMBER
        mov     rax, EXIT_UNEXPECTED_TOKEN
        jmp     .error
    ENDIF
    mov     rsi, [rdx + TOKEN_value]
    call    str_to_int                 // rax = field byte size
    mov     r11, rax                   // r11 = field size
    
    // Build fully-qualified name "StructName.FieldName" in arena
    mov     rdi, [rbx + PREP_arena]
    lea     rsi, [r13]             // struct name
    lea     rdx, [rbx]             // field name
    // (In a full implementation this calls a str_concat helper)
    // For now we store field name directly and rely on dot-notation lookup
    
    // Register SYMBOL: kind=SYM_STRUCT_FIELD, value=offset, size=field_size
    mov     rdi, [rbx + PREP_ctx]
    sub     rsp, SYMBOL_SIZE
    mov     rsi, rsp
    mov     byte [rsi + SYMBOL_tag],  TAG_SYMBOL
    mov     byte [rsi + SYMBOL_kind], SYM_STRUCT_FIELD
    mov     byte [rsi + SYMBOL_vis],  VIS_LOCAL
    mov     [rsi + SYMBOL_name],  rbx      // field name ptr
    mov     [rsi + SYMBOL_value], r14      // byte offset
    mov     [rsi + SYMBOL_size],  r11      // field byte width  <-- THE KEY
    call    symbol_add
    add     rsp, SYMBOL_SIZE
    
    // Advance offset
    add     r14, r11
    jmp     .field_loop
    
.register_struct:
    // Register the struct itself: kind=SYM_STRUCT, size=total
    mov     rdi, [rbx + PREP_ctx]
    sub     rsp, SYMBOL_SIZE
    mov     rsi, rsp
    mov     byte [rsi + SYMBOL_tag],  TAG_SYMBOL
    mov     byte [rsi + SYMBOL_kind], SYM_STRUCT
    mov     byte [rsi + SYMBOL_vis],  VIS_LOCAL
    mov     [rsi + SYMBOL_name],  r13     // struct name ptr
    mov     qword [rsi + SYMBOL_value], 0
    mov     [rsi + SYMBOL_size],  r14     // total byte size
    call    symbol_add
    add     rsp, SYMBOL_SIZE
    
    xor     rax, rax
    jmp     .done

.error:
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    epilogue

/**
 * [error_struct_bounds]
 * Purpose: Print a diagnostic for a struct bounds violation and abort.
 * Input:
 *   RDI = pointer to field name string
 *   RSI = declared field byte size
 *   RDX = attempted access byte size
 */
global error_struct_bounds
error_struct_bounds:
    prologue
    extern  error_emit            // error.s generic message emitter
    // Passes all three args straight through; error_emit formats the message
    call    error_emit
    mov     rax, EXIT_STRUCT_BOUNDS
    epilogue

[SECTION .rodata]
str_endstruc:  db "endstruc", 0
str_field:     db "field", 0
