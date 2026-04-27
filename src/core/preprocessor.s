/*
 ============================================
 File     : src/core/preprocessor.s
 Project  : utasm
 Version  : 0.1.0
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
    call    lexer_next
    test    rax, rax
    jnz     .done                  // lexer error

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

    // pop include context
    mov     r10, [r9 + INCLUDECTX_lexer]
    mov     [rbx + PREP_lexer], r10    // restore previous lexer
    
    mov     r11, [r9 + INCLUDECTX_parent]
    mov     [r8 + ASMCTX_inc_ctx], r11 // restore parent in AsmCtx

    // get next token from restored lexer
    jmp     .next

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

    // ... handle other directives ...

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

    // 1. Open the file
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

    // 5. Save old lexer state in IncludeCtx
    mov     r12, [rbx + PREP_ctx]
    mov     rdi, [rbx + PREP_arena]
    mov     rsi, INCLUDECTX_SIZE
    call    arena_alloc
    test    rax, rax
    jnz     .error_oom
    mov     r9, rdx                // r9 = new IncludeCtx

    mov     byte [r9 + INCLUDECTX_tag], TAG_INCLUDE_CTX
    mov     r10, [r12 + ASMCTX_inc_ctx]
    mov     [r9 + INCLUDECTX_parent], r10 // link to previous
    mov     [r12 + ASMCTX_inc_ctx], r9    // update current in AsmCtx
    
    // Save current lexer in the context so we can restore it
    mov     r11, [rbx + PREP_lexer]
    mov     [r9 + INCLUDECTX_lexer], r11
    
    mov     [rbx + PREP_lexer], r8 // Switch to new lexer

    // 6. Close the fd (mmap keeps it open if needed, but we don't need it)
    mov     rdi, r13
    call    io_close

    xor     rax, rax
    jmp     .done

.error_open:
    // ... emit error ...
    mov     rax, EXIT_FILE_NOT_FOUND
    jmp     .done

.error_size:
.error_mmap:
.error_oom:
    mov     rax, EXIT_ERROR
    jmp     .done

.expected_string:
    mov     rax, EXIT_ERROR
    jmp     .done

.error:
    // rax already set
    jmp     .done

.done:
    add     rsp, TOKEN_SIZE
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
    // ... logic for parsing param count ...
    
    // For now, let's just implement a stub that skips until %endmacro
    // to keep the preprocessor running.

.skip_loop:
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r12
    call    lexer_next
    test    rax, rax
    jnz     .error
    
    cmp     byte [r12 + TOKEN_kind], TOK_EOF
    je      .error_eof
    
    cmp     byte [r12 + TOKEN_kind], TOK_PERCENT
    jne     .skip_loop
    
    // check if it is endmacro
    mov     rdi, [rbx + PREP_lexer]
    mov     rsi, r12
    call    lexer_next
    // ... comparison logic ...
    
    xor     rax, rax

.error:
    add     rsp, TOKEN_SIZE * 2
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

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
    pop     rbx
    ret
