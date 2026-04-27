/*
 ============================================================================
 File        : src/linker/linker.s
 Project     : utasm
 Version     : 0.1.0
 Description : Main Linker Orchestrator. Coordinates relocations, symbol 
               resolution, and final file emission.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"

extern binary_emit
extern elf64_emit
extern reloc_resolve_all
extern error_emit

[SECTION .text]

/**
 * [linker_run]
 * Purpose: The main entry point for the linking stage.
 * Input:
 *   RDI: Pointer to AsmCtx
 * Output:
 *   RAX: EXIT_OK or error code
 */
global linker_run
linker_run:
    prologue
    push    rbx
    mov     rbx, rdi               // RBX = AsmCtx

    // 1. Resolve all relocations
    // This patches the in-memory buffers with final addresses.
    mov     rdi, rbx
    call    reloc_resolve_all
    IF rax, ne, EXIT_OK
        jmp .done
    ENDIF

    // 2. Determine Output Format
    mov     rax, [rbx + ASMCTX_flags]
    test    rax, CTX_FLAG_FORMAT_BIN
    jnz     .emit_binary

    test    rax, CTX_FLAG_FORMAT_ELF
    jnz     .emit_elf

    // Default to ELF if nothing specified
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
