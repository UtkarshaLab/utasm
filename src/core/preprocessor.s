/*
 ============================================
 File     : src/core/preprocessor.s
 Project  : utasm
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"

extern error_new_from_errno
extern symbol_add
extern symbol_find
extern str_to_int
extern str_cmp

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
    mov     byte [rdi + PREP_skip_depth], 0
    mov     byte [rdi + PREP_has_peek], FALSE
    mov     byte [rdi + PREP_mac_depth], 0 // (A83)
    mov     [rdi + PREP_lexer], rsi
    mov     [rdi + PREP_ctx], rdx
    mov     [rdi + PREP_arena], rcx
    xor     rax, rax
    ret

global preprocessor_next_token
preprocessor_next_token:
    push    rbx
    push    r12
    mov     rbx, rdi               // rbx = PrepState
    
    // 1. Handle peek slot
    cmp     byte [rbx + PREP_has_peek], TRUE
    jne     .no_peek
    
    // Return peek token
    mov     byte [rbx + PREP_has_peek], FALSE
    lea     rdx, [rbx + PREP_peek]
    xor     rax, rax
    pop     r12
    pop     rbx
    ret

.no_peek:
    // 2. Allocate token in arena for the result
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, TOKEN_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error
    mov     r12, rdx               // r12 = pointer to new token

    mov     rdi, rbx
    mov     rsi, r12
    call    prep_internal_next
    test    rax, rax
    jnz     .error
    
    mov     rdx, r12
    xor     rax, rax
    pop     r12
    pop     rbx
    ret

global preprocessor_putback_token
preprocessor_putback_token:
    prologue
    push    rbx
    push    r12
    mov     rbx, rdi               // rdi = PrepState
    mov     r12, rsi               // rsi = TOKEN*
    
    // Copy token into peek slot
    lea     rdi, [rbx + PREP_peek]
    mov     rsi, r12
    mov     rcx, TOKEN_SIZE
    rep     movsb
    
    mov     byte [rbx + PREP_has_peek], TRUE
    
    pop     r12
    pop     rbx
    epilogue

// ---- preprocessor_peek_token ------------
global preprocessor_peek_token
preprocessor_peek_token:
    push    rbx
    mov     rbx, rdi
    
    cmp     byte [rbx + PREP_has_peek], TRUE
    je      .done
    
    lea     rsi, [rbx + PREP_peek]
    call    prep_internal_next
    test    rax, rax
    jnz     .fail
    
    mov     byte [rbx + PREP_has_peek], TRUE

.done:
    lea     rdx, [rbx + PREP_peek]
    xor     rax, rax
    pop     rbx
    ret

.fail:
    xor     rdx, rdx
    pop     rbx
    ret

// ---- prep_internal_next -----------------
prep_internal_next:
    push    rbx
    push    r12
    mov     rbx, rdi               // rbx = PrepState
    mov     r12, rsi               // r12 = Token dest

.next:
    // 1. Check if we are expanding a macro
    mov     rax, [rbx + PREP_ctx]
    mov     rax, [rax + ASMCTX_mac_exp]
    test    rax, rax
    jz      .from_lexer

    // Get token from expansion body
    call    prep_expand_next
    test    rax, rax
    jz      .done                  // expansion produced a token
    // if expansion finished, try again (checks for parent or falls to lexer)
    jmp     .next

.from_lexer:
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .done                  // lexer error

    // check if it's a macro call
    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .not_macro_call
    
    // look up in symtab
    mov     rdi, [rbx + PREP_ctx]
    mov     rsi, [r12 + TOKEN_value]
    call    symbol_find
    test    rax, rax
    jnz     .not_macro_call        // not found or error
    
    cmp     byte [rdx + SYMBOL_kind], SYM_MACRO
    jne     .not_macro_call
    
    // Found a macro call!
    mov     rdi, rbx
    mov     rsi, [rdx + SYMBOL_value] // rsi = pointer to MACRO struct
    call    prep_expand_start
    test    rax, rax
    jnz     .done                  // error starting expansion
    jmp     .next                  // get first token of expansion

.not_macro_call:
    // handle EOF
    cmp     byte [r12 + TOKEN_kind], TOK_EOF
    je      .handle_eof

    // check if skipping
    cmp     byte [rbx + PREP_skip_depth], 0
    je      .not_skipping

    // we are skipping. only care about % directives
    cmp     byte [r12 + TOKEN_kind], TOK_PERCENT
    jne     .next                  // consume everything else

    // handle directive even when skipping
    mov     rdi, rbx
    mov     rsi, r12
    call    prep_handle_directive
    jmp     .next

.not_skipping:
    cmp     byte [r12 + TOKEN_kind], TOK_PERCENT
    jne     .done                  // normal token

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
    jz      .done                  // real EOF (main file)

    // 1. Unmap the current file buffer
    mov     rdi, [r9 + INCLUDECTX_buf]
    mov     rsi, [r9 + INCLUDECTX_size]
    extern  io_munmap
    call    io_munmap
    
    // 2. Restore previous lexer
    mov     r10, [r9 + INCLUDECTX_lexer]
    mov     [rbx + PREP_lexer], r10
    
    // 3. Pop include context
    mov     r11, [r9 + INCLUDECTX_parent]
    mov     [r8 + ASMCTX_inc_ctx], r11
    
    // 4. Try getting next token from parent
    jmp     .next

.done:
    pop     r12
    pop     rbx
    ret

// ---- prep_expand_start ------------------
/*
 prep_expand_start
 Starts expanding a macro.
 Input    : rdi = pointer to PrepState
            rsi = pointer to MACRO struct
 Output   : rax = EXIT_OK or error code
*/
prep_expand_start:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     rbx, rdi               // rbx = PrepState
    mov     r12, rsi               // r12 = MACRO struct

    // 0. Check recursion depth (A83: Optimized O(1) check)
    inc     byte [rbx + PREP_mac_depth]
    IF byte [rbx + PREP_mac_depth], g, MAX_MACRO_RECURSION
        mov rax, EXIT_MACRO_RECURSION
        jmp .error_recursion
    ENDIF
    // Increment global expansion ID (A70)
    mov     r8, [rbx + PREP_ctx]
    inc     dword [r8 + ASMCTX_mac_exp_id]

.error_recursion:
    jmp     .error

    // 1. Allocate MACROEXP struct
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, MACROEXP_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error
    mov     r13, rdx               // r13 = MACROEXP struct

    mov     byte [r13 + MACROEXP_tag], TAG_MACRO_EXP
    mov     [r13 + MACROEXP_macro], r12
    mov     qword [r13 + MACROEXP_rep_count], 1 // Default: expand once
    // Check arity
    movzx   rax, byte [r12 + MACRO_min_params]
    movzx   rdx, byte [r12 + MACRO_max_params]
    
    // Allocate space for up to MAX_PARAMS (let's say 32)
    // For now, we'll allocate based on max_params if not variadic, 
    // or a fixed buffer if variadic.
    mov     r14, 32                // max potential params for variadic
    cmp     dl, 0xFF
    je      .alloc_params
    movzx   r14, dl
    
.alloc_params:
    mov     rsi, r14
    imul    rsi, 8
    mov     rdi, [rbx + PREP_arena]
    call    arena_alloc
    check_err
    mov     [r13 + MACROEXP_params], rdx
    mov     r14, rdx               // r14 = param array
    
    xor     r15, r15               // current param index
.param_loop:
    // Check if we reached max
    movzx   rax, byte [r12 + MACRO_max_params]
    IF al, ne, 0xFF
        cmp r15b, al
        jge .check_trailing
    ELSE
        // Variadic limit (hardcoded to 32 slots in allocation)
        IF r15, ge, 32
            mov rax, EXIT_MACRO_ARITY_FAIL | jmp .error
        ENDIF
    ENDIF
    
    // Peek to see if we have more arguments (comma or not)
    // Actually, we should lex and if it's a newline, we stop.
    // If it's a comma, we continue.
    
    // For the first param, we don't need a comma.
    test    r15, r15
    jz      .parse_param_value
    
    // consume comma
    sub     rsp, TOKEN_SIZE
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, rsp
    call    lexer_next
    IF byte [rsp + TOKEN_kind], ne, TOK_COMMA
        // No more params? Check if we met min
        add     rsp, TOKEN_SIZE
        movzx   rax, byte [r12 + MACRO_min_params]
        cmp     r15b, al
        jl      .error_too_few_args
        jmp     .done_params
    ENDIF
    add     rsp, TOKEN_SIZE

.get_param:
    // Check if this is the LAST parameter of a variadic macro
    movzx   rax, byte [r12 + MACRO_max_params]
    IF al, e, 0xFF
        // If we are at min_params - 1? No, usually variadic is just the last one.
        // Let's say if we are at index (min_params - 1), we capture everything else.
        movzx   rcx, byte [r12 + MACRO_min_params]
        dec     rcx
        IF r15, e, rcx
            call    prep_capture_greedy
            jmp     .done_params
        ENDIF
    ENDIF

.parse_param_value:
    // allocate token for param
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, TOKEN_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error
    mov     [r14 + r15 * 8], rdx
    
    // lex into it
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, rdx
    call    lexer_next
    test    rax, rax
    jnz     .error
    
    // Guard: check if we hit newline/EOF unexpectedly
    mov     al, [rdx + TOKEN_kind]
    cmp     al, TOK_NEWLINE
    je      .error_too_few_args
    cmp     al, TOK_EOF
    je      .error_too_few_args

    inc     r15
    jmp     .param_loop

.check_trailing:
    // Check for too many arguments (is there a comma next?)
    mov     rdi, [rbx + PREP_lexer]
    extern  lexer_peek
    sub     rsp, TOKEN_SIZE
    mov     rsi, rsp
    call    lexer_peek
    mov     al, [rsp + TOKEN_kind]
    add     rsp, TOKEN_SIZE
    cmp     al, TOK_COMMA
    je      .error_too_many_args
    jmp     .done_params

.error_too_few_args:
.error_too_many_args:
    mov     rax, EXIT_MACRO_ARITY_FAIL
    jmp     .error

.done_params:
    mov     rax, [rbx + PREP_ctx]
    mov     rax, [rax + ASMCTX_mac_exp]
    mov     [rax + MACROEXP_nparams], r15b
    
    // 3. Link to previous
    mov     r8, [rbx + PREP_ctx]
    mov     r9, [r8 + ASMCTX_mac_exp]
    mov     [r13 + MACROEXP_parent], r9
    mov     [r8 + ASMCTX_mac_exp], r13
    
    xor     rax, rax
    jmp     .done

.error_pop_token:
    add     rsp, TOKEN_SIZE
    jmp     .error

.error_expected_comma:
    add     rsp, TOKEN_SIZE
    mov     rax, EXIT_INVALID_OPERAND
    jmp     .done

.error:
    mov     rax, EXIT_MACRO_EXP

.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- prep_expand_next -------------------
/*
 prep_expand_next
 Serves the next token from the current macro expansion.
 Handles parameter substitution.
 Input    : rdi = pointer to PrepState
            rsi = pointer to Token (destination)
 Output   : rax = 0 (produced token) or non-zero (finished)
*/
prep_expand_next:
    push    rbx
    push    r12
    push    r13
    mov     rbx, rdi               // rbx = PrepState
    mov     r12, rsi               // r12 = Token dest

    mov     r8, [rbx + PREP_ctx]
    mov     r13, [r8 + ASMCTX_mac_exp] // r13 = current expansion
    test    r13, r13
    jz      .finished

    // 1. Get current token index
    mov     rax, [r13 + MACROEXP_body]
    mov     r9, [r13 + MACROEXP_macro]
    cmp     eax, [r9 + MACRO_ntokens]
    jge     .expansion_end

    // 2. Copy token from macro body
    mov     r10, [r9 + MACRO_tokens]
    imul    rax, TOKEN_SIZE
    add     r10, rax               // r10 = source token

    // copy to dest
    mov     rdi, r12
    mov     rsi, r10
    mov     rcx, (TOKEN_SIZE / 8)
    rep movsq

    // increment body pos
    inc     qword [r13 + MACROEXP_body]

    // 2.5 Handle Stringification (#) (A67)
    IF byte [r12 + TOKEN_kind], e, TOK_HASH
        // Peek at NEXT token in macro body
        mov     rax, [r13 + MACROEXP_body]
        mov     r9, [r13 + MACROEXP_macro]
        cmp     eax, [r9 + MACRO_ntokens]
        jge     .produced              // Nothing after #
        
        mov     r10, [r9 + MACRO_tokens]
        imul    rax, TOKEN_SIZE
        add     r10, rax               // r10 = potential parameter ref
        
        IF byte [r10 + TOKEN_kind], e, TOK_DIRECTIVE
            // Check if it's %1-%9
            mov     rdi, [r10 + TOKEN_value]
            movzx   rax, byte [rdi]
            sub     al, '0'
            IF al, ge, 1 | IF al, le, 9
                // Yes, it's stringification!
                // 1. Consume the directive token
                inc     qword [r13 + MACROEXP_body]
                
                // 2. Get the parameter token
                dec     al
                movzx   rax, al
                mov     r11, [r13 + MACROEXP_params]
                mov     rsi, [r11 + rax * 8]   // rsi = param token
                
                // 3. Stringify it (Create a TOK_STRING)
                mov     byte [r12 + TOKEN_kind], TOK_STRING
                
                // Use TOKEN_value or name string? 
                // For TOK_IDENT, use value. For others, we need a helper.
                // Simple implementation: use the value directly if it's already a string.
                mov     rax, [rsi + TOKEN_value]
                mov     [r12 + TOKEN_value], rax
                
                jmp     .produced
            ENDIF
        ENDIF
    ENDIF

    // 3. Handle parameter substitution
    // Macro parameters are TOK_DIRECTIVE with value like "0", "1", "2"...
    cmp     byte [r12 + TOKEN_kind], TOK_DIRECTIVE
    jne     .produced

    mov     rdi, [r12 + TOKEN_value]
    movzx   rax, byte [rdi]
    
    // CASE 1: %0 (Parameter Count)
    IF al, e, '0'
        // Allocate space for the number string
        mov     rdi, [rbx + PREP_arena]
        mov     rsi, 32
        call    arena_alloc
        test    rax, rax
        jnz     .expansion_end // or other error
        
        mov     rdi, rdx       // dst
        movzx   rsi, byte [r13 + MACROEXP_nparams]
        extern  str_int_to_str
        call    str_int_to_str
        
        mov     byte [r12 + TOKEN_kind], TOK_NUMBER
        mov     [r12 + TOKEN_value], rdx // pointer to formatted string
        jmp     .produced
    ENDIF

    // CASE 2: %1-%9 (Parameter Reference)
    sub     al, '0'
    IF al, ge, 1 | IF al, le, 9
        // it's a param ref! (1-9)
        // check if it is within nparams
        movzx   rcx, byte [r13 + MACROEXP_nparams]
        cmp     al, cl
        jg      .produced              // out of range, keep as directive
        
        // replace r12 with the parameter token
        dec     al                     // 0-indexed
        mov     r11, [r13 + MACROEXP_params]
        movzx   rax, al
        mov     rsi, [r11 + rax * 8]   // rsi = param token
        
        mov     rdi, r12
        mov     rcx, (TOKEN_SIZE / 8)
        rep movsq
        jmp     .produced
    ENDIF

    // CASE 3: Variadic Expansion %{n..} (A69)
    IF byte [rdi], e, '{'
        // parse braced parameter ref like "{1..}"
        inc     rdi                    // skip {
        
        // simple parser for digit
        movzx   rax, byte [rdi]
        sub     al, '0'
        IF al, ge, 1 | IF al, le, 9
            // r14 = starting index (1-based)
            movzx   r14, al
            
            // check for ".." suffix
            IF byte [rdi + 1], e, '.' | IF byte [rdi + 2], e, '.'
                // It's %{n..}!
                // We need to expand all params from r14 to nparams.
                // This is complex for a single prep_expand_next call 
                // because it returns one token.
                // For now, we'll implement it by expanding the FIRST 
                // param in the range and setting a flag to expand 
                // the rest in subsequent calls? 
                
                // Better: if nparams > r14, we expand r14 and then 
                // we'd need to inject commas.
                // To keep it simple for now, we'll support %{n..} as a 
                // way to get ALL arguments from n onwards as a single 
                // space-separated sequence if captured greedy.
                
                // If the parameter was captured via prep_capture_greedy, 
                // it is ALREADY a single string.
                movzx   rcx, byte [r13 + MACROEXP_nparams]
                cmp     r14b, cl
                jg      .produced      // Out of range
                
                dec     r14b           // 0-indexed
                mov     r11, [r13 + MACROEXP_params]
                movzx   rax, r14b
                mov     rsi, [r11 + rax * 8]
                
                mov     rdi, r12
                mov     rcx, (TOKEN_SIZE / 8)
                rep movsq
                jmp     .produced
            ENDIF
        ENDIF
    ENDIF

                jmp     .produced
            ENDIF
        ENDIF
    ENDIF

    // CASE 4: Macro Local Label %% (A70)
    IF byte [r12 + TOKEN_kind], e, TOK_MACRO_LOCAL
        // Expand to ..@ID_label
        mov     r8, [rbx + PREP_ctx]
        movzx   r14, dword [r8 + ASMCTX_mac_exp_id]
        
        // 1. Allocate buffer for ID string
        mov     rdi, [rbx + PREP_arena]
        mov     rsi, 32
        call    arena_alloc
        test    rax, rax
        jnz     .produced
        mov     r15, rdx               // r15 = ID string buffer
        
        mov     rdi, r15
        mov     rsi, r14               // value
        extern  str_int_to_str
        call    str_int_to_str
        
        // 2. Allocate final label buffer
        mov     rdi, [rbx + PREP_arena]
        mov     rsi, MAX_TOKEN
        call    arena_alloc
        test    rax, rax
        jnz     .produced
        mov     r14, rdx               // r14 = final label buffer
        
        // 3. Construct "..@ID_label"
        mov     byte [r14], '.'
        mov     byte [r14+1], '.'
        mov     byte [r14+2], '@'
        
        mov     rdi, r14
        add     rdi, 3                 // skip "..@"
        mov     rsi, r15               // ID string
        mov     rdx, [r12 + TOKEN_value] // original label name
        extern  str_concat
        call    str_concat
        
        // Update token
        mov     byte [r12 + TOKEN_kind], TOK_IDENT
        mov     [r12 + TOKEN_value], r14
        jmp     .produced
    ENDIF

.produced:
    // ---- A68: Token Concatenation (##) ----
.check_concat:
    mov     r8, [rbx + PREP_ctx]
    mov     r13, [r8 + ASMCTX_mac_exp]
    test    r13, r13
    jz      .done_concat

    mov     rax, [r13 + MACROEXP_body]
    mov     r9, [r13 + MACROEXP_macro]
    cmp     eax, [r9 + MACRO_ntokens]
    jge     .done_concat
    
    // Peek at next token
    mov     r10, [r9 + MACRO_tokens]
    imul    rax, TOKEN_SIZE
    add     r10, rax               // r10 = next token in body
    
    IF byte [r10 + TOKEN_kind], e, TOK_CONCAT
        // 1. Consume ##
        inc     qword [r13 + MACROEXP_body]
        
        // 2. Get the NEXT operand (A ## B)
        // We need to produce the next token into a temp buffer
        sub     rsp, TOKEN_SIZE
        mov     rdi, rbx
        mov     rsi, rsp
        call    prep_expand_next
        IF rax, ne, 0
            // Error or expansion end (unexpected)
            add     rsp, TOKEN_SIZE
            jmp     .done_concat
        ENDIF
        
        // 3. Concatenate r12 (merged so far) and rsp (next token)
        // Allocate space for combined string
        mov     rdi, [rbx + PREP_arena]
        mov     rsi, MAX_TOKEN
        extern  arena_alloc
        call    arena_alloc
        test    rax, rax
        jnz     .done_concat           // OOM or error
        
        mov     r14, rdx               // r14 = concat buffer
        
        mov     rdi, r14
        mov     rsi, [r12 + TOKEN_value]
        mov     rdx, [rsp + TOKEN_value]
        extern  str_concat
        call    str_concat
        
        // 4. Update r12 to be the merged IDENT
        mov     byte [r12 + TOKEN_kind], TOK_IDENT
        mov     [r12 + TOKEN_value], r14
        
        add     rsp, TOKEN_SIZE
        jmp     .check_concat          // Chain: allow A ## B ## C
    ENDIF

.done_concat:
    xor     rax, rax
    jmp     .done

.expansion_end:
    // Check for %rep loop
    cmp     dword [r13 + MACROEXP_rep_count], 1
    jle     .do_pop
    
    dec     dword [r13 + MACROEXP_rep_count]
    mov     qword [r13 + MACROEXP_body], 0
    mov     rax, 1                 // try again (retry expansion from start of loop)
    jmp     .done

.do_pop:
    call    prep_expand_pop
    // we finished this expansion, but there might be a parent
    // we return non-zero to tell caller to try again (which will check mac_exp again)
    mov     rax, 1
    jmp     .done

.finished:
    mov     rax, 1

.done:
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- prep_expand_pop --------------------
prep_expand_pop:
    mov     r8, [rdi + PREP_ctx]
    mov     r9, [r8 + ASMCTX_mac_exp]
    test    r9, r9
    jz      .done
    
    mov     r10, [r9 + MACROEXP_parent]
    dec     byte [rdi + PREP_mac_depth] // A83: Correctly pop depth
    mov     [r8 + ASMCTX_mac_exp], r10
.done:
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
    push    r13
    mov     rbx, rdi               // rbx = PrepState
    
    // next token should be the directive identifier
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE        // space for temp token
    mov     r12, rsp               // r12 = temp token dest
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .expected_ident

    // check which directive it is
    mov     rdi, [r12 + TOKEN_value] // directive name
    lea     rsi, [dir_inc]
    call    str_cmp
    test    rax, rax
    jz      .do_inc

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_def]
    call    str_cmp
    test    rax, rax
    jz      .do_def

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_if]
    call    str_cmp
    test    rax, rax
    jz      .do_if

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_ifdef]
    call    str_cmp
    test    rax, rax
    jz      .do_ifdef

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_ifndef]
    call    str_cmp
    test    rax, rax
    jz      .do_ifndef

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_else]
    call    str_cmp
    test    rax, rax
    jz      .do_else

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_endif]
    call    str_cmp
    test    rax, rax
    jz      .do_endif

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_macro]
    call    str_cmp
    test    rax, rax
    jz      .do_macro

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_struc]
    call    str_cmp
    test    rax, rax
    jz      .do_struc

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_rep]
    call    str_cmp
    test    rax, rax
    jz      .do_rep

    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [dir_endrep]
    call    str_cmp
    test    rax, rax
    jz      .do_endrep

    xor     rax, rax
    jmp     .done

.do_inc:
    mov     rdi, rbx
    call    prep_handle_inc
    jmp     .done

.do_def:
    cmp     byte [rbx + PREP_skip_depth], 0
    jne     .done                  // don't execute when skipping
    mov     rdi, rbx
    call    prep_handle_def
    jmp     .done

.do_if:
    mov     rdi, rbx
    call    prep_handle_if
    jmp     .done

.do_ifdef:
    mov     rdi, rbx
    call    prep_handle_ifdef
    jmp     .done

.do_ifndef:
    mov     rdi, rbx
    call    prep_handle_ifndef
    jmp     .done

.do_else:
    mov     rdi, rbx
    call    prep_handle_else
    jmp     .done

.do_endif:
    mov     rdi, rbx
    call    prep_handle_endif
    jmp     .done

.do_macro:
    mov     rdi, rbx
    call    macro_handle_def
    jmp     .done

.do_rep:
    mov     rdi, rbx
    call    prep_handle_rep
    jmp     .done

.do_endrep:
    // %endrep is handled by the capture loop in prep_handle_rep
    // if we hit it here, it's an orphan %endrep
    mov     rax, EXIT_ERROR
    jmp     .done

.error:
    // keep rax as error
    jmp     .done

.expected_ident:
    mov     rax, EXIT_ERROR
    jmp     .done

.done:
    add     rsp, TOKEN_SIZE
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- prep_handle_inc --------------------
/*
 prep_handle_inc
 Handles the %inc directive.
 Input    : rdi = pointer to PrepState
 Output   : rax = EXIT_OK or error code
*/
prep_handle_inc:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     rbx, rdi               // rbx = PrepState

    // next token must be a string (filename)
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r12, rsp
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_STRING
    jne     .expected_string

    // 0. Check include depth
    mov     r8, [rbx + PREP_ctx]
    mov     r9, [r8 + ASMCTX_inc_ctx]
    xor     eax, eax               // default depth = 0
    test    r9, r9
    jz      .depth_ok
    movzx   eax, byte [r9 + INCLUDECTX_depth]
    inc     eax
    cmp     eax, MAX_INCLUDES
    jge     .error_too_deep

.depth_ok:
    movzx   r15d, al               // save new depth in r15 (will be overwritten later, but we need it for context)
    // Actually, r15 is used for buffer pointer later. 
    // Let's use the stack but be careful to pop.
    push    rax

    // 1. Path traversal protection (Check for "..")
    mov     rdi, [r12 + TOKEN_value]
    lea     rsi, [str_dotdot]
    extern  str_find_str
    call    str_find_str
    test    rax, rax
    jz      .path_traversal_error

    // 2. Open the file
    mov     rdi, [r12 + TOKEN_value]
    mov     rsi, AMD64_O_RDONLY
    xor     rdx, rdx
    call    io_open
    test    rax, rax
    jnz     .error_open
    mov     r13, rdx               // r13 = fd

    // 2. Get file size
    mov     rdi, r13
    call    io_file_size
    test    rax, rax
    jnz     .error_size
    mov     r14, rdx               // r14 = size

    // 3. Map file into memory
    xor     rdi, rdi               // addr = NULL
    mov     rsi, r14               // length
    mov     rdx, PROT_READ         // prot
    mov     rcx, MAP_PRIVATE       // flags
    mov     r8, r13                // fd
    xor     r9, r9                 // offset = 0
    call    io_mmap
    test    rax, rax
    jnz     .error_mmap
    mov     r15, rdx               // r15 = buffer

    // 4. Create new LexerState
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, LEXER_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error_oom
    mov     r8, rdx                // r8 = new lexer

    // initialize new lexer
    mov     rdi, r8
    mov     rsi, r15               // buf
    mov     rdx, r14               // size
    mov     rcx, [r12 + TOKEN_value] // filename
    mov     r9, [rbx + PREP_ctx]
    mov     r10, [rbx + PREP_arena]
    call    lexer_init

    // 5. Save state in IncludeCtx
    mov     r12, [rbx + PREP_ctx]
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, INCLUDECTX_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error_oom
    mov     r9, rdx                // r9 = new IncludeCtx

    mov     byte [r9 + INCLUDECTX_tag], TAG_INCLUDE_CTX
    pop     rax                    // restore new depth
    mov     byte [r9 + INCLUDECTX_depth], al
    
    mov     r10, [r12 + ASMCTX_inc_ctx]
    mov     [r9 + INCLUDECTX_parent], r10 // link to previous
    mov     [r12 + ASMCTX_inc_ctx], r9    // update current in AsmCtx
    
    // Store current file info for unmapping later
    mov     [r9 + INCLUDECTX_buf], r15
    mov     [r9 + INCLUDECTX_size], r14
    
    // Save current lexer in the context so we can restore it
    mov     r11, [rbx + PREP_lexer]
    mov     [r9 + INCLUDECTX_lexer], r11
    
    mov     [rbx + PREP_lexer], r8 // Switch to new lexer

    // 6. Close the fd (mmap keeps it open if needed, but we don't need it)
    mov     rdi, r13
    call    io_close

    xor     rax, rax
    jmp     .done

.error_too_deep:
    mov     rdi, [rbx + PREP_ctx]
    mov     rsi, [rbx + PREP_lexer]
    mov     rsi, [rsi + LEXER_file]
    mov     edx, dword [rbx + PREP_lexer]
    mov     edx, dword [rdx + LEXER_line]
    movzx   rcx, word [rbx + PREP_lexer]
    movzx   rcx, word [rcx + LEXER_col]
    lea     r8,  [msg_include_too_deep]
    call    error_emit
    mov     rax, EXIT_MACRO_RECURSION // reuse recursion exit code
    jmp     .done

.error_open:
    pop     rax
    mov     rax, EXIT_FILE_NOT_FOUND
    jmp     .done

.error_size:
.error_mmap:
.error_oom:
    pop     rax
    mov     rax, EXIT_ERROR
    jmp     .done

.expected_string:
    mov     rax, EXIT_ERROR
    jmp     .done

.error:
    // rax already set
    jmp     .done

.path_traversal_error:
    mov     rdi, [rbx + PREP_ctx]
    mov     rsi, [rbx + PREP_lexer]
    mov     rsi, [rsi + LEXER_file]
    mov     edx, dword [rbx + PREP_lexer]
    mov     edx, dword [rdx + LEXER_line]
    movzx   rcx, word [rbx + PREP_lexer]
    movzx   rcx, word [rcx + LEXER_col]
    lea     r8,  [msg_path_traversal]
    extern  error_emit
    call    error_emit
    mov     rax, EXIT_FILE_PERM
    jmp     .done

.done:
    add     rsp, TOKEN_SIZE
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

[SECTION .rodata]
dir_inc:    db "inc", 0
dir_def:    db "def", 0
dir_if:     db "if", 0
dir_ifdef:  db "ifdef", 0
dir_ifndef: db "ifndef", 0
dir_else:   db "else", 0
dir_endif:  db "endif", 0
dir_rep:    db "rep", 0
dir_endrep: db "endrep", 0
dir_macro:  db "macro", 0
dir_endm:   db "endmacro", 0
dir_struc:  db "struc", 0
dir_endstruc: db "endstruc", 0
str_dotdot: db "..", 0
msg_path_traversal: db "path traversal detected in %inc: usage of '..' is prohibited", 0
msg_include_too_deep: db "maximum include nesting depth exceeded", 0

// ---- prep_handle_struc ------------------
/*
 prep_handle_struc
 Handles the %struc directive.
 Input    : rdi = pointer to PrepState
 Output   : rax = EXIT_OK or error code
*/
prep_handle_struc:
    push    rbx
    mov     rbx, rdi               // rbx = PrepState

    // 1. Lex the struct name
    call    preprocessor_next_token
    check_err
    
    // 2. Dispatch to parser
    mov     rdi, rbx               // rdi = PrepState
    mov     rsi, rdx               // rsi = Name Token
    extern  parser_parse_struc
    call    parser_parse_struc
    
    pop     rbx
    ret
// ---- prep_handle_def --------------------
/*
 prep_handle_def
 Handles the %def directive.
 Input    : rdi = pointer to PrepState
 Output   : rax = EXIT_OK or error code
*/
prep_handle_def:
    push    rbx
    push    r12
    push    r13
    mov     rbx, rdi               // rbx = PrepState

    // 1. Lex the identifier (the constant name)
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r12, rsp               // r12 = name token
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .expected_ident

    // Save the name pointer
    mov     r13, [r12 + TOKEN_value]

    // 2. Lex the value
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r12, rsp               // r12 = value token
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    // 3. Create a symbol entry
    sub     rsp, SYMBOL_SIZE
    mov     rdi, rsp               // rdi = temp Symbol dest
    
    // zero out the struct
    mov     rcx, 6                 // 48 / 8 = 6
    xor     rax, rax
    mov     r10, rdi               // save rdi
    rep stosq
    mov     rdi, r10               // restore rdi

    mov     byte [rdi + SYMBOL_tag], TAG_SYMBOL
    mov     byte [rdi + SYMBOL_kind], SYM_CONSTANT
    mov     [rdi + SYMBOL_name], r13
    
    // handle value
    cmp     byte [r12 + TOKEN_kind], TOK_NUMBER
    jne     .finish_def            // for now, ignore non-numeric %def

    push    rdi
    mov     rdi, [r12 + TOKEN_value]
    call    str_to_int             // from string.s
    pop     rdi
    mov     [rdi + SYMBOL_value], rdx

.finish_def:
    mov     rdi, [rbx + PREP_ctx]  // rdi = AsmCtx
    mov     rsi, rsp               // rsi = pointer to temp Symbol on stack
    call    symbol_add
    test    rax, rax
    jnz     .error

    xor     rax, rax

.error:
    add     rsp, (TOKEN_SIZE * 2) + SYMBOL_SIZE
    pop     r13
    pop     r12
    pop     rbx
    ret

.expected_ident:
    mov     rax, EXIT_ERROR
    jmp     .error

/**
 * [prep_capture_greedy]
 */
prep_capture_greedy:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi               // rbx = PrepState
    mov     r12, [rbx + PREP_lexer]
    
    // 1. Find the end of the line in the current lexer buffer
    mov     r13, [r12 + LEXER_pos] // start
    mov     r14, r13               // current
.find_eol:
    cmp     r14, [r12 + LEXER_end]
    jge     .found_eol
    movzx   rax, byte [r14]
    cmp     al, 10                 // LF
    je      .found_eol
    inc     r14
    jmp     .find_eol

.found_eol:
    // length = r14 - r13
    mov     rdx, r14
    sub     rdx, r13               // rdx = length
    
    // 2. Allocate and copy
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, rdx
    inc     rsi                    // +1 for null
    call    arena_alloc
    check_err
    mov     r10, rdx               // r10 = dst
    
    mov     rdi, r10
    mov     rsi, r13
    mov     rdx, r14
    sub     rdx, r13               // length
    mov     rcx, rdx
    rep     movsb
    mov     byte [rdi], 0          // null terminate
    
    // 3. Update lexer position (consume the text, but not the newline)
    mov     [r12 + LEXER_pos], r14
    
    // 4. Create string token
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, TOKEN_SIZE
    call    arena_alloc
    mov     byte [rdx + TOKEN_kind], TOK_STRING
    mov     [rdx + TOKEN_value], r10
    
    // 5. Store in macro params
    mov     rax, [rbx + PREP_ctx]
    mov     rax, [rax + ASMCTX_mac_exp]
    mov     rcx, [rax + MACROEXP_params]
    mov     [rcx + r15 * 8], rdx
    
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue

    jmp     prep_handle_if // jump over the junk
    
.loop:
    sub     rsp, TOKEN_SIZE
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, rsp
    call    lexer_next
    
    mov     r10, rsp
    cmp     byte [r10 + TOKEN_kind], TOK_NEWLINE
    je      .done
    cmp     byte [r10 + TOKEN_kind], TOK_EOF
    je      .done
    
    mov     rsi, [r10 + TOKEN_value]
    IF rsi, ne, 0
        mov     rdi, rsi
        call    str_len
        mov     rcx, rax
        mov     rdi, r12
        add     rdi, r13
        rep movsb
        add     r13, rax
        mov     byte [r12 + r13], ' '
        inc     r13
    ENDIF
    add     rsp, TOKEN_SIZE
    jmp     .loop

.done:
    add     rsp, TOKEN_SIZE
    mov     byte [r12 + r13], 0
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, TOKEN_SIZE
    call    arena_alloc
    mov     byte [rdx + TOKEN_kind], TOK_STRING
    mov     [rdx + TOKEN_value], r12
    
    mov     rax, [rbx + PREP_ctx]
    mov     rax, [rax + ASMCTX_mac_exp]
    mov     rcx, [rax + MACROEXP_params]
    mov     [rcx + r15 * 8], rdx
    
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue

// ---- prep_handle_if ---------------------
/*
 prep_handle_if
 Handles the %if directive by evaluating a mathematical expression.
 Input    : rdi = PrepState
 Output   : rax = EXIT_OK or error
*/
prep_handle_if:
    prologue
    push    rbx
    push    r12
    mov     rbx, rdi               // rbx = PrepState

    // 1. If we are already skipping, just increment depth
    cmp     byte [rbx + PREP_skip_depth], 0
    jne     .already_skipping

    // 2. Evaluate expression
    mov     rdi, [rbx + PREP_ctx]
    extern  parser_evaluate_expression
    call    parser_evaluate_expression
    test    rax, rax
    jnz     .done
    
    // 3. Evaluate boolean result
    test    rdx, rdx
    jnz     .condition_true

    // 4. Condition false, begin skipping
    inc     byte [rbx + PREP_skip_depth]
    inc     byte [rbx + PREP_depth]
    xor     rax, rax
    jmp     .done

.condition_true:
    inc     byte [rbx + PREP_depth]
    xor     rax, rax
    jmp     .done

.already_skipping:
    inc     byte [rbx + PREP_skip_depth]
    inc     byte [rbx + PREP_depth]
    xor     rax, rax

.done:
    pop     r12
    pop     rbx
    epilogue

// ---- prep_handle_ifdef ------------------
/*
 prep_handle_ifdef
 Handles the %ifdef directive.
*/
prep_handle_ifdef:
    push    rbx
    push    r12
    mov     rbx, rdi

    // increment total depth
    inc     byte [rbx + PREP_depth]

    // if already skipping, just return
    cmp     byte [rbx + PREP_skip_depth], 0
    jne     .done

    // next token must be an identifier
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r12, rsp
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .expected_ident

    // check if symbol exists
    mov     rdi, [rbx + PREP_ctx]
    mov     rsi, [r12 + TOKEN_value]
    call    symbol_find
    test    rax, rax
    jz      .found

    // not found -> start skipping
    mov     al, [rbx + PREP_depth]
    mov     [rbx + PREP_skip_depth], al

.found:
    xor     rax, rax

.done:
    add     rsp, TOKEN_SIZE
    pop     r12
    pop     rbx
    ret

.error:
.expected_ident:
    mov     rax, EXIT_ERROR
    jmp     .done

// ---- prep_handle_ifndef -----------------
prep_handle_ifndef:
    push    rbx
    push    r12
    mov     rbx, rdi

    inc     byte [rbx + PREP_depth]
    cmp     byte [rbx + PREP_skip_depth], 0
    jne     .done

    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r12, rsp
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .expected_ident

    mov     rdi, [rbx + PREP_ctx]
    mov     rsi, [r12 + TOKEN_value]
    call    symbol_find
    test    rax, rax
    jnz     .not_found             // not zero means error -> NOT found

    // found -> start skipping (since it's ifndef)
    mov     al, [rbx + PREP_depth]
    mov     [rbx + PREP_skip_depth], al

.not_found:
    xor     rax, rax

.done:
    add     rsp, TOKEN_SIZE
    pop     r12
    pop     rbx
    ret

.error:
.expected_ident:
    mov     rax, EXIT_ERROR
    jmp     .done

// ---- prep_handle_else -------------------
prep_handle_else:
    push    rbx
    mov     rbx, rdi

    mov     al, [rbx + PREP_depth]
    test    al, al
    jz      .error                 // %else without %if

    // 1. If we are currently skipping at THIS depth, we stop skipping.
    cmp     al, [rbx + PREP_skip_depth]
    je      .stop_skipping

    // 2. If we are NOT skipping at any depth, we START skipping (because the %if was taken)
    cmp     byte [rbx + PREP_skip_depth], 0
    jne     .done                  // we are skipping at a higher level, do nothing

    mov     [rbx + PREP_skip_depth], al
    jmp     .done

.stop_skipping:
    mov     byte [rbx + PREP_skip_depth], 0

.done:
    xor     rax, rax
    pop     rbx
    ret

.error:
    mov     rax, EXIT_ERROR
    pop     rbx
    ret

// ---- prep_handle_endif ------------------
prep_handle_endif:
    push    rbx
    mov     rbx, rdi

    mov     al, [rbx + PREP_depth]
    test    al, al
    jz      .error_no_if           // %endif without %if

    // check if we were skipping at this depth
    cmp     al, [rbx + PREP_skip_depth]
    jne     .not_our_skip

    // we were skipping and now we reached the matching %endif
    mov     byte [rbx + PREP_skip_depth], 0
// ---- macro_handle_def -------------------
/*
 macro_handle_def
 Handles the %macro directive.
 Input    : rdi = pointer to PrepState
 Output   : rax = EXIT_OK or error code
*/
macro_handle_def:
    push    rbx
    push    r12
    push    r13
    push    r14
    mov     rbx, rdi               // rbx = PrepState

    // 1. Lex the macro name
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r12, rsp               // r12 = name token
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error

    cmp     byte [r12 + TOKEN_kind], TOK_IDENT
    jne     .error_expected_ident

    // 2. Lex the parameter count
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     r13, rsp               // r13 = param count token
    mov     rsi, r13
    call    lexer_next
    test    rax, rax
    jnz     .error

    // Param count can be N, N-M, or N-*
    xor     r14, r14               // min_params
    mov     r15, r14               // max_params
    
    cmp     byte [r13 + TOKEN_kind], TOK_NUMBER
    jne     .body_start            // No params specified
    
    // Parse minimum
    mov     rdi, [r13 + TOKEN_value]
    call    str_to_int
    mov     r14, rax
    mov     r15, rax               // Default max = min
    
    // Peek for hyphen '-'
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     rsi, rsp
    call    lexer_peek
    IF byte [rsp + TOKEN_kind], e, TOK_MINUS
        // Consume hyphen
        mov     rdi, [rbx + PREP_lexer]
        mov     rsi, rsp
        call    lexer_next
        
        // Lex next for max
        mov     rdi, [rbx + PREP_lexer]
        mov     rsi, rsp
        call    lexer_next
        
        IF byte [rsp + TOKEN_kind], e, TOK_NUMBER
            mov     rdi, [rsp + TOKEN_value]
            call    str_to_int
            mov     r15, rax
        ELSEIF byte [rsp + TOKEN_kind], e, TOK_ASTERISK
            mov     r15, 0xFF      // Variadic
        ENDIF
    ENDIF
    ENDIF
    add     rsp, TOKEN_SIZE

    // VALIDATION: Enforce max 32 parameters
    IF r14, g, 32
        mov     rax, EXIT_MACRO_DEF
        jmp     .error
    ENDIF
    IF r15, ne, 0xFF
        IF r15, g, 32
            mov     rax, EXIT_MACRO_DEF
            jmp     .error
        ENDIF
    ENDIF

.body_start:
    // 3. Allocate MACRO struct in arena
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, MACRO_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error
    mov     r15, rdx               // r15 = pointer to MACRO struct

    mov     byte [r15 + MACRO_tag], TAG_MACRO
    mov     rax, [r12 + TOKEN_value]
    mov     [r15 + MACRO_name], rax
    mov     [r15 + MACRO_min_params], r14b
    mov     [r15 + MACRO_max_params], r15b

    // 4. Capture tokens until %endmacro
    mov     rdi, [rbx + PREP_arena]
    mov     rax, [rdi + ARENA_ptr]
    mov     [r15 + MACRO_tokens], rax
    xor     r14, r14               // token count

.capture_loop:
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, TOKEN_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error
    mov     r13, rdx               // r13 = next token slot

    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r13
    call    lexer_next
    test    rax, rax
    jnz     .error

    // Check for % directive
    cmp     byte [r13 + TOKEN_kind], TOK_PERCENT
    jne     .not_endmacro

    // Peek next to see if it's endmacro
    // Actually, we can just lex it and check.
    // If it's not endmacro, we just store it as part of the macro.
    // But wait, %directives are special.
    
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     rsi, rsp
    call    lexer_next             // get the identifier after %
    
    mov     rdi, [rsp + TOKEN_value]
    lea     rsi, [dir_endm]        // "endmacro"
    call    str_cmp
    test    rax, rax
    jz      .found_endmacro

    // Not endmacro. We need to "unlex" or just handle this.
    // Simpler: macros cannot contain other %directives for now?
    // NASM allows it. But for bootstrap, let's keep it simple.
    // If we want to support it, we'd need to store both tokens.
    
    add     rsp, TOKEN_SIZE
    inc     r14
    jmp     .capture_loop

.not_endmacro:
    cmp     byte [r13 + TOKEN_kind], TOK_EOF
    je      .error_eof
    inc     r14
    jmp     .capture_loop

.found_endmacro:
    add     rsp, TOKEN_SIZE        // clean up temp token
    mov     [r15 + MACRO_ntokens], r14d

    // 5. Register in symbol table
    sub     rsp, SYMBOL_SIZE
    mov     rdi, rsp
    mov     byte [rdi + SYMBOL_tag], TAG_SYMBOL
    mov     byte [rdi + SYMBOL_kind], SYM_MACRO
    mov     rax, [r15 + MACRO_name]
    mov     [rdi + SYMBOL_name], rax
    mov     [rdi + SYMBOL_value], r15

    mov     rdi, [rbx + PREP_ctx]
    mov     rsi, rsp
    call    symbol_add
    add     rsp, SYMBOL_SIZE
    
    xor     rax, rax
    jmp     .done

.error:
    add     rsp, TOKEN_SIZE * 2
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

/**
 * [prep_handle_rep]
 * Input: RDI = PrepState
 */
prep_handle_rep:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    mov     rbx, rdi

    // 1. Get repeat count
    mov     rdi, [rbx + PREP_lexer]
    sub     rsp, TOKEN_SIZE
    mov     rsi, rsp
    call    lexer_next
    IF byte [rsp + TOKEN_kind], ne, TOK_NUMBER
        mov rax, EXIT_ERROR | jmp .error
    ENDIF
    mov     rdi, [rsp + TOKEN_value]
    call    str_to_int
    mov     r14, rax               // r14 = count
    add     rsp, TOKEN_SIZE

    IF r14, g, MAX_REP_COUNT
        mov rax, EXIT_ERROR | jmp .error
    ENDIF

    // 2. Allocate anonymous MACRO struct
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, MACRO_SIZE
    call    arena_alloc
    check_err
    mov     r15, rdx
    mov     byte [r15 + MACRO_tag], TAG_MACRO
    mov     qword [r15 + MACRO_name], 0
    mov     byte [r15 + MACRO_min_params], 0
    mov     byte [r15 + MACRO_max_params], 0

    // 3. Capture tokens until %endrep
    mov     rdi, [rbx + PREP_arena]
    mov     rax, [rdi + ARENA_ptr]
    mov     [r15 + MACRO_tokens], rax
    xor     r13, r13               // token count

.capture:
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, TOKEN_SIZE
    call    arena_alloc
    check_err
    mov     r12, rdx
    
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r12
    call    lexer_next
    check_err

    // Check for %endrep
    IF byte [r12 + TOKEN_kind], e, TOK_PERCENT
        sub     rsp, TOKEN_SIZE
        mov     rdi, [rbx + PREP_lexer]
        mov     rsi, rsp
        call    lexer_next
        check_err
        
        mov     rdi, [rsp + TOKEN_value]
        lea     rsi, [dir_endrep]
        call    str_cmp
        IF rax, e, 0
            add rsp, TOKEN_SIZE
            jmp .captured
        ENDIF
        add rsp, TOKEN_SIZE
        // If not %endrep, we keep the percent token and continue
    ENDIF

    inc     r13
    jmp     .capture

.captured:
    mov     [r15 + MACRO_ntokens], r13d
    
    // 4. Start expansion
    mov     rdi, rbx
    mov     rsi, r15
    call    prep_expand_start
    mov     [rdx + MACROEXP_rep_count], r14 // set the actual count
    
    xor     rax, rax
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.error:
    jmp .done

.error_expected_ident:
.error_eof:
    mov     rax, EXIT_ERROR
    jmp     .error

.not_our_skip:
    dec     byte [rbx + PREP_depth]
    xor     rax, rax
    jmp     .done

.error_no_if:
    mov     rax, EXIT_ERROR

.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret
