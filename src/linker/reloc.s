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

    // sym_va = base_addr + symbol.value
    mov     rax, [rdx + SYMBOL_value]
    add     rax, r13                       // sym_va

    // patch_offset = reloc.offset
    mov     r8, [rsi + RELOC_offset]

    // patch_ptr = output_buffer + patch_offset
    lea     r9, [r12 + r8]

    // addend
    mov     r10, [rsi + RELOC_addend]

    // dispatch on type
    mov     r11d, [rsi + RELOC_type]

    cmp     r11d, R_X86_64_64
    je      .abs64

    cmp     r11d, R_X86_64_32
    je      .abs32

    cmp     r11d, R_X86_64_32S
    je      .abs32s

    // Default: PC32 / PLT32
    // patch_val = sym_va - (base_addr + patch_offset + 4) + addend
    mov     rdx, r13
    add     rdx, r8
    add     rdx, 4                         // PC = patch_va + 4
    sub     rax, rdx
    add     rax, r10                       // apply addend

    // Range check: must fit in signed 32 bits
    movsx   rdx, eax
    cmp     rdx, rax
    jne     .range_err

    mov     dword [r9], eax
    jmp     .next

.abs64:
    add     rax, r10
    mov     qword [r9], rax
    jmp     .next

.abs32:
    add     rax, r10
    // Must fit in 32-bit zero-extended
    test    rax, 0xFFFFFFFF00000000
    jnz     .range_err
    mov     dword [r9], eax
    jmp     .next

.abs32s:
    add     rax, r10
    movsx   rdx, eax
    cmp     rdx, rax
    jne     .range_err
    mov     dword [r9], eax

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
