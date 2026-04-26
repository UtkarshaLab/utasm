/*
 ============================================
 File     : include/constant.s
 Project  : utasm
 Version  : 0.0.1
 Author   : Utkarsha Lab
 License  : Proprietary
 ============================================
*/

// ---- Exit Codes --------------------------

%def EXIT_OK                0   // success
%def EXIT_ERROR             1   // general error
%def EXIT_USAGE             2   // bad arguments

%def EXIT_FILE_NOT_FOUND    3   // file not found
%def EXIT_FILE_PERM         4   // permission denied
%def EXIT_FILE_READ         5   // file read error
%def EXIT_FILE_WRITE        6   // file write error

%def EXIT_INC_NOT_FOUND     10  // include file not found
%def EXIT_MACRO_DEF         11  // macro definition error
%def EXIT_MACRO_EXP         12  // macro expansion error
%def EXIT_DEFINE            13  // define error

%def EXIT_UNKNOWN_INSTR     20  // unknown instruction
%def EXIT_INVALID_OPERAND   21  // invalid operand
%def EXIT_INVALID_REG       22  // invalid register
%def EXIT_INVALID_IMM       23  // invalid immediate
%def EXIT_INVALID_ADDR      24  // invalid addressing mode
%def EXIT_UNEXPECTED_TOKEN  25  // unexpected token
%def EXIT_UNEXPECTED_EOF    26  // unexpected end of file

%def EXIT_ENCODE_FAIL       30  // encoding failed
%def EXIT_IMM_RANGE         31  // immediate out of range
%def EXIT_OFFSET_RANGE      32  // offset out of range
%def EXIT_UNSUPPORTED_INSTR 33  // unsupported instruction
%def EXIT_ALIGN_ERROR       34  // alignment error

%def EXIT_UNDEF_SYMBOL      40  // undefined symbol
%def EXIT_DUP_SYMBOL        41  // duplicate symbol
%def EXIT_SYMBOL_RANGE      42  // symbol out of range
%def EXIT_CIRCULAR_REF      43  // circular reference

%def EXIT_LD_SCRIPT_404     50  // linker script not found
%def EXIT_LD_SCRIPT_PARSE   51  // linker script parse error
%def EXIT_SECTION_OVERLAP   52  // section overlap
%def EXIT_RELOC_ERROR       53  // relocation error
%def EXIT_UNDEF_REF         54  // undefined reference
%def EXIT_MULTI_DEF         55  // multiple definition

%def EXIT_OUT_CREATE        60  // output file creation failed
%def EXIT_ELF_WRITE         61  // ELF write error
%def EXIT_BIN_WRITE         62  // binary write error

%def EXIT_QEMU_404          70  // QEMU not found
%def EXIT_QEMU_FAIL         71  // QEMU launch failed

%def EXIT_INTERNAL          127 // internal utasm error
%def EXIT_OOM               128 // out of memory

// ---- Boolean -----------------------------

%def TRUE                   1
%def FALSE                  0
%def NULL                   0
%def OK                     0
%def ERR                    -1

// ---- Limits ------------------------------

%def MAX_ARGS               32          // max CLI arguments
%def MAX_PATH               4096        // max file path length
%def MAX_LINE               1024        // max source line length
%def MAX_TOKEN              256         // max token length
%def MAX_SYMBOL             65536       // max symbols in table
%def MAX_SECTIONS           64          // max ELF sections
%def MAX_INCLUDES           256         // max nested includes
%def MAX_MACRO_PARAMS       32          // max macro parameters
%def MAX_MACRO_DEPTH        64          // max macro nesting depth
%def MAX_REP_COUNT          65536       // max %rep iterations
%def MAX_ERRORS             10          // stop after N errors

// ---- Buffer Sizes ------------------------

%def BUF_INPUT              65536       // input file buffer
%def BUF_OUTPUT             65536       // output file buffer
%def BUF_TOKEN              4096        // token buffer
%def BUF_ERROR              1024        // error message buffer
%def BUF_LINE               1024        // line buffer

// ---- Target Architecture -----------------

%def TARGET_AARCH64         1
%def TARGET_AMD64           2
%def TARGET_RISCV64         3

// ---- Output Format -----------------------

%def FMT_ELF64              1
%def FMT_BIN                2

// ---- Optimization Level ------------------

%def OPT_NONE               0
%def OPT_BASIC              1

// ---- Log Levels --------------------------

%def LOG_DEBUG              0
%def LOG_INFO               1
%def LOG_WARN               2
%def LOG_ERROR              3
%def LOG_FATAL              4

// ---- Syscalls (AMD64 Linux) --------------
// used by utasm host code during bootstrap

%def SYS_READ               0
%def SYS_WRITE              1
%def SYS_OPEN               2
%def SYS_CLOSE              3
%def SYS_STAT               4
%def SYS_FSTAT              5
%def SYS_LSEEK              8
%def SYS_MMAP               9
%def SYS_MUNMAP             11
%def SYS_BRK                12
%def SYS_EXIT               60
%def SYS_EXIT_GROUP         231

// ---- File Flags --------------------------

%def O_RDONLY               0
%def O_WRONLY               1
%def O_RDWR                 2
%def O_CREAT                64
%def O_TRUNC                512

// ---- ELF64 Constants ---------------------

%def ELFMAG0                0x7F        // ELF magic byte 0
%def ELFMAG1                0x45        // E
%def ELFMAG2                0x4C        // L
%def ELFMAG3                0x46        // F
%def ELFCLASS64             2           // 64-bit
%def ELFDATA2LSB            1           // little endian
%def ET_REL                 1           // relocatable
%def ET_EXEC                2           // executable
%def EM_AARCH64             183         // AArch64 machine
%def EM_X86_64              62          // AMD64 machine
%def EM_RISCV               243         // RISC-V machine
%def SHT_NULL               0           // null section
%def SHT_PROGBITS           1           // program data
%def SHT_SYMTAB             2           // symbol table
%def SHT_STRTAB             3           // string table
%def SHT_RELA               4           // relocation entries
%def SHT_NOBITS             8           // bss
%def SHF_WRITE              0x1         // writable
%def SHF_ALLOC              0x2         // occupies memory
%def SHF_EXECINSTR          0x4         // executable
%def PT_LOAD                1           // loadable segment
%def PF_X                   0x1         // execute
%def PF_W                   0x2         // write
%def PF_R                   0x4         // read

// ---- Memory Layout (utasm host) ----------

%def UTASM_HEAP_BASE        0x10000000  // heap start
%def UTASM_HEAP_SIZE        0x10000000  // 256MB max heap
%def UTASM_STACK_SIZE       0x100000    // 1MB stack