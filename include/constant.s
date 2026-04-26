/*
 ============================================
 File     : include/constant.s
 Project  : utasm
 Version  : 0.0.1
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
%def EXIT_DEFINE            13  // invalid or malformed %define directive

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
// Types of segments described by program headers.

%def PT_LOAD                1           // loadable segment

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