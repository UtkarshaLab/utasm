/*
 ============================================
 File     : src/core/error.s
 Project  : utasm
 Version  : 0.1.0
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"

// ============================================================================
// ERROR REPORTER
// ============================================================================
// Handles all diagnostic output for utasm.
// Prints errors, warnings, and info messages to stderr.
//
// Output format:
//   file.s:line:col: error: message
//   file.s:line:col: warning: message
//   file.s:line:col: note: message
//
// Color output (when CTX_FLAG_COLOR is set):
//   error   → bold red
//   warning → bold yellow
//   note    → bold cyan
//   info    → bold white
//
// All errors increment AsmCtx.err_count.
// All warnings increment AsmCtx.warn_count.
// When err_count >= MAX_ERRORS, utasm stops immediately.
// When CTX_FLAG_WERROR is set, warnings are treated as errors.
//
// Calling convention (AMD64):
//   args  : rdi, rsi, rdx, rcx, r8, r9
//   return: rax = error code, rdx = result
//   callee saved: rbx, r12-r15, rbp

[SECTION .text]

// ---- error_init -------------------------
/*
 error_init
 Initialises the error reporter against an AsmCtx.
 Must be called before any other error function.
 Input    : rdi = pointer to AsmCtx
 Output   : rax = EXIT_OK or EXIT_INTERNAL
 Clobbers : rcx
*/
global error_init
error_init:
    test    rdi, rdi
    jz      .null_ptr

    // validate AsmCtx tag
    cmp     byte [rdi + ASMCTX_tag], TAG_ASM_CTX
    jne     .bad_ctx

    // zero error and warning counters
    mov     word [rdi + ASMCTX_err_count],  0
    mov     word [rdi + ASMCTX_warn_count], 0

    xor     rax, rax
    ret

.null_ptr:
.bad_ctx:
    mov     rax, EXIT_INTERNAL
    ret

// ---- error_emit -------------------------
/*
 error_emit
 Emits a formatted error message to stderr.
 Increments AsmCtx.err_count.
 If err_count >= MAX_ERRORS, calls error_fatal.
 If CTX_FLAG_WERROR is set, warnings become errors — but
 this function always treats its input as a hard error.
 Input    : rdi = pointer to AsmCtx
            rsi = pointer to filename string (or NULL)
            rdx = line number (0 if unknown)
            rcx = column number (0 if unknown)
            r8  = pointer to message string
 Output   : rax = EXIT_OK or EXIT_INTERNAL
 Clobbers : r9, r10, r11
*/
global error_emit
error_emit:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi               // save AsmCtx
    mov     r12, rsi               // save filename
    mov     r13, rdx               // save line
    mov     r14, rcx               // save column
    mov     r15, r8                // save message

    // validate ctx
    test    rbx, rbx
    jz      .bad_ctx
    cmp     byte [rbx + ASMCTX_tag], TAG_ASM_CTX
    jne     .bad_ctx

    // increment error count
    movzx   rax, word [rbx + ASMCTX_err_count]
    inc     rax
    mov     word [rbx + ASMCTX_err_count], ax

    // check color flag
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .no_color_error

    // write bold red for error
    mov     rdi, STDERR_FILENO
    lea     rsi, [color_bold_red]
    mov     rdx, color_bold_red_len
    call    error_write_raw

.no_color_error:
    // print: filename:line:col: error: message
    call    .print_location
    call    .print_severity_error
    call    .print_message

    // reset color
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .check_limit

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_reset]
    mov     rdx, color_reset_len
    call    error_write_raw

.check_limit:
    // check if we hit MAX_ERRORS
    movzx   rax, word [rbx + ASMCTX_err_count]
    cmp     rax, MAX_ERRORS
    jl      .done

    // too many errors — fatal
    mov     rdi, rbx
    lea     rsi, [msg_too_many_errors]
    call    error_fatal

.done:
    xor     rax, rax
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.bad_ctx:
    mov     rax, EXIT_INTERNAL
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- error_warn -------------------------
/*
 error_warn
 Emits a formatted warning message to stderr.
 Increments AsmCtx.warn_count.
 If CTX_FLAG_WERROR is set, calls error_emit instead.
 Input    : rdi = pointer to AsmCtx
            rsi = pointer to filename string (or NULL)
            rdx = line number (0 if unknown)
            rcx = column number (0 if unknown)
            r8  = pointer to message string
 Output   : rax = EXIT_OK or EXIT_INTERNAL
 Clobbers : r9, r10, r11
*/
global error_warn
error_warn:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi
    mov     r12, rsi
    mov     r13, rdx
    mov     r14, rcx
    mov     r15, r8

    test    rbx, rbx
    jz      .bad_ctx
    cmp     byte [rbx + ASMCTX_tag], TAG_ASM_CTX
    jne     .bad_ctx

    // if WERROR flag set — treat as error
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_WERROR
    jz      .emit_warn

    // redirect to error_emit
    mov     rdi, rbx
    mov     rsi, r12
    mov     rdx, r13
    mov     rcx, r14
    mov     r8,  r15
    call    error_emit
    jmp     .done

.emit_warn:
    // increment warning count
    movzx   rax, word [rbx + ASMCTX_warn_count]
    inc     rax
    mov     word [rbx + ASMCTX_warn_count], ax

    // color — bold yellow
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .no_color_warn

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_bold_yellow]
    mov     rdx, color_bold_yellow_len
    call    error_write_raw

.no_color_warn:
    call    .print_location
    call    .print_severity_warn
    call    .print_message

    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .done

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_reset]
    mov     rdx, color_reset_len
    call    error_write_raw

.done:
    xor     rax, rax
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.bad_ctx:
    mov     rax, EXIT_INTERNAL
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- error_note -------------------------
/*
 error_note
 Emits a note (supplementary information) to stderr.
 Does not increment any counter.
 Input    : rdi = pointer to AsmCtx
            rsi = pointer to filename string (or NULL)
            rdx = line number (0 if unknown)
            rcx = column number (0 if unknown)
            r8  = pointer to message string
 Output   : rax = EXIT_OK or EXIT_INTERNAL
 Clobbers : r9, r10, r11
*/
global error_note
error_note:
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi
    mov     r12, rsi
    mov     r13, rdx
    mov     r14, rcx
    mov     r15, r8

    test    rbx, rbx
    jz      .bad_ctx
    cmp     byte [rbx + ASMCTX_tag], TAG_ASM_CTX
    jne     .bad_ctx

    // color — bold cyan
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .no_color_note

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_bold_cyan]
    mov     rdx, color_bold_cyan_len
    call    error_write_raw

.no_color_note:
    call    .print_location
    call    .print_severity_note
    call    .print_message

    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .done

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_reset]
    mov     rdx, color_reset_len
    call    error_write_raw

.done:
    xor     rax, rax
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

.bad_ctx:
    mov     rax, EXIT_INTERNAL
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    ret

// ---- error_info -------------------------
/*
 error_info
 Emits a plain informational message to stderr.
 Used for verbose/debug output — not a diagnostic.
 Only emits if CTX_FLAG_VERBOSE is set.
 Input    : rdi = pointer to AsmCtx
            rsi = pointer to message string
 Output   : rax = EXIT_OK or EXIT_INTERNAL
 Clobbers : rcx, rdx, r8, r9
*/
global error_info
error_info:
    test    rdi, rdi
    jz      .bad_ctx
    cmp     byte [rdi + ASMCTX_tag], TAG_ASM_CTX
    jne     .bad_ctx

    // only emit if verbose flag set
    mov     rax, [rdi + ASMCTX_flags]
    test    rax, CTX_FLAG_VERBOSE
    jz      .done

    push    rbx
    push    r12
    mov     rbx, rdi
    mov     r12, rsi

    // color — bold white
    test    rax, CTX_FLAG_COLOR
    jz      .no_color_info

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_bold_white]
    mov     rdx, color_bold_white_len
    call    error_write_raw

.no_color_info:
    // print: "utasm: info: message\n"
    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_prefix_info]
    mov     rdx, msg_prefix_info_len
    call    error_write_raw

    mov     rdi, STDERR_FILENO
    mov     rsi, r12
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_newline]
    mov     rdx, 1
    call    error_write_raw

    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .no_reset_info

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_reset]
    mov     rdx, color_reset_len
    call    error_write_raw

.no_reset_info:
    pop     r12
    pop     rbx

.done:
    xor     rax, rax
    ret

.bad_ctx:
    mov     rax, EXIT_INTERNAL
    ret

// ---- error_fatal ------------------------
/*
 error_fatal
 Emits a fatal error message and exits immediately.
 Does not return.
 Input    : rdi = pointer to AsmCtx (or NULL)
            rsi = pointer to message string
 Output   : does not return
 Clobbers : all
*/
global error_fatal
error_fatal:
    push    r12
    push    r13
    mov     r12, rdi               // save ctx (may be NULL)
    mov     r13, rsi               // save message

    // color if ctx available and color enabled
    test    r12, r12
    jz      .no_color_fatal
    cmp     byte [r12 + ASMCTX_tag], TAG_ASM_CTX
    jne     .no_color_fatal
    mov     rax, [r12 + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .no_color_fatal

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_bold_red]
    mov     rdx, color_bold_red_len
    call    error_write_raw

.no_color_fatal:
    // print: "utasm: fatal: message\n"
    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_prefix_fatal]
    mov     rdx, msg_prefix_fatal_len
    call    error_write_raw

    mov     rdi, STDERR_FILENO
    mov     rsi, r13
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_newline]
    mov     rdx, 1
    call    error_write_raw

    // reset color
    test    r12, r12
    jz      .exit_now
    cmp     byte [r12 + ASMCTX_tag], TAG_ASM_CTX
    jne     .exit_now
    mov     rax, [r12 + ASMCTX_flags]
    test    rax, CTX_FLAG_COLOR
    jz      .exit_now

    mov     rdi, STDERR_FILENO
    lea     rsi, [color_reset]
    mov     rdx, color_reset_len
    call    error_write_raw

.exit_now:
    mov     rax, AMD64_SYS_EXIT
    mov     rdi, EXIT_INTERNAL
    syscall
    // never reached

// ---- error_summary ----------------------
/*
 error_summary
 Prints a final summary line after assembly completes.
 Example: "2 errors, 1 warning generated."
 Input    : rdi = pointer to AsmCtx
 Output   : rax = EXIT_OK or EXIT_INTERNAL
 Clobbers : rcx, rdx, r8, r9, r10, r11
*/
global error_summary
error_summary:
    test    rdi, rdi
    jz      .bad_ctx
    cmp     byte [rdi + ASMCTX_tag], TAG_ASM_CTX
    jne     .bad_ctx

    push    rbx
    mov     rbx, rdi

    movzx   rax, word [rbx + ASMCTX_err_count]
    movzx   rcx, word [rbx + ASMCTX_warn_count]

    // only print if there were errors or warnings
    test    rax, rax
    jnz     .print_summary
    test    rcx, rcx
    jz      .done

.print_summary:
    // print error count
    movzx   rdi, word [rbx + ASMCTX_err_count]
    call    error_uint_to_str
    mov     rdi, STDERR_FILENO
    mov     rsi, rdx
    call    error_write_str

    lea     rsi, [msg_summary_errors_label]
    mov     rdx, msg_summary_errors_label_len
    mov     rdi, STDERR_FILENO
    call    error_write_raw

    // print warning count
    movzx   rdi, word [rbx + ASMCTX_warn_count]
    call    error_uint_to_str
    mov     rdi, STDERR_FILENO
    mov     rsi, rdx
    call    error_write_str

    lea     rsi, [msg_summary_warnings_label]
    mov     rdx, msg_summary_warnings_label_len
    mov     rdi, STDERR_FILENO
    call    error_write_raw

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_newline]
    mov     rdx, 1
    call    error_write_raw

.done:
    xor     rax, rax
    pop     rbx
    ret

.bad_ctx:
    mov     rax, EXIT_INTERNAL
    ret

// ============================================================================
// INTERNAL HELPERS
// ============================================================================

// ---- .print_location --------------------
/*
 .print_location (internal)
 Prints "filename:line:col: " to stderr.
 Uses rbx=AsmCtx, r12=filename, r13=line, r14=col.
*/
.print_location:
    // print filename if available
    test    r12, r12
    jz      .no_file

    mov     rdi, STDERR_FILENO
    mov     rsi, r12
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_colon]
    mov     rdx, 1
    call    error_write_raw

.no_file:
    // print line number if non-zero
    test    r13, r13
    jz      .no_line

    mov     rdi, r13
    call    error_uint_to_str
    mov     rdi, STDERR_FILENO
    mov     rsi, rdx
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_colon]
    mov     rdx, 1
    call    error_write_raw

.no_line:
    // print column if non-zero
    test    r14, r14
    jz      .no_col

    mov     rdi, r14
    call    error_uint_to_str
    mov     rdi, STDERR_FILENO
    mov     rsi, rdx
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_colon_space]
    mov     rdx, 2
    call    error_write_raw

.no_col:
    ret

// ---- .print_severity_error --------------
.print_severity_error:
    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_error]
    mov     rdx, msg_error_len
    call    error_write_raw
    ret

// ---- .print_severity_warn ---------------
.print_severity_warn:
    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_warning]
    mov     rdx, msg_warning_len
    call    error_write_raw
    ret

// ---- .print_severity_note ---------------
.print_severity_note:
    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_note]
    mov     rdx, msg_note_len
    call    error_write_raw
    ret

// ---- .print_message ---------------------
.print_message:
    mov     rdi, STDERR_FILENO
    mov     rsi, r15
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_newline]
    mov     rdx, 1
    call    error_write_raw
    ret

// ---- error_write_raw --------------------
/*
 error_write_raw
 Writes exactly rdx bytes from rsi to file descriptor rdi.
 Input    : rdi = file descriptor
            rsi = pointer to buffer
            rdx = byte count
 Output   : rax = EXIT_OK or EXIT_FILE_WRITE
 Clobbers : rax, r11
*/
error_write_raw:
    mov     rax, AMD64_SYS_WRITE
    syscall
    test    rax, rax
    js      .write_fail
    xor     rax, rax
    ret
.write_fail:
    mov     rax, EXIT_FILE_WRITE
    ret

// ---- error_write_str --------------------
/*
 error_write_str
 Writes a null-terminated string to file descriptor rdi.
 Input    : rdi = file descriptor
            rsi = pointer to null-terminated string
 Output   : rax = EXIT_OK or EXIT_FILE_WRITE
 Clobbers : rax, rdx, rcx, r11
*/
error_write_str:
    push    rdi
    push    rsi
    mov     rdi, rsi
    call    str_len
    mov     rdx, rax               // length
    pop     rsi
    pop     rdi
    mov     rax, AMD64_SYS_WRITE
    syscall
    test    rax, rax
    js      .fail
    xor     rax, rax
    ret
.fail:
    mov     rax, EXIT_FILE_WRITE
    ret

// ---- error_uint_to_str ------------------
/*
 error_uint_to_str
 Converts an unsigned integer to a decimal string.
 Uses an internal static buffer — not reentrant.
 Input    : rdi = unsigned integer value
 Output   : rax = EXIT_OK
             rdx = pointer to null-terminated decimal string
 Clobbers : rcx, r8, r9, r10
*/
error_uint_to_str:
    lea     r8, [uint_buf + 20]     // build from end
    mov     byte [r8], 0            // null terminator
    mov     rax, rdi                // value to convert
    mov     rcx, 10                 // base 10

    test    rax, rax
    jnz     .loop

    dec     r8
    mov     byte [r8], '0'
    jmp     .done

.loop:
    test    rax, rax
    jz      .done
    xor     rdx, rdx
    div     rcx                     // rax = quot, rdx = rem
    add     dl, '0'                 // convert rem to char
    dec     r8
    mov     byte [r8], dl           // store char
    jmp     .loop

.done:
    xor     rax, rax                // EXIT_OK
    mov     rdx, r8                 // pointer to string
    ret

// ============================================================================
// DATA
// ============================================================================

[SECTION .data]

// ---- ANSI color codes --------------------

color_bold_red:
    db      0x1B, "[1;31m"
color_bold_red_len equ $ - color_bold_red

color_bold_yellow:
    db      0x1B, "[1;33m"
color_bold_yellow_len equ $ - color_bold_yellow

color_bold_cyan:
    db      0x1B, "[1;36m"
color_bold_cyan_len equ $ - color_bold_cyan

color_bold_white:
    db      0x1B, "[1;37m"
color_bold_white_len equ $ - color_bold_white

color_reset:
    db      0x1B, "[0m"
color_reset_len equ $ - color_reset

// ---- severity labels ---------------------

msg_error:
    db      "error: "
msg_error_len equ $ - msg_error

msg_warning:
    db      "warning: "
msg_warning_len equ $ - msg_warning

msg_note:
    db      "note: "
msg_note_len equ $ - msg_note

// ---- prefixes ----------------------------

msg_prefix_info:
    db      "utasm: info: "
msg_prefix_info_len equ $ - msg_prefix_info

msg_prefix_fatal:
    db      "utasm: fatal: "
msg_prefix_fatal_len equ $ - msg_prefix_fatal

// ---- summary -----------------------------

msg_summary_errors_label:
    db      " error(s) and ", 0
msg_summary_errors_label_len equ $ - msg_summary_errors_label - 1

msg_summary_warnings_label:
    db      " warning(s) generated.", 0
msg_summary_warnings_label_len equ $ - msg_summary_warnings_label - 1

// ---- misc --------------------------------

msg_too_many_errors:
    db      "too many errors — stopping.", 0

msg_system_error:
    db      "system error (errno ", 0

msg_system_error_suffix:
    db      ")", 0

msg_colon:
    db      ":"

msg_colon_space:
    db      ": "

msg_newline:
    db      10

// ---- error_new_from_errno ----------------
/*
 error_new_from_errno
 Translates a system errno into a diagnostic message.
 Input    : rdi = errno (i64)
 Output   : rax = EXIT_OK
 Clobbers : r8, r9, r10
*/
global error_new_from_errno
error_new_from_errno:
    // for now, just print "system error (errno X)"
    // we don't have a full strerror yet
    push    rdi
    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_system_error]
    mov     rdx, 21
    call    error_write_raw

    pop     rdi
    call    error_uint_to_str
    mov     rdi, STDERR_FILENO
    mov     rsi, rdx
    call    error_write_str

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_system_error_suffix]
    mov     rdx, 1
    call    error_write_raw

    mov     rdi, STDERR_FILENO
    lea     rsi, [msg_newline]
    mov     rdx, 1
    call    error_write_raw

    xor     rax, rax
    ret

// ---- integer conversion buffer -----------

[SECTION .bss]

uint_buf:   resb 21                // max 20 digits for uint64 + null
