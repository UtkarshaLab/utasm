%ifndef TYPE_S
%define TYPE_S

;
; ============================================
; File     : include/type.s
; Project  : utasm
; Author   : Utkarsha Lab
; License  : Apache-2.0
; Description: Core data zenith_struc definitions using automatic offset calculation.
; ============================================
;

%include "include/macro.s"

%define TOK_COMMENT            0x20

; ============================================================================
; STRUCT: Token
; ============================================================================

zenith_struc TOKEN
    zenith_field tag,      1       ; always TAG_TOKEN
    zenith_field kind,     1       ; TOK_* value
    zenith_field flags,    1       ; reserved
    zenith_field pad0,     5       ; alignment
    zenith_field value,    8       ; pointer or integer
    zenith_field line,     4       ; source line
    zenith_field col,      2       ; source column
    zenith_field len,      2       ; token length
    zenith_field file,     8       ; filename pointer
zenith_endstruc

; ============================================================================
; STRUCT: Arena
; ============================================================================

zenith_struc ARENA
    zenith_field tag,      1       ; always TAG_ARENA
    zenith_field pad0,     7       ; alignment padding
    zenith_field base,     8       ; start of arena memory
    zenith_field ptr,      8       ; next free byte
    zenith_field end,      8       ; end of arena memory
zenith_endstruc

; ============================================================================
; STRUCT: Symbol
; ============================================================================

zenith_struc SYMBOL
    zenith_field tag,      1       ; always TAG_SYMBOL
    zenith_field kind,     1       ; SYM_* value
    zenith_field vis,      1       ; VIS_* value
    zenith_field pad0,     5       ; alignment padding
    zenith_field name,     8       ; pointer to name string
    zenith_field value,    8       ; address or constant value
    zenith_field size,     8       ; size in bytes
    zenith_field section,  4       ; section index
    zenith_field name_idx, 4       ; index into .strtab
    zenith_field elf_idx,  4       ; final index in ELF .symtab
    zenith_field line,     4       ; definition line
    zenith_field file,     8       ; definition filename
zenith_endstruc

; ============================================================================
; STRUCT: Section
; ============================================================================

zenith_struc SECTION
    zenith_field tag,      1       ; always TAG_SECTION
    zenith_field type,     1       ; SEC_* internal type (was kind)
    zenith_field flags,    2       ; SHF_* flags
    zenith_field elf_type, 4       ; SHT_* ELF type
    zenith_field name,     8       ; pointer to section name
    zenith_field data,     8       ; pointer to content buffer
    zenith_field size,     8       ; current size
    zenith_field cap,      8       ; buffer capacity
    zenith_field addr,     8       ; virtual address
    zenith_field align,    8       ; required alignment
    zenith_field index,    4       ; ELF section index
    zenith_field group_flags, 4    ; GRP_COMDAT
    zenith_field group_sig,   8    ; pointer to signature SYMBOL
    zenith_field pad1,        8    ; maintain 16-byte alignment
zenith_endstruc

; ============================================================================
; STRUCT: Relocation
; ============================================================================

zenith_struc RELOC
    zenith_field tag,         1       ; TAG_RELOC
    zenith_field type,        1       ; RELOC_* value (Arch-specific)
    zenith_field pad0,         2       ; alignment
    zenith_field offset,      4       ; offset in binary section
    zenith_field addend,      8       ; signed addend for RELA
    zenith_field sym,         8       ; pointer to symbol name string
    zenith_field section,     8       ; pointer to target section
    zenith_field pc_adjust,   4       ; adjustment for PC-relative relocs
    zenith_field pad1,         4       ; alignment padding
zenith_endstruc

; ============================================================================
; STRUCT: IncludeCtx
; ============================================================================

zenith_struc INCLUDECTX
    zenith_field tag,      1       ; always TAG_INCLUDE_CTX
    zenith_field depth,    1       ; nesting depth
    zenith_field pad0,      6       ; alignment padding
    zenith_field file,     8       ; filename pointer
    zenith_field parent,   8       ; parent IncludeCtx
    zenith_field buf,      8       ; file buffer
    zenith_field size,     8       ; file size (for munmap)
    zenith_field pos,      8       ; read position
    zenith_field line,     4       ; current line
    zenith_field pad1,     4       ; alignment padding
    zenith_field lexer,    8       ; saved LexerState
zenith_endstruc

; ============================================================================
; STRUCT: MacroDef
; ============================================================================

zenith_struc MACRO
    zenith_field tag,      1       ; always TAG_MACRO
    zenith_field min_params, 1     ; minimum required parameters
    zenith_field max_params, 1     ; maximum allowed parameters (0xFF = variadic)
    zenith_field pad0,      5       ; alignment padding
    zenith_field name,     8       ; macro name
    zenith_field ntokens,  4       ; token count in body
    zenith_field tokens,   8       ; pointer to token array
    zenith_field pad1,     4       ; alignment padding
zenith_endstruc

; ============================================================================
; STRUCT: MacroExpansion
; ============================================================================

zenith_struc MACROEXP
    zenith_field tag,      1       ; always TAG_MACRO_EXP
    zenith_field depth,    1       ; nesting depth
    zenith_field nparams,  1       ; parameter count
    zenith_field rep_count, 4      ; repetitions remaining (for %rep)
    zenith_field pad0,      1       ; alignment padding
    zenith_field macro,    8       ; pointer to Macro symbol
    zenith_field parent,   8       ; parent MacroExpansion
    zenith_field params,   8       ; parameter string array
    zenith_field body,     8       ; current body position
    zenith_field line,     4       ; invocation line
    zenith_field pad1,     4       ; alignment padding
zenith_endstruc

; ============================================================================
; STRUCT: AsmCtx
; ============================================================================

zenith_struc ASMCTX
    zenith_field tag,         1       ; always TAG_ASM_CTX
    zenith_field target,      1       ; TARGET_* value
    zenith_field fmt,         1       ; FMT_* value
    zenith_field opt,         1       ; OPT_* value
    zenith_field err_count,   2       ; error counter
    zenith_field warn_count,  2       ; warning counter
    zenith_field arena,       8       ; pointer to Arena
    zenith_field symtab,      8       ; pointer to symbol table
    zenith_field symcount,    4       ; symbol count
    zenith_field pad0,         4       ; alignment padding
    zenith_field sections,    8       ; pointer to section array
    zenith_field seccount,    4       ; section count
    zenith_field group_count, 4       ; section group count
    zenith_field relocs,      8       ; pointer to relocation array
    zenith_field nrelocs,     4       ; relocation count
    zenith_field inst_len,    4       ; current instruction length (0-15)
    zenith_field debug_line,  4       ; current source line for DWARF
    zenith_field debug_file,  4       ; current source file index for DWARF
    zenith_field debug_col,   4       ; current source column for DWARF
    zenith_field standalone,  1       ; 1 if generating standalone executable
    zenith_field pad_sove,    7       ; alignment padding
    zenith_field entry_point, 8       ; virtual address of entry point
    zenith_field inc_ctx,     8       ; current IncludeCtx
    zenith_field mac_exp,     8       ; current MacroExpansion
    zenith_field input,       8       ; input filename
    zenith_field output,      8       ; output filename
    zenith_field ld_script,   8       ; linker script
    zenith_field inc_paths,   8       ; include path array
    zenith_field ninc_paths,  4       ; include path count
    zenith_field flags,       4       ; CTX_FLAG_* values
    zenith_field last_global, 8       ; pointer to string of last global label
    zenith_field curr_sec,    8       ; pointer to current active SECTION
    zenith_field total_lines, 8       ; total lines processed
    zenith_field perf_start,  8       ; RDTSC start cycles
    zenith_field perf_end,    8       ; RDTSC end cycles
    zenith_field symhash,     8       ; pointer to symbol hash table (64k entries)
    zenith_field expr_depth,  4       ; expression recursion depth sentinel
    zenith_field mac_exp_id,  4       ; global macro expansion counter (A70)
    zenith_field last_symbol, 8       ; pointer to last defined SYMBOL (for equ)
zenith_endstruc

; ============================================================================
; STRUCT: LexerState
; ============================================================================

zenith_struc LEXER
    zenith_field tag,      1       ; always TAG_LEXER
    zenith_field pad0,      7       ; alignment padding
    zenith_field buf,      8       ; buffer start
    zenith_field pos,      8       ; current position
    zenith_field end,      8       ; buffer end
    zenith_field file,     8       ; filename pointer
    zenith_field line,     4       ; current line
    zenith_field col,      2       ; current column
    zenith_field pad1,     2       ; alignment padding
    zenith_field peek,     TOKEN_SIZE ; inline token storage
    zenith_field has_peek, 1       ; peek valid flag
    zenith_field pad2,     7       ; alignment padding
    zenith_field ctx,      8       ; pointer to AsmCtx
    zenith_field arena,    8       ; pointer to Arena
zenith_endstruc

; ============================================================================
; STRUCT: Archive
; ============================================================================
zenith_struc ARCHIVE
    zenith_field tag,          1       ; TAG_ARCHIVE
    zenith_field pad0,         7       ; alignment padding
    zenith_field buf,          8       ; pointer to mapped library
    zenith_field size,         8       ; total size
    zenith_field curr,         8       ; current iterator position
    zenith_field symtab,       8       ; pointer to '/' member (symbols)
    zenith_field strtab,       8       ; pointer to ';' member (long names)
    zenith_field nmembers,     4       ; total members found
    zenith_field pad1,         4       ; alignment padding
zenith_endstruc

; ============================================================================
; STRUCT: PrepState
; ============================================================================

zenith_struc PREP
    zenith_field tag,          1       ; always TAG_PREPROCESSOR
    zenith_field depth,        1       ; conditional depth
    zenith_field skip_depth,   1       ; skipping depth
    zenith_field has_peek,     1       ; TRUE if peek is valid
    zenith_field mac_depth,    1       ; macro recursion depth (A83)
    zenith_field pad0,         3       ; alignment padding
    zenith_field line,         4       ; current source line
    zenith_field col,          4       ; current source column
    zenith_field peek,         TOKEN_SIZE ; peek buffer
    zenith_field lexer,        8       ; current LexerState
    zenith_field ctx,          8       ; pointer to AsmCtx
    zenith_field arena,        8       ; pointer to Arena
zenith_endstruc

; ============================================================================
; STRUCT: Operand
; ============================================================================

zenith_struc OPERAND
    zenith_field tag,      1       ; always TAG_OPERAND
    zenith_field kind,     1       ; OP_* value
    zenith_field size,     1       ; operand size
    zenith_field reg,      1       ; register ID
    zenith_field segment,  1       ; segment override (0x64, 0x65)
    zenith_field is_high,  1       ; 1 if AH/CH/DH/BH
    zenith_field mask,     1       ; AVX-512 k-register mask (0-7)
    zenith_field ctrl,     1       ; AVX-512 rounding/broadcast control
    zenith_field flags,    1       ; OP_FLAG_* value
    zenith_field reloc,    4       ; relocation type (e.g. :lo12:)
    zenith_field imm,      8       ; immediate or displacement
    zenith_field base,     1       ; base register
    zenith_field index,    1       ; index register
    zenith_field scale,    1       ; scale factor
    zenith_field pad0,     5       ; alignment padding
    zenith_field sym,      8       ; pointer to Symbol
    zenith_field shift_type, 1     ; AArch64 shift type (LSL, LSR, etc)
    zenith_field shift_imm,  1     ; shift immediate amount
    zenith_field pad1,      14      ; future reservation
zenith_endstruc

; ============================================================================
; STRUCT: Instruction
; ============================================================================

zenith_struc INST
    zenith_field tag,       1       ; always TAG_INSTRUCTION
    zenith_field op_id,     2       ; mnemonic ID
    zenith_field prefixes,  4       ; instruction prefixes (up to 4 slots)
    zenith_field nops,      1       ; operand count
    zenith_field flags,     1       ; instruction flags
    zenith_field op0,       OPERAND_SIZE
    zenith_field op1,       OPERAND_SIZE
    zenith_field op2,       OPERAND_SIZE
    zenith_field op3,       OPERAND_SIZE
zenith_endstruc

; ============================================================================
; STRUCT: PHDR (Elf64_Phdr)
; ============================================================================
zenith_struc PHDR
    zenith_field type,     4       ; segment type (PT_LOAD, etc)
    zenith_field flags,    4       ; segment flags (PF_X | PF_W | PF_R)
    zenith_field offset,   8       ; file offset
    zenith_field vaddr,    8       ; virtual address
    zenith_field paddr,    8       ; physical address
    zenith_field filesz,   8       ; size in file
    zenith_field memsz,    8       ; size in memory
    zenith_field align,    8       ; alignment
zenith_endstruc

%endif
