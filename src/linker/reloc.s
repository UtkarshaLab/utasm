/*
 ============================================================================
 File        : src/linker/reloc.s
 Project     : utasm
 Version     : 0.1.0
 Description : Relocation engine for the utasm linker.
               Records, resolves, and applies x86_64 relocations across
               all output formats (ELF64 .o and flat binary).
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"
%inc "include/elf.s"

[SECTION .text]

// ============================================================================
// reloc_record
// ============================================================================
/*
 reloc_record
 Adds one relocation entry to the AsmCtx reloc table.
 Called by the encoder whenever it emits a symbol reference that cannot
 be resolved at encode time (forward references, extern labels).

 Input  : rdi = AsmCtx*
           rsi = byte offset within .text of the patch site
           rdx = pointer to symbol name string (null-terminated)
           rcx = addend (signed 64-bit, usually -4 for PC32)
           r8  = relocation type (R_X86_64_* constant)
 Output : rax = EXIT_OK or EXIT_OOM
*/
global reloc_record
reloc_record:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14

    mov     rbx, rdi               // AsmCtx
    mov     r12, rsi               // offset
    mov     r13, rdx               // sym name ptr
    mov     r14, rcx               // addend
    // r8 = reloc type (held in r8 throughout)

    // Check capacity
    mov     eax, [rbx + ASMCTX_reloccount]
    cmp     eax, MAX_RELOC
    jge     .oom

    // Get slot pointer: reloctab + count * RELOC_SIZE
    mov     rcx, rax
    imul    rcx, RELOC_SIZE
    mov     rdx, [rbx + ASMCTX_reloctab]
    add     rdx, rcx               // rdx = pointer to new slot

    // Zero the slot
    push    rdx
    mov     rdi, rdx
    mov     rsi, RELOC_SIZE
    call    mem_zero
    pop     rdx

    // Fill fields
    mov     [rdx + RELOC_offset], r12
    mov     [rdx + RELOC_sym],    r13
    mov     [rdx + RELOC_addend], r14
    mov     [rdx + RELOC_type],   r8d

    // Increment count
    inc     dword [rbx + ASMCTX_reloccount]

    xor     rax, rax
    jmp     .done

.oom:
    mov     rax, EXIT_OOM

.done:
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

// ============================================================================
// reloc_resolve_all
// ============================================================================
/*
 reloc_resolve_all
 Second-pass resolver: walks every recorded relocation, looks up the
 symbol in the symbol table, computes the final patch value, and writes
 it into the in-memory output buffer.

 Supports the following relocation types:
   R_X86_64_PC32    — 32-bit PC-relative (call/jmp to near symbols)
   R_X86_64_64      — 64-bit absolute address
   R_X86_64_32      — 32-bit zero-extended absolute
   R_X86_64_32S     — 32-bit sign-extended absolute
   R_X86_64_PLT32   — Same as PC32 for direct call resolution

 Input  : rdi = AsmCtx*
           rsi = pointer to output buffer base (virtual address 0 = file offset 0)
           rdx = base virtual address (load address / ORG)
 Output : rax = EXIT_OK or EXIT_UNDEF_REF / EXIT_OFFSET_RANGE
*/
global reloc_resolve_all
reloc_resolve_all:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     rbx, rdi               // AsmCtx
    mov     r12, rsi               // output buffer base
    mov     r13, rdx               // base_addr (ORG / load VA)

    mov     r14, [rbx + ASMCTX_reloctab]
    mov     r15d, [rbx + ASMCTX_reloccount]
    xor     ecx, ecx               // index

.loop:
    cmp     ecx, r15d
    jge     .done

    lea     rsi, [r14 + rcx * RELOC_SIZE]  // rsi = RELOC*

    // Resolve symbol
    mov     rdi, rbx
    mov     rdx, [rsi + RELOC_sym]         // sym name ptr
    extern  symbol_find
    call    symbol_find
    test    rax, rax
    jnz     .undef
    
    mov     r10, rdx                       // r10 = SYMBOL*
    
    // sym_va = symbol.section.addr + symbol.value
    movzx   eax, word [r10 + SYMBOL_section] // section index
    // lookup section addr
    // (Simplified: Get section pointer from AsmCtx.sections + index*8)
    mov     rdi, [rbx + ASMCTX_sections]
    mov     rax, [rdi + rax * 8]             // rax = SECTION*
    mov     rdi, [rax + SECTION_addr]        // rdi = section VA
    
    mov     rax, [r10 + SYMBOL_value]
    add     rax, rdi                         // sym_va = section_base + value

    // patch_offset = reloc.offset
    mov     r8, [rsi + RELOC_offset]

    // patch_ptr = output_buffer + patch_offset
    lea     r9, [r12 + r8]

    // addend
    mov     r10, [rsi + RELOC_addend]

    // patch_va = reloc.section.addr + patch_offset
    mov     rax, [rsi + RELOC_section]     // rsi is RELOC*, get SECTION*
    mov     r10, [rax + SECTION_addr]
    add     r10, r8                        // r10 = patch_va

    // Apply the relocation via unified helper
    mov     rdi, rsi                       // RELOC*
    mov     rsi, rax                       // sym_va
    mov     rdx, r9                        // patch_ptr
    mov     rcx, r10                       // patch_va
    call    reloc_apply_one
    check_err

.next:
    inc     ecx
    jmp     .loop

.done:
    xor     rax, rax
    jmp     .ret

.undef:
    mov     rax, EXIT_UNDEF_REF
    jmp     .ret

.range_err:
    mov     rax, EXIT_OFFSET_RANGE

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

/**
 * [reloc_apply_one]
 * Purpose: Unified relocation applier for all targets.
 */
global reloc_apply_one
reloc_apply_one:
    prologue
    push    rbx
    mov     rbx, rdi               // RELOC*
    mov     rax, rsi               // sym_va
    mov     r8, rdx                // patch_ptr
    mov     r9, rcx                // patch_va
    
    mov     r11d, [rbx + RELOC_type]
    mov     r10, [rbx + RELOC_addend]

    // ---- Dispatch ----
    cmp     r11d, R_X86_64_64
    je      .abs64
    cmp     r11d, R_AARCH64_JMP26
    je      .aarch64_jmp26
    cmp     r11d, R_AARCH64_CALL26
    je      .aarch64_jmp26

    // Default: PC-relative (x86_64 PC32, etc)
    sub     rax, r9                // Target - Patch_VA
    movsx   r10, dword [rbx + RELOC_pc_adjust]
    sub     rax, r10               // Adjust for PC (e.g. 4 for x86_64)
    mov     r10, [rbx + RELOC_addend]
    add     rax, r10
    mov     [r8], eax
    jmp     .done_patch

.abs64:
    add     rax, r10
    mov     [r8], rax
    jmp     .done_patch

.aarch64_jmp26:
    sub     rax, r9
    sar     rax, 2
    and     eax, 0x03FFFFFF
    mov     edx, [r8]
    and     edx, 0xFC000000
    or      edx, eax
    mov     [r8], edx
    jmp     .done_patch

.done_patch:
    xor     rax, rax
    pop     rbx
    epilogue

.ret:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

// ============================================================================
// reloc_init
// ============================================================================
/*
 reloc_init
 Allocates the relocation table inside the AsmCtx arena.
 Must be called once after arena_init and before any encoding begins.

 Input  : rdi = AsmCtx*
 Output : rax = EXIT_OK or EXIT_OOM
*/
global reloc_init
reloc_init:
    prologue
    push    rbx
    mov     rbx, rdi

    mov     rdi, [rbx + ASMCTX_arena]
    mov     rsi, RELOC_SIZE
    imul    rsi, MAX_RELOC
    extern  arena_alloc
    call    arena_alloc
    check_err

    mov     [rbx + ASMCTX_reloctab],   rdx
    mov     dword [rbx + ASMCTX_reloccount], 0
    xor     rax, rax

    pop     rbx
    epilogue
