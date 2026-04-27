/*
 ============================================
 File     : include/type.s
 Project  : utasm
 Version  : 0.1.0
 Author   : Utkarsha Lab
 License  : Apache-2.0
 Description: Core data structure definitions using automatic offset calculation.
 ============================================
*/

%inc "include/macro.s"

%def TOK_COMMENT            0x20

// ============================================================================
// STRUCT: Token
// ============================================================================

struc TOKEN
    field tag,      1       // always TAG_TOKEN
    field kind,     1       // TOK_* value
    field flags,    1       // reserved
    field pad0,     5       // alignment
    field value,    8       // pointer or integer
    field line,     4       // source line
    field col,      2       // source column
    field len,      2       // token length
    field file,     8       // filename pointer
endstruc

// ============================================================================
// STRUCT: Arena
// ============================================================================

struc ARENA
    field tag,      1       // always TAG_ARENA
    field pad0,     7       // alignment padding
    field base,     8       // start of arena memory
    field ptr,      8       // next free byte
    field end,      8       // end of arena memory
endstruc

// ============================================================================
// STRUCT: Symbol
// ============================================================================

struc SYMBOL
    field tag,      1       // always TAG_SYMBOL
    field kind,     1       // SYM_* value
    field vis,      1       // VIS_* value
    field pad0,     5       // alignment padding
    field name,     8       // pointer to name string
    field value,    8       // address or constant value
    field size,     8       // size in bytes
    field section,  4       // section index
    field name_idx, 4       // index into .strtab
    field line,     4       // definition line
    field file,     8       // definition filename
endstruc

// ============================================================================
// STRUCT: Section
// ============================================================================

struc SECTION
    field tag,      1       // always TAG_SECTION
    field type,     1       // SEC_* value
    field flags,    2       // SHF_* flags
    field pad0,      4       // alignment padding
    field name,     8       // pointer to section name
    field data,     8       // pointer to content buffer
    field size,     8       // current size
    field cap,      8       // buffer capacity
    field addr,     8       // virtual address
    field align,    8       // required alignment
    field index,    4       // ELF section index
    field pad1,     4       // alignment padding
endstruc

// ============================================================================
// STRUCT: Relocation
// ============================================================================

struc RELOC
    field tag,         1       // TAG_RELOC
    field type,        1       // RELOC_* value
    field pad0,         2       // alignment
    field offset,      4       // offset in binary section
    field pc_adjust,   4       // adjustment for PC-relative relocs
    field symbol,      8       // pointer to symbol name string
    field section,     8       // pointer to target section
endstruc

// ============================================================================
// STRUCT: IncludeCtx
// ============================================================================

struc INCLUDECTX
    field tag,      1       // always TAG_INCLUDE_CTX
    field depth,    1       // nesting depth
    field pad0,      6       // alignment padding
    field file,     8       // filename pointer
    field parent,   8       // parent IncludeCtx
    field buf,      8       // file buffer
    field size,     8       // file size (for munmap)
    field pos,      8       // read position
    field line,     4       // current line
    field pad1,     4       // alignment padding
    field lexer,    8       // saved LexerState
endstruc

// ============================================================================
// STRUCT: MacroDef
// ============================================================================

struc MACRO
    field tag,      1       // always TAG_MACRO
    field min_params, 1     // minimum required parameters
    field max_params, 1     // maximum allowed parameters (0xFF = variadic)
    field pad0,      5       // alignment padding
    field name,     8       // macro name
    field ntokens,  4       // token count in body
    field tokens,   8       // pointer to token array
    field pad1,     4       // alignment padding
endstruc
endstruc

// ============================================================================
// STRUCT: MacroExpansion
// ============================================================================

struc MACROEXP
    field tag,      1       // always TAG_MACRO_EXP
    field depth,    1       // nesting depth
    field nparams,  1       // parameter count
    field pad0,      5       // alignment padding
    field macro,    8       // pointer to Macro symbol
    field parent,   8       // parent MacroExpansion
    field params,   8       // parameter string array
    field body,     8       // current body position
    field line,     4       // invocation line
    field pad1,     4       // alignment padding
endstruc

// ============================================================================
// STRUCT: AsmCtx
// ============================================================================

struc ASMCTX
    field tag,         1       // always TAG_ASM_CTX
    field target,      1       // TARGET_* value
    field fmt,         1       // FMT_* value
    field opt,         1       // OPT_* value
    field err_count,   2       // error counter
    field warn_count,  2       // warning counter
    field arena,       8       // pointer to Arena
    field symtab,      8       // pointer to symbol table
    field symcount,    4       // symbol count
    field pad0,         4       // alignment padding
    field sections,    8       // pointer to section array
    field seccount,    4       // section count
    field relocs,      8       // pointer to relocation array
    field nrelocs,     4       // relocation count
    field inst_len,    4       // current instruction length (0-15)
    field debug_line,  4       // current source line for DWARF
    field debug_file,  4       // current source file index for DWARF
    field debug_col,   4       // current source column for DWARF
    field standalone,  1       // 1 if generating standalone executable
    field pad_sove,    7       // alignment padding
    field entry_point, 8       // virtual address of entry point
    field inc_ctx,     8       // current IncludeCtx
    field mac_exp,     8       // current MacroExpansion
    field input,       8       // input filename
    field output,      8       // output filename
    field ld_script,   8       // linker script
    field inc_paths,   8       // include path array
    field ninc_paths,  4       // include path count
    field flags,       4       // CTX_FLAG_* values
    field last_global, 8       // pointer to string of last global label
    field curr_sec,    8       // pointer to current active SECTION
    field total_lines, 8       // total lines processed
    field perf_start,  8       // RDTSC start cycles
    field perf_end,    8       // RDTSC end cycles
    field symhash,     8       // pointer to symbol hash table (64k entries)
    field pad2,        8       // future reservation
endstruc

// ============================================================================
// STRUCT: LexerState
// ============================================================================

struc LEXER
    field tag,      1       // always TAG_LEXER
    field pad0,      7       // alignment padding
    field buf,      8       // buffer start
    field pos,      8       // current position
    field end,      8       // buffer end
    field file,     8       // filename pointer
    field line,     4       // current line
    field col,      2       // current column
    field pad1,     2       // alignment padding
    field peek,     TOKEN_SIZE // inline token storage
    field has_peek, 1       // peek valid flag
    field pad2,     7       // alignment padding
    field ctx,      8       // pointer to AsmCtx
    field arena,    8       // pointer to Arena
endstruc

// ============================================================================
// STRUCT: PrepState
// ============================================================================

struc PREP
    field tag,          1       // always TAG_PREPROCESSOR
    field depth,        1       // conditional depth
    field skip_depth,   1       // skipping depth
    field has_peek,     1       // TRUE if peek is valid
    field pad0,         4       // alignment padding
    field peek,         TOKEN_SIZE // peek buffer
    field lexer,        8       // current LexerState
    field ctx,          8       // pointer to AsmCtx
    field arena,        8       // pointer to Arena
endstruc

// ============================================================================
// STRUCT: Operand
// ============================================================================

struc OPERAND
    field tag,      1       // always TAG_OPERAND
    field kind,     1       // OP_* value
    field size,     1       // operand size
    field reg,      1       // register ID
    field segment,  1       // segment override (0x64, 0x65)
    field is_high,  1       // 1 if AH/CH/DH/BH
    field mask,     1       // AVX-512 k-register mask (0-7)
    field ctrl,     1       // AVX-512 rounding/broadcast control
    field reloc,    4       // relocation type (e.g. :lo12:)
    field imm,      8       // immediate or displacement
    field base,     1       // base register
    field index,    1       // index register
    field scale,    1       // scale factor
    field pad0,     5       // alignment padding
    field sym,      8       // pointer to Symbol
    field pad1,     16      // future reservation
endstruc

// ============================================================================
// STRUCT: Instruction
// ============================================================================

struc INST
    field tag,       1       // always TAG_INSTRUCTION
    field op_id,     2       // mnemonic ID
    field prefix,    1       // instruction prefix (e.g. 0xF3)
    field nops,      1       // operand count
    field flags,     1       // instruction flags
    field pad0,      1       // alignment padding
    field op0,       OPERAND_SIZE
    field op1,       OPERAND_SIZE
    field op2,       OPERAND_SIZE
    field op3,       OPERAND_SIZE
endstruc

// ============================================================================
// STRUCT: PHDR (Elf64_Phdr)
// ============================================================================
struc PHDR
    field type,     4       // segment type (PT_LOAD, etc)
    field flags,    4       // segment flags (PF_X | PF_W | PF_R)
    field offset,   8       // file offset
    field vaddr,    8       // virtual address
    field paddr,    8       // physical address
    field filesz,   8       // size in file
    field memsz,    8       // size in memory
    field align,    8       // alignment
endstruc
