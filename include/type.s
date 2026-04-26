/*
 ============================================
 File     : include/type.s
 Project  : utasm
 Version  : 0.0.1
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

// ============================================================================
// TYPE TAGS
// ============================================================================
// Every struct in utasm has a 1-byte type tag at offset 0.
// Always check the tag before accessing any other field.
// This is our Rust-style tagged union discipline.

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


// ============================================================================
// STRUCT: LexerState
// ============================================================================
// Complete state of the lexer for one source file.
// Passed to every lexer function.
// Size: 104 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag       1 byte   always TAG_LEXER
//   +1   pad       7 bytes  alignment padding
//   +8   buf       8 bytes  pointer to source file buffer
//   +16  pos       8 bytes  current read position in buffer
//   +24  end       8 bytes  pointer to one byte past end of buffer
//   +32  file      8 bytes  pointer to source filename string
//   +40  line      4 bytes  current line number (1-based)
//   +44  col       2 bytes  current column number (1-based)
//   +46  pad2      2 bytes  alignment padding
//   +48  peek      32 bytes TOKEN_SIZE inline token storage
//   +80  has_peek  1 byte   TRUE if peek slot is valid
//   +81  pad3      7 bytes  alignment padding
//   +88  ctx       8 bytes  pointer to AsmCtx
//   +96  arena     8 bytes  pointer to Arena
// Total: 104 bytes

%def LEXER_tag              0       // offset of tag field
%def LEXER_buf              8       // offset of buffer pointer
%def LEXER_pos              16      // offset of current position
%def LEXER_end              24      // offset of end pointer
%def LEXER_file             32      // offset of filename pointer
%def LEXER_line             40      // offset of line number
%def LEXER_col              44      // offset of column number
%def LEXER_peek             48      // offset of inline peek token
%def LEXER_has_peek         80      // offset of peek valid flag
%def LEXER_ctx              88      // offset of AsmCtx pointer
%def LEXER_arena            96      // offset of Arena pointer
%def LEXER_SIZE             104     // total struct size

// ============================================================================
// TOKEN TYPES
// ============================================================================
// Classification of every token produced by the lexer.
// Stored in Token.kind field.

%def TOK_UNKNOWN            0x00    // unrecognized token
%def TOK_EOF                0x01    // end of input stream
%def TOK_NEWLINE            0x02    // line terminator
%def TOK_IDENT              0x03    // identifier or mnemonic
%def TOK_NUMBER             0x04    // numeric literal
%def TOK_STRING             0x05    // quoted string literal
%def TOK_CHAR               0x06    // character literal
%def TOK_LABEL              0x07    // label definition (ends with :)
%def TOK_LOCAL_LABEL        0x08    // local label (starts with .)
%def TOK_REGISTER           0x09    // register name
%def TOK_COMMA              0x0A    // ,
%def TOK_COLON              0x0B    // :
%def TOK_LBRACKET           0x0C    // [
%def TOK_RBRACKET           0x0D    // ]
%def TOK_LBRACE             0x0E    // {
%def TOK_RBRACE             0x0F    // }
%def TOK_LPAREN             0x10    // (
%def TOK_RPAREN             0x11    // )
%def TOK_PLUS               0x12    // +
%def TOK_MINUS              0x13    // -
%def TOK_STAR               0x14    // *
%def TOK_SLASH              0x15    // /
%def TOK_PERCENT            0x16    // %
%def TOK_AMPERSAND          0x17    // &
%def TOK_PIPE               0x18    // |
%def TOK_CARET              0x19    // ^
%def TOK_TILDE              0x1A    // ~
%def TOK_LSHIFT             0x1B    // 
%def TOK_RSHIFT             0x1C    // >>
%def TOK_HASH               0x1D    // # immediate prefix
%def TOK_AT                 0x1E    // @ symbol prefix
%def TOK_DIRECTIVE          0x1F    // assembler directive
%def TOK_COMMENT            0x20    // comment (usually discarded)

// ============================================================================
// SYMBOL TYPES
// ============================================================================
// Classification of entries in the symbol table.
// Stored in Symbol.kind field.

%def SYM_UNKNOWN            0x00    // unresolved or unknown
%def SYM_LABEL              0x01    // code label
%def SYM_DATA               0x02    // data label
%def SYM_CONSTANT           0x03    // %def constant
%def SYM_MACRO              0x04    // macro definition
%def SYM_EXTERN             0x05    // external reference
%def SYM_SECTION            0x06    // section name

// ============================================================================
// SYMBOL VISIBILITY
// ============================================================================
// Scope of a symbol — local to file or globally exported.

%def VIS_LOCAL              0x00    // visible within file only
%def VIS_GLOBAL             0x01    // exported to linker

// ============================================================================
// SECTION TYPES
// ============================================================================

%def SEC_TEXT               0x01    // executable code
%def SEC_DATA               0x02    // initialized data
%def SEC_BSS                0x03    // uninitialized data
%def SEC_RODATA             0x04    // read-only data
%def SEC_CUSTOM             0x05    // user-defined section

// ============================================================================
// RELOCATION TYPES
// ============================================================================

%def RELOC_ABS64            0x01    // absolute 64-bit address
%def RELOC_REL32            0x02    // PC-relative 32-bit offset
%def RELOC_REL64            0x03    // PC-relative 64-bit offset
%def RELOC_GOT              0x04    // GOT-relative reference

// ============================================================================
// STRUCT: Token
// ============================================================================
// Produced by the lexer. Consumed by the parser and preprocessor.
// Size: 32 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_TOKEN
//   +1   kind    1 byte   TOK_* value
//   +2   flags   1 byte   reserved for future use
//   +3   pad     5 bytes  alignment padding
//   +8   value   8 bytes  pointer to string or raw integer value
//   +16  line    4 bytes  source line number (1-based)
//   +20  col     2 bytes  source column number (1-based)
//   +22  len     2 bytes  token length in bytes
//   +24  file    8 bytes  pointer to source filename string
// Total: 32 bytes

%def TOKEN_tag              0       // offset of tag field
%def TOKEN_kind             1       // offset of kind field
%def TOKEN_flags            2       // offset of flags field
%def TOKEN_value            8       // offset of value field
%def TOKEN_line             16      // offset of line number
%def TOKEN_col              20      // offset of column number
%def TOKEN_len              22      // offset of token length
%def TOKEN_file             24      // offset of filename pointer
%def TOKEN_SIZE             32      // total struct size

// ============================================================================
// STRUCT: Symbol
// ============================================================================
// One entry in the symbol table.
// Size: 48 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_SYMBOL
//   +1   kind    1 byte   SYM_* value
//   +2   vis     1 byte   VIS_LOCAL or VIS_GLOBAL
//   +3   pad     5 bytes  alignment padding
//   +8   name    8 bytes  pointer to null-terminated name string
//   +16  value   8 bytes  address or constant value
//   +24  size    8 bytes  size in bytes (for data symbols)
//   +32  section 4 bytes  section index this symbol belongs to
//   +36  line    4 bytes  source line where defined
//   +40  file    8 bytes  pointer to source filename string
// Total: 48 bytes

%def SYMBOL_tag             0       // offset of tag field
%def SYMBOL_kind            1       // offset of kind field
%def SYMBOL_vis             2       // offset of visibility field
%def SYMBOL_name            8       // offset of name pointer
%def SYMBOL_value           16      // offset of value field
%def SYMBOL_size            24      // offset of size field
%def SYMBOL_section         32      // offset of section index
%def SYMBOL_line            36      // offset of line number
%def SYMBOL_file            40      // offset of filename pointer
%def SYMBOL_SIZE            48      // total struct size

// ============================================================================
// STRUCT: Section
// ============================================================================
// Represents one output section (.text, .data, .bss, etc.)
// Size: 64 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_SECTION
//   +1   type    1 byte   SEC_* value
//   +2   flags   2 bytes  SHF_* permission flags
//   +4   pad     4 bytes  alignment padding
//   +8   name    8 bytes  pointer to section name string
//   +16  data    8 bytes  pointer to section content buffer
//   +24  size    8 bytes  current section size in bytes
//   +32  cap     8 bytes  buffer capacity in bytes
//   +40  addr    8 bytes  virtual address assigned by linker
//   +48  align   8 bytes  required alignment in bytes
//   +56  index   4 bytes  section index in ELF output
//   +60  pad2    4 bytes  alignment padding
// Total: 64 bytes

%def SECTION_tag            0       // offset of tag field
%def SECTION_type           1       // offset of type field
%def SECTION_flags          2       // offset of flags field
%def SECTION_name           8       // offset of name pointer
%def SECTION_data           16      // offset of data pointer
%def SECTION_size           24      // offset of size field
%def SECTION_cap            32      // offset of capacity field
%def SECTION_addr           40      // offset of virtual address
%def SECTION_align          48      // offset of alignment
%def SECTION_index          56      // offset of section index
%def SECTION_SIZE           64      // total struct size

// ============================================================================
// STRUCT: Relocation
// ============================================================================
// One relocation entry — a symbol reference that the linker must patch.
// Size: 32 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_RELOC
//   +1   type    1 byte   RELOC_* value
//   +2   pad     6 bytes  alignment padding
//   +8   offset  8 bytes  offset within section where patch applies
//   +16  symbol  8 bytes  pointer to Symbol being referenced
//   +24  addend  8 bytes  signed addend value
// Total: 32 bytes

%def RELOC_tag              0       // offset of tag field
%def RELOC_type             1       // offset of type field
%def RELOC_offset           8       // offset of patch location
%def RELOC_symbol           16      // offset of symbol pointer
%def RELOC_addend           24      // offset of addend
%def RELOC_SIZE             32      // total struct size

// ============================================================================
// STRUCT: MacroExpansion
// ============================================================================
// Tracks state of an active macro expansion on the call stack.
// Size: 48 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_MACRO_EXP
//   +1   depth   1 byte   current nesting depth
//   +2   nparams 1 byte   number of parameters
//   +3   pad     5 bytes  alignment padding
//   +8   macro   8 bytes  pointer to Symbol (macro definition)
//   +16  parent  8 bytes  pointer to parent MacroExpansion or NULL
//   +24  params  8 bytes  pointer to parameter string array
//   +32  body    8 bytes  pointer to current body position
//   +40  line    4 bytes  source line of invocation
//   +44  pad2    4 bytes  alignment padding
// Total: 48 bytes

%def MACROEXP_tag           0       // offset of tag field
%def MACROEXP_depth         1       // offset of depth field
%def MACROEXP_nparams       2       // offset of parameter count
%def MACROEXP_macro         8       // offset of macro symbol pointer
%def MACROEXP_parent        16      // offset of parent pointer
%def MACROEXP_params        24      // offset of parameter array pointer
%def MACROEXP_body          32      // offset of body position pointer
%def MACROEXP_line          40      // offset of invocation line
%def MACROEXP_SIZE          48      // total struct size

// ============================================================================
// STRUCT: MacroDef
// ============================================================================
// Definition of a preprocessor macro.
// Size: 32 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag       1 byte   always TAG_MACRO
//   +1   nparams   1 byte   number of parameters
//   +2   pad       6 bytes  alignment padding
//   +8   name      8 bytes  pointer to macro name string
//   +16  tokens    8 bytes  pointer to token array (body)
//   +24  ntokens   4 bytes  number of tokens in the body
//   +28  pad2      4 bytes  alignment padding
// Total: 32 bytes

%def MACRO_tag              0       // offset of tag field
%def MACRO_nparams          1       // offset of parameter count
%def MACRO_name             8       // offset of name pointer
%def MACRO_tokens           16      // offset of body token array
%def MACRO_ntokens          24      // offset of token count
%def MACRO_SIZE             32      // total struct size

// ============================================================================
// STRUCT: IncludeCtx
// ============================================================================
// Tracks state of an active %inc file inclusion.
// Size: 56 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_INCLUDE_CTX
//   +1   depth   1 byte   include nesting depth
//   +2   pad     6 bytes  alignment padding
//   +8   file    8 bytes  pointer to filename string
//   +16  parent  8 bytes  pointer to parent IncludeCtx or NULL
//   +24  buf     8 bytes  pointer to file buffer
//   +32  pos     8 bytes  current read position in buffer
//   +40  line    4 bytes  current line number in this file
//   +44  pad2    4 bytes  alignment padding
//   +48  lexer   8 bytes  pointer to saved LexerState
// Total: 56 bytes

%def INCLUDECTX_tag         0       // offset of tag field
%def INCLUDECTX_depth       1       // offset of depth field
%def INCLUDECTX_file        8       // offset of filename pointer
%def INCLUDECTX_parent      16      // offset of parent pointer
%def INCLUDECTX_buf         24      // offset of buffer pointer
%def INCLUDECTX_pos         32      // offset of read position
%def INCLUDECTX_line        40      // offset of line number
%def INCLUDECTX_lexer       48      // offset of saved lexer pointer
%def INCLUDECTX_SIZE        56      // total struct size

// ============================================================================
// STRUCT: Arena
// ============================================================================
// Bump allocator. One arena per compilation pass.
// All tokens, symbols, strings allocated here.
// Freed all at once at end of pass — no individual free calls.
// Size: 32 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag     1 byte   always TAG_ARENA
//   +1   pad     7 bytes  alignment padding
//   +8   base    8 bytes  pointer to start of arena memory
//   +16  ptr     8 bytes  pointer to next free byte
//   +24  end     8 bytes  pointer to one byte past end of arena
// Total: 32 bytes

%def ARENA_tag              0       // offset of tag field
%def ARENA_base             8       // offset of base pointer
%def ARENA_ptr              16      // offset of next free pointer
%def ARENA_end              24      // offset of end pointer
%def ARENA_SIZE             32      // total struct size

// ============================================================================
// STRUCT: AsmCtx
// ============================================================================
// Master assembler context. One instance per utasm run.
// Every module receives a pointer to this struct.
// Size: 128 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag         1 byte   always TAG_ASM_CTX
//   +1   target      1 byte   TARGET_* value
//   +2   fmt         1 byte   FMT_* value
//   +3   opt         1 byte   OPT_* value
//   +4   err_count   2 bytes  number of errors so far
//   +6   warn_count  2 bytes  number of warnings so far
//   +8   arena       8 bytes  pointer to Arena
//   +16  symtab      8 bytes  pointer to symbol table base
//   +24  symcount    4 bytes  number of symbols defined
//   +28  pad         4 bytes  alignment padding
//   +32  sections    8 bytes  pointer to section array
//   +40  seccount    4 bytes  number of sections
//   +44  pad2        4 bytes  alignment padding
//   +48  inc_ctx     8 bytes  pointer to current IncludeCtx
//   +56  mac_exp     8 bytes  pointer to current MacroExpansion
//   +64  input       8 bytes  pointer to input filename string
//   +72  output      8 bytes  pointer to output filename string
//   +80  ld_script   8 bytes  pointer to linker script filename
//   +88  inc_paths   8 bytes  pointer to include path array
//   +96  ninc_paths  4 bytes  number of include paths
//   +100 flags       4 bytes  misc flags (debug, verbose, etc.)
//   +104 pad3        24 bytes alignment padding
// Total: 128 bytes

%def ASMCTX_tag             0       // offset of tag field
%def ASMCTX_target          1       // offset of target field
%def ASMCTX_fmt             2       // offset of format field
%def ASMCTX_opt             3       // offset of optimization level
%def ASMCTX_err_count       4       // offset of error counter
%def ASMCTX_warn_count      6       // offset of warning counter
%def ASMCTX_arena           8       // offset of arena pointer
%def ASMCTX_symtab          16      // offset of symbol table pointer
%def ASMCTX_symcount        24      // offset of symbol count
%def ASMCTX_sections        32      // offset of section array pointer
%def ASMCTX_seccount        40      // offset of section count
%def ASMCTX_inc_ctx         48      // offset of include context pointer
%def ASMCTX_mac_exp         56      // offset of macro expansion pointer
%def ASMCTX_input           64      // offset of input filename pointer
%def ASMCTX_output          72      // offset of output filename pointer
%def ASMCTX_ld_script       80      // offset of linker script pointer
%def ASMCTX_inc_paths       88      // offset of include path array pointer
%def ASMCTX_ninc_paths      96      // offset of include path count
%def ASMCTX_flags           100     // offset of flags field
%def ASMCTX_SIZE            128     // total struct size

// ---- AsmCtx flags ------------------------

%def CTX_FLAG_DEBUG         0x01    // debug mode enabled
%def CTX_FLAG_VERBOSE       0x02    // verbose output enabled
%def CTX_FLAG_WERROR        0x04    // treat warnings as errors
%def CTX_FLAG_COLOR         0x08    // colored output enabled
%def CTX_FLAG_LISTING       0x10    // generate listing file
%def CTX_FLAG_MAPFILE       0x20    // generate map file
%def CTX_FLAG_STRIP         0x40    // strip symbols from output

// ============================================================================
// STRUCT: PrepState
// ============================================================================
// State of the preprocessor.
// Tracks nested conditionals and the active lexer.
// Size: 32 bytes. Aligned to 8 bytes.
//
// Layout:
//   +0   tag        1 byte   always TAG_PREPROCESSOR
//   +1   depth      1 byte   current %if nesting depth
//   +2   skip_depth 1 byte   depth at which skipping started (0 if not skipping)
//   +3   pad        5 bytes  alignment padding
//   +8   lexer      8 bytes  pointer to current LexerState
//   +16  ctx        8 bytes  pointer to AsmCtx
//   +24  arena      8 bytes  pointer to Arena
// Total: 32 bytes

%def PREP_tag               0       // offset of tag field
%def PREP_depth             1       // offset of depth field
%def PREP_skip_depth        2       // offset of skip_depth field
%def PREP_lexer             8       // offset of current lexer pointer
%def PREP_ctx               16      // offset of AsmCtx pointer
%def PREP_arena             24      // offset of Arena pointer
%def PREP_SIZE              32      // total struct size