/*
 ============================================
 File     : src/core/preprocessor.s
 Project  : utasm
 Version  : 0.0.1
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"

// ============================================================================
// PREPROCESSOR
// ============================================================================
// Processes assembler directives and manages the token stream.
// Handles file inclusions, macro expansions, and conditional assembly.
//
// All functions return error codes in rax and results in rdx.
// Follows standard utasm calling convention (AMD64).
// ============================================================================

[SECTION .text]

// ---- prep_init --------------------------
/*
 prep_init
 Initialises the preprocessor state.
 Input    : rdi = pointer to PrepState
            rsi = pointer to initial LexerState
            rdx = pointer to AsmCtx
            rcx = pointer to Arena
 Output   : rax = EXIT_OK
 Clobbers : none
*/
global prep_init
prep_init:
    mov     byte [rdi + PREP_tag], TAG_PREPROCESSOR
    mov     byte [rdi + PREP_depth], 0
    mov     byte [rdi + PREP_skipping], FALSE
    mov     [rdi + PREP_lexer], rsi
    mov     [rdi + PREP_ctx], rdx
    mov     [rdi + PREP_arena], rcx
    xor     rax, rax
    ret

// ---- prep_next_token --------------------
/*
 prep_next_token
 Gets the next token from the preprocessor stream.
 Handles branching and directive execution internally.
 Input    : rdi = pointer to PrepState
            rsi = pointer to Token (destination)
 Output   : rax = EXIT_OK or error code
 Clobbers : r8, r9, r10, r11
*/
global prep_next_token
prep_next_token:
    push    rbx
    push    r12
    mov     rbx, rdi               // rbx = PrepState
    mov     r12, rsi               // r12 = Token dest

.next:
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r12
    call    lexer_next_token
    test    rax, rax
    jnz     .done                  // lexer error

    // handle EOF
    cmp     byte [r12 + TOKEN_kind], TOK_EOF
    je      .handle_eof

    // check if skipping
    cmp     byte [rbx + PREP_skipping], TRUE
    jne     .not_skipping

    // we are skipping. check for %if / %else / %endif
    cmp     byte [r12 + TOKEN_kind], TOK_PERCENT
    jne     .next                  // just consume and get next

    // it's a %, could be %if/%endif. peek next
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r12
    call    lexer_peek_token
    // if it's "if", "ifdef", "ifndef", "else", "endif"
    // we must handle them even when skipping to track depth.
    // ... logic for depth tracking ...
    // For now, let's just handle non-skipping logic.

.not_skipping:
    cmp     byte [r12 + TOKEN_kind], TOK_PERCENT
    jne     .done                  // normal token, return it

    // it's a directive. handle it.
    mov     rdi, rbx
    mov     rsi, r12
    call    prep_handle_directive
    test    rax, rax
    jnz     .done                  // error handling directive

    // if the directive didn't produce a token, get next
    jmp     .next

.handle_eof:
    // check if we have a parent include context
    mov     r8, [rbx + PREP_ctx]
    mov     r9, [r8 + ASMCTX_inc_ctx]
    test    r9, r9
    jz      .done                  // real EOF

    // pop include context
    // ... logic for popping include context ...
    // For now, return EOF
    jmp     .done

.done:
    pop     r12
    pop     rbx
    ret

// ---- prep_handle_directive --------------
/*
 prep_handle_directive
 Processes a directive starting with %.
 Input    : rdi = pointer to PrepState
            rsi = pointer to % Token
 Output   : rax = EXIT_OK or error code
 Clobbers : ...
*/
prep_handle_directive:
    push    rbx
    push    r12
    mov     rbx, rdi               // rbx = PrepState
    
    // next token should be the directive identifier
    mov     rdi, [rbx + PREP_lexer]
    lea     rsi, [uint_buf]        // temp reuse uint_buf for token? No, better use arena.
    // We need a way to get the identifier string.
    // lexer_next_token into r12
    sub     rsp, 32                // space for temp token
    mov     r12, rsp
    mov     rsi, r12
    call    lexer_next_token
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .expected_ident

    // check which directive it is
    // ... logic for comparing directive name ...
    // %inc, %def, %if, %else, %endif, etc.

    xor     rax, rax

.error:
    add     rsp, 32
    pop     r12
    pop     rbx
    ret

.expected_ident:
    // error_emit(EXIT_EXPECTED_IDENT)
    mov     rax, EXIT_ERROR
    jmp     .error
