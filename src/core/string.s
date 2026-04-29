;
; ============================================
; File     : src/core/string.s
; Project  : utasm
; Author   : Utkarsha Lab
; License  : Apache-2.0
; ============================================
;

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

; ============================================================================
; STRING UTILITIES
; ============================================================================
; Core string and memory operations used by every utasm module.
; The lexer, parser, preprocessor, symbol table, and error reporter
; all depend on these routines.
;
; Calling convention (AMD64):
;   args  : rdi, rsi, rdx, rcx, r8, r9
;   return: rax = error code, rdx = result
;   callee saved: rbx, r12-r15, rbp
;
; All functions that can fail return:
;   rax = EXIT_OK or error code
;   rdx = result value (only valid if rax == EXIT_OK)
;
; Functions that cannot fail (pure computation):
;   rax = result directly (no error code)

[SECTION .text]
    cld                             ; ensure direction flag is always forward

; ---- str_len ----------------------------
;
; str_len
; Returns the length of a null-terminated string.
; Does not count the null terminator.
; Cannot fail â€” returns length directly in rax.
; Input    : rdi = pointer to null-terminated string
; Output   : rax = length in bytes
; Clobbers : rcx
;
global str_len
str_len:
    ; guard against NULL pointer
    test    rdi, rdi
    jz      .null_ptr

    xor     rax, rax               ; length counter = 0

.loop:
    cmp     byte [rdi + rax], 0    ; check current byte
    je      .done                  ; found null terminator
    inc     rax                    ; advance counter
    jmp     .loop

.done:
    ret

.null_ptr:
    xor     rax, rax               ; NULL = length 0
    ret

; ---- str_cmp ----------------------------
;
; str_cmp
; Compares two null-terminated strings lexicographically.
; Input    : rdi = pointer to string A
            rsi = pointer to string B
; Output   : rax = 0  if A == B
             rax = -1 if A <  B
             rax =  1 if A >  B
; Clobbers : rcx, rdx
;
global str_cmp
str_cmp:
    ; guard against NULL
    test    rdi, rdi
    jz      .a_null
    test    rsi, rsi
    jz      .b_null

.loop:
    mov     cl, byte [rdi]         ; cl = byte from A
    mov     dl, byte [rsi]         ; dl = byte from B
    cmp     cl, dl
    jl      .a_less
    jg      .a_greater
    test    cl, cl                 ; both equal â€” check null
    jz      .equal                 ; both null = strings equal
    inc     rdi
    inc     rsi
    jmp     .loop

.equal:
    xor     rax, rax               ; rax = 0
    ret

.a_less:
    mov     rax, -1
    ret

.a_greater:
    mov     rax, 1
    ret

.a_null:
    test    rsi, rsi
    jz      .equal                 ; both NULL = equal
    mov     rax, -1                ; A=NULL < B
    ret

.b_null:
    mov     rax, 1                 ; A > B=NULL
    ret

; ---- str_cmp_n --------------------------
;
; str_cmp_n
; Compares at most n bytes of two strings.
; Input    : rdi = pointer to string A
            rsi = pointer to string B
            rdx = maximum bytes to compare
; Output   : rax = 0 equal, -1 A < B, 1 A > B
; Clobbers : rcx, r8
;
global str_cmp_n
str_cmp_n:
    test    rdx, rdx               ; n = 0 means equal
    jz      .equal
    test    rdi, rdi
    jz      .a_null
    test    rsi, rsi
    jz      .b_null

    xor     rcx, rcx               ; counter = 0

.loop:
    cmp     rcx, rdx               ; reached limit?
    jge     .equal
    mov     al, byte [rdi + rcx]
    mov     r8b, byte [rsi + rcx]
    cmp     al, r8b
    jl      .a_less
    jg      .a_greater
    test    al, al                 ; null terminator?
    jz      .equal
    inc     rcx
    jmp     .loop

.equal:
    xor     rax, rax
    ret

.a_less:
    mov     rax, -1
    ret

.a_greater:
    mov     rax, 1
    ret

.a_null:
    test    rsi, rsi
    jz      .equal
    mov     rax, -1
    ret

.b_null:
    mov     rax, 1
    ret

; ---- str_copy ---------------------------
;
; str_copy
; Copies null-terminated string from src to dst.
; Destination must be large enough â€” no bounds check.
; Input    : rdi = destination buffer pointer
            rsi = source string pointer
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = pointer to destination (same as rdi)
; Clobbers : rcx, r8
;
global str_copy
str_copy:
    test    rdi, rdi
    jz      .null_ptr
    test    rsi, rsi
    jz      .null_ptr

    mov     rdx, rdi               ; save dst for return

.loop:
    mov     cl, byte [rsi]         ; read source byte
    mov     byte [rdi], cl         ; write to destination
    test    cl, cl                 ; null terminator?
    jz      .done
    inc     rdi
    inc     rsi
    jmp     .loop

.done:
    xor     rax, rax               ; rax = EXIT_OK
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- str_copy_n -------------------------
;
; str_copy_n
; Copies at most n bytes from src to dst.
; Always null-terminates dst if n > 0.
; Input    : rdi = destination buffer pointer
            rsi = source string pointer
            rdx = maximum bytes to copy (not including null)
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = pointer to destination
; Clobbers : rcx, r8, r9
;
global str_copy_n
str_copy_n:
    test    rdi, rdi
    jz      .null_ptr
    test    rsi, rsi
    jz      .null_ptr
    test    rdx, rdx
    jz      .zero_n

    push    rbx
    mov     rbx, rdi               ; save dst
    mov     rcx, rdx               ; counter = n

.loop:
    test    rcx, rcx
    jz      .terminate
    mov     r8b, byte [rsi]
    mov     byte [rdi], r8b
    test    r8b, r8b
    jz      .done
    inc     rdi
    inc     rsi
    dec     rcx
    jmp     .loop

.terminate:
    mov     byte [rdi], 0          ; always null terminate

.done:
    xor     rax, rax
    mov     rdx, rbx               ; rdx = original dst
    pop     rbx
    ret

.zero_n:
    mov     byte [rdi], 0          ; null terminate empty
    xor     rax, rax
    mov     rdx, rdi
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- str_concat -------------------------
;
; str_concat
; Appends src to the end of dst.
; Destination must have enough space.
; Input    : rdi = destination buffer pointer
            rsi = source string pointer
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = pointer to destination
; Clobbers : rcx, r8
;
global str_concat
str_concat:
    test    rdi, rdi
    jz      .null_ptr
    test    rsi, rsi
    jz      .null_ptr

    push    rbx
    mov     rbx, rdi               ; save original dst

    ; find end of dst
.find_end:
    cmp     byte [rdi], 0
    je      .append
    inc     rdi
    jmp     .find_end

    ; append src
.append:
    mov     cl, byte [rsi]
    mov     byte [rdi], cl
    test    cl, cl
    jz      .done
    inc     rdi
    inc     rsi
    jmp     .append

.done:
    xor     rax, rax
    mov     rdx, rbx
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- mem_copy ---------------------------
;
; mem_copy
; Copies n bytes from src to dst.
; Regions must not overlap â€” use mem_move for overlapping regions.
; Input    : rdi = destination pointer
            rsi = source pointer
            rdx = number of bytes to copy
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = destination pointer
; Clobbers : rcx, r8
;
global mem_copy
mem_copy:
    test    rdi, rdi
    jz      .null_ptr
    test    rsi, rsi
    jz      .null_ptr

    push    rbx
    mov     rbx, rdi               ; save dst
    mov     rcx, rdx               ; count = n
    rep movsb                      ; copy rcx bytes from rsi to rdi

    xor     rax, rax
    mov     rdx, rbx
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- mem_move ---------------------------
;
; mem_move
; Copies n bytes from src to dst safely handling overlapping regions.
; Input    : rdi = destination pointer
            rsi = source pointer
            rdx = number of bytes to copy
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = destination pointer
; Clobbers : rcx, r8
;
global mem_move
mem_move:
    test    rdi, rdi
    jz      .null_ptr
    test    rsi, rsi
    jz      .null_ptr

    push    rbx
    mov     rbx, rdi               ; save dst

    ; if dst < src, copy forward (no overlap issue)
    cmp     rdi, rsi
    jl      .forward
    ; if dst > src, copy backward to avoid clobber
    jg      .backward

    ; dst == src, nothing to do
    jmp     .done

.forward:
    mov     rcx, rdx
    rep movsb
    jmp     .done

.backward:
    ; start from end and copy backwards
    mov     rcx, rdx
    add     rdi, rcx
    add     rsi, rcx
    dec     rdi
    dec     rsi
    std                            ; set direction flag = backward
    rep movsb
    cld                            ; restore direction flag = forward

.done:
    xor     rax, rax
    mov     rdx, rbx
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- mem_set ----------------------------
;
; mem_set
; Fills n bytes at dst with the given byte value.
; Input    : rdi = destination pointer
            rsi = byte value to fill (low byte used)
            rdx = number of bytes to fill
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = destination pointer
; Clobbers : rax, rcx, r8
;
global mem_set
mem_set:
    test    rdi, rdi
    jz      .null_ptr

    push    rbx
    mov     rbx, rdi               ; save dst
    mov     rax, rsi               ; fill value
    mov     rcx, rdx               ; count
    rep stosb                      ; fill rcx bytes at rdi with al

    xor     rax, rax
    mov     rdx, rbx
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- mem_zero ---------------------------
;
; mem_zero
; Fills n bytes at dst with zero.
; Input    : rdi = destination pointer
            rsi = number of bytes to zero
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = destination pointer
; Clobbers : rax, rcx
;
global mem_zero
mem_zero:
    test    rdi, rdi
    jz      .null_ptr

    push    rbx
    mov     rbx, rdi
    xor     rax, rax               ; fill value = 0
    mov     rcx, rsi               ; count
    rep stosb

    xor     rax, rax
    mov     rdx, rbx
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- mem_cmp ----------------------------
;
; mem_cmp
; Compares n bytes of two memory regions.
; Input    : rdi = pointer to region A
            rsi = pointer to region B
            rdx = number of bytes to compare
; Output   : rax = 0 equal, -1 A < B, 1 A > B
; Clobbers : rcx, r8
;
global mem_cmp
mem_cmp:
    test    rdx, rdx
    jz      .equal
    test    rdi, rdi
    jz      .null_a
    test    rsi, rsi
    jz      .null_b

    xor     rcx, rcx

.loop:
    cmp     rcx, rdx
    jge     .equal
    mov     al, byte [rdi + rcx]
    mov     r8b, byte [rsi + rcx]
    cmp     al, r8b
    jl      .a_less
    jg      .a_greater
    inc     rcx
    jmp     .loop

.equal:
    xor     rax, rax
    ret

.a_less:
    mov     rax, -1
    ret

.a_greater:
    mov     rax, 1
    ret

.null_a:
    mov     rax, -1
    ret

.null_b:
    mov     rax, 1
    ret

; ---- str_to_int -------------------------
;
; str_to_int
; Converts a string to a signed 64-bit integer.
; Supports decimal, hex (0x prefix), binary (0b prefix),
; octal (0o prefix), and optional leading sign (+ or -).
; Input    : rdi = pointer to null-terminated string
; Output   : rax = EXIT_OK or EXIT_INVALID_IMM
             rdx = parsed integer value (signed)
; Clobbers : rcx, r8, r9, r10
;
global str_to_int
str_to_int:
    test    rdi, rdi
    jz      .null_ptr

    push    rbx
    push    r12
    push    r13

    xor     rbx, rbx               ; result = 0
    mov     r12, 10                ; default base = 10
    xor     r13, r13               ; sign = positive (0 = pos, 1 = neg)

    ; check for leading sign
    mov     al, byte [rdi]
    cmp     al, '+'
    je      .skip_sign
    cmp     al, '-'
    jne     .check_prefix
    mov     r13, 1                 ; negative
.skip_sign:
    inc     rdi

.check_prefix:
    ; check for 0x, 0b, 0o prefix
    mov     al, byte [rdi]
    cmp     al, '0'
    jne     .check_suffix
    mov     al, byte [rdi + 1]
    cmp     al, 'x'
    je      .set_hex
    cmp     al, 'X'
    je      .set_hex
    cmp     al, 'b'
    je      .set_bin
    cmp     al, 'B'
    je      .set_bin
    cmp     al, 'o'
    je      .set_oct
    cmp     al, 'O'
    je      .set_oct
    jmp     .check_suffix

.set_hex:
    mov     r12, 16
    add     rdi, 2
    jmp     .parse_loop

.set_bin:
    mov     r12, 2
    add     rdi, 2
    jmp     .parse_loop

.set_oct:
    mov     r12, 8
    add     rdi, 2
    jmp     .parse_loop

.check_suffix:
    ; Check for trailing radix markers (h, b, o, d)
    push    rdi
    extern  str_len
    call    str_len
    pop     rdi
    test    rax, rax
    jz      .parse_loop
    
    ; r8 = length, r9 = last char
    mov     r8, rax
    movzx   r9, byte [rdi + r8 - 1]
    
    ; Hex: h, H
    cmp     r9, 'h'
    je      .found_hex_suffix
    cmp     r9, 'H'
    je      .found_hex_suffix
    
    ; Bin: b, B
    cmp     r9, 'b'
    je      .found_bin_suffix
    cmp     r9, 'B'
    je      .found_bin_suffix
    
    ; Oct: o, O, q, Q
    cmp     r9, 'o'
    je      .found_oct_suffix
    cmp     r9, 'O'
    je      .found_oct_suffix
    cmp     r9, 'q'
    je      .found_oct_suffix
    cmp     r9, 'Q'
    je      .found_oct_suffix
    
    ; Dec: d, D
    cmp     r9, 'd'
    je      .found_dec_suffix
    cmp     r9, 'D'
    je      .found_dec_suffix
    
    jmp     .parse_loop

.found_hex_suffix:
    mov     r12, 16
    dec     r8                     ; ignore suffix in loop
    jmp     .parse_loop_limit

.found_bin_suffix:
    mov     r12, 2
    dec     r8
    jmp     .parse_loop_limit

.found_oct_suffix:
    mov     r12, 8
    dec     r8
    jmp     .parse_loop_limit

.found_dec_suffix:
    mov     r12, 10
    dec     r8
    jmp     .parse_loop_limit

.parse_loop:
    ; Use full length if no suffix
    push    rdi
    extern  str_len
    call    str_len
    pop     rdi
    mov     r8, rax

.parse_loop_limit:
    xor     r10, r10               ; i = 0
.loop:
    cmp     r10, r8
    jge     .apply_sign
    
    movzx   rax, byte [rdi + r10]
    test    al, al
    jz      .apply_sign

    ; convert char to digit value
    cmp     al, '0'
    jl      .invalid
    cmp     al, '9'
    jle     .is_decimal

    ; check hex letters
    cmp     al, 'a'
    jl      .check_upper
    cmp     al, 'f'
    jg      .invalid
    sub     al, 'a'
    add     al, 10
    jmp     .validate_digit

.check_upper:
    cmp     al, 'A'
    jl      .invalid
    cmp     al, 'F'
    jg      .invalid
    sub     al, 'A'
    add     al, 10
    jmp     .validate_digit

.is_decimal:
    sub     al, '0'

.validate_digit:
    ; digit must be < base
    movzx   r9, al
    cmp     r9, r12
    jge     .invalid

    ; result = result * base + digit
    mov     rax, rbx
    mul     r12
    test    rdx, rdx
    jnz     .overflow
    add     rax, r9
    jc      .overflow
    mov     rbx, rax
    inc     r10
    jmp     .loop

.overflow:
    mov     rax, EXIT_INVALID_IMM
    xor     rdx, rdx
    pop     r13
    pop     r12
    pop     rbx
    ret

.apply_sign:
    test    r13, r13               ; negative?
    jz      .done
    neg     rbx                    ; negate result

.done:
    xor     rax, rax               ; rax = EXIT_OK
    mov     rdx, rbx               ; rdx = parsed value
    pop     r13
    pop     r12
    pop     rbx
    ret

.invalid:
    mov     rax, EXIT_INVALID_IMM
    xor     rdx, rdx
    pop     r13
    pop     r12
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- str_find_char ----------------------
;
; str_find_char
; Finds the first occurrence of a byte in a string.
; Input    : rdi = pointer to null-terminated string
            rsi = byte to search for (low byte used)
; Output   : rax = EXIT_OK if found, EXIT_ERROR if not found
             rdx = pointer to first occurrence
; Clobbers : rcx
;
global str_find_char
str_find_char:
    test    rdi, rdi
    jz      .null_ptr

.loop:
    mov     cl, byte [rdi]
    test    cl, cl                 ; end of string?
    jz      .not_found
    cmp     cl, sil                ; match?
    je      .found
    inc     rdi
    jmp     .loop

.found:
    xor     rax, rax
    mov     rdx, rdi
    ret

.not_found:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- str_is_digit -----------------------
;
; str_is_digit
; Checks if a single character is a decimal digit.
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_digit
str_is_digit:
    cmp     dil, '0'
    jl      .false
    cmp     dil, '9'
    jg      .false
    mov     rax, TRUE
    ret
.false:
    mov     rax, FALSE
    ret

; ---- str_is_alpha -----------------------
;
; str_is_alpha
; Checks if a single character is an ASCII letter.
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_alpha
str_is_alpha:
    cmp     dil, 'a'
    jl      .check_upper
    cmp     dil, 'z'
    jle     .true
.check_upper:
    cmp     dil, 'A'
    jl      .false
    cmp     dil, 'Z'
    jle     .true
.false:
    mov     rax, FALSE
    ret
.true:
    mov     rax, TRUE
    ret

; ---- str_is_alnum -----------------------
;
; str_is_alnum
; Checks if a character is alphanumeric (letter or digit).
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_alnum
str_is_alnum:
    push    rdi
    call    str_is_alpha
    pop     rdi
    cmp     rax, TRUE
    je      .true
    call    str_is_digit
    ret
.true:
    mov     rax, TRUE
    ret

; ---- str_is_space -----------------------
;
; str_is_space
; Checks if a character is whitespace (space, tab, CR).
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_space
str_is_space:
    cmp     dil, ' '
    je      .true
    cmp     dil, 0x09              ; tab
    je      .true
    cmp     dil, 0x0D              ; carriage return
    je      .true
    mov     rax, FALSE
    ret
.true:
    mov     rax, TRUE
    ret

; ---- str_is_ident_start -----------------
;
; str_is_ident_start
; Checks if a character can start an identifier.
; Valid: letter, underscore, dot (for local labels).
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_ident_start
str_is_ident_start:
    cmp     dil, '_'
    je      .true
    cmp     dil, '.'
    je      .true
    push    rdi
    call    str_is_alpha
    pop     rdi
    ret
.true:
    mov     rax, TRUE
    ret

; ---- str_is_ident_char ------------------
;
; str_is_ident_char
; Checks if a character can appear inside an identifier.
; Valid: letter, digit, underscore, dot.
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_ident_char
str_is_ident_char:
    cmp     dil, '_'
    je      .true
    cmp     dil, '.'
    je      .true
    push    rdi
    call    str_is_alnum
    pop     rdi
    ret
.true:
    mov     rax, TRUE
    ret

; ---- str_is_hex_digit -------------------
;
; str_is_hex_digit
; Checks if a character is a valid hexadecimal digit.
; Input    : rdi = character value (low byte used)
; Output   : rax = TRUE or FALSE
; Clobbers : none
;
global str_is_hex_digit
str_is_hex_digit:
    push    rdi
    call    str_is_digit
    pop     rdi
    cmp     rax, TRUE
    je      .true
    cmp     dil, 'a'
    jl      .check_upper
    cmp     dil, 'f'
    jle     .true
.check_upper:
    cmp     dil, 'A'
    jl      .false
    cmp     dil, 'F'
    jle     .true
.false:
    mov     rax, FALSE
    ret
.true:
    mov     rax, TRUE
    ret

; ---- str_concat_dot ----------------------
;
; str_concat_dot
; Builds "A.B" from two strings into a caller-supplied buffer.
; Used by the struct field resolver to build "StructName.FieldName".
; Input    : rdi = destination buffer (must hold len(A)+len(B)+2 bytes)
            rsi = pointer to string A (struct name)
            rdx = pointer to string B (field name)
; Output   : rax = EXIT_OK or EXIT_ERROR
            rdx = destination pointer
; Clobbers : rcx, r8, r9
;
global str_concat_dot
str_concat_dot:
    test    rdi, rdi
    jz      .null_ptr
    test    rsi, rsi
    jz      .null_ptr
    test    rdx, rdx
    jz      .null_ptr

    push    rbx
    push    r12
    push    r13
    mov     rbx, rdi               ; save dst start
    mov     r12, rsi               ; save A ptr
    mov     r13, rdx               ; save B ptr

    ; copy A into dst
    mov     rsi, r12
    call    str_copy
    test    rax, rax
    jnz     .error

    ; append '.'
    mov     rdi, rbx
    call    str_len                ; rax = len(A)
    add     rdi, rax
    mov     byte [rdi], '.'
    inc     rdi

    ; append B
    mov     rsi, r13
    call    str_copy
    test    rax, rax
    jnz     .error

    xor     rax, rax
    mov     rdx, rbx
    pop     r13
    pop     r12
    pop     rbx
    ret

.error:
    pop     r13
    pop     r12
    pop     rbx
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

; ---- str_int_to_str ----------------------
;
; str_int_to_str
; Converts an unsigned 64-bit integer to a decimal ASCII string.
; Input    : rdi = destination buffer (must hold at least 21 bytes)
            rsi = unsigned 64-bit value to format
; Output   : rax = EXIT_OK or EXIT_ERROR
            rdx = pointer to destination (null-terminated)
; Clobbers : rcx, r8, r9, r10
;
global str_int_to_str
str_int_to_str:
    test    rdi, rdi
    jz      .null_ptr

    push    rbx
    push    r12
    push    r13
    mov     rbx, rdi               ; save dst
    mov     r12, rsi               ; value to convert
    
    ; handle zero specially
    test    r12, r12
    jnz     .nonzero
    mov     byte [rdi], '0'
    mov     byte [rdi + 1], 0
    xor     rax, rax
    mov     rdx, rbx
    pop     r13
    pop     r12
    pop     rbx
    ret

.nonzero:
    ; build digits in reverse into a 21-byte temp buffer on stack
    sub     rsp, 24
    mov     r13, rsp               ; temp buffer
    xor     rcx, rcx               ; digit count

    mov     rax, r12
    mov     r8, 10

.div_loop:
    test    rax, rax
    jz      .reverse
    xor     rdx, rdx
    div     r8
    add     dl, '0'
    mov     byte [r13 + rcx], dl
    inc     rcx
    jmp     .div_loop

.reverse:
    ; copy reversed digits into dst
    mov     r9, 0                  ; dst index
.rev_loop:
    test    rcx, rcx
    jz      .terminate
    dec     rcx
    mov     al, byte [r13 + rcx]
    mov     byte [rbx + r9], al
    inc     r9
    jmp     .rev_loop

.terminate:
    mov     byte [rbx + r9], 0    ; null terminate
    add     rsp, 24
    xor     rax, rax
    mov     rdx, rbx
    pop     r13
    pop     r12
    pop     rbx
    ret

.null_ptr:
    mov     rax, EXIT_ERROR
    xor     rdx, rdx
    ret

;*
; * [str_concat]
; * Purpose: Concatenates two null-terminated strings into a destination.
; * Input:
; *   RDI: Destination buffer
; *   RSI: String A
; *   RDX: String B
; ;
global str_concat
str_concat:
    prologue
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi               ; RBX = Dest
    mov     r12, rsi               ; R12 = A
    mov     r13, rdx               ; R13 = B
    
    ; Copy String A
    mov     rdi, rbx
    mov     rsi, r12
    call    str_copy
    
    ; Find end of Dest
    mov     rdi, rbx
    call    str_len
    add     rdi, rax               ; RDI points to null terminator of A
    
    ; Copy String B
    mov     rsi, r13
    call    str_copy
    
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue
;*
; * [str_find_str]
; * Purpose: Finds a substring within a string.
; * Input:
; *   RDI: Haystack (null-terminated)
; *   RSI: Needle (null-terminated)
; * Output:
; *   RAX: EXIT_OK if found, EXIT_ERROR if not
; *   RDX: Pointer to start of needle in haystack
; ;
global str_find_str
str_find_str:
    prologue
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi               ; Haystack
    mov     r12, rsi               ; Needle
    
    ; handle empty needle
    movzx   rax, byte [r12]
    test    al, al
    jz      .found_empty
    
.outer:
    movzx   rax, byte [rbx]
    test    al, al
    jz      .not_found
    
    ; check match at current position
    mov     rdi, rbx
    mov     rsi, r12
.inner:
    movzx   rax, byte [rdi]
    movzx   rcx, byte [rsi]
    test    cl, cl
    jz      .found                 ; reached end of needle
    cmp     al, cl
    jne     .next_outer
    inc     rdi
    inc     rsi
    jmp     .inner

.next_outer:
    inc     rbx
    jmp     .outer

.found_empty:
    mov     rdx, rbx
    xor     rax, rax
    jmp     .done

.found:
    mov     rdx, rbx
    xor     rax, rax
    jmp     .done

.not_found:
    mov     rax, EXIT_ERROR
    ; fall through to .done

.done:
    pop     r13
    pop     r12
    pop     rbx
    epilogue

; ---- str_utf8_decode --------------------
;
; str_utf8_decode
; Decodes a single UTF-8 character sequence and validates it.
; Follows RFC 3629 / Unicode 15.0 strict validation.
; 
; Input    : rdi = pointer to UTF-8 sequence
            rsi = pointer to end of buffer (boundary check)
; Output   : rax = number of bytes consumed (1-4) or 0 on error
             rdx = decoded Unicode codepoint
; Clobbers : rcx, r8, r9
;
global str_utf8_decode
str_utf8_decode:
    ; check boundary
    cmp     rdi, rsi
    jge     .error
    
    movzx   eax, byte [rdi]
    
    ; 1-byte (ASCII)
    test    al, 0x80
    jz      .one_byte
    
    ; 2-byte: 110xxxxx
    mov     cl, al
    and     cl, 0xE0
    cmp     cl, 0xC0
    je      .two_bytes
    
    ; 3-byte: 1110xxxx
    mov     cl, al
    and     cl, 0xF0
    cmp     cl, 0xE0
    je      .three_bytes
    
    ; 4-byte: 11110xxx
    mov     cl, al
    and     cl, 0xF8
    cmp     cl, 0xF0
    je      .four_bytes
    
.error:
    xor     rax, rax
    ret

.one_byte:
    mov     rdx, rax
    mov     rax, 1
    ret

.two_bytes:
    ; next byte?
    lea     rcx, [rdi + 1]
    cmp     rcx, rsi
    jge     .error
    
    ; validate 10xxxxxx
    movzx   r8d, byte [rcx]
    mov     r9d, r8d
    and     r9d, 0xC0
    cmp     r9d, 0x80
    jne     .error
    
    ; Decode: ((al & 0x1F) << 6) | (r8 & 0x3F)
    and     eax, 0x1F
    shl     eax, 6
    and     r8d, 0x3F
    or      eax, r8d
    
    ; Overlong check: must be > 0x7F
    cmp     eax, 0x7F
    jle     .error
    
    mov     rdx, rax
    mov     rax, 2
    ret

.three_bytes:
    ; next 2 bytes?
    lea     rcx, [rdi + 2]
    cmp     rcx, rsi
    jge     .error
    
    ; Byte 2: 10xxxxxx
    movzx   r8d, byte [rdi + 1]
    mov     r9d, r8d
    and     r9d, 0xC0
    cmp     r9d, 0x80
    jne     .error
    
    ; Byte 3: 10xxxxxx
    movzx   ecx, byte [rdi + 2]
    mov     r9d, ecx
    and     r9d, 0xC0
    cmp     r9d, 0x80
    jne     .error
    
    ; Decode: ((al & 0x0F) << 12) | ((r8 & 0x3F) << 6) | (rc)
    and     eax, 0x0F
    shl     eax, 12
    and     r8d, 0x3F
    shl     r8d, 6
    or      eax, r8d
    and     ecx, 0x3F
    or      eax, ecx
    
    ; Overlong check: must be > 0x7FF
    cmp     eax, 0x7FF
    jle     .error
    
    ; Surrogate check: must not be in U+D800 - U+DFFF
    cmp     eax, 0xD800
    jl      .3_ok
    cmp     eax, 0xDFFF
    jle     .error
    
.3_ok:
    mov     rdx, rax
    mov     rax, 3
    ret

.four_bytes:
    ; next 3 bytes?
    lea     rcx, [rdi + 3]
    cmp     rcx, rsi
    jge     .error
    
    ; Byte 2
    movzx   r8d, byte [rdi + 1]
    mov     r9d, r8d
    and     r9d, 0xC0
    cmp     r9d, 0x80
    jne     .error
    
    ; Byte 3
    movzx   ecx, byte [rdi + 2]
    mov     r9d, ecx
    and     r9d, 0xC0
    cmp     r9d, 0x80
    jne     .error
    
    ; Byte 4
    movzx   r9d, byte [rdi + 3]
    mov     r10d, r9d
    and     r10d, 0xC0
    cmp     r10d, 0x80
    jne     .error
    
    ; Decode
    and     eax, 0x07
    shl     eax, 18
    and     r8d, 0x3F
    shl     r8d, 12
    or      eax, r8d
    and     ecx, 0x3F
    shl     ecx, 6
    or      eax, ecx
    and     r9d, 0x3F
    or      eax, r9d
    
    ; Overlong check: > 0xFFFF
    cmp     eax, 0xFFFF
    jle     .error
    
    ; Out of range: <= 0x10FFFF
    cmp     eax, 0x10FFFF
    jg      .error
    
    mov     rdx, rax
    mov     rax, 4
    ret
; ---- str_copy ---------------------------
;
; str_copy
; Copies a null-terminated string to destination.
; Input    : rdi = destination pointer
            rsi = source pointer
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = destination pointer
; Clobbers : rcx, r8
;
global str_copy
str_copy:
    test    rdi, rdi
    jz      .null_ptr_copy
    test    rsi, rsi
    jz      .null_ptr_copy

    push    rdi
.loop_copy:
    mov     al, [rsi]
    mov     [rdi], al
    test    al, al
    jz      .done_copy
    inc     rdi
    inc     rsi
    jmp     .loop_copy

.done_copy:
    pop     rdx
    xor     rax, rax
    ret

.null_ptr_copy:
    mov     rax, 1
    xor     rdx, rdx
    ret

; ---- str_concat -------------------------
;
; str_concat
; Concatenates two null-terminated strings.
; Input    : rdi = destination buffer (must have enough space)
            rsi = first string
            rdx = second string
; Output   : rax = EXIT_OK or EXIT_ERROR
             rdx = destination buffer
; Clobbers : r8, r9, r10, r11
;
global str_concat
str_concat:
    test    rdi, rdi
    jz      .null_ptr_concat
    test    rsi, rsi
    jz      .null_ptr_concat
    test    rdx, rdx
    jz      .null_ptr_concat

    push    rdi
    push    rdx

    ; 1. Copy first string
    call    str_copy
    
    ; 2. Find end of first string in dst
    mov     rdi, rdx
.find_end_concat:
    cmp     byte [rdi], 0
    je      .copy_second_concat
    inc     rdi
    jmp     .find_end_concat

.copy_second_concat:
    pop     rsi
    call    str_copy

    pop     rdx
    xor     rax, rax
    ret

.null_ptr_concat:
    mov     rax, 1
    xor     rdx, rdx
    ret
