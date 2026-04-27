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

// ============================================================================
// TYPE TAGS
// ============================================================================
// Every struct in utasm has a 1-byte type tag at offset 0.
// Always check the tag before accessing any other field.

%def TAG_TOKEN              0x01
%def TAG_SYMBOL             0x02
%def TAG_SECTION            0x03
%def TAG_RELOC              0x04
%def TAG_MACRO              0x05
%def TAG_MACRO_EXP          0x06
%def TAG_INCLUDE_CTX        0x07
%def TAG_ASM_CTX            0x08
%def TAG_ARENA              0x09
%def TAG_LEXER              0x0A
%def TAG_PREPROCESSOR       0x0B
%def TAG_OPERAND            0x0C
%def TAG_INSTRUCTION        0x0D

// ============================================================================
// TOKEN TYPES
// ============================================================================

%def TOK_UNKNOWN            0x00
%def TOK_EOF                0x01
%def TOK_NEWLINE            0x02
%def TOK_IDENT              0x03
%def TOK_NUMBER             0x04
%def TOK_STRING             0x05
%def TOK_CHAR               0x06
%def TOK_LABEL              0x07
%def TOK_LOCAL_LABEL        0x08
%def TOK_REGISTER           0x09
%def TOK_COMMA              0x0A
%def TOK_COLON              0x0B
%def TOK_LBRACKET           0x0C
%def TOK_RBRACKET           0x0D
%def TOK_LBRACE             0x0E
%def TOK_RBRACE             0x0F
%def TOK_LPAREN             0x10
%def TOK_RPAREN             0x11
%def TOK_PLUS               0x12
%def TOK_MINUS              0x13
%def TOK_STAR               0x14
%def TOK_SLASH              0x15
%def TOK_PERCENT            0x16
%def TOK_AMPERSAND          0x17
%def TOK_PIPE               0x18
%def TOK_CARET              0x19
%def TOK_TILDE              0x1A
%def TOK_LSHIFT             0x1B
%def TOK_RSHIFT             0x1C
%def TOK_HASH               0x1D
%def TOK_AT                 0x1E
%def TOK_DIRECTIVE          0x1F
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

%def SYM_UNKNOWN            0x00
%def SYM_LABEL              0x01
%def SYM_DATA               0x02
%def SYM_CONSTANT           0x03
%def SYM_MACRO              0x04
%def SYM_EXTERN             0x05
%def SYM_SECTION            0x06

%def VIS_LOCAL              0x00
%def VIS_GLOBAL             0x01

struc SYMBOL
    field tag,      1       // always TAG_SYMBOL
    field kind,     1       // SYM_* value
    field vis,      1       // VIS_* value
    field pad0,     5       // alignment padding
    field name,     8       // pointer to name string
    field value,    8       // address or constant value
    field size,     8       // size in bytes
    field section,  4       // section index
    field line,     4       // definition line
    field file,     8       // definition filename
endstruc

// ============================================================================
// STRUCT: Section
// ============================================================================

%def SEC_TEXT               0x01
%def SEC_DATA               0x02
%def SEC_BSS                0x03
%def SEC_RODATA             0x04
%def SEC_CUSTOM             0x05

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

%def RELOC_ABS64            0x01
%def RELOC_REL32            0x02
%def RELOC_REL64            0x03
%def RELOC_GOT              0x04

struc RELOC
    field tag,         1       // TAG_RELOC
    field type,        1       // RELOC_* value
    field pad0,         2       // alignment
    field offset,      4       // offset in binary section
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
    field nparams,  1       // parameter count
    field pad0,      6       // alignment padding
    field name,     8       // macro name
    field tokens,   8       // pointer to token array
    field ntokens,  4       // number of tokens
    field pad1,     4       // alignment padding
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
    field inc_ctx,     8       // current IncludeCtx
    field mac_exp,     8       // current MacroExpansion
    field input,       8       // input filename
    field output,      8       // output filename
    field ld_script,   8       // linker script
    field inc_paths,   8       // include path array
    field ninc_paths,  4       // include path count
    field flags,       4       // CTX_FLAG_* values
    field pad2,        24      // future reservation
endstruc

%def CTX_FLAG_DEBUG         0x01
%def CTX_FLAG_VERBOSE       0x02
%def CTX_FLAG_WERROR        0x04
%def CTX_FLAG_COLOR         0x08
%def CTX_FLAG_LISTING       0x10
%def CTX_FLAG_MAPFILE       0x20
%def CTX_FLAG_STRIP         0x40

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

%def OP_NONE                0x00
%def OP_REG                 0x01
%def OP_IMM                 0x02
%def OP_MEM                 0x03
%def OP_SYMBOL              0x04

struc OPERAND
    field tag,      1       // always TAG_OPERAND
    field kind,     1       // OP_* value
    field size,     1       // operand size
    field reg,      1       // register ID
    field segment,  1       // segment override (0x64, 0x65)
    field is_high,  1       // 1 if AH/CH/DH/BH
    field mask,     1       // AVX-512 k-register mask (0-7)
    field ctrl,     1       // AVX-512 rounding/broadcast control
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
    field pad0,       2       // alignment padding
    field op0,       OPERAND_SIZE
    field op1,       OPERAND_SIZE
    field op2,       OPERAND_SIZE
    field pad1,      8       // alignment padding
endstruc
