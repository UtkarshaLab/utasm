/*
 ============================================================================
 File        : include/elf.s
 Project     : utasm
 Description : ELF64 format constants, header offsets, and section/segment
               type definitions. Used by src/linker/elf64.s to emit valid
               ELF64 object files and executables.
 ============================================================================
*/

// ============================================================================
// ELF MAGIC & IDENTIFICATION
// ============================================================================
%def ELFMAG0                0x7F        // e_ident[0]
%def ELFMAG1                0x45        // 'E'
%def ELFMAG2                0x4C        // 'L'
%def ELFMAG3                0x46        // 'F'
%def ELFMAG                 0x464C457F  // 4-byte magic (little-endian)

// e_ident[EI_CLASS]
%def ELFCLASSNONE           0
%def ELFCLASS32             1
%def ELFCLASS64             2           // 64-bit ELF

// e_ident[EI_DATA]
%def ELFDATANONE            0
%def ELFDATA2LSB            1           // Little-endian (x86_64)
%def ELFDATA2MSB            2           // Big-endian

// e_ident[EI_VERSION]
%def EV_NONE                0
%def EV_CURRENT             1

// e_ident[EI_OSABI]
%def ELFOSABI_NONE          0           // UNIX System V ABI
%def ELFOSABI_LINUX         3           // Linux
%def ELFOSABI_FREEBSD       9
%def ELFOSABI_STANDALONE    255         // Standalone (embedded / bare-metal OS)

// e_ident indices
%def EI_MAG0                0
%def EI_MAG1                1
%def EI_MAG2                2
%def EI_MAG3                3
%def EI_CLASS               4
%def EI_DATA                5
%def EI_VERSION             6
%def EI_OSABI               7
%def EI_ABIVERSION          8
%def EI_PAD                 9
%def EI_NIDENT              16

// ============================================================================
// ELF FILE TYPES (e_type)
// ============================================================================
%def ET_NONE                0           // No file type
%def ET_REL                 1           // Relocatable object file (.o)
%def ET_EXEC                2           // Executable file
%def ET_DYN                 3           // Shared object (.so)
%def ET_CORE                4           // Core dump
%def ET_LOOS                0xFE00      // OS-specific range begin
%def ET_HIOS                0xFEFF      // OS-specific range end
%def ET_LOPROC              0xFF00      // Processor-specific range begin
%def ET_HIPROC              0xFFFF      // Processor-specific range end

// ============================================================================
// MACHINE TYPES (e_machine)
// ============================================================================
%def EM_NONE                0
%def EM_386                 3           // Intel 80386
%def EM_MIPS                8           // MIPS
%def EM_PPC                 20          // PowerPC
%def EM_PPC64               21          // 64-bit PowerPC
%def EM_ARM                 40          // ARM 32-bit
%def EM_X86_64              62          // AMD64 / x86-64
%def EM_AARCH64             183         // ARM 64-bit (AArch64)
%def EM_RISCV               243         // RISC-V

// ============================================================================
// ELF64 FILE HEADER LAYOUT (Ehdr) — Byte Offsets
// ============================================================================
// Total size: 64 bytes
%def ELF64_EHDR_SIZE        64

%def EHDR_IDENT             0           // e_ident[16]       16 bytes
%def EHDR_TYPE              16          // e_type             2 bytes
%def EHDR_MACHINE           18          // e_machine          2 bytes
%def EHDR_VERSION           20          // e_version          4 bytes
%def EHDR_ENTRY             24          // e_entry            8 bytes
%def EHDR_PHOFF             32          // e_phoff            8 bytes
%def EHDR_SHOFF             40          // e_shoff            8 bytes
%def EHDR_FLAGS             48          // e_flags            4 bytes
%def EHDR_EHSIZE            52          // e_ehsize           2 bytes
%def EHDR_PHENTSIZE         54          // e_phentsize        2 bytes
%def EHDR_PHNUM             56          // e_phnum            2 bytes
%def EHDR_SHENTSIZE         58          // e_shentsize        2 bytes
%def EHDR_SHNUM             60          // e_shnum            2 bytes
%def EHDR_SHSTRNDX          62          // e_shstrndx         2 bytes

// ============================================================================
// ELF64 SECTION HEADER LAYOUT (Shdr) — Byte Offsets
// ============================================================================
// Total size: 64 bytes
%def ELF64_SHDR_SIZE        64

%def SHDR_NAME              0           // sh_name            4 bytes (index into .shstrtab)
%def SHDR_TYPE              4           // sh_type            4 bytes
%def SHDR_FLAGS             8           // sh_flags           8 bytes
%def SHDR_ADDR              16          // sh_addr            8 bytes
%def SHDR_OFFSET            24          // sh_offset          8 bytes
%def SHDR_SIZE              32          // sh_size            8 bytes
%def SHDR_LINK              40          // sh_link            4 bytes
%def SHDR_INFO              44          // sh_info            4 bytes
%def SHDR_ADDRALIGN         48          // sh_addralign       8 bytes
%def SHDR_ENTSIZE           56          // sh_entsize         8 bytes

// ============================================================================
// SECTION TYPES (sh_type)
// ============================================================================
%def SHT_NULL               0           // Inactive section
%def SHT_PROGBITS           1           // Program-defined content
%def SHT_SYMTAB             2           // Symbol table
%def SHT_STRTAB             3           // String table
%def SHT_RELA               4           // Relocation with explicit addends
%def SHT_HASH               5           // Symbol hash table
%def SHT_DYNAMIC            6           // Dynamic linking info
%def SHT_NOTE               7           // Notes
%def SHT_NOBITS             8           // .bss — occupies no file space
%def SHT_REL                9           // Relocation without addends
%def SHT_SHLIB              10          // Reserved (unspecified semantics)
%def SHT_DYNSYM             11          // Dynamic symbol table
%def SHT_INIT_ARRAY         14          // Array of init function ptrs
%def SHT_FINI_ARRAY         15          // Array of fini function ptrs
%def SHT_PREINIT_ARRAY      16          // Array of pre-init function ptrs
%def SHT_GROUP              17          // Section group
%def SHT_SYMTAB_SHNDX       18          // Extended symbol table index
%def SHT_RELR               19          // Compact relative relocations
%def SHT_LOOS               0x60000000  // OS-specific begin
%def SHT_GNU_HASH           0x6FFFFFF6  // GNU hash table
%def SHT_GNU_VERNEED        0x6FFFFFFE  // GNU version requirement
%def SHT_GNU_VERSYM         0x6FFFFFFF  // GNU version symbol
%def SHT_HIOS               0x6FFFFFFF  // OS-specific end
%def SHT_LOPROC             0x70000000  // Processor-specific begin
%def SHT_X86_64_UNWIND      0x70000001  // x86_64 unwind table
%def SHT_HIPROC             0x7FFFFFFF  // Processor-specific end

// ============================================================================
// SECTION FLAGS (sh_flags)
// ============================================================================
%def SHF_WRITE              0x1         // Section is writable
%def SHF_ALLOC              0x2         // Section occupies memory during exec
%def SHF_EXECINSTR          0x4         // Section contains executable code
%def SHF_MERGE              0x10        // Section may be merged
%def SHF_STRINGS            0x20        // Section contains null-terminated strings
%def SHF_INFO_LINK          0x40        // sh_info holds section header index
%def SHF_LINK_ORDER         0x80        // Preserve order after combining
%def SHF_OS_NONCONFORMING   0x100       // Non-standard OS handling required
%def SHF_GROUP              0x200       // Section is member of a group
%def SHF_TLS                0x400       // Section holds thread-local data
%def SHF_COMPRESSED         0x800       // Section with compressed data
%def SHF_MASKOS             0x0FF00000  // OS-specific flags mask
%def SHF_MASKPROC           0xF0000000  // Processor-specific flags mask
%def SHF_GNU_RETAIN         0x200000    // GNU: Retain section in final link

// ============================================================================
// ELF64 PROGRAM HEADER LAYOUT (Phdr) — Byte Offsets
// ============================================================================
// Total size: 56 bytes
%def ELF64_PHDR_SIZE        56

%def PHDR_TYPE              0           // p_type             4 bytes
%def PHDR_FLAGS             4           // p_flags            4 bytes
%def PHDR_OFFSET            8           // p_offset           8 bytes
%def PHDR_VADDR             16          // p_vaddr            8 bytes
%def PHDR_PADDR             24          // p_paddr            8 bytes
%def PHDR_FILESZ            32          // p_filesz           8 bytes
%def PHDR_MEMSZ             40          // p_memsz            8 bytes
%def PHDR_ALIGN             48          // p_align            8 bytes

// ============================================================================
// SEGMENT TYPES (p_type)
// ============================================================================
%def PT_NULL                0           // Unused entry
%def PT_LOAD                1           // Loadable segment
%def PT_DYNAMIC             2           // Dynamic linking info
%def PT_INTERP              3           // Interpreter path
%def PT_NOTE                4           // Auxiliary info
%def PT_SHLIB               5           // Reserved
%def PT_PHDR                6           // Program header table itself
%def PT_TLS                 7           // Thread-local storage
%def PT_LOOS                0x60000000
%def PT_GNU_EH_FRAME        0x6474E550  // .eh_frame_hdr segment
%def PT_GNU_STACK           0x6474E551  // Stack permissions
%def PT_GNU_RELRO           0x6474E552  // Read-only after relocation
%def PT_GNU_PROPERTY        0x6474E553  // GNU properties
%def PT_HIOS                0x6FFFFFFF
%def PT_LOPROC              0x70000000
%def PT_HIPROC              0x7FFFFFFF

// ============================================================================
// SEGMENT PERMISSION FLAGS (p_flags)
// ============================================================================
%def PF_X                   0x1         // Executable
%def PF_W                   0x2         // Writable
%def PF_R                   0x4         // Readable
%def PF_RX                  0x5         // Readable + Executable (.text)
%def PF_RW                  0x6         // Readable + Writable  (.data/.bss)
%def PF_RWX                 0x7         // All permissions (dangerous)

// ============================================================================
// ELF64 SYMBOL TABLE ENTRY (Sym64) — Byte Offsets
// ============================================================================
// Total size: 24 bytes
%def ELF64_SYM_SIZE         24

%def SYM64_NAME             0           // st_name    4 bytes (strtab index)
%def SYM64_INFO             4           // st_info    1 byte  (bind | type)
%def SYM64_OTHER            5           // st_other   1 byte  (visibility)
%def SYM64_SHNDX            6           // st_shndx   2 bytes (section index)
%def SYM64_VALUE            8           // st_value   8 bytes (address/value)
%def SYM64_SIZE             16          // st_size    8 bytes (symbol size)

// ---- Symbol Binding (high nibble of st_info) ----
%def STB_LOCAL              0           // Local symbol (not visible outside obj)
%def STB_GLOBAL             1           // Global symbol
%def STB_WEAK               2           // Weak symbol (overrideable)
%def STB_LOOS               10
%def STB_GNU_UNIQUE         10          // GNU: unique symbol
%def STB_HIOS               12
%def STB_LOPROC             13
%def STB_HIPROC             15

// ---- Symbol Type (low nibble of st_info) ----
%def STT_NOTYPE             0           // Unspecified type
%def STT_OBJECT             1           // Data object (variable, array)
%def STT_FUNC               2           // Function / code entry point
%def STT_SECTION            3           // Associated with a section
%def STT_FILE               4           // Source file name
%def STT_COMMON             5           // Uninitialised common block
%def STT_TLS                6           // Thread-local storage object
%def STT_LOOS               10
%def STT_GNU_IFUNC          10          // GNU indirect function (ifunc)
%def STT_HIOS               12
%def STT_LOPROC             13
%def STT_HIPROC             15

// ---- Symbol Visibility (low 2 bits of st_other) ----
%def STV_DEFAULT            0           // Default (controlled by binding)
%def STV_INTERNAL           1           // Processor-specific hidden
%def STV_HIDDEN             2           // Hidden from other components
%def STV_PROTECTED          3           // Not preemptable

// ---- Special Section Indices ----
%def SHN_UNDEF              0           // Undefined section
%def SHN_LORESERVE          0xFF00
%def SHN_LOPROC             0xFF00
%def SHN_HIPROC             0xFF1F
%def SHN_LOOS               0xFF20
%def SHN_HIOS               0xFF3F
%def SHN_ABS                0xFFF1      // Absolute value (not relocated)
%def SHN_COMMON             0xFFF2      // Common block — size in st_value
%def SHN_XINDEX             0xFFFF      // Extended index (use SYMTAB_SHNDX)
%def SHN_HIRESERVE          0xFFFF

// ============================================================================
// ELF64 RELOCATION ENTRY — Byte Offsets (Rela — with addend)
// ============================================================================
// Total size: 24 bytes
%def ELF64_RELA_SIZE        24

%def RELA_OFFSET            0           // r_offset   8 bytes
%def RELA_INFO              8           // r_info     8 bytes (sym << 32 | type)
%def RELA_ADDEND            16          // r_addend   8 bytes (signed)

// ---- Relocation Without Addend (Rel) ----
// Total size: 16 bytes
%def ELF64_REL_SIZE         16
%def REL_OFFSET             0
%def REL_INFO               8

// ============================================================================
// x86_64 RELOCATION TYPES (used in r_info low 32 bits)
// ============================================================================
%def R_X86_64_NONE          0           // No relocation
%def R_X86_64_64            1           // Direct 64-bit symbol value
%def R_X86_64_PC32          2           // PC-relative 32-bit signed
%def R_X86_64_GOT32         3           // 32-bit GOT offset
%def R_X86_64_PLT32         4           // 32-bit PLT offset (call)
%def R_X86_64_COPY          5           // Copy symbol at runtime
%def R_X86_64_GLOB_DAT      6           // Create GOT entry
%def R_X86_64_JUMP_SLOT     7           // Create PLT entry
%def R_X86_64_RELATIVE      8           // Adjust by program base
%def R_X86_64_GOTPCREL      9           // 32-bit signed PC-rel GOT
%def R_X86_64_32            10          // Direct 32-bit zero-extended
%def R_X86_64_32S           11          // Direct 32-bit sign-extended
%def R_X86_64_16            12          // Direct 16-bit zero-extended
%def R_X86_64_PC16          13          // PC-relative 16-bit signed
%def R_X86_64_8             14          // Direct 8-bit
%def R_X86_64_PC8           15          // PC-relative 8-bit signed
%def R_X86_64_DTPMOD64      16          // TLS module index
%def R_X86_64_DTPOFF64      17          // TLS module-relative offset
%def R_X86_64_TPOFF64       18          // TP-relative offset, 64-bit
%def R_X86_64_TLSGD         19          // 32-bit PC-rel offset to GD TLS
%def R_X86_64_TLSLD         20          // 32-bit PC-rel offset to LD TLS
%def R_X86_64_DTPOFF32      21          // TLS module-relative offset, 32-bit
%def R_X86_64_GOTTPOFF      22          // 32-bit PC-rel offset to IE TLS
%def R_X86_64_TPOFF32       23          // TP-relative offset, 32-bit
%def R_X86_64_PC64          24          // PC-relative 64-bit
%def R_X86_64_GOTOFF64      25          // 64-bit offset from GOT base
%def R_X86_64_GOTPC32       26          // 32-bit signed PC-rel to GOT
%def R_X86_64_GOT64         27          // 64-bit GOT entry offset
%def R_X86_64_GOTPCREL64    28
%def R_X86_64_GOTPC64       29
%def R_X86_64_GOTPLT64      30
%def R_X86_64_PLTOFF64      31
%def R_X86_64_SIZE32        32
%def R_X86_64_SIZE64        33
%def R_X86_64_GOTPC32_TLSDESC 34
%def R_X86_64_TLSDESC_CALL  35
%def R_X86_64_TLSDESC       36
%def R_X86_64_IRELATIVE     37          // Adjust indirectly
%def R_X86_64_RELATIVE64    38
%def R_X86_64_GOTPCRELX     41          // Relaxable GOTPCREL
%def R_X86_64_REX_GOTPCRELX 42          // Relaxable GOTPCREL (REX)

// ---- AArch64 Relocation Types -----------
%def R_AARCH64_ABS64        257
%def R_AARCH64_COPY         258
%def R_AARCH64_GLOB_DAT     259
%def R_AARCH64_JUMP_SLOT    260
%def R_AARCH64_RELATIVE     261
%def R_AARCH64_ADR_PREL_PG_HI21 275
%def R_AARCH64_ADD_ABS_LO12_NC 277
%def R_AARCH64_CALL26       283
%def R_AARCH64_JMP26        282

// ---- RISC-V Relocation Types -----------
%def R_RISCV_64             2
%def R_RISCV_RELATIVE       3
%def R_RISCV_COPY           4
%def R_RISCV_JUMP_SLOT      5
%def R_RISCV_BRANCH         16
%def R_RISCV_JAL            17
%def R_RISCV_CALL           18
%def R_RISCV_PCREL_HI20     26
%def R_RISCV_PCREL_LO12_I   27
%def R_RISCV_PCREL_LO12_S   28
%def R_RISCV_HI20           29
%def R_RISCV_LO12_I         30
%def R_RISCV_LO12_S         31

// ============================================================================
// HELPER MACRO: ELF64_R_INFO — pack symbol index and reloc type
// ============================================================================
// Usage: ELF64_R_INFO sym_idx, reloc_type  -> result in rax
%macro ELF64_R_INFO 2
    mov     rax, %1
    shl     rax, 32
    or      rax, %2
%endmacro

// ============================================================================
// ELF64 DYNAMIC SECTION TAGS (d_tag in .dynamic)
// ============================================================================
%def DT_NULL                0           // End of dynamic array
%def DT_NEEDED              1           // Name of needed library
%def DT_PLTRELSZ            2           // Size of PLT relocation table
%def DT_PLTGOT              3           // Address of PLT/GOT
%def DT_HASH                4           // Symbol hash table address
%def DT_STRTAB              5           // String table address
%def DT_SYMTAB              6           // Symbol table address
%def DT_RELA                7           // RELA relocation table address
%def DT_RELASZ              8           // Size of RELA table
%def DT_RELAENT             9           // Size of one RELA entry
%def DT_STRSZ               10          // String table size
%def DT_SYMENT              11          // Size of one symbol table entry
%def DT_INIT                12          // Address of init function
%def DT_FINI                13          // Address of fini function
%def DT_SONAME              14          // Shared object name
%def DT_RPATH               15          // Library search path (deprecated)
%def DT_SYMBOLIC            16          // Symbolic flag
%def DT_REL                 17          // REL relocation table
%def DT_RELSZ               18          // Size of REL table
%def DT_RELENT              19          // Size of one REL entry
%def DT_PLTREL              20          // Type of PLT relocation
%def DT_DEBUG               21          // Debugger info
%def DT_TEXTREL             22          // Text section relocation
%def DT_JMPREL              23          // Address of PLT relocation entries
%def DT_BIND_NOW            24          // Process relocations immediately
%def DT_INIT_ARRAY          25          // Array of init function addresses
%def DT_FINI_ARRAY          26          // Array of fini function addresses
%def DT_INIT_ARRAYSZ        27          // Size of DT_INIT_ARRAY
%def DT_FINI_ARRAYSZ        28          // Size of DT_FINI_ARRAY
%def DT_RUNPATH             29          // Library search path
%def DT_FLAGS               30          // Flags for object being loaded
%def DT_GNU_HASH            0x6FFFFEF5  // GNU hash table
%def DT_VERSYM              0x6FFFFFF0  // Version symbol table
%def DT_RELACOUNT           0x6FFFFFF9  // Count of RELA relocations
%def DT_RELCOUNT            0x6FFFFFFA  // Count of REL relocations
%def DT_FLAGS_1             0x6FFFFFFB  // State flags
%def DT_VERDEF              0x6FFFFFFC  // Version definition table
%def DT_VERDEFNUM           0x6FFFFFFD  // Count of verdef entries
%def DT_VERNEED             0x6FFFFFFE  // Version requirement table
%def DT_VERNEEDNUM          0x6FFFFFFF  // Count of verneed entries
