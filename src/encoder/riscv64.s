/*
 ============================================================================
 File        : src/encoder/riscv64.s
 Project     : utasm
 Version     : 0.1.0
 Description : RISC-V 64-bit instruction encoder.
               Implementation mirrors the scale and robustness of amd64.s.
               Supports RV64IM base and extensions.
 ============================================================================
*/

%inc "include/constant.s"
%inc "include/type.s"
%inc "include/macro.s"
%inc "include/arch/riscv64.s"

[SECTION .text]

// ============================================================================
// riscv64_encode_instruction
// ============================================================================
/*
 riscv64_encode_instruction
 Top-level dispatcher for RISC-V 64 encoding.

 Input  : rdi = AsmCtx*
           rsi = INST*
 Output : rax = EXIT_OK or EXIT_ENCODE_FAIL
*/
global riscv64_encode_instruction
riscv64_encode_instruction:
    prologue
    push    rbx
    push    r12
    push    r13

    mov     rbx, rdi               // RBX = AsmCtx
    mov     r12, rsi               // R12 = INST*

    // Reset length counter (RISC-V 32-bit instructions)
    mov     dword [rbx + ASMCTX_inst_len], 4

    movzx   eax, word [r12 + INST_op_id]

    // ---- R-Type (Arithmetic) ----
    IF eax, e, ID_RV_ADD
        mov     r13d, 0x00000033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_SUB
        mov     r13d, 0x40000033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_SLL
        mov     r13d, 0x00001033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_SLT
        mov     r13d, 0x00002033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_SLTU
        mov     r13d, 0x00003033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_XOR
        mov     r13d, 0x00004033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_SRL
        mov     r13d, 0x00005033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_SRA
        mov     r13d, 0x40005033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_OR
        mov     r13d, 0x00006033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_AND
        mov     r13d, 0x00007033 | call riscv64_encode_r_type

    // ---- R-Type (RV64M Extensions) ----
    ELSEIF eax, e, ID_RV_MUL
        mov     r13d, 0x02000033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_MULH
        mov     r13d, 0x02001033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_MULHSU
        mov     r13d, 0x02002033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_MULHU
        mov     r13d, 0x02003033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_DIV
        mov     r13d, 0x02004033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_DIVU
        mov     r13d, 0x02005033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_REM
        mov     r13d, 0x02006033 | call riscv64_encode_r_type
    ELSEIF eax, e, ID_RV_REMU
        mov     r13d, 0x02007033 | call riscv64_encode_r_type

    // ---- I-Type (Immediate Arithmetic) ----
    ELSEIF eax, e, ID_RV_ADDI
        mov     r13d, 0x00000013 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_SLTI
        mov     r13d, 0x00002013 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_SLTIU
        mov     r13d, 0x00003013 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_XORI
        mov     r13d, 0x00004013 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_ORI
        mov     r13d, 0x00006013 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_ANDI
        mov     r13d, 0x00007013 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_SLLI
        mov     r13d, 0x00001013 | call riscv64_encode_i_shift
    ELSEIF eax, e, ID_RV_SRLI
        mov     r13d, 0x00005013 | call riscv64_encode_i_shift
    ELSEIF eax, e, ID_RV_SRAI
        mov     r13d, 0x40005013 | call riscv64_encode_i_shift

    // ---- I-Type (Loads) ----
    ELSEIF eax, e, ID_RV_LB
        mov     r13d, 0x00000003 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_LH
        mov     r13d, 0x00001003 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_LW
        mov     r13d, 0x00002003 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_LD
        mov     r13d, 0x00003003 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_LBU
        mov     r13d, 0x00004003 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_LHU
        mov     r13d, 0x00005003 | call riscv64_encode_i_type
    ELSEIF eax, e, ID_RV_LWU
        mov     r13d, 0x00006003 | call riscv64_encode_i_type

    // ---- S-Type (Stores) ----
    ELSEIF eax, e, ID_RV_SB
        mov     r13d, 0x00000023 | call riscv64_encode_s_type
    ELSEIF eax, e, ID_RV_SH
        mov     r13d, 0x00001023 | call riscv64_encode_s_type
    ELSEIF eax, e, ID_RV_SW
        mov     r13d, 0x00002023 | call riscv64_encode_s_type
    ELSEIF eax, e, ID_RV_SD
        mov     r13d, 0x00003023 | call riscv64_encode_s_type

    // ---- B-Type (Branches) ----
    ELSEIF eax, e, ID_RV_BEQ
        mov     r13d, 0x00000063 | call riscv64_encode_b_type
    ELSEIF eax, e, ID_RV_BNE
        mov     r13d, 0x00001063 | call riscv64_encode_b_type
    ELSEIF eax, e, ID_RV_BLT
        mov     r13d, 0x00004063 | call riscv64_encode_b_type
    ELSEIF eax, e, ID_RV_BGE
        mov     r13d, 0x00005063 | call riscv64_encode_b_type
    ELSEIF eax, e, ID_RV_BLTU
        mov     r13d, 0x00006063 | call riscv64_encode_b_type
    ELSEIF eax, e, ID_RV_BGEU
        mov     r13d, 0x00007063 | call riscv64_encode_b_type

    // ---- U-Type ----
    ELSEIF eax, e, ID_RV_LUI
        mov     r13d, 0x00000037 | call riscv64_encode_u_type
    ELSEIF eax, e, ID_RV_AUIPC
        mov     r13d, 0x00000017 | call riscv64_encode_u_type

    // ---- J-Type ----
    ELSEIF eax, e, ID_RV_JAL
        call    riscv64_encode_j_type
    ELSEIF eax, e, ID_RV_JALR
        call    riscv64_encode_jalr

    // ---- String Operations (AMD64 Parity) ----
    ELSEIF eax, ge, ID_RV_MOVSB
        IF eax, le, ID_RV_MOVSQ
            call riscv64_encode_string_mov
        ENDIF
    ELSEIF eax, ge, ID_RV_STOSB
        IF eax, le, ID_RV_STOSQ
            call riscv64_encode_string_sto
        ENDIF

    // ---- Type Conversion & Bit Reversal ----
    ELSEIF eax, e, ID_RV_REV8
        call    riscv64_encode_rev8
    ELSEIF eax, ge, ID_RV_SEXTB
        IF eax, le, ID_RV_SEXTH
            call riscv64_encode_extend
        ENDIF

    // ---- Privileged & CSR Instructions ----
    ELSEIF eax, ge, 3084            // CSR range (CSRC to CSRWI)
        IF eax, le, 3096
            call riscv64_encode_csr
        ENDIF
    ELSEIF eax, e, 3121             // ECALL
        mov     edi, 0x00000073 | call riscv64_emit_word
    ELSEIF eax, e, 3122             // EBREAK
        mov     edi, 0x00100073 | call riscv64_emit_word
    ELSEIF eax, e, 3244             // MRET
        mov     edi, 0x30200073 | call riscv64_emit_word
    ELSEIF eax, e, 3332             // SRET
        mov     edi, 0x10200073 | call riscv64_emit_word

    // ---- Memory Barriers ----
    ELSEIF eax, e, 3123             // FENCE
        call    riscv64_encode_fence
    ELSEIF eax, e, 3124             // FENCE.I
        mov     edi, 0x0000100F | call riscv64_emit_word

    // ---- Atomic Memory Operations (AMO) ----
    ELSEIF eax, ge, 3033            // AMOADD.W range
        IF eax, le, 3083
            call riscv64_encode_amo
        ENDIF

    // ---- Floating Point (Basic RV64F/D) ----
    ELSEIF eax, ge, 3128            // FADD.S range
        IF eax, le, 3180
            call riscv64_encode_fp
        ENDIF

    // ---- Pseudo Instructions ----
    ELSEIF eax, e, ID_RV_LI
        call    riscv64_encode_li

    ELSE
        mov     rax, EXIT_ENCODE_FAIL
        jmp     .done
    ENDIF

    xor     rax, rax

.done:
    pop     r13
    pop     r12
    pop     rbx
    epilogue

// ============================================================================
// Internal Helpers & Encoders
// ============================================================================

riscv64_emit_word:
    prologue
    mov     rdx, rdi               // instruction word
    mov     rdi, rbx               // AsmCtx
    mov     rsi, [r12 + INST_section]
    extern  asmctx_emit_dword
    call    asmctx_emit_dword
    epilogue

// ---- R-Type ----
// Format: funct7 | rs2 | rs1 | funct3 | rd | opcode
riscv64_encode_r_type:
    prologue
    lea     r10, [r12 + INST_op0]  // rd
    lea     r11, [r12 + INST_op1]  // rs1
    lea     r9,  [r12 + INST_op2]  // rs2
    
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 15
    or      eax, edi
    movzx   edi, byte [r9 + OPERAND_reg]
    shl     edi, 20
    or      eax, edi
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- I-Type ----
// Format: imm[11:0] | rs1 | funct3 | rd | opcode
riscv64_encode_i_type:
    prologue
    lea     r10, [r12 + INST_op0]  // rd
    lea     r11, [r12 + INST_op1]  // rs1 (or mem base)
    
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    
    IF byte [r11 + OPERAND_kind], e, OP_MEM
        movzx   edi, byte [r11 + OPERAND_base]
        shl     edi, 15
        or      eax, edi
        mov     edi, [r11 + OPERAND_imm]
    ELSE
        movzx   edi, byte [r11 + OPERAND_reg]
        shl     edi, 15
        or      eax, edi
        lea     r9, [r12 + INST_op2]
        mov     edi, [r9 + OPERAND_imm]
    ENDIF
    
    and     edi, 0xFFF
    shl     edi, 20
    or      eax, edi
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- I-Shift Type ----
// SLLI, SRLI, SRAI (imm is 6-bit for RV64)
riscv64_encode_i_shift:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     r9,  [r12 + INST_op2]
    
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 15
    or      eax, edi
    
    mov     edi, [r9 + OPERAND_imm]
    and     edi, 0x3F              // 6-bit shift amount
    shl     edi, 20
    or      eax, edi
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- S-Type ----
// Format: imm[11:5] | rs2 | rs1 | funct3 | imm[4:0] | opcode
riscv64_encode_s_type:
    prologue
    lea     r10, [r12 + INST_op0]  // rs2 (source)
    lea     r11, [r12 + INST_op1]  // [rs1, imm]
    
    mov     eax, r13d
    movzx   edi, byte [r11 + OPERAND_base]
    shl     edi, 15
    or      eax, edi
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 20
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    mov     ecx, edi
    and     ecx, 0x1F              // imm[4:0]
    shl     ecx, 7
    or      eax, ecx
    shr     edi, 5
    and     edi, 0x7F              // imm[11:5]
    shl     edi, 25
    or      eax, edi
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- B-Type ----
// Format: imm[12] | imm[10:5] | rs2 | rs1 | funct3 | imm[4:1] | imm[11] | opcode
riscv64_encode_b_type:
    prologue
    lea     r10, [r12 + INST_op0]  // rs1
    lea     r11, [r12 + INST_op1]  // rs2
    lea     r9,  [r12 + INST_op2]  // imm
    
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 15
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 20
    or      eax, edi
    
    mov     edi, [r9 + OPERAND_imm]
    // Scramble bits
    mov     ecx, edi
    and     ecx, 0x800             // imm[11]
    shr     ecx, 4
    or      eax, ecx
    
    mov     ecx, edi
    and     ecx, 0x1E              // imm[4:1]
    shl     ecx, 7
    or      eax, ecx
    
    mov     ecx, edi
    and     ecx, 0x7E0             // imm[10:5]
    shl     ecx, 20
    or      eax, ecx
    
    mov     ecx, edi
    and     ecx, 0x1000            // imm[12]
    shl     ecx, 19
    or      eax, ecx
    
    IF byte [r9 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx
        mov     rsi, [r12 + INST_offset]
        mov     rdx, [r9 + OPERAND_value]
        xor     rcx, rcx
        mov     r8, R_RISCV_BRANCH
        extern  reloc_record
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- U-Type ----
// Format: imm[31:12] | rd | opcode
riscv64_encode_u_type:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    and     edi, 0xFFFFF000
    or      eax, edi
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- J-Type (JAL) ----
riscv64_encode_j_type:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, 0x0000006F
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    // Scramble bits
    mov     ecx, edi
    and     ecx, 0xFF000           // imm[19:12]
    or      eax, ecx
    
    mov     ecx, edi
    and     ecx, 0x800             // imm[11]
    shl     ecx, 9
    or      eax, ecx
    
    mov     ecx, edi
    and     ecx, 0x7FE             // imm[10:1]
    shl     ecx, 20
    or      eax, ecx
    
    mov     ecx, edi
    and     ecx, 0x100000          // imm[20]
    shl     ecx, 11
    or      eax, ecx
    
    IF byte [r11 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx
        mov     rsi, [r12 + INST_offset]
        mov     rdx, [r11 + OPERAND_value]
        xor     rcx, rcx
        mov     r8, R_RISCV_JAL
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- JALR ----
riscv64_encode_jalr:
    prologue
    mov     r13d, 0x00000067
    call    riscv64_encode_i_type
    epilogue

// ---- riscv64_encode_string_mov ----
riscv64_encode_string_mov:
    prologue
    // LB t0, 0(a1)      (0x00058283)
    // SB t0, 0(a2)      (0x00560023)
    // ADDI a1, a1, 1    (0x00158593)
    // ADDI a2, a2, 1    (0x00160613)
    // ADDI a3, a3, -1   (0xFFF68693)
    // BNE a3, zero, -12 (0xFE069AE3)
    mov     edi, 0x00058283 | call riscv64_emit_word
    mov     edi, 0x00560023 | call riscv64_emit_word
    mov     edi, 0x00158593 | call riscv64_emit_word
    mov     edi, 0x00160613 | call riscv64_emit_word
    mov     edi, 0xFFF68693 | call riscv64_emit_word
    mov     edi, 0xFE069AE3 | call riscv64_emit_word
    epilogue

// ---- riscv64_encode_rev8 ----
riscv64_encode_rev8:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    mov     eax, 0x6B805013        // REV8 base (Zbb)
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 15
    or      eax, edi
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- riscv64_encode_extend ----
riscv64_encode_extend:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    mov     eax, 0x60401013        // SEXT.B base
    IF word [r12 + INST_op_id], e, ID_RV_SEXTH
        mov eax, 0x60501013
    ENDIF
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 15
    or      eax, edi
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- riscv64_encode_csr ----
// CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI
riscv64_encode_csr:
    prologue
    lea     r10, [r12 + INST_op0] // rd
    lea     r11, [r12 + INST_op1] // csr
    lea     r9,  [r12 + INST_op2] // rs1 or uimm
    
    mov     eax, 0x00000073
    movzx   ecx, word [r12 + INST_op_id]
    
    // Funct3 mapping
    IF ecx, e, ID_RV_CSRRW | or eax, 0x00001000 | ENDIF
    IF ecx, e, ID_RV_CSRRS | or eax, 0x00002000 | ENDIF
    IF ecx, e, ID_RV_CSRRC | or eax, 0x00003000 | ENDIF
    IF ecx, e, ID_RV_CSRRWI | or eax, 0x00005000 | ENDIF
    IF ecx, e, ID_RV_CSRRSI | or eax, 0x00006000 | ENDIF
    IF ecx, e, ID_RV_CSRRCI | or eax, 0x00007000 | ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    and     edi, 0xFFF
    shl     edi, 20
    or      eax, edi
    
    IF byte [r9 + OPERAND_kind], e, OP_REG
        movzx edi, byte [r9 + OPERAND_reg]
        shl   edi, 15
        or    eax, edi
    ELSE
        mov   edi, [r9 + OPERAND_imm]
        and   edi, 0x1F
        shl   edi, 15
        or    eax, edi
    ENDIF
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue

// ---- riscv64_encode_fp ----
// FADD.S/D, FSUB.S/D, FMUL.S/D, FDIV.S/D, FSQRT.S/D
riscv64_encode_fp:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     r9,  [r12 + INST_op2]
    
    mov     eax, 0x00000053
    movzx   ecx, word [r12 + INST_op_id]
    
    // Funct7 & Funct3 mapping
    IF ecx, ge, ID_RV_FADD_S | IF ecx, le, ID_RV_FADD_D // FADD
        or eax, 0x00000000
    ENDIF | ENDIF
    IF ecx, ge, ID_RV_FSUB_S | IF ecx, le, ID_RV_FSUB_D // FSUB
        or eax, 0x08000000
    ENDIF | ENDIF
    IF ecx, ge, ID_RV_FMUL_S | IF ecx, le, ID_RV_FMUL_D // FMUL
        or eax, 0x10000000
    ENDIF | ENDIF
    IF ecx, ge, ID_RV_FDIV_S | IF ecx, le, ID_RV_FDIV_D // FDIV
        or eax, 0x18000000
    ENDIF | ENDIF
    
    // Precision: bit 25 (0=Single, 1=Double)
    // We assume ID even=single, odd=double in the ISA table
    test    ecx, 1
    jnz     .double
    jmp     .reg
.double:
    or      eax, 0x01000000
    
.reg:
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 7
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 15
    or      eax, edi
    movzx   edi, byte [r9 + OPERAND_reg]
    shl     edi, 20
    or      eax, edi
    
    mov     rdi, rax
    call    riscv64_emit_word
    epilogue
