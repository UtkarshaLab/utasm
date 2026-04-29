/*
 ============================================================================
 File        : src/linker/archive_gen.s
 Project     : utasm
 Description : Unix Archive (.a) Generator Implementation.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/archive.s"
%inc "include/macro.s"

[SECTION .text]

/**
 * [archive_gen_header]
 * Purpose: Fills an ARHDR structure with member metadata.
 * Input:
 *   RDI: Pointer to ARHDR (60 bytes)
 *   RSI: Filename string
 *   RDX: Member size (integer)
 * Output:
 *   None
 */
global archive_gen_header
archive_gen_header:
    prologue
    push    rbx
    push    r12
    push    r13
    
    mov     rbx, rdi               // ARHDR*
    mov     r12, rsi               // filename
    mov     r13, rdx               // size
    
    // 1. Clear Header (Space Padded)
    mov     rsi, AR_HDR_SIZE
    mov     dl, ' '
    extern  mem_set
    call    mem_set
    
    // 2. Write Name (Ends with '/')
    mov     rdi, rbx
    mov     rsi, r12
    extern  str_len
    call    str_len
    mov     rcx, rax
    IF rcx, g, 15 | mov rcx, 15 | ENDIF
    
    mov     rdi, rbx
    mov     rsi, r12
    // rdx is already set to size if we used mem_set, but we need to copy rcx bytes
    rep movsb
    mov     byte [rdi], '/'        // Add AR terminator
    
    // 3. Date (Fixed 0 for now)
    mov     byte [rbx + 16], '0'
    
    // 4. UID / GID (Fixed 0)
    mov     byte [rbx + 28], '0'
    mov     byte [rbx + 34], '0'
    
    // 5. Mode (Fixed 644 octal)
    mov     dword [rbx + 40], "644 "
    
    // 6. Size (Decimal ASCII)
    mov     rdi, r13
    extern  error_uint_to_str      // Reusing helper from diagnostics
    call    error_uint_to_str
    mov     rsi, rdx               // string ptr
    mov     rdi, rbx
    add     rdi, 48                // size offset
    extern  str_len
    call    str_len
    mov     rcx, rax
    rep movsb
    
    // 7. Magic (`\n)
    mov     word [rbx + 58], 0x0A60 // "`\n"
    
    pop     r13
    pop     r12
    pop     rbx
    epilogue

/**
 * [archive_write_member]
 * Purpose: Writes a member (header + data + optional padding) to a buffer.
 * Input:
 *   RDI: Output Buffer Pointer (current write position)
 *   RSI: Filename
 *   RDX: Data Pointer
 *   RCX: Data Size
 * Output:
 *   RAX: Number of bytes written
 */
global archive_write_member
archive_write_member:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     rbx, rdi               // out
    mov     r12, rsi               // name
    mov     r13, rdx               // data
    mov     r14, rcx               // size
    
    // 1. Write Header
    mov     rdi, rbx
    mov     rsi, r12
    mov     rdx, r14
    call    archive_gen_header
    
    // 2. Write Data
    lea     rdi, [rbx + AR_HDR_SIZE]
    mov     rsi, r13
    mov     rcx, r14
    rep movsb
    
    // 3. Optional Padding (AR members start on even boundaries)
    mov     rax, AR_HDR_SIZE
    add     rax, r14
    test    r14, 1
    JZ      .done
    
    mov     byte [rdi], 0x0A       // Newline padding
    inc     rax
    
.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue
