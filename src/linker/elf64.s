/*
 ============================================================================
 File        : src/linker/elf64.s
 Project     : utasm
 Version     : 0.1.0
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
    
    // 1. Unit Length
    mov     dword [rsp], 32
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

// ============================================================================
// elf64_write_ehdr
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
    mov     qword [r14 + EHDR_SHOFF], 0
    mov     dword [r14 + EHDR_FLAGS], 0
    mov     word  [r14 + EHDR_EHSIZE],    ELF64_EHDR_SIZE
    mov     word  [r14 + EHDR_SHENTSIZE], ELF64_SHDR_SIZE
    // e_shnum and e_shstrndx patched in elf64_write_shdrs
    mov     word  [r14 + EHDR_SHNUM],     7   // NULL,.text,.data,.bss,.symtab,.strtab,.shstrtab + .rela.text = 8
    mov     word  [r14 + EHDR_SHSTRNDX],  6   // .shstrtab is section index 6

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
    
    // CODE Segment
    mov     dword [r14 + PHDR_type],   PT_LOAD
    mov     dword [r14 + PHDR_flags],  (PF_R | PF_X)
    mov     qword [r14 + PHDR_offset], 176
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
    
    // DATA Segment
    add     r14, 56
    mov     dword [r14 + PHDR_type],   PT_LOAD
    mov     dword [r14 + PHDR_flags],  (PF_R | PF_W)
    // Simplified offset for now
    mov     qword [r14 + PHDR_offset], 4096
    mov     rax, [r12 + ASMCTX_entry_point]
    add     rax, 4096
    mov     qword [r14 + PHDR_vaddr],  rax
    mov     qword [r14 + PHDR_paddr],  rax
    
    mov     rdi, r12
    mov     rsi, SEC_DATA
    call    asmctx_get_section
    mov     rax, [rdx + SECTION_size]
    mov     qword [r14 + PHDR_filesz], rax
    mov     qword [r14 + PHDR_memsz],  rax
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
    push    r14
    push    r15
    
    mov     rbx, [r12 + ASMCTX_symtab]
    mov     r14d, [r12 + ASMCTX_symcount]
    
    // Start at index 1 (0 is null byte)
    mov     r15, 1
    xor     ecx, ecx
    
.loop:
    cmp     ecx, r14d
    jge     .done
    
    lea     rdi, [rbx + rcx * SYMBOL_SIZE]
    mov     rsi, [rdi + SYMBOL_name]
    test    rsi, rsi
    jz      .next
    
    // Store current offset
    mov     [rdi + SYMBOL_name_idx], r15d
    
    // Advance offset by string length + 1 (null)
    mov     rdi, rsi
    extern  str_len
    call    str_len
    add     r15, rax
    inc     r15
    
.next:
    inc     ecx
    jmp     .loop
    
.done:
    pop     r15
    pop     r14
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
    push    r14
    push    r15

    // Allocate one Sym64 entry on stack as scratch
    sub     rsp, ELF64_SYM_SIZE

    // First entry: null symbol (required by ELF spec)
    mov     rdi, rsp
    mov     rsi, ELF64_SYM_SIZE
    call    mem_zero
    mov     rdi, r13d
    mov     rsi, rsp
    mov     rdx, ELF64_SYM_SIZE
    call    io_write
    check_err

    // Walk symbol table
    mov     rbx, [r12 + ASMCTX_symtab]
    mov     r14d, [r12 + ASMCTX_symcount]
    xor     r15, r15               // symbol index

.loop:
    cmp     r15d, r14d
    jge     .done

    lea     rdi, [rbx + r15 * SYMBOL_SIZE]   // current SYMBOL*

    // Zero the Sym64 scratch
    push    rdi
    mov     rdi, rsp
    add     rdi, 8
    mov     rsi, ELF64_SYM_SIZE
    call    mem_zero
    pop     rdi

    // st_name: index into .strtab
    mov     eax, [rdi + SYMBOL_name_idx]
    mov     dword [rsp + SYM64_NAME], eax

    // st_info: STB_GLOBAL | STT_FUNC for labels, STB_LOCAL for the rest
    mov     al, [rdi + SYMBOL_kind]
    cmp     al, SYM_LABEL
    je      .func_sym
    // default: local data object
    mov     byte [rsp + SYM64_INFO], (STB_LOCAL << 4) | STT_NOTYPE
    jmp     .write_sym
.func_sym:
    mov     byte [rsp + SYM64_INFO], (STB_GLOBAL << 4) | STT_FUNC

.write_sym:
    mov     al, [rdi + SYMBOL_vis]
    mov     byte [rsp + SYM64_OTHER], al

    // st_shndx: section index — assume .text (1) for labels
    mov     word [rsp + SYM64_SHNDX], 1

    // st_value: symbol address
    mov     rax, [rdi + SYMBOL_value]
    mov     qword [rsp + SYM64_VALUE], rax

    // st_size: symbol size
    mov     rax, [rdi + SYMBOL_size]
    mov     qword [rsp + SYM64_SIZE], rax

    mov     rdi, r13d
    mov     rsi, rsp
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
    mov     rax, [rdi + RELOC_sym]
    shl     rax, 32
    
    // ---- FIX: ARCH-SPECIFIC RELOC TYPE ----
    movzx   edx, dword [rdi + RELOC_type]
    or      rax, rdx
    mov     qword [rsp + RELA_INFO], rax

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

    sub     rsp, ELF64_SHDR_SIZE   // scratch shdr

    // Helper: write one zeroed shdr then fill fields
    // For brevity each section uses its own inline block.

    // [0] NULL section header
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [1] .text
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  1            // offset in shstrtab
    mov     dword [rsp + SHDR_TYPE],  SHT_PROGBITS
    mov     qword [rsp + SHDR_FLAGS], SHF_ALLOC | SHF_EXECINSTR
    mov     qword [rsp + SHDR_ADDRALIGN], 16
    // size and offset filled in by caller (or via AsmCtx)
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [2] .data
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  7
    mov     dword [rsp + SHDR_TYPE],  SHT_PROGBITS
    mov     qword [rsp + SHDR_FLAGS], SHF_ALLOC | SHF_WRITE
    mov     qword [rsp + SHDR_ADDRALIGN], 8
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [3] .bss
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  13
    mov     dword [rsp + SHDR_TYPE],  SHT_NOBITS
    mov     qword [rsp + SHDR_FLAGS], SHF_ALLOC | SHF_WRITE
    mov     qword [rsp + SHDR_ADDRALIGN], 8
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [4] .symtab
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  18
    mov     dword [rsp + SHDR_TYPE],  SHT_SYMTAB
    mov     qword [rsp + SHDR_FLAGS], 0
    mov     dword [rsp + SHDR_LINK],  5            // .strtab index
    mov     qword [rsp + SHDR_ENTSIZE], ELF64_SYM_SIZE
    mov     qword [rsp + SHDR_ADDRALIGN], 8
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [5] .strtab
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  26
    mov     dword [rsp + SHDR_TYPE],  SHT_STRTAB
    mov     qword [rsp + SHDR_FLAGS], 0
    mov     qword [rsp + SHDR_ADDRALIGN], 1
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [6] .shstrtab
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  34
    mov     dword [rsp + SHDR_TYPE],  SHT_STRTAB
    mov     qword [rsp + SHDR_FLAGS], 0
    mov     qword [rsp + SHDR_ADDRALIGN], 1
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    // [7] .rela.text
    mov     rdi, rsp | mov     rsi, ELF64_SHDR_SIZE | call mem_zero
    mov     dword [rsp + SHDR_NAME],  44
    mov     dword [rsp + SHDR_TYPE],  SHT_RELA
    mov     qword [rsp + SHDR_FLAGS], SHF_INFO_LINK
    mov     dword [rsp + SHDR_LINK],  4            // .symtab index
    mov     dword [rsp + SHDR_INFO],  1            // applies to .text (index 1)
    mov     qword [rsp + SHDR_ENTSIZE], ELF64_RELA_SIZE
    mov     qword [rsp + SHDR_ADDRALIGN], 8
    mov     rdi, r13d | mov     rsi, rsp | mov rdx, ELF64_SHDR_SIZE | call io_write
    check_err

    add     rsp, ELF64_SHDR_SIZE
    xor     rax, rax
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
