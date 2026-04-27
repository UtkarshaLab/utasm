/*
 ============================================
 File     : include/constant.s
 Project  : utasm
 Version  : 0.1.0
 Author   : Utkarsha Lab
 License  : Apache-2.0
 ============================================
*/

// ============================================================================
// EXIT CODES
// ============================================================================
// Process termination status values passed to the system exit call.
// Valid range is strictly 0 through 125. Values 126 and 127 are reserved
// by the host command interpreter for its own errors. Values 128 and above
// are reserved by the platform for signal-based termination and must never
// be used as normal exit codes.

%def EXIT_OK                0   // operation completed successfully
%def EXIT_ERROR             1   // unspecified general failure
%def EXIT_USAGE             2   // invalid command-line arguments or flags

%def EXIT_FILE_NOT_FOUND    3   // requested input file does not exist
%def EXIT_FILE_PERM         4   // insufficient permissions to access file
%def EXIT_FILE_READ         5   // error occurred during file read operation
%def EXIT_FILE_WRITE        6   // error occurred during file write operation

%def EXIT_INC_NOT_FOUND     10  // included file specified by source not found
%def EXIT_MACRO_DEF         11  // malformed or illegal macro definition
%def EXIT_MACRO_EXP         12  // failure during macro expansion phase
%def EXIT_MACRO_RECURSION   13  // nested macro depth exceeded limit
%def EXIT_DEFINE            14  // invalid or malformed %define directive

%def EXIT_UNKNOWN_INSTR     20  // mnemonic does not match any known instruction
%def EXIT_INVALID_OPERAND   21  // operand syntax is not valid for instruction
%def EXIT_INVALID_REG       22  // register name is unrecognized or illegal
%def EXIT_INVALID_IMM       23  // immediate value format or content is invalid
%def EXIT_INVALID_ADDR      24  // addressing mode expression is malformed
%def EXIT_UNEXPECTED_TOKEN  25  // token encountered where none was expected
%def EXIT_UNEXPECTED_EOF    26  // end of input reached before construct completed

%def EXIT_ENCODE_FAIL       30  // instruction encoding could not be generated
%def EXIT_IMM_RANGE         31  // immediate value exceeds allowed bit width
%def EXIT_OFFSET_RANGE      32  // branch or memory offset exceeds range
%def EXIT_UNSUPPORTED_INSTR 33  // valid instruction not supported by target
%def EXIT_ALIGN_ERROR       34  // alignment directive could not be satisfied
%def EXIT_STRUCT_BOUNDS     35  // memory write size exceeds struct field byte width

%def EXIT_UNDEF_SYMBOL      40  // referenced symbol has no definition
%def EXIT_DUP_SYMBOL        41  // symbol defined more than once
%def EXIT_SYMBOL_RANGE      42  // symbol value exceeds representable range
%def EXIT_CIRCULAR_REF      43  // circular dependency detected between symbols

%def EXIT_LD_SCRIPT_404     50  // linker script file not found
%def EXIT_LD_SCRIPT_PARSE   51  // linker script contains syntax errors
%def EXIT_SECTION_OVERLAP   52  // two or more output sections occupy same address
%def EXIT_RELOC_ERROR       53  // relocation could not be applied
%def EXIT_UNDEF_REF         54  // symbol referenced but never defined
%def EXIT_MULTI_DEF         55  // symbol defined in multiple input objects

%def EXIT_OUT_CREATE        60  // failed to create output file
%def EXIT_ELF_WRITE         61  // error writing ELF format output
%def EXIT_BIN_WRITE         62  // error writing flat binary output

%def EXIT_QEMU_404          70  // emulator binary not found in path
%def EXIT_QEMU_FAIL         71  // emulator process exited with error

%def EXIT_INTERNAL          124 // unrecoverable internal assembler error
%def EXIT_OOM               125 // memory allocation request could not be fulfilled

// ============================================================================
// BOOLEAN AND STATUS VALUES
// ============================================================================
// Generic truth values and operation status indicators.
// ERR uses a signed representation and must only be tested with signed
// conditional jumps (JL, JG, etc.). For unsigned-safe error testing,
// use STATUS_ERR instead.

%def TRUE                   1   // logical affirmative
%def FALSE                  0   // logical negative
%def NULL                   0   // null pointer value
%def OK                     0   // function success status
%def ERR                    -1  // function failure status (signed only)
%def STATUS_ERR             1   // function failure status (unsigned-safe)

// ============================================================================
// LIMITS AND CAPACITIES
// ============================================================================
// Hard upper bounds for internal data structures and processing loops.
// These prevent unbounded growth that could exhaust host resources.

%def MAX_ARGS               32          // maximum command-line arguments
%def MAX_PATH               4096        // maximum file path length in bytes
%def MAX_LINE               1024        // maximum source line length
%def MAX_TOKEN              256         // maximum single token length
%def MAX_SYMBOL             65536       // maximum entries in symbol table
%def MAX_SECTIONS           64          // maximum ELF sections per object
%def MAX_INCLUDES           256         // maximum nested include depth
%def MAX_MACRO_PARAMS       32          // maximum parameters per macro
%def MAX_MACRO_DEPTH        64          // maximum nested macro expansion depth
%def MAX_REP_COUNT          65536       // maximum iterations per %rep block
%def MAX_ERRORS             50          // fatal stop threshold for error count
%def MAX_WARNINGS           100         // threshold for warning count

// ============================================================================
// BUFFER SIZES
// ============================================================================
// Working buffer dimensions for streaming I/O operations.
// These are chunk sizes for incremental read and write operations,
// not maximum file size limits. Large files are processed in multiple
// passes through these buffers.

%def BUF_INPUT              65536       // input file read chunk
%def BUF_OUTPUT             65536       // output file write chunk
%def BUF_TOKEN              4096        // token accumulation workspace
%def BUF_ERROR              1024        // formatted error message buffer
%def BUF_LINE               1024        // single line processing buffer
 
 // ============================================================================
 // TYPE TAGS
 // ============================================================================
 // Every struct in utasm has a 1-byte type tag at offset 0.
 
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
 %def TOK_FLOAT              0x21
 
 // ============================================================================
 // SYMBOL KINDS AND VISIBILITY
 // ============================================================================
 
 %def SYM_UNKNOWN            0x00
 %def SYM_LABEL              0x01
 %def SYM_DATA               0x02
 %def SYM_CONSTANT           0x03
 %def SYM_MACRO              0x04
 %def SYM_EXTERN             0x05
 %def SYM_SECTION            0x06
 %def SYM_STRUCT             0x07  // a struc definition (name -> total_size)
 %def SYM_STRUCT_FIELD       0x08  // a struct field   (name -> offset, size = field byte width)
 
 %def VIS_LOCAL              0x00
 %def VIS_GLOBAL             0x01
 %def VIS_WEAK               0x02
 
 // ============================================================================
 // SECTION TYPES
 // ============================================================================
 
 %def SEC_TEXT               0x01
 %def SEC_DATA               0x02
 %def SEC_BSS                0x03
 %def SEC_RODATA             0x04
 %def SEC_CUSTOM             0x05
 
 // ============================================================================
 // OPERAND KINDS
 // ============================================================================
 
 %def OP_NONE                0x00
 %def OP_REG                 0x01
 %def OP_IMM                 0x02
 %def OP_MEM                 0x03
 %def OP_SYMBOL              0x04
 
 // ============================================================================
 // CONTEXT FLAGS
 // ============================================================================
 
 %def CTX_FLAG_DEBUG         0x01
 %def CTX_FLAG_VERBOSE       0x02
 %def CTX_FLAG_WERROR        0x04
 %def CTX_FLAG_COLOR         0x08
 %def CTX_FLAG_LISTING       0x10
 %def CTX_FLAG_MAPFILE       0x20
 %def CTX_FLAG_STRIP         0x40
 
 // ============================================================================
 // CPU FEATURE BITS (AMD64)
 // ============================================================================
 
 %def FEAT_AVX               (1 << 0)
 %def FEAT_AVX2              (1 << 1)
 %def FEAT_AVX512F           (1 << 2)
 %def FEAT_AVX512DQ          (1 << 3)
 %def FEAT_AVX512BW          (1 << 4)
 %def FEAT_AVX512VL          (1 << 5)
 %def FEAT_AMX_TILE          (1 << 6)
 %def FEAT_AMX_INT8          (1 << 7)
 %def FEAT_AMX_BF16          (1 << 8)
 %def FEAT_SGX               (1 << 9)
 %def FEAT_AES               (1 << 10)
 %def FEAT_SHA               (1 << 11)
 %def FEAT_KL                (1 << 12)
 
 // ============================================================================
 // INSTRUCTION FLAGS
 // ============================================================================
 
 %def F_VEX                  (1 << 0)    // uses VEX encoding
 %def F_EVEX                 (1 << 1)    // uses EVEX encoding
 %def F_MODRM                (1 << 2)    // requires ModRM byte
 %def F_REX                  (1 << 3)    // requires REX prefix in 64-bit
 %def F_MMX                  (1 << 4)    // uses MMX registers
 %def F_XMM                  (1 << 5)    // uses XMM/SSE registers
 %def F_FPU                  (1 << 6)    // uses x87 FPU registers
 %def F_LOCK                 (1 << 7)    // supports LOCK prefix
 
 // ============================================================================
 // OPERAND SIZES (BITS)
 // ============================================================================
 
 %def SZ_8                   8
 %def SZ_16                  16
 %def SZ_32                  32
 %def SZ_64                  64
 %def SZ_128                 128
 %def SZ_256                 256
 %def SZ_512                 512
 

// ============================================================================
// TARGET ARCHITECTURE IDENTIFIERS
// ============================================================================
// Numeric identifiers for supported instruction set architectures.
// Used by conditional assembly and target-specific code generation paths.

%def TARGET_AARCH64         1           // ARM 64-bit architecture
%def TARGET_AMD64           2           // x86-64 architecture
%def TARGET_RISCV64         3           // RISC-V 64-bit architecture

// ============================================================================
// OUTPUT FORMAT IDENTIFIERS
// ============================================================================
// Determines the binary format written by the assembler and linker.

%def FMT_ELF64              1           // ELF64 relocatable or executable
%def FMT_BIN                2           // flat raw binary (no metadata)

// ============================================================================
// OPTIMIZATION LEVELS
// ============================================================================
// Controls the aggressiveness of assembler and linker optimizations.

%def OPT_NONE               0           // no optimizations applied
%def OPT_BASIC              1           // basic peephole and dead code removal

// ============================================================================
// LOG LEVELS
// ============================================================================
// Severity classification for diagnostic and debug messages.
// Higher values indicate more critical conditions.

%def LOG_DEBUG              0           // verbose internal state tracing
%def LOG_INFO               1           // informational progress messages
%def LOG_WARN               2           // potential problem detected
%def LOG_ERROR              3           // recoverable error occurred
%def LOG_FATAL              4           // unrecoverable error, termination imminent

// ============================================================================
// STANDARD FILE DESCRIPTORS
// ============================================================================
// Numeric handles for the default I/O streams available to every process.

%def STDIN_FILENO           0           // standard input stream
%def STDOUT_FILENO          1           // standard output stream
%def STDERR_FILENO          2           // standard error stream

// ============================================================================
// SYSTEM CALL NUMBERS (AMD64 HOST)
// ============================================================================
// Trap numbers for invoking host platform services on AMD64.
// Prefixed by architecture to allow future multi-arch support without collision.
// These are used only by the bootstrap host binary, not by target output code.

%def AMD64_SYS_READ         0           // read from file descriptor
%def AMD64_SYS_WRITE        1           // write to file descriptor
%def AMD64_SYS_OPEN         2           // open or create file
%def AMD64_SYS_CLOSE        3           // close file descriptor
%def AMD64_SYS_STAT         4           // get file status by path
%def AMD64_SYS_FSTAT        5           // get file status by descriptor
%def AMD64_SYS_LSEEK        8           // reposition file offset
%def AMD64_SYS_MMAP         9           // map file or memory into address space
%def AMD64_SYS_MUNMAP       11          // unmap memory region
%def AMD64_SYS_BRK          12          // adjust program break (heap end)
%def AMD64_SYS_EXIT         60          // terminate current process
%def AMD64_SYS_EXIT_GROUP   231         // terminate all threads in process group

// ============================================================================
// FILE ACCESS FLAGS (AMD64 HOST)
// ============================================================================
// Bit flags controlling file open behavior on the AMD64 host platform.
// Combined with bitwise OR when invoking the open system call.

%def AMD64_O_RDONLY         0           // open for read-only access
%def AMD64_O_WRONLY         1           // open for write-only access
%def AMD64_O_RDWR           2           // open for read-write access
%def AMD64_O_CREAT          64          // create file if it does not exist
%def AMD64_O_TRUNC          512         // truncate existing file to zero length

// ============================================================================
// MEMORY PROTECTION FLAGS
// ============================================================================
// Access permission bits for memory-mapped regions.
// Used when allocating or modifying virtual memory pages.

%def PROT_NONE              0           // no access permitted
%def PROT_READ              1           // read access permitted
%def PROT_WRITE             2           // write access permitted
%def PROT_EXEC              4           // execute access permitted

// ============================================================================
// MEMORY MAPPING FLAGS
// ============================================================================
// Behavior modifiers for memory mapping operations.
// Combined with bitwise OR when invoking mmap.

%def MAP_SHARED             1           // modifications visible to other mappings
%def MAP_PRIVATE            2           // modifications are private copy-on-write
%def MAP_ANONYMOUS          0x20        // mapping not backed by any file
%def MAP_FIXED              0x10        // force mapping at requested address
%def MAP_FAILED             -1          // mapping failure return value

// ============================================================================
// ERROR RETURN CODES (ERRNO VALUES)
// ============================================================================
// Standard numeric codes returned by system calls on failure.
// These match the conventional errno numbering used by the host platform.

%def ENOENT                 2           // no such file or directory
%def EIO                    5           // input/output error
%def ENOMEM                 12          // cannot allocate memory
%def EACCES                 13          // permission denied
%def EINVAL                 22          // invalid argument

// ============================================================================
// MEMORY ALIGNMENT
// ============================================================================
// Fundamental page and alignment constants for memory management.

%def PAGE_SIZE              4096        // default virtual memory page size in bytes

// ============================================================================
// ELF64 MAGIC AND IDENTIFICATION
// ============================================================================
// Bytes and indices for the ELF file header identification array.
// EI_MAG0 through EI_MAG3 spell the magic number 0x7F 'E' 'L' 'F'.

%def ELFMAG0                0x7F        // magic byte 0
%def ELFMAG1                0x45        // magic byte 1 ('E')
%def ELFMAG2                0x4C        // magic byte 2 ('L')
%def ELFMAG3                0x46        // magic byte 3 ('F')
%def ELFCLASS64             2           // 64-bit object class
%def ELFDATA2LSB            1           // little-endian data encoding

// ---- ELF e_ident[] array indices ---------

%def EI_MAG0                0           // offset of first magic byte
%def EI_MAG1                1           // offset of second magic byte
%def EI_MAG2                2           // offset of third magic byte
%def EI_MAG3                3           // offset of fourth magic byte
%def EI_CLASS               4           // offset of file class field
%def EI_DATA                5           // offset of data encoding field
%def EI_VERSION             6           // offset of ELF version field
%def EI_OSABI               7           // offset of OS/ABI identification field
%def EI_NIDENT              16          // total size of e_ident[] array

// ============================================================================
// ELF64 VERSION
// ============================================================================

%def EV_CURRENT             1           // current ELF version identifier

// ============================================================================
// ELF64 OBJECT TYPES
// ============================================================================
// Classification of ELF object files.

%def ET_REL                 1           // relocatable file
%def ET_EXEC                2           // executable file

// ============================================================================
// ELF64 MACHINE TYPES
// ============================================================================
// Architecture identifiers stored in the ELF header e_machine field.

%def EM_AARCH64             183         // ARM AArch64
%def EM_X86_64              62          // AMD64 / x86-64
%def EM_RISCV               243         // RISC-V 64-bit

// ============================================================================
// ELF64 SECTION HEADER TYPES
// ============================================================================
// Types of sections contained in an ELF object file.

%def SHT_NULL               0           // inactive section header
%def SHT_PROGBITS           1           // program-defined data and code
%def SHT_SYMTAB             2           // symbol table
%def SHT_STRTAB             3           // string table
%def SHT_RELA               4           // relocation entries with explicit addends
%def SHT_REL                9           // relocation entries without addends
%def SHT_NOBITS             8           // uninitialized data (BSS)
%def SHT_GROUP              17          // section group (0x11)

// ---- Section Group Flags ----
%def GRP_COMDAT             0x1         // COMDAT group

// ============================================================================
// ELF64 SECTION FLAGS
// ============================================================================
// Attribute bits describing section permissions and memory behavior.

%def SHF_WRITE              0x1         // section contains writable data
%def SHF_ALLOC              0x2         // section occupies memory at runtime
%def SHF_EXECINSTR          0x4         // section contains executable instructions

// ============================================================================
// ELF64 PROGRAM HEADER TYPES
// ============================================================================
%def PT_NULL                0
%def PT_LOAD                1
%def PT_DYNAMIC             2
%def PT_INTERP              3
%def PT_NOTE                4
%def PT_SHLIB               5
%def PT_PHDR                6

// ============================================================================
// ELF64 PROGRAM HEADER FLAGS
// ============================================================================
// Permission bits for loadable segments.

%def PF_X                   0x1         // execute permission
%def PF_W                   0x2         // write permission
%def PF_R                   0x4         // read permission

// ============================================================================
// ELF64 SYMBOL TABLE BINDINGS
// ============================================================================
// Visibility scope of symbols within and across object files.

%def STB_LOCAL              0           // visible only within defining file
%def STB_GLOBAL             1           // visible to all linked files

// ============================================================================
// ELF64 SYMBOL TABLE TYPES
// ============================================================================
// Classification of symbol semantics.

%def STT_NOTYPE             0           // unspecified symbol type
%def STT_OBJECT             1           // data object (variable, array, etc.)
%def STT_FUNC               2           // function or executable code

// ============================================================================
// ELF64 SPECIAL SECTION INDICES
// ============================================================================
// Reserved section index values with special meaning.

%def SHN_UNDEF              0           // undefined or external symbol

// ============================================================================
// UTASM HOST MEMORY LAYOUT
// ============================================================================
// Address space configuration for the utasm process itself.
// UTASM_HEAP_BASE is an advisory hint passed to the memory allocator.
// The system may place the heap at a different address; this value merely
// suggests a preferred region. Do not assume the heap begins exactly here.

%def UTASM_HEAP_BASE        0x10000000  // preferred heap region start address
%def UTASM_HEAP_SIZE        0x10000000  // maximum heap reservation (256 MiB)
%def UTASM_STACK_SIZE       0x100000    // default stack allocation (1 MiB)

// ============================================================================
// ARCHITECTURAL REGISTERS (AMD64)
// ============================================================================
%def REG_RIP                0xFE        // special identifier for RIP
 
 // ============================================================================
 // AMD64 RELOCATION TYPES (Standard ELF)
 // ============================================================================
 
 %def R_X86_64_NONE          0
 %def R_X86_64_64            1
 %def R_X86_64_PC32          2
 %def R_X86_64_GOT32         3
 %def R_X86_64_PLT32         4
 %def R_X86_64_COPY          5
 %def R_X86_64_GLOB_DAT      6
 %def R_X86_64_JUMP_SLOT     7
 %def R_X86_64_RELATIVE      8
 %def R_X86_64_GOTPCREL      9
 %def R_X86_64_32            10
 %def R_X86_64_32S           11
 %def R_X86_64_16            12
 %def R_X86_64_PC16          13
 %def R_X86_64_8             14
 %def R_X86_64_PC8           15
 
 // Backward compatibility aliases
 %def RELOC_ABS64            R_X86_64_64
 %def RELOC_REL32            R_X86_64_PC32
 %def RELOC_REL64            1           // Legacy map
 %def RELOC_GOT              R_X86_64_GOT32

// ============================================================================
// REGISTER IDENTIFIERS
// ============================================================================
// Internal numeric identifiers for architectural registers.

%def REG_NONE               0xFF        // sentinel for "no register"

// Base GPR indices
%def REG_RAX                0
%def REG_RCX                1
%def REG_RDX                2
%def REG_RBX                3
%def REG_RSP                4
%def REG_RBP                5
%def REG_RSI                6
%def REG_RDI                7
%def R_AARCH64_ABS64         257
%def R_AARCH64_ADR_PREL_LO21 274
%def R_AARCH64_ADR_PREL_PG_HI21 275
%def R_AARCH64_ADD_ABS_LO12_NC 277
%def R_AARCH64_LDST64_ABS_LO12_NC 286
%def R_AARCH64_CALL26        283
%def R_AARCH64_JUMP26        282

%def R_RISCV_64             2
%def R_RISCV_HI20           26
%def R_RISCV_LO12_I         27
%def R_RISCV_CALL           18
%def R_RISCV_RELAX          51

// ============================================================================
// LEXER CHARACTER PROPERTIES
// ============================================================================
%def CHAR_IS_DIGIT          0x01
%def CHAR_IS_IDENT_START    0x02
%def CHAR_IS_IDENT_PART     0x04
%def CHAR_IS_WHITESPACE     0x08
%def CHAR_IS_HEX            0x10
