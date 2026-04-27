/*
 ============================================================================
 File        : include/register.s
 Project     : utasm
 Version     : 0.1.0
 Description : AMD64 register semantic aliases for kernel and OS development.
               Provides ABI calling convention aliases, system register
               constants, and MSR identifiers usable in utasm source files.
 ============================================================================
*/

// ============================================================================
// AMD64 SYSV ABI — CALLING CONVENTION ALIASES
// ============================================================================
// These aliases map the SysV AMD64 ABI roles onto concrete register names.
// Use these in kernel code for self-documenting system call sequences.

%def ARG1                   rdi     // 1st function argument
%def ARG2                   rsi     // 2nd function argument
%def ARG3                   rdx     // 3rd function argument
%def ARG4                   rcx     // 4th function argument
%def ARG5                   r8      // 5th function argument
%def ARG6                   r9      // 6th function argument
%def RETVAL                 rax     // primary return value
%def RETVAL2                rdx     // secondary return value (rdx:rax pair)
%def SYSCALL_NUM            rax     // system call number register
%def SYSCALL_ARG1           rdi     // syscall argument 1
%def SYSCALL_ARG2           rsi     // syscall argument 2
%def SYSCALL_ARG3           rdx     // syscall argument 3
%def SYSCALL_ARG4           r10     // syscall argument 4 (note: NOT rcx)
%def SYSCALL_ARG5           r8      // syscall argument 5
%def SYSCALL_ARG6           r9      // syscall argument 6
%def SYSCALL_RET            rax     // syscall return value / error (negative)

// ---- Callee-Saved (non-volatile) Registers ----
%def CALLEE0                rbx
%def CALLEE1                r12
%def CALLEE2                r13
%def CALLEE3                r14
%def CALLEE4                r15
%def FRAME_PTR              rbp
%def STACK_PTR              rsp

// ============================================================================
// SEGMENT REGISTER SELECTOR VALUES
// ============================================================================
// Standard GDT selector values used in a flat 64-bit kernel.
// The RPL (bits 1:0) = 0 means Ring 0 (kernel), = 3 means Ring 3 (user).

%def SEL_NULL               0x0000  // null descriptor
%def SEL_KERNEL_CODE        0x0008  // kernel code segment (Ring 0)
%def SEL_KERNEL_DATA        0x0010  // kernel data segment (Ring 0)
%def SEL_USER_CODE          0x001B  // user code  segment (Ring 3, RPL=3)
%def SEL_USER_DATA          0x0023  // user data  segment (Ring 3, RPL=3)
%def SEL_TSS                0x0028  // Task State Segment descriptor

// ---- Segment Override Prefix Bytes ----
%def SEG_ES                 0x26
%def SEG_CS                 0x2E
%def SEG_SS                 0x36
%def SEG_DS                 0x3E
%def SEG_FS                 0x64
%def SEG_GS                 0x65

// ============================================================================
// CONTROL REGISTER BIT MASKS
// ============================================================================

// ---- CR0 ----
%def CR0_PE                 0x00000001  // Protected Mode Enable
%def CR0_MP                 0x00000002  // Monitor Coprocessor
%def CR0_EM                 0x00000004  // Emulation (disable x87)
%def CR0_TS                 0x00000008  // Task Switched (lazy FPU)
%def CR0_ET                 0x00000010  // Extension Type
%def CR0_NE                 0x00000020  // Numeric Error (x87 internal)
%def CR0_WP                 0x00010000  // Write Protect (Ring 0 obeys PTE WP)
%def CR0_AM                 0x00040000  // Alignment Mask
%def CR0_NW                 0x20000000  // Not Write-through (cache)
%def CR0_CD                 0x40000000  // Cache Disable
%def CR0_PG                 0x80000000  // Paging Enable

// ---- CR4 ----
%def CR4_VME                0x00000001  // Virtual-8086 Mode Extensions
%def CR4_PVI                0x00000002  // Protected-Mode Virtual Interrupts
%def CR4_TSD                0x00000004  // Time Stamp Disable (RDTSC in Ring 0 only)
%def CR4_DE                 0x00000008  // Debugging Extensions
%def CR4_PSE                0x00000010  // Page Size Extension (4MB pages)
%def CR4_PAE                0x00000020  // Physical Address Extension (>4GB)
%def CR4_MCE                0x00000040  // Machine Check Enable
%def CR4_PGE                0x00000080  // Page Global Enable (TLB global pages)
%def CR4_PCE                0x00000100  // Performance Counter Enable
%def CR4_OSFXSR             0x00000200  // OS support for FXSAVE/FXRSTOR
%def CR4_OSXMMEXCPT         0x00000400  // OS Unmasked SIMD FP exceptions
%def CR4_UMIP               0x00000800  // User-Mode Instruction Prevention
%def CR4_LA57               0x00001000  // 5-Level Paging (57-bit VA)
%def CR4_VMXE               0x00002000  // Virtual Machine Extensions Enable
%def CR4_SMXE               0x00004000  // Safer Mode Extensions Enable
%def CR4_FSGSBASE           0x00010000  // RDFSBASE/RDGSBASE/WRFSBASE/WRGSBASE
%def CR4_PCIDE              0x00020000  // PCID Enable
%def CR4_OSXSAVE            0x00040000  // XSAVE and Processor Extended States
%def CR4_SMEP               0x00100000  // Supervisor Mode Execution Protection
%def CR4_SMAP               0x00200000  // Supervisor Mode Access Protection
%def CR4_PKE                0x00400000  // Protection Keys for User Pages
%def CR4_CET                0x00800000  // Control-flow Enforcement Technology
%def CR4_PKS                0x01000000  // Protection Keys for Supervisor Pages

// ---- EFLAGS / RFLAGS bit positions ----
%def RFLAGS_CF              0x00000001  // Carry Flag
%def RFLAGS_PF              0x00000004  // Parity Flag
%def RFLAGS_AF              0x00000010  // Auxiliary Carry Flag
%def RFLAGS_ZF              0x00000040  // Zero Flag
%def RFLAGS_SF              0x00000080  // Sign Flag
%def RFLAGS_TF              0x00000100  // Trap Flag (single-step)
%def RFLAGS_IF              0x00000200  // Interrupt Enable Flag
%def RFLAGS_DF              0x00000400  // Direction Flag
%def RFLAGS_OF              0x00000800  // Overflow Flag
%def RFLAGS_IOPL_MASK       0x00003000  // I/O Privilege Level (bits 12-13)
%def RFLAGS_NT              0x00004000  // Nested Task Flag
%def RFLAGS_RF              0x00010000  // Resume Flag
%def RFLAGS_VM              0x00020000  // Virtual-8086 Mode
%def RFLAGS_AC              0x00040000  // Alignment Check
%def RFLAGS_VIF             0x00080000  // Virtual Interrupt Flag
%def RFLAGS_VIP             0x00100000  // Virtual Interrupt Pending
%def RFLAGS_ID              0x00200000  // CPUID support probe bit

// ============================================================================
// MODEL-SPECIFIC REGISTERS (MSRs)
// ============================================================================
// Used with RDMSR / WRMSR instructions. Load address into ECX first.

// ---- Extended Feature Enable Register ----
%def MSR_EFER               0xC0000080  // Extended Feature Enables
%def EFER_SCE               0x00000001  // SYSCALL/SYSRET enable
%def EFER_LME               0x00000100  // Long Mode Enable
%def EFER_LMA               0x00000400  // Long Mode Active (read-only)
%def EFER_NXE               0x00000800  // No-Execute Enable (NX bit in PTE)
%def EFER_SVME              0x00001000  // AMD-V (SVM) Enable
%def EFER_LMSLE             0x00002000  // Long Mode Segment Limit Enable
%def EFER_FFXSR             0x00004000  // Fast FXSAVE/FXRSTOR
%def EFER_TCE               0x00008000  // Translation Cache Extension (AMD)

// ---- SYSCALL / SYSRET Target MSRs ----
%def MSR_STAR               0xC0000081  // SYSCALL CS:SS selectors + compat ret
%def MSR_LSTAR              0xC0000082  // SYSCALL target RIP (Long Mode)
%def MSR_CSTAR              0xC0000083  // SYSCALL target RIP (Compat Mode)
%def MSR_SFMASK             0xC0000084  // RFLAGS mask on SYSCALL entry

// ---- FS/GS Base MSRs ----
%def MSR_FS_BASE            0xC0000100  // FS.Base virtual address
%def MSR_GS_BASE            0xC0000101  // GS.Base virtual address
%def MSR_KERNEL_GS_BASE     0xC0000102  // Shadow GS.Base (SWAPGS target)

// ---- Local APIC MSR ----
%def MSR_APIC_BASE          0x0000001B  // APIC base address + enable bits
%def APIC_BASE_BSP          0x00000100  // Is bootstrap processor?
%def APIC_BASE_ENABLE       0x00000800  // Global APIC enable
%def APIC_BASE_X2APIC       0x00000C00  // x2APIC mode

// ---- TSC & Performance MSRs ----
%def MSR_TSC                0x00000010  // Time Stamp Counter
%def MSR_TSC_DEADLINE       0x000006E0  // TSC Deadline for APIC timer
%def MSR_PERF_CTL0          0xC0010000  // AMD: Performance Control 0
%def MSR_PERF_CTR0          0xC0010004  // AMD: Performance Counter 0
%def MSR_FIXED_CTR0         0x00000309  // Intel: Fixed Counter 0 (inst retired)
%def MSR_FIXED_CTR1         0x0000030A  // Intel: Fixed Counter 1 (clk unhalted)
%def MSR_FIXED_CTR2         0x0000030B  // Intel: Fixed Counter 2 (ref cycles)

// ---- Memory Type Range Registers ----
%def MSR_MTRR_DEF_TYPE      0x000002FF  // MTRR default type
%def MSR_MTRR_PHYSBASE0     0x00000200  // MTRR physical base 0
%def MSR_MTRR_PHYSMASK0     0x00000201  // MTRR physical mask 0

// ---- Thermal & Power MSRs ----
%def MSR_THERM_STATUS       0x0000019C  // Thermal Status register
%def MSR_POWER_CTL          0x000001FC  // Power Control register

// ---- Spectre / Meltdown Mitigations ----
%def MSR_SPEC_CTRL          0x00000048  // Speculation Control (IBRS, STIBP)
%def MSR_PRED_CMD           0x00000049  // Prediction Command (IBPB)
%def SPEC_CTRL_IBRS         0x00000001  // Indirect Branch Restricted Speculation
%def SPEC_CTRL_STIBP        0x00000002  // Single Thread Indirect Branch Predictors
%def SPEC_CTRL_SSBD         0x00000004  // Speculative Store Bypass Disable

// ============================================================================
// DEBUG REGISTER BIT MASKS
// ============================================================================

// ---- DR7 — Debug Control Register ----
%def DR7_L0                 0x00000001  // Local enable breakpoint 0
%def DR7_G0                 0x00000002  // Global enable breakpoint 0
%def DR7_L1                 0x00000004  // Local enable breakpoint 1
%def DR7_G1                 0x00000008  // Global enable breakpoint 1
%def DR7_L2                 0x00000010  // Local enable breakpoint 2
%def DR7_G2                 0x00000020  // Global enable breakpoint 2
%def DR7_L3                 0x00000040  // Local enable breakpoint 3
%def DR7_G3                 0x00000080  // Global enable breakpoint 3
%def DR7_LE                 0x00000100  // Local exact breakpoint enable
%def DR7_GE                 0x00000200  // Global exact breakpoint enable
%def DR7_RTM                0x00000800  // Advanced debugging of RTM regions
%def DR7_GD                 0x00002000  // General Detect Enable

// ---- DR6 — Debug Status Register ----
%def DR6_B0                 0x00000001  // Breakpoint 0 triggered
%def DR6_B1                 0x00000002  // Breakpoint 1 triggered
%def DR6_B2                 0x00000004  // Breakpoint 2 triggered
%def DR6_B3                 0x00000008  // Breakpoint 3 triggered
%def DR6_BD                 0x00002000  // Debug register accessed
%def DR6_BS                 0x00004000  // Single-step triggered
%def DR6_BT                 0x00008000  // Task switch triggered

// ============================================================================
// x87 FPU CONTROL / STATUS WORD BITS
// ============================================================================

%def FCW_IM                 0x0001      // Invalid Operation mask
%def FCW_DM                 0x0002      // Denormalized Operand mask
%def FCW_ZM                 0x0004      // Zero Divide mask
%def FCW_OM                 0x0008      // Overflow mask
%def FCW_UM                 0x0010      // Underflow mask
%def FCW_PM                 0x0020      // Precision mask
%def FCW_PC_SINGLE          0x0000      // Precision: 24-bit mantissa
%def FCW_PC_DOUBLE          0x0200      // Precision: 53-bit mantissa
%def FCW_PC_EXTENDED        0x0300      // Precision: 64-bit mantissa (default)
%def FCW_RC_NEAREST         0x0000      // Round: to nearest (default)
%def FCW_RC_DOWN            0x0400      // Round: toward -infinity
%def FCW_RC_UP              0x0800      // Round: toward +infinity
%def FCW_RC_TRUNC           0x0C00      // Round: toward zero (truncate)

// ============================================================================
// MXCSR — SSE Control/Status Register Bits
// ============================================================================

%def MXCSR_IE               0x0001      // Invalid Operation flag
%def MXCSR_DE               0x0002      // Denormal flag
%def MXCSR_ZE               0x0004      // Divide-by-Zero flag
%def MXCSR_OE               0x0008      // Overflow flag
%def MXCSR_UE               0x0010      // Underflow flag
%def MXCSR_PE               0x0020      // Precision flag
%def MXCSR_DAZ              0x0040      // Denormals Are Zeros
%def MXCSR_IM               0x0080      // Invalid Operation mask
%def MXCSR_DM               0x0100      // Denormal mask
%def MXCSR_ZM               0x0200      // Divide-by-Zero mask
%def MXCSR_OM               0x0400      // Overflow mask
%def MXCSR_UM               0x0800      // Underflow mask
%def MXCSR_PM               0x1000      // Precision mask
%def MXCSR_RC_NEAREST        0x0000      // Round to nearest
%def MXCSR_RC_DOWN           0x2000      // Round toward -infinity
%def MXCSR_RC_UP             0x4000      // Round toward +infinity
%def MXCSR_RC_TRUNC          0x6000      // Round toward zero
%def MXCSR_FTZ              0x8000      // Flush to Zero (denormals)
%def MXCSR_DEFAULT          0x1F80      // Recommended kernel default
