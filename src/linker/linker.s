;
 ============================================================================
 File        : src/linker/linker.s
 Project     : utasm
 Description : Main Linker Orchestrator. Coordinates relocations, symbol 
               resolution, and final file emission.
 ============================================================================
;

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"

extern binary_emit
extern elf64_emit
extern reloc_resolve_all
extern error_emit

[SECTION .text]

;*
 * [linker_run]
 * Purpose: The main entry point for the linking stage.
 * Input:
 *   RDI: Pointer to AsmCtx
 * Output:
 *   RAX: EXIT_OK or error code
 ;
global linker_run
linker_run:
    prologue
    push    rbx
    mov     rbx, rdi               ; RBX = AsmCtx

    ; 1. Resolve all relocations
    mov     rdi, rbx
    call    reloc_resolve_all
    check_err

    ; 1.5 Check for section overlaps
    mov     rdi, rbx
    call    linker_check_overlaps
    check_err

    ; 2. Determine Output Format
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_FORMAT_BIN
    jnz     .emit_binary

    test    rax, CTX_FLAG_FORMAT_ELF
    jnz     .emit_elf

    ; Default to ELF if nothing specified
    jmp     .emit_elf

.emit_binary:
    mov     rdi, rbx
    call    binary_emit
    jmp     .done

.emit_elf:
    mov     rdi, rbx
    call    elf64_emit
    jmp     .done

.done:
    pop     rbx
    epilogue

;*
 * [linker_check_overlaps]
 * Input: RDI = AsmCtx
 * Checks all section VA ranges for intersections.
 ;
linker_check_overlaps:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi               ; RBX = AsmCtx
    mov     r12, [rbx + ASMCTX_sections]
    mov     r13d, [rbx + ASMCTX_seccount]
    
    xor     r14, r14               ; i = 0
.outer:
    cmp     r14d, r13d
    jge     .done
    
    mov     rax, r14
    shl     rax, 3
    mov     r10, [r12 + rax]       ; r10 = Section[i]
    
    ; Check if empty or NOBITS
    cmp     qword [r10 + SECTION_size], 0
    je      .next_i
    
    mov     r15, r14
    inc     r15                    ; j = i + 1
.inner:
    cmp     r15d, r13d
    jge     .next_i
    
    mov     rax, r15
    shl     rax, 3
    mov     r11, [r12 + rax]       ; r11 = Section[j]
    
    cmp     qword [r11 + SECTION_size], 0
    je      .next_j

    ; Overlap if (A.start < B.end) && (B.start < A.end)
    ; A.start = r10.addr
    ; A.end   = r10.addr + r10.size
    ; B.start = r11.addr
    ; B.end   = r11.addr + r11.size
    
    mov     rax, [r10 + SECTION_addr]
    mov     rdx, rax
    add     rdx, [r10 + SECTION_size] ; rdx = A.end
    
    mov     rcx, [r11 + SECTION_addr]
    mov     r8,  rcx
    add     r8,  [r11 + SECTION_size] ; r8 = B.end
    
    ; (A.start < B.end)
    cmp     rax, r8
    jge     .next_j
    
    ; (B.start < A.end)
    cmp     rcx, rdx
    jge     .next_j
    
    ; OVERLAP DETECTED
    mov     rax, EXIT_SECTION_OVERLAP
    jmp     .ret

.next_j:
    inc     r15
    jmp     .inner
    
.next_i:
    inc     r14
    jmp     .outer

.done:
    xor     rax, rax
.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue
