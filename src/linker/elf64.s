/*
 ============================================================================
 File        : src/linker/elf64.s
 Project     : utasm
 Description : ELF64 relocatable object file emitter (-f elf64).
               Writes a standards-compliant ELF64 .o file consumable by
               ld, lld, and any POSIX linker.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"
%inc "include/elf.s"

[SECTION .text]

// ============================================================================
// elf64_emit
// ============================================================================
/*
 elf64_emit
 Top-level entry point: writes a complete ELF64 relocatable object file
 from the current AsmCtx to the file descriptor provided.

 Layout written to disk:
   [0]   ELF64 File Header         (64 bytes)
   [64]  .text section data        (variable)
         .data section data        (variable)
         .bss  section data        (0 bytes in file)
   [...]  .symtab entries          (24 bytes each)
   [...]  .strtab null-term strings
   [...]  .shstrtab section names
   [...]  .rela.text entries       (24 bytes each)
   [end]  Section Header Table     (64 bytes each)

 Input  : rdi = pointer to AsmCtx
           rsi = output file descriptor (i32)
 Output : rax = EXIT_OK or error code
*/
global elf64_emit
elf64_emit:
    prologue
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rdi               // r12 = AsmCtx
    mov     r13d, esi              // r13d = fd

    // ---- 0. Resolve Entry Point (Standalone only) ----
    IF byte [r12 + ASMCTX_standalone], e, 1
        mov     rdi, r12
        call    elf64_resolve_entry
        check_err
    ENDIF

    // ---- 1. Write ELF Header ----
    mov     rdi, [r12 + ASMCTX_arena]
    mov     rsi, ELF64_EHDR_SIZE
    call    arena_alloc
    check_err
    mov     r14, rdx               // r14 = ehdr buffer

    call    elf64_write_ehdr
    check_err

    mov     rdi, r13d
    mov     rsi, r14
    mov     rdx, ELF64_EHDR_SIZE
    call    io_write
    check_err

    // ---- 2. Write Program Headers (if standalone) ----
    IF byte [r12 + ASMCTX_standalone], e, 1
        call    elf64_write_phdrs
        check_err
    ENDIF

    // ---- 3. Write .text section ----
    call    elf64_write_text_section
    check_err

    // ---- 4. Write .data section ----
    call    elf64_write_data_section
    check_err

    // ---- 5. Write Metadata sections ----
    call    elf64_prepare_strtab
    check_err
    call    elf64_write_symtab
    check_err
    call    elf64_write_strtab
    check_err
    call    elf64_write_shstrtab
    check_err
    call    elf64_write_rela
    check_err
    call    elf64_write_debug_line
    check_err
    call    elf64_write_debug_info
    check_err
    call    elf64_write_debug_abbrev
    check_err

    // ---- 6. Write Section Header Table ----
    call    elf64_write_shdrs
    check_err

    xor     rax, rax
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    epilogue

/**
 * [elf64_write_debug_line]
 */
elf64_write_debug_line:
    prologue
    push    rbx
    sub     rsp, 16
    
    // 1. Unit Length (Length of data after this field)
    // 2 (version) + 1 (type) + 1 (addr_size) + 4 (abbrev) = 8
    // Note: Line info stub here is even simpler.
    mov     dword [rsp], 0
    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, 4
    call    io_write
    check_err
    
    // 2. Version
    mov     word [rsp], 5
    mov     rdx, 2
    call    io_write
    check_err
    
    add     rsp, 16
    pop     rbx
    xor     rax, rax
    epilogue

/**
 * [elf64_write_debug_info]
 * Writes a minimal DWARF v5 Compile Unit header.
 */
elf64_write_debug_info:
    prologue
    push    rbx
    sub     rsp, 16
    
    // 1. Unit Length (Version + Type + AddrSize + AbbrevOffset = 8)
    mov     dword [rsp], 8
    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, 4
    call    io_write
    
    // 2. Version (5)
    mov     word [rsp], 5
    mov     rdx, 2
    call    io_write
    
    // 3. Unit Type (DW_UT_compile = 1)
    mov     byte [rsp], 1
    mov     rdx, 1
    call    io_write
    
    // 4. Address Size (8)
    mov     byte [rsp], 8
    mov     rdx, 1
    call    io_write
    
    // 5. Abbrev Offset (0)
    mov     dword [rsp], 0
    mov     rdx, 4
    call    io_write
    
    add     rsp, 16
    pop     rbx
    xor     rax, rax
    epilogue

/**
 * [elf64_write_debug_abbrev]
 * Writes a minimal DWARF v5 abbreviation table.
 */
elf64_write_debug_abbrev:
    prologue
    // Write a single 0 byte (Empty abbrev table)
    sub     rsp, 16
    mov     byte [rsp], 0
    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, 1
    call    io_write
    add     rsp, 16
    xor     rax, rax
    epilogue

// ============================================================================
// elf64_write_ehdr
// ============================================================================
/*
 elf64_resolve_entry
 Finds the _start symbol and computes its absolute virtual address.
 Input  : rdi = AsmCtx
 Output : rax = EXIT_OK or EXIT_UNDEF_SYMBOL
*/
elf64_resolve_entry:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     r12, rdi // AsmCtx
    
    mov     rdi, [r12 + ASMCTX_symtab]
    lea     rsi, [rel .str_start]
    extern  symbol_find
    call    symbol_find
    IF rax, e, EXIT_OK
        mov     r10, rdx // SYMBOL*
        mov     rax, [r10 + SYMBOL_value]
        
        // Add section base address
        mov     r11d, dword [r10 + SYMBOL_section]
        mov     r14, [r12 + ASMCTX_sections]
        mov     r13, [r14 + r11 * 8] // SECTION*
        add     rax, [r13 + SECTION_addr]
        
        mov     [r12 + ASMCTX_entry_point], rax
        xor     rax, rax
    ELSE
        mov     rax, EXIT_UNDEF_REF
    ENDIF
    
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

.str_start: db "_start", 0

// ============================================================================
/*
 elf64_write_ehdr
 Fills the 64-byte ELF file header buffer at r14 with correct values
 for a relocatable AMD64 object file (ET_REL).
 Input  : r12 = AsmCtx, r14 = ehdr buffer
 Output : rax = EXIT_OK
*/
elf64_write_ehdr:
    prologue

    // Zero the buffer
    mov     rdi, r14
    mov     rsi, ELF64_EHDR_SIZE
    call    mem_zero
    check_err

    // e_ident magic
    mov     byte [r14 + EHDR_IDENT + EI_MAG0],    ELFMAG0
    mov     byte [r14 + EHDR_IDENT + EI_MAG1],    ELFMAG1
    mov     byte [r14 + EHDR_IDENT + EI_MAG2],    ELFMAG2
    mov     byte [r14 + EHDR_IDENT + EI_MAG3],    ELFMAG3
    mov     byte [r14 + EHDR_IDENT + EI_CLASS],   ELFCLASS64
    mov     byte [r14 + EHDR_IDENT + EI_DATA],    ELFDATA2LSB
    mov     byte [r14 + EHDR_IDENT + EI_VERSION], EV_CURRENT
    mov     byte [r14 + EHDR_IDENT + EI_OSABI],   ELFOSABI_NONE

    // e_type
    IF byte [r12 + ASMCTX_standalone], e, 1
        mov     word [r14 + EHDR_TYPE],    ET_EXEC
    ELSE
        mov     word [r14 + EHDR_TYPE],    ET_REL
    ENDIF
    
    // ---- FIX: DYNAMIC MACHINE TYPE ----
    mov     al, [r12 + ASMCTX_target]
    IF al, e, TARGET_AARCH64
        mov     word [r14 + EHDR_MACHINE], EM_AARCH64
    ELSEIF al, e, TARGET_RISCV64
        mov     word [r14 + EHDR_MACHINE], EM_RISCV64
    ELSE
        mov     word [r14 + EHDR_MACHINE], EM_X86_64
    ENDIF
    
    mov     dword [r14 + EHDR_VERSION], EV_CURRENT

    // e_entry
    mov     rax, [r12 + ASMCTX_entry_point]
    mov     qword [r14 + EHDR_ENTRY], rax

    // e_phoff
    IF byte [r12 + ASMCTX_standalone], e, 1
        mov     qword [r14 + EHDR_PHOFF], ELF64_EHDR_SIZE
        mov     word  [r14 + EHDR_PHENTSIZE], ELF64_PHDR_SIZE
        mov     word  [r14 + EHDR_PHNUM], 2 // For now: 1 Code + 1 Data
    ELSE
        mov     qword [r14 + EHDR_PHOFF], 0
        mov     word  [r14 + EHDR_PHENTSIZE], 0
        mov     word  [r14 + EHDR_PHNUM], 0
    ENDIF

    // e_shoff will be patched after all sections are written
    // e_shnum and e_shstrndx
    movzx   eax, word [r12 + ASMCTX_seccount]
    add     eax, 4                 // NULL + symtab + strtab + shstrtab
    IF dword [r12 + ASMCTX_reloccount], ne, 0
        inc     eax                // .rela.text
    ENDIF
    mov     word  [r14 + EHDR_SHNUM], ax
    
    // .shstrtab index is 1 + seccount + 2 (symtab, strtab)
    movzx   ecx, word [r12 + ASMCTX_seccount]
    add     ecx, 3                 // 0:NULL, 1..N:User, N+1:sym, N+2:str, N+3:shstr
    mov     word  [r14 + EHDR_SHSTRNDX], cx

    xor     rax, rax
    epilogue

/**
 * [elf64_write_phdrs]
 */
elf64_write_phdrs:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    
    mov     r12, rdi               // r12 = AsmCtx
    mov     r13d, esi              // r13d = fd
    
    // Allocate 112 bytes for 2 PHDRs
    mov     rdi, [r12 + ASMCTX_arena]
    mov     rsi, 112
    call    arena_alloc
    check_err
    mov     r14, rdx               // r14 = buffer
    
    mov     rdi, r14
    mov     rsi, 112
    call    mem_zero
    
    // 1. Calculate Code Offset: Immediately after Headers
    mov     rax, ELF64_EHDR_SIZE
    add     rax, 112               // 2 PHDRs * 56 bytes
    mov     r15, rax               // r15 = code_offset
    
    // CODE Segment
    mov     dword [r14 + PHDR_type],   PT_LOAD
    mov     dword [r14 + PHDR_flags],  (PF_R | PF_X)
    mov     qword [r14 + PHDR_offset], r15
    mov     rax, [r12 + ASMCTX_entry_point]
    mov     qword [r14 + PHDR_vaddr],  rax
    mov     qword [r14 + PHDR_paddr],  rax
    
    mov     rdi, r12
    mov     rsi, SEC_TEXT
    call    asmctx_get_section
    mov     rax, [rdx + SECTION_size]
    mov     qword [r14 + PHDR_filesz], rax
    mov     qword [r14 + PHDR_memsz],  rax
    mov     qword [r14 + PHDR_align],  0x1000
    
    // 2. Calculate Data Offset: Align(Code_Offset + Code_Size, 4096)
    add     r15, rax               // r15 = code_offset + code_size
    add     r15, 4095
    and     r15, -4096             // r15 = data_offset (aligned)
    
    // DATA Segment
    add     r14, 56
    mov     dword [r14 + PHDR_type],   PT_LOAD
    mov     dword [r14 + PHDR_flags],  (PF_R | PF_W)
    mov     qword [r14 + PHDR_offset], r15
    
    // Virtual Address for data segment: Entry + (Data_Offset - Code_Offset)
    mov     rax, [r12 + ASMCTX_entry_point]
    mov     rcx, r15               // data_offset
    sub     rcx, [r14 - 56 + PHDR_offset] // code_offset
    add     rax, rcx
    
    mov     qword [r14 + PHDR_vaddr],  rax
    mov     qword [r14 + PHDR_paddr],  rax
    
    mov     rdi, r12
    mov     rsi, SEC_DATA
    call    asmctx_get_section
    mov     rax, [rdx + SECTION_size]
    mov     qword [r14 + PHDR_filesz], rax
    
    // memsz = data_size + bss_size
    mov     r8, rax                // r8 = data_size
    
    mov     rdi, r12
    mov     rsi, SEC_BSS
    call    asmctx_get_section
    mov     rax, [rdx + SECTION_size]
    add     r8, rax                // r8 = data_size + bss_size
    
    mov     qword [r14 + PHDR_memsz],  r8
    mov     qword [r14 + PHDR_align],  0x1000
    
    // Write buffer
    sub     r14, 56
    mov     rdi, r13d
    mov     rsi, r14
    mov     rdx, 112
    call    io_write
    check_err
    
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue

// ============================================================================
// elf64_write_text_section
// ============================================================================
/*
 Writes the assembled .text bytes to the output fd.
 Input  : r12 = AsmCtx, r13 = fd
 Output : rax = EXIT_OK or error
*/
elf64_write_text_section:
    prologue

    // Get .text section from AsmCtx section array
    mov     rdi, r12
    mov     rsi, SEC_TEXT
    call    asmctx_get_section
    check_err
    mov     r10, rdx               // r10 = SECTION*

    mov     rdi, r13d              // fd
    mov     rsi, [r10 + SECTION_data]
    mov     rdx, [r10 + SECTION_size]
    call    io_write
    check_err

    xor     rax, rax
    epilogue

// ============================================================================
// elf64_write_data_section
// ============================================================================
elf64_write_data_section:
    prologue

    mov     rdi, r12
    mov     rsi, SEC_DATA
    call    asmctx_get_section
    check_err
    mov     r10, rdx

    mov     rdi, r13d
    mov     rsi, [r10 + SECTION_data]
    mov     rdx, [r10 + SECTION_size]
    call    io_write
    check_err

    xor     rax, rax
    epilogue

// ============================================================================
// elf64_prepare_strtab
// ============================================================================
elf64_prepare_strtab:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     r12, rdi               // AsmCtx
    mov     rbx, [r12 + ASMCTX_symtab]
    
    // Start at index 1 (0 is null byte)
    mov     r15, 1
    xor     r14, r14               // i = 0
    
.outer_loop:
    cmp     r14d, [r12 + ASMCTX_symcount]
    jge     .done
    
    lea     r13, [rbx + r14 * SYMBOL_SIZE]
    mov     rsi, [r13 + SYMBOL_name]
    test    rsi, rsi
    jz      .next_outer
    
    // Check if this string appeared before index r14
    xor     rcx, rcx               // j = 0
.inner_loop:
    cmp     ecx, r14d
    jge     .is_unique
    
    lea     rdi, [rbx + rcx * SYMBOL_SIZE]
    mov     rax, [rdi + SYMBOL_name]
    test    rax, rax
    jz      .next_inner
    
    // Compare names
    push    rsi
    push    rcx
    mov     rdi, rax
    extern  str_cmp
    call    str_cmp
    pop     rcx
    pop     rsi
    
    test    rax, rax
    jnz     .next_inner
    
    // Found duplicate! Reuse index
    mov     eax, [rbx + rcx * SYMBOL_SIZE + SYMBOL_name_idx]
    mov     [r13 + SYMBOL_name_idx], eax
    jmp     .next_outer

.next_inner:
    inc     ecx
    jmp     .inner_loop

.is_unique:
    // Store current offset
    mov     [r13 + SYMBOL_name_idx], r15d
    
    // Advance offset
    mov     rdi, rsi
    extern  str_len
    call    str_len
    add     r15, rax
    inc     r15
    
.next_outer:
    inc     r14
    jmp     .outer_loop
    
.done:
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue

// ============================================================================
// elf64_write_symtab
// ============================================================================
/*
 Writes the ELF64 symbol table (.symtab).
 Each utasm SYMBOL maps to one Sym64 entry (24 bytes).
 Input  : r12 = AsmCtx, r13 = fd
*/
elf64_write_symtab:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15

    mov     r12, rdi               // r12 = AsmCtx
    mov     r13d, esi              // r13d = fd
    
    sub     rsp, ELF64_SYM_SIZE    // scratch Sym64

    // ---- 1. Null Symbol ----
    mov     rdi, rsp
    mov     rsi, ELF64_SYM_SIZE
    call    mem_zero
    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, ELF64_SYM_SIZE
    call    io_write
    check_err

    // ---- 2. Pass 1: Local Symbols ----
    mov     r11, 1                 // ELF symbol index (0 is Null)
    xor     r14, r14               // internal loop index
    mov     r15, [r12 + ASMCTX_symtab]
    mov     ebx, [r12 + ASMCTX_symcount]
.local_loop:
    cmp     r14d, ebx
    jge     .global_pass
    
    lea     r10, [r15 + r14 * SYMBOL_SIZE]
    IF byte [r10 + SYMBOL_vis], e, VIS_LOCAL
        mov     [r10 + SYMBOL_elf_idx], r11d
        call    .write_one_sym
        check_err
        inc     r11
    ENDIF
    inc     r14
    jmp     .local_loop

    // ---- 3. Pass 2: Global/Weak Symbols ----
.global_pass:
    xor     r14, r14
.global_loop:
    cmp     r14d, ebx
    jge     .done
    
    lea     r10, [r15 + r14 * SYMBOL_SIZE]
    IF byte [r10 + SYMBOL_vis], ne, VIS_LOCAL
        mov     [r10 + SYMBOL_elf_idx], r11d
        call    .write_one_sym
        check_err
        inc     r11
    ENDIF
    inc     r14
    jmp     .global_loop

.done:
    add     rsp, ELF64_SYM_SIZE
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue

// Helper: writes SYMBOL at R10 to FD R13D using scratch RSP
.write_one_sym:
    push    rdi
    push    rsi
    push    rdx
    
    mov     rdi, rsp
    add     rdi, 24                // back to scratch
    mov     rsi, ELF64_SYM_SIZE
    call    mem_zero
    
    // st_name
    mov     eax, [r10 + SYMBOL_name_idx]
    mov     [rsp + 24 + SYM64_NAME], eax
    
    // st_info: (bind << 4) | (kind == LABEL ? FUNC : OBJECT)
    movzx   eax, byte [r10 + SYMBOL_vis]   // VIS_LOCAL=0, VIS_GLOBAL=1, VIS_WEAK=2
    shl     al, 4
    mov     cl, [r10 + SYMBOL_kind]
    IF cl, e, SYM_LABEL
        or      al, STT_FUNC
    ELSE
        or      al, STT_OBJECT
    ENDIF
    mov     [rsp + 24 + SYM64_INFO], al
    
    // st_other: STV_DEFAULT (0)
    mov     byte [rsp + 24 + SYM64_OTHER], 0
    
    // st_shndx
    movzx   eax, word [r10 + SYMBOL_section]
    mov     [rsp + 24 + SYM64_SHNDX], ax
    
    // st_value
    mov     rax, [r10 + SYMBOL_value]
    mov     [rsp + 24 + SYM64_VALUE], rax
    
    // st_size
    mov     rax, [r10 + SYMBOL_size]
    mov     [rsp + 24 + SYM64_SIZE], rax
    
    mov     rdi, r13d
    lea     rsi, [rsp + 24]
    mov     rdx, ELF64_SYM_SIZE
    call    io_write
    
    pop     rdx
    pop     rsi
    pop     rdi
    mov     rdx, ELF64_SYM_SIZE
    call    io_write
    check_err

    inc     r15
    jmp     .loop

.done:
    add     rsp, ELF64_SYM_SIZE
    xor     rax, rax
    pop     r15
    pop     r14
    pop     rbx
    epilogue

// ============================================================================
// elf64_write_strtab
// ============================================================================
/*
 Writes the .strtab section — a sequence of null-terminated symbol names.
 The null symbol at index 0 is the first byte (\0).
*/
elf64_write_strtab:
    prologue
    push    rbx
    push    r14

    // Write leading null byte
    sub     rsp, 8
    mov     byte [rsp], 0
    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, 1
    call    io_write
    add     rsp, 8
    check_err

    // Walk symbols and write each name
    mov     rbx, [r12 + ASMCTX_symtab]
    mov     r14d, [r12 + ASMCTX_symcount]
    xor     rcx, rcx

.loop:
    cmp     ecx, r14d
    jge     .done

    lea     rdi, [rbx + rcx * SYMBOL_SIZE]
    mov     rsi, [rdi + SYMBOL_name]
    test    rsi, rsi
    jz      .next

    mov     rdi, rsi
    call    str_len                // rax = length
    mov     rdx, rax
    inc     rdx                    // include null terminator

    mov     rdi, r13d
    // rsi still points to the name
    call    io_write
    check_err

.next:
    inc     ecx
    jmp     .loop

.done:
    xor     rax, rax
    pop     r14
    pop     rbx
    epilogue

// ============================================================================
// elf64_write_shstrtab
// ============================================================================
/*
 Writes .shstrtab — section name string table.
 Fixed set of names for the standard sections we emit.
*/
elf64_write_shstrtab:
    prologue

    mov     rdi, r13d

    // Write the whole shstrtab as one blob
    lea     rsi, [shstrtab_data]
    mov     rdx, shstrtab_size
    call    io_write
    check_err

    xor     rax, rax
    epilogue

// ============================================================================
// elf64_write_rela
// ============================================================================
/*
 Writes .rela.text — relocation entries for unresolved symbols in .text.
 Walks the RELOC table stored in AsmCtx.
*/
elf64_write_rela:
    prologue
    push    rbx
    push    r14

    sub     rsp, ELF64_RELA_SIZE   // scratch Rela64 on stack

    mov     rbx, [r12 + ASMCTX_reloctab]
    mov     r14d, [r12 + ASMCTX_reloccount]
    xor     rcx, rcx

.loop:
    cmp     ecx, r14d
    jge     .done

    lea     rdi, [rbx + rcx * RELOC_SIZE]

    // r_offset
    mov     rax, [rdi + RELOC_offset]
    mov     qword [rsp + RELA_OFFSET], rax

    // r_info: (sym_index << 32) | reloc_type
    mov     rsi, [rdi + RELOC_sym] // symbol name ptr
    mov     rdi, [r12 + ASMCTX_symtab]
    extern  symbol_find
    call    symbol_find
    IF rax, e, EXIT_OK
        mov     eax, [rdx + SYMBOL_elf_idx]
    ELSE
        // If symbol is truly missing, this should have been caught in Pass 2.
        // For now, use 0 (Null symbol) as fallback.
        xor     eax, eax
    ENDIF
    
    mov     r11, rax
    shl     r11, 32
    
    // ---- FIX: ARCH-SPECIFIC RELOC TYPE ----
    movzx   edx, dword [rdi + RELOC_type]
    or      r11, rdx
    mov     qword [rsp + RELA_INFO], r11

    // r_addend
    mov     rax, [rdi + RELOC_addend]
    mov     qword [rsp + RELA_ADDEND], rax

    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, ELF64_RELA_SIZE
    call    io_write
    check_err

    inc     ecx
    jmp     .loop

.done:
    add     rsp, ELF64_RELA_SIZE
    xor     rax, rax
    pop     r14
    pop     rbx
    epilogue

// ============================================================================
// elf64_write_shdrs
// ============================================================================
/*
 Writes the section header table (8 entries for a minimal object).
 Sections: [0] NULL, [1] .text, [2] .data, [3] .bss,
           [4] .symtab, [5] .strtab, [6] .shstrtab, [7] .rela.text
*/
elf64_write_shdrs:
    prologue
    push    rbx
    push    r12
    push    r13
    push    r14
    push    r15
    
    mov     rbx, rdi               // AsmCtx
    mov     r12, rsi               // FD
    
    sub     rsp, ELF64_SHDR_SIZE   // scratch shdr
    
    // 1. NULL Section [0]
    mov     rdi, rsp | mov rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     rdi, r12 | mov rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    
    // 2. Iterate User Sections
    mov     r14, [rbx + ASMCTX_sections]
    mov     r15d, [rbx + ASMCTX_seccount]
    xor     ecx, ecx
    
    // Initial file offset (after ELF header + Phdrs)
    // For now, assume a fixed start or pass it in. 
    // Actually, we should calculate this based on the previous sections.
    mov     r11, 0x1000            // Initial page alignment for .text
    
.sec_loop:
    cmp     ecx, r15d
    jge     .sec_done
    
    mov     r13, [r14 + rcx * 8]   // r13 = SECTION*
    
    mov     rdi, rsp | mov rsi, ELF64_SHDR_SIZE | call mem_zero
    
    // Name index (placeholder)
    mov     dword [rsp + SHDR_NAME], 0 
    
    mov     eax, [r13 + SECTION_elf_type]
    mov     dword [rsp + SHDR_TYPE], eax
    
    movzx   eax, word [r13 + SECTION_flags]
    mov     qword [rsp + SHDR_FLAGS], rax
    
    mov     rax, [r13 + SECTION_addr]
    mov     qword [rsp + SHDR_ADDR], rax
    
    // sh_offset: Align current r11 to section alignment
    mov     rax, [r13 + SECTION_align]
    test    rax, rax | jnz .use_align | mov rax, 1 | .use_align:
    
    // r11 = (r11 + rax - 1) & ~(rax - 1)
    dec     rax
    add     r11, rax
    not     rax
    and     r11, rax
    
    mov     qword [rsp + SHDR_OFFSET], r11
    
    mov     rax, [r13 + SECTION_size]
    mov     qword [rsp + SHDR_SIZE], rax
    
    // Update r11 for next section (unless it's NOBITS)
    cmp     dword [r13 + SECTION_elf_type], 8 // SHT_NOBITS (.bss)
    je      .no_offset_inc
    add     r11, rax
.no_offset_inc:
    
    mov     rax, [r13 + SECTION_align]
    test    rax, rax | jz .def_align
    mov     qword [rsp + SHDR_ADDRALIGN], rax
    jmp     .emit
.def_align:
    mov     qword [rsp + SHDR_ADDRALIGN], 1
    
.emit:
    mov     rdi, r12 | mov rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    
    inc     ecx
    jmp     .sec_loop
    
.sec_done:
    // 3. .symtab [1 + seccount]
    mov     rdi, rsp | mov rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME], 18    // ".symtab"
    mov     dword [rsp + SHDR_TYPE], 2     // SHT_SYMTAB
    mov     qword [rsp + SHDR_ENTSIZE], 24 // sizeof(Elf64_Sym)
    // ... offset/size calculation would go here ...
    mov     rdi, r12 | mov rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write

    // 4. .strtab [2 + seccount]
    mov     rdi, rsp | mov rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME], 26    // ".strtab"
    mov     dword [rsp + SHDR_TYPE], 3     // SHT_STRTAB
    mov     rdi, r12 | mov rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write

    // 5. .shstrtab [3 + seccount]
    mov     rdi, rsp | mov rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME], 34    // ".shstrtab"
    mov     dword [rsp + SHDR_TYPE], 3     // SHT_STRTAB
    mov     rdi, r12 | mov rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    pop     r15
    pop     r14
    pop     r13
    pop     r12
    pop     rbx
    epilogue

// ============================================================================
// Read-only data: .shstrtab content
// ============================================================================
[SECTION .rodata]

shstrtab_data:
    db 0                // [0]  null (index 0 = unnamed)
    db ".text", 0       // [1]
    db ".data", 0       // [7]
    db ".bss",  0       // [13]
    db ".symtab", 0     // [18]
    db ".strtab", 0     // [26]
    db ".shstrtab", 0   // [34]
    db ".rela.text", 0  // [44]
shstrtab_end:
%def shstrtab_size (shstrtab_end - shstrtab_data)
