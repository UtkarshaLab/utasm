%ifndef TYPE_S
%define TYPE_S

;
; ============================================
; File     : include/type.s
; Project  : utasm
; Author   : Utkarsha Lab
; License  : Apache-2.0
; Description: Core data ut_struc definitions using automatic offset calculation.
; ============================================
;

%include "include/macro.s"

%define TOK_COMMENT            0x20

; ============================================================================
; STRUCT: Token
; ============================================================================

ut_struc TOKEN
    ut_field tag,      1       ; always TAG_TOKEN
    ut_field kind,     1       ; TOK_* value
    ut_field flags,    1       ; reserved
    ut_field pad0,     5       ; alignment
    ut_field value,    8       ; pointer or integer
    ut_field line,     4       ; source line
    ut_field col,      2       ; source column
    ut_field len,      2       ; token length
    ut_field file,     8       ; filename pointer
ut_endstruc

; ============================================================================
; STRUCT: Arena
; ============================================================================

ut_struc ARENA
    ut_field tag,      1       ; always TAG_ARENA
    ut_field pad0,     7       ; alignment padding
    ut_field base,     8       ; start of arena memory
    ut_field ptr,      8       ; next free byte
    ut_field end,      8       ; end of arena memory
ut_endstruc

; ============================================================================
; STRUCT: Symbol
; ============================================================================

ut_struc SYMBOL
    ut_field tag,      1       ; always TAG_SYMBOL
    ut_field kind,     1       ; SYM_* value
    ut_field vis,      1       ; VIS_* value
    ut_field pad0,     5       ; alignment padding
    ut_field name,     8       ; pointer to name string
    ut_field value,    8       ; address or constant value
    ut_field size,     8       ; size in bytes
    ut_field section,  4       ; section index
    ut_field name_idx, 4       ; index into .strtab
    ut_field elf_idx,  4       ; final index in ELF .symtab
    ut_field line,     4       ; definition line
    ut_field file,     8       ; definition filename
ut_endstruc

; ============================================================================
; STRUCT: Section
; ============================================================================

ut_struc SECTION
    ut_field tag,      1       ; always TAG_SECTION
    ut_field type,     1       ; SEC_* internal type (was kind)
    ut_field flags,    2       ; SHF_* flags
    ut_field elf_type, 4       ; SHT_* ELF type
    ut_field name,     8       ; pointer to section name
    ut_field data,     8       ; pointer to content buffer
    ut_field size,     8       ; current size
    ut_field cap,      8       ; buffer capacity
    ut_field addr,     8       ; virtual address
    ut_field align,    8       ; required alignment
    ut_field index,    4       ; ELF section index
    ut_field group_flags, 4    ; GRP_COMDAT
    ut_field group_sig,   8    ; pointer to signature SYMBOL
    ut_field pad1,        8    ; maintain 16-byte alignment
ut_endstruc

; ============================================================================
; STRUCT: Relocation
; ============================================================================

ut_struc RELOC
    ut_field tag,         1       ; TAG_RELOC
    ut_field type,        1       ; RELOC_* value (Arch-specific)
    ut_field pad0,         2       ; alignment
    ut_field offset,      4       ; offset in binary section
    ut_field addend,      8       ; signed addend for RELA
    ut_field sym,         8       ; pointer to symbol name string
    ut_field section,     8       ; pointer to target section
    ut_field pc_adjust,   4       ; adjustment for PC-relative relocs
    ut_field pad1,         4       ; alignment padding
ut_endstruc

; ============================================================================
; STRUCT: IncludeCtx
; ============================================================================

ut_struc INCLUDECTX
    ut_field tag,      1       ; always TAG_INCLUDE_CTX
    ut_field depth,    1       ; nesting depth
    ut_field pad0,      6       ; alignment padding
    ut_field file,     8       ; filename pointer
    ut_field parent,   8       ; parent IncludeCtx
    ut_field buf,      8       ; file buffer
    ut_field size,     8       ; file size (for munmap)
    ut_field pos,      8       ; read position
    ut_field line,     4       ; current line
    ut_field pad1,     4       ; alignment padding
    ut_field lexer,    8       ; saved LexerState
ut_endstruc

; ============================================================================
; STRUCT: MacroDef
; ============================================================================

ut_struc MACRO
    ut_field tag,      1       ; always TAG_MACRO
    ut_field min_params, 1     ; minimum required parameters
    ut_field max_params, 1     ; maximum allowed parameters (0xFF = variadic)
    ut_field pad0,      5       ; alignment padding
    ut_field name,     8       ; macro name
    ut_field ntokens,  4       ; token count in body
    ut_field tokens,   8       ; pointer to token array
    ut_field pad1,     4       ; alignment padding
ut_endstruc

; ============================================================================
; STRUCT: MacroExpansion
; ============================================================================

ut_struc MACROEXP
    ut_field tag,      1       ; always TAG_MACRO_EXP
    ut_field depth,    1       ; nesting depth
    ut_field nparams,  1       ; parameter count
    ut_field rep_count, 4      ; repetitions remaining (for %rep)
    ut_field pad0,      1       ; alignment padding
    ut_field macro,    8       ; pointer to Macro symbol
    ut_field parent,   8       ; parent MacroExpansion
    ut_field params,   8       ; parameter string array
    ut_field body,     8       ; current body position
    ut_field line,     4       ; invocation line
    ut_field pad1,     4       ; alignment padding
ut_endstruc

; ============================================================================
; STRUCT: AsmCtx
; ============================================================================

ut_struc ASMCTX
    ut_field tag,         1       ; always TAG_ASM_CTX
    ut_field target,      1       ; TARGET_* value
    ut_field fmt,         1       ; FMT_* value
    ut_field opt,         1       ; OPT_* value
    ut_field err_count,   2       ; error counter
    ut_field warn_count,  2       ; warning counter
    ut_field arena,       8       ; pointer to Arena
    ut_field symtab,      8       ; pointer to symbol table
    ut_field symcount,    4       ; symbol count
    ut_field pad0,         4       ; alignment padding
    ut_field sections,    8       ; pointer to section array
    ut_field seccount,    4       ; section count
    ut_field group_count, 4       ; section group count
    ut_field relocs,      8       ; pointer to relocation array
    ut_field nrelocs,     4       ; relocation count
    ut_field inst_len,    4       ; current instruction length (0-15)
    ut_field debug_line,  4       ; current source line for DWARF
    ut_field debug_file,  4       ; current source file index for DWARF
    ut_field debug_col,   4       ; current source column for DWARF
    ut_field standalone,  1       ; 1 if generating standalone executable
    ut_field pad_sove,    7       ; alignment padding
    ut_field entry_point, 8       ; virtual address of entry point
    ut_field inc_ctx,     8       ; current IncludeCtx
    ut_field mac_exp,     8       ; current MacroExpansion
    ut_field input,       8       ; input filename
    ut_field output,      8       ; output filename
    ut_field ld_script,   8       ; linker script
    ut_field inc_paths,   8       ; include path array
    ut_field ninc_paths,  4       ; include path count
    ut_field flags,       4       ; CTX_FLAG_* values
    ut_field last_global, 8       ; pointer to string of last global label
    ut_field curr_sec,    8       ; pointer to current active SECTION
    ut_field total_lines, 8       ; total lines processed
    ut_field perf_start,  8       ; RDTSC start cycles
    ut_field perf_end,    8       ; RDTSC end cycles
    ut_field symhash,     8       ; pointer to symbol hash table (64k entries)
    ut_field expr_depth,  4       ; expression recursion depth sentinel
    ut_field mac_exp_id,  4       ; global macro expansion counter (A70)
    ut_field last_symbol, 8       ; pointer to last defined SYMBOL (for equ)
ut_endstruc

; ============================================================================
; STRUCT: LexerState
; ============================================================================

ut_struc LEXER
    ut_field tag,      1       ; always TAG_LEXER
    ut_field pad0,      7       ; alignment padding
    ut_field buf,      8       ; buffer start
    ut_field pos,      8       ; current position
    ut_field end,      8       ; buffer end
    ut_field file,     8       ; filename pointer
    ut_field line,     4       ; current line
    ut_field col,      2       ; current column
    ut_field pad1,     2       ; alignment padding
    ut_field peek,     TOKEN_SIZE ; inline token storage
    ut_field has_peek, 1       ; peek valid flag
    ut_field pad2,     7       ; alignment padding
    ut_field ctx,      8       ; pointer to AsmCtx
    ut_field arena,    8       ; pointer to Arena
ut_endstruc

; ============================================================================
; STRUCT: Archive
; ============================================================================
ut_struc ARCHIVE
    ut_field tag,          1       ; TAG_ARCHIVE
    ut_field pad0,         7       ; alignment padding
    ut_field buf,          8       ; pointer to mapped library
    ut_field size,         8       ; total size
    ut_field curr,         8       ; current iterator position
    ut_field symtab,       8       ; pointer to '/' member (symbols)
    ut_field strtab,       8       ; pointer to ';' member (long names)
    ut_field nmembers,     4       ; total members found
    ut_field pad1,         4       ; alignment padding
ut_endstruc

; ============================================================================
; STRUCT: PrepState
; ============================================================================

ut_struc PREP
    ut_field tag,          1       ; always TAG_PREPROCESSOR
    ut_field depth,        1       ; conditional depth
    ut_field skip_depth,   1       ; skipping depth
    ut_field has_peek,     1       ; TRUE if peek is valid
    ut_field mac_depth,    1       ; macro recursion depth (A83)
    ut_field pad0,         3       ; alignment padding
    ut_field line,         4       ; current source line
    ut_field col,          4       ; current source column
    ut_field peek,         TOKEN_SIZE ; peek buffer
    ut_field lexer,        8       ; current LexerState
    ut_field ctx,          8       ; pointer to AsmCtx
    ut_field arena,        8       ; pointer to Arena
ut_endstruc

; ============================================================================
; STRUCT: Operand
; ============================================================================

ut_struc OPERAND
    ut_field tag,      1       ; always TAG_OPERAND
    ut_field kind,     1       ; OP_* value
    ut_field size,     1       ; operand size
    ut_field reg,      1       ; register ID
    ut_field segment,  1       ; segment override (0x64, 0x65)
    ut_field is_high,  1       ; 1 if AH/CH/DH/BH
    ut_field mask,     1       ; AVX-512 k-register mask (0-7)
    ut_field ctrl,     1       ; AVX-512 rounding/broadcast control
    ut_field flags,    1       ; OP_FLAG_* value
    ut_field reloc,    4       ; relocation type (e.g. :lo12:)
    ut_field imm,      8       ; immediate or displacement
    ut_field base,     1       ; base register
    ut_field index,    1       ; index register
    ut_field scale,    1       ; scale factor
    ut_field pad0,     5       ; alignment padding
    ut_field sym,      8       ; pointer to Symbol
    ut_field shift_type, 1     ; AArch64 shift type (LSL, LSR, etc)
    ut_field shift_imm,  1     ; shift immediate amount
    ut_field pad1,      14      ; future reservation
ut_endstruc

; ============================================================================
; STRUCT: Instruction
; ============================================================================

ut_struc INST
    ut_field tag,       1       ; always TAG_INSTRUCTION
    ut_field op_id,     2       ; mnemonic ID
    ut_field prefixes,  4       ; instruction prefixes (up to 4 slots)
    ut_field nops,      1       ; operand count
    ut_field flags,     1       ; instruction flags
    ut_field op0,       OPERAND_SIZE
    ut_field op1,       OPERAND_SIZE
    ut_field op2,       OPERAND_SIZE
    ut_field op3,       OPERAND_SIZE
ut_endstruc

; ============================================================================
; STRUCT: PHDR (Elf64_Phdr)
; ============================================================================
ut_struc PHDR
    ut_field type,     4       ; segment type (PT_LOAD, etc)
    ut_field flags,    4       ; segment flags (PF_X | PF_W | PF_R)
    ut_field offset,   8       ; file offset
    ut_field vaddr,    8       ; virtual address
    ut_field paddr,    8       ; physical address
    ut_field filesz,   8       ; size in file
    ut_field memsz,    8       ; size in memory
    ut_field align,    8       ; alignment
ut_endstruc

%endif
