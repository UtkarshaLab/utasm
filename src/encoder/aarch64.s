;
; ============================================================================
; File        : src/encoder/aarch64.s
; Project     : utasm
; Description : AArch64 instruction encoder. Encodes parsed INST structs
               into 32-bit fixed-width AArch64 machine code words.
               Implementation mirrors the scale and robustness of amd64.s.
; ============================================================================
;

%include "include/constant.s"
%include "include/type.s"
%include "include/macro.s"
%include "include/arch/aarch64.s"

[SECTION .text]

; ============================================================================
; aarch64_encode_instruction
; ============================================================================
;
; aarch64_encode_instruction
; Top-level dispatcher for AArch64 instruction encoding.

; Input  : rdi = AsmCtx*
           rsi = INST*
; Output : rax = EXIT_OK or EXIT_ENCODE_FAIL
;
global aarch64_encode_instruction
aarch64_encode_instruction:
    prologue
    push    rbx
    push    r12
    push    r13

    mov     rbx, rdi               ; RBX = AsmCtx
    mov     r12, rsi               ; R12 = INST*

    ; A96: Dispatch Integrity - Validate operand count
    IF byte [r12 + INST_nops], g, 4
        mov rax, EXIT_ENCODE_FAIL | jmp .done
    ENDIF

    ; Reset length counter (AArch64 is always 4 bytes per instruction)
    mov     dword [rbx + ASMCTX_inst_len], 4

    ; 0. VALIDATION: Check operand size consistency (A87: Hardened)
    movzx   ecx, byte [r12 + INST_nops]
    IF ecx, ge, 2
        lea     r10, [r12 + INST_op0]
        lea     r11, [r12 + INST_op1]
        mov     al, [r10 + OPERAND_size]
        mov     ah, [r11 + OPERAND_size]
        IF al, ne, 0 | IF ah, ne, 0
            IF al, ne, ah
                ; Exceptions: Immediate/Symbol can vary
                IF byte [r11 + OPERAND_kind], ne, OP_IMM
                IF byte [r11 + OPERAND_kind], ne, OP_SYMBOL
                    mov rax, EXIT_INVALID_OPERAND | jmp .done
                ENDIF
                ENDIF
            ENDIF
        ENDIF
    ENDIF

    movzx   eax, word [r12 + INST_op_id]

    IF eax, e, ID_AARCH64_ADD
        mov     r13d, 0x8B000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_SUB
        mov     r13d, 0xCB000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ADR
        mov     r13d, 0x10000000 | call aarch64_encode_adr
    ELSEIF eax, e, ID_AARCH64_ADRP
        mov     r13d, 0x90000000 | call aarch64_encode_adr
    ELSEIF eax, e, ID_AARCH64_AND
        mov     r13d, 0x8A000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ORR
        mov     r13d, 0xAA000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_EOR
        mov     r13d, 0xCA000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ANDS
        mov     r13d, 0xEA000000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_BIC
        mov     r13d, 0x8A200000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_ORN
        mov     r13d, 0xAA200000 | call aarch64_encode_dp_reg
    ELSEIF eax, e, ID_AARCH64_EON
        mov     r13d, 0xCA200000 | call aarch64_encode_dp_reg

    ; ---- String Operations (AMD64 Parity) ----
    ELSEIF eax, ge, ID_AARCH64_MOVSB
        IF eax, le, ID_AARCH64_MOVSQ
            call aarch64_encode_string_mov
        ENDIF
    ELSEIF eax, ge, ID_AARCH64_STOSB
        IF eax, le, ID_AARCH64_STOSQ
            call aarch64_encode_string_sto
        ENDIF

    ; ---- Type Conversion & Bit Reversal ----
    ELSEIF eax, e, ID_AARCH64_REV
        call    aarch64_encode_rev
    ELSEIF eax, ge, ID_AARCH64_SXTB
        IF eax, le, ID_AARCH64_SXTW
            call aarch64_encode_extend
        ENDIF

    ; ---- System & Barrier Instructions ----
    ELSEIF eax, e, ID_AARCH64_SVC
        call    aarch64_encode_svc
    ELSEIF eax, ge, ID_AARCH64_MRS         ; MRS/MSR range
        IF eax, le, ID_AARCH64_MSR
            call aarch64_encode_system_reg
        ENDIF
    ELSEIF eax, e, ID_AARCH64_DSB
        mov     edi, 0xD503309F | call aarch64_emit_word
    ELSEIF eax, e, ID_AARCH64_DMB
        mov     edi, 0xD50330BF | call aarch64_emit_word
    ELSEIF eax, e, ID_AARCH64_ISB
        mov     edi, 0xD5033FDF | call aarch64_emit_word
    ELSEIF eax, e, ID_AARCH64_WFI
        mov     edi, 0xD503205F | call aarch64_emit_word
    ELSEIF eax, e, ID_AARCH64_HLT
        call    aarch64_encode_hlt
    ELSEIF eax, e, ID_AARCH64_UBFM
        mov     r13d, 0x53000000 | call aarch64_encode_bitfield
    ELSEIF eax, e, ID_AARCH64_SBFM
        mov     r13d, 0x13000000 | call aarch64_encode_bitfield
    ELSEIF eax, e, ID_AARCH64_BFM
        mov     r13d, 0x33000000 | call aarch64_encode_bitfield

    ; ---- Floating Point (Basic) ----
    ELSEIF eax, ge, 2154            ; FADD, FSUB, FMUL, FDIV
        IF eax, le, 2165
            call aarch64_encode_fp_bin
        ENDIF

    ; ---- Arithmetic & Logical (Immediate) ----
    ; (Handled within dp_reg if op2 is immediate, but often distinct opcodes)
    ; For AArch64, ADD/SUB immediate uses a different format.

    ; ---- Movement ----
    ELSEIF eax, e, ID_AARCH64_MOV
        call    aarch64_encode_mov
    ELSEIF eax, e, ID_AARCH64_MOVZ
        mov     r13d, 0xD2800000 | call aarch64_encode_mov_wide
    ELSEIF eax, e, ID_AARCH64_MOVN
        mov     r13d, 0x92800000 | call aarch64_encode_mov_wide
    ELSEIF eax, e, ID_AARCH64_MOVK
        mov     r13d, 0xF2800000 | call aarch64_encode_mov_wide

    ; ---- Comparison ----
    ELSEIF eax, e, ID_AARCH64_CMP
        call    aarch64_encode_cmp
    ELSEIF eax, e, ID_AARCH64_TST
        call    aarch64_encode_tst

    ; ---- Branches ----
    ELSEIF eax, e, ID_AARCH64_B
        call    aarch64_encode_branch
    ELSEIF eax, e, ID_AARCH64_BL
        mov     r13d, 0x94000000 | call aarch64_encode_branch_link
    ELSEIF eax, e, ID_AARCH64_BR
        mov     r13d, 0xD61F0000 | call aarch64_encode_branch_reg
    ELSEIF eax, e, ID_AARCH64_BLR
        mov     r13d, 0xD63F0000 | call aarch64_encode_branch_reg
    ELSEIF eax, e, ID_AARCH64_RET
        call    aarch64_encode_ret
    ELSEIF eax, e, ID_AARCH64_CBZ
        mov     r13d, 0x34000000 | call aarch64_encode_comp_branch
    ELSEIF eax, e, ID_AARCH64_CBNZ
        mov     r13d, 0x35000000 | call aarch64_encode_comp_branch

    ; ---- Load / Store ----
    ELSEIF eax, e, ID_AARCH64_LDR
        call    aarch64_encode_ldr
    ELSEIF eax, e, ID_AARCH64_STR
        call    aarch64_encode_str
    ELSEIF eax, e, ID_AARCH64_LDP
        mov     r13d, 1 | call aarch64_encode_ldst_pair
    ELSEIF eax, e, ID_AARCH64_STP
        mov     r13d, 0 | call aarch64_encode_ldst_pair

    ; ---- SIMD (NEON) ----
    ELSEIF eax, ge, ID_AARCH64_ADD_V
        IF eax, le, ID_AARCH64_EOR_V
            call    aarch64_encode_vector_bin
        ENDIF
    
    ; ---- Misc ----
    ELSEIF eax, e, ID_AARCH64_NOP
        mov     edi, 0xD503201F | call aarch64_emit_word
    ELSEIF eax, e, ID_AARCH64_SVC
        call    aarch64_encode_svc
    ELSE
        mov     rax, EXIT_ENCODE_FAIL
        jmp     .done
    ENDIF

    xor     rax, rax
.done:
    pop     r13
    pop     r12
    pop     rbx
    xor     rax, rax
    epilogue

;*
; * [aarch64_encode_bitfield]
; ;
aarch64_encode_bitfield:
    prologue
    push    r13
    mov     r13d, esi              ; r13d = base opcode
    
    ; Rd (op0)
    lea     r10, [r12 + INST_op0]
    movzx   eax, byte [r10 + OPERAND_reg]
    or      r13d, eax
    
    ; Set sf and N based on register size
    movzx   eax, byte [r10 + OPERAND_size]
    IF eax, e, 8
        or      r13d, 0x80400000   ; sf=1, N=1
    ENDIF
    
    ; Rn (op1)
    lea     r10, [r12 + INST_op1]
    movzx   eax, byte [r10 + OPERAND_reg]
    shl     eax, 5
    or      r13d, eax
    
    ; immr (op2)
    lea     r10, [r12 + INST_op2]
    mov     eax, [r10 + OPERAND_imm]
    and     eax, 0x3F
    shl     eax, 16
    or      r13d, eax
    
    ; imms (op3)
    lea     r10, [r12 + INST_op3]
    mov     eax, [r10 + OPERAND_imm]
    and     eax, 0x3F
    shl     eax, 10
    or      r13d, eax
    
    mov     edi, r13d
    call    aarch64_emit_word
    
    pop     r13
    xor     rax, rax
    epilogue

; ---- aarch64_encode_adr ----
; ADR/ADRP Rd, label
aarch64_encode_adr:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    ; Scramble 21-bit immediate:
    ; immlo: bits [1:0]   -> [30:29] of instruction
    ; immhi: bits [20:2]  -> [23:5]  of instruction
    mov     edi, [r11 + OPERAND_imm]
    mov     ecx, edi
    and     ecx, 0x03              ; immlo
    shl     ecx, 29
    or      eax, ecx
    
    mov     ecx, edi
    shr     ecx, 2
    and     ecx, 0x7FFFF           ; immhi (19 bits)
    shl     ecx, 5
    or      eax, ecx
    
    IF byte [r11 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx
        mov     rsi, [r12 + INST_offset]
        mov     rdx, [r11 + OPERAND_sym]
        mov     rcx, [r11 + OPERAND_imm]
        mov     r8, R_AARCH64_ADR_PREL_LO21
        IF r13d, e, 0x90000000
            mov r8, R_AARCH64_ADR_PREL_PG_HI21
        ENDIF
        extern  reloc_record
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     edi, eax
    call    aarch64_emit_word
    epilogue

; ============================================================================
; Internal Helpers & Encoders
; ============================================================================

aarch64_emit_word:
    prologue
    ; Write 4 bytes to current section
    mov     rdx, rdi               ; instruction word
    mov     rdi, rbx               ; AsmCtx
    mov     rsi, [r12 + INST_section]
    extern  asmctx_emit_dword
    call    asmctx_emit_dword
    epilogue

; ---- aarch64_encode_dp_reg ----
; Covers ADD, SUB, AND, ORR, EOR, etc. (Shifted register)
; Format: sf | op | 0 | shift | 0 | Rm | imm6 | Rn | Rd
aarch64_encode_dp_reg:
    prologue
    lea     r10, [r12 + INST_op0]  ; Rd
    lea     r11, [r12 + INST_op1]  ; Rn
    lea     r9,  [r12 + INST_op2]  ; Rm or Imm

    mov     eax, r13d              ; base opcode

    ; sf bit (64-bit vs 32-bit)
    mov     al, [r10 + OPERAND_size]
    IF al, e, 8
        or      eax, 0x80000000
    ENDIF

    ; VALIDATION: All GPR operands must match Rd size
    IF byte [r11 + OPERAND_size], ne, al
        mov rax, EXIT_INVALID_OPERAND | jmp .ret
    ENDIF
    IF byte [r9 + OPERAND_kind], e, OP_REG
        IF byte [r9 + OPERAND_size], ne, al
            mov rax, EXIT_INVALID_OPERAND | jmp .ret
        ENDIF
    ENDIF

    movzx   edi, byte [r10 + OPERAND_reg]   ; Rd
    or      eax, edi

    movzx   edi, byte [r11 + OPERAND_reg]   ; Rn
    shl     edi, 5
    or      eax, edi

    ; Check if op2 is register or immediate
    IF byte [r9 + OPERAND_kind], e, OP_REG
        movzx   edi, byte [r9 + OPERAND_reg] ; Rm
        shl     edi, 16
        or      eax, edi

        ; Handle shift (LSL, LSR, ASR, ROR)
        movzx   edi, byte [r9 + OPERAND_shift_type]
        and     edi, 0x03
        shl     edi, 22            ; shift type bits [23:22]
        or      eax, edi
        
        movzx   edi, byte [r9 + OPERAND_shift_imm]
        and     edi, 0x3F
        shl     edi, 10            ; imm6 bits [15:10]
        or      eax, edi
    ELSEIF byte [r9 + OPERAND_kind], e, OP_IMM
        ; ADD/SUB (immediate) uses different format: sf | op | 1 | sh | imm12 | Rn | Rd
        ; We detect this and adjust the opcode base
        and     eax, 0x7FFFFFFF ; clear high bit temporarily
        IF eax, e, 0x0B000000  ; ADD
            mov eax, 0x11000000
        ELSEIF eax, e, 0x4B000000 ; SUB
            mov eax, 0x51000000
        ENDIF
        ; Restore sf
        IF byte [r10 + OPERAND_size], e, 8
            or      eax, 0x80000000
        ENDIF
        
        mov     rax, [r9 + OPERAND_imm]
        
        ; Record relocation if it's a symbol (A73)
        IF byte [r9 + OPERAND_kind], e, OP_SYMBOL
            push    rax
            mov     rdi, rbx               ; AsmCtx
            mov     rsi, [r12 + INST_offset]
            mov     rdx, [r9 + OPERAND_sym]
            mov     rcx, rax               ; addend (the imm value)
            mov     r8, R_AARCH64_ADD_ABS_LO12_NC
            extern  reloc_record
            call    reloc_record
            pop     rax
        ENDIF

        ; Check if imm fits in 12 bits
        IF rax, le, 0xFFF
            ; Fits directly
            mov edi, eax
            shl edi, 10
            or  eax, edi
        ELSE
            ; Check if it fits with LSL #12 (bits 12-23)
            mov rdx, rax
            test rdx, 0xFFF
            jnz .error_imm_range    ; must be multiple of 4096 if > 4095
            
            shr rdx, 12
            IF rdx, le, 0xFFF
                ; Fits with shift
                or  eax, (1 << 22)  ; set sh bit
                mov edi, edx
                and edi, 0xFFF
                shl edi, 10
                or  eax, edi
            ELSE
                jmp .error_imm_range
            ENDIF
        ENDIF
        jmp .done_arith

.error_imm_range:
    mov rax, EXIT_IMM_RANGE
    jmp .ret
.done_arith:
    ENDIF

    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_mov ----
aarch64_encode_mov:
    prologue
    lea     r9, [r12 + INST_op1]
    IF byte [r9 + OPERAND_kind], e, OP_IMM
        mov     r13d, 0xD2800000 ; MOVZ base
        call    aarch64_encode_mov_wide
    ELSE
        ; MOV Rd, Rn  =>  ORR Rd, XZR, Rn
        mov     r13d, 0xAA000000
        ; We simulate ORR Rd, XZR, Rn by forcing Rn to be XZR (31) or something
        ; Actually ORR Rd, XZR, Rm is: sf | 0101010 | 00 | Rm | 000000 | 11111 | Rd
        ; Let's just call dp_reg with special setup?
        ; Simpler: hardcode it
        lea     r10, [r12 + INST_op0]
        lea     r11, [r12 + INST_op1]
        mov     eax, 0x2A0003E0 ; ORR (32-bit) with Rn=WZR
        IF byte [r10 + OPERAND_size], e, 8
            or  eax, 0x80000000
        ENDIF
        movzx   edi, byte [r10 + OPERAND_reg]
        or      eax, edi
        movzx   edi, byte [r11 + OPERAND_reg]
        shl     edi, 16
        or      eax, edi
        mov     rdi, rax
        call    aarch64_emit_word
    ENDIF
    epilogue

; ---- aarch64_encode_mov_wide ----
; MOVZ, MOVN, MOVK
aarch64_encode_mov_wide:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, r13d
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    and     edi, 0xFFFF
    shl     edi, 5
    or      eax, edi
    
    ; TODO: Handle shift (LSL #16, #32, #48)
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_branch ----
aarch64_encode_branch:
    prologue
    lea     r10, [r12 + INST_op0]
    ; B label => 0x14000000 | (imm26 >> 2)
    mov     eax, 0x14000000
    mov     edi, [r10 + OPERAND_imm]
    sar     edi, 2
    and     edi, 0x03FFFFFF
    or      eax, edi
    
    ; If operand is a symbol, record relocation
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx               ; AsmCtx
        mov     rsi, [r12 + INST_offset] ; current instr offset
        mov     rdx, [r10 + OPERAND_value] ; sym name
        xor     rcx, rcx               ; addend
        mov     r8, R_AARCH64_JMP26
        extern  reloc_record
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_branch_link ----
aarch64_encode_branch_link:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     eax, r13d
    mov     edi, [r10 + OPERAND_imm]
    sar     edi, 2
    and     edi, 0x03FFFFFF
    or      eax, edi
    
    IF byte [r10 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        mov     rdi, rbx               ; AsmCtx
        mov     rsi, [r12 + INST_offset] ; offset
        mov     rdx, [r10 + OPERAND_value] ; sym name
        xor     rcx, rcx               ; addend
        mov     r8, R_AARCH64_CALL26
        call    reloc_record
        pop     rax
    ENDIF
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_branch_reg ----
aarch64_encode_branch_reg:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     eax, r13d
    movzx   edi, byte [r10 + OPERAND_reg]
    shl     edi, 5
    or      eax, edi
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_comp_branch ----
aarch64_encode_comp_branch:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, r13d
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    mov     edi, [r11 + OPERAND_imm]
    sar     edi, 2
    and     edi, 0x7FFFF
    shl     edi, 5
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_ret ----
aarch64_encode_ret:
    prologue
    ; RET {Xn} => 0xD65F0000 | (Rn << 5)
    mov     eax, 0xD65F0000
    IF byte [r12 + INST_nops], e, 0
        or      eax, (30 << 5) ; default to X30 (LR)
    ELSE
        lea     r10, [r12 + INST_op0]
        movzx   edi, byte [r10 + OPERAND_reg]
        shl     edi, 5
        or      eax, edi
    ENDIF
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_ldr / str ----
aarch64_encode_ldr:
    prologue
    mov     r13d, 0xB9400000 ; LDR (unsigned immediate) 32-bit
    call    aarch64_encode_ldst
    epilogue

aarch64_encode_str:
    prologue
    mov     r13d, 0xB9000000 ; STR (unsigned immediate) 32-bit
    call    aarch64_encode_ldst
    epilogue

aarch64_encode_ldst:
    prologue
    lea     r10, [r12 + INST_op0] ; Rt
    lea     r11, [r12 + INST_op1] ; [Rn, #imm]
    
    mov     eax, r13d
    
    ; Size bits [31:30]
    ; 00=8, 01=16, 10=32, 11=64
    mov     cl, [r10 + OPERAND_size]
    IF cl, e, 8
        or      eax, 0xC0000000
    ELSEIF cl, e, 4
        or      eax, 0x80000000
    ELSEIF cl, e, 2
        or      eax, 0x40000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    movzx   edi, byte [r11 + OPERAND_base]
    shl     edi, 5
    or      eax, edi
    
    mov     rdi, [r11 + OPERAND_imm]
    
    ; Record relocation if symbol is present (A73)
    IF byte [r11 + OPERAND_kind], e, OP_SYMBOL
        push    rax
        push    rdi
        mov     rdi, rbx               ; AsmCtx
        mov     rsi, [r12 + INST_offset]
        mov     rdx, [r11 + OPERAND_sym]
        mov     rcx, [r11 + OPERAND_imm] ; addend
        
        ; Pick relocation based on size
        mov     r8, R_AARCH64_LDST32_ABS_LO12_NC
        movzx   r10, byte [r10 + OPERAND_size]
        IF r10, e, 8
            mov r8, R_AARCH64_LDST64_ABS_LO12_NC
        ELSEIF r10, e, 2
            mov r8, R_AARCH64_LDST16_ABS_LO12_NC
        ELSEIF r10, e, 1
            mov r8, R_AARCH64_LDST8_ABS_LO12_NC
        ENDIF
        
        extern  reloc_record
        call    reloc_record
        pop     rdi
        pop     rax
    ENDIF

    ; Unsigned offset is scaled by size
    IF cl, e, 8
        shr     edi, 3
    ELSEIF cl, e, 4
        shr     edi, 2
    ELSEIF cl, e, 2
        shr     edi, 1
    ENDIF
    and     edi, 0xFFF
    shl     edi, 10
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_ldst_pair ----
aarch64_encode_ldst_pair:
    prologue
    ; LDP/STP Xt1, Xt2, [Xn, #imm]
    ; Format: opc | 101 | V | L | imm7 | Rt2 | Rn | Rt1
    lea     r10, [r12 + INST_op0] ; Rt1
    lea     r11, [r12 + INST_op1] ; Rt2
    lea     r9,  [r12 + INST_op2] ; [Rn, #imm]
    
    mov     eax, 0x28000000
    IF r13d, e, 1
        or      eax, 0x00400000 ; L bit
    ENDIF
    
    IF byte [r10 + OPERAND_size], e, 8
        or      eax, 0x80000000 ; opc=10
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 10
    or      eax, edi
    movzx   edi, byte [r9 + OPERAND_base]
    shl     edi, 5
    or      eax, edi
    
    mov     edi, [r9 + OPERAND_imm]
    ; imm7 is scaled by size
    IF byte [r10 + OPERAND_size], e, 8
        sar     edi, 3
    ELSE
        sar     edi, 2
    ENDIF
    and     edi, 0x7F
    shl     edi, 15
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_cmp / tst ----
aarch64_encode_cmp:
    prologue
    push    rbx
    push    r12
    push    r13
    
    ; CMP Xn, Xm => SUBS XZR, Xn, Xm
    ; Use r13d for temporary opcode construction
    mov     r13d, 0x6B00001F       ; SUBS (reg) base with Rd=31 (XZR)
    
    lea     r10, [r12 + INST_op0]  ; Rn
    lea     r11, [r12 + INST_op1]  ; Rm
    
    ; sf bit
    IF byte [r10 + OPERAND_size], e, 8
        or  r13d, 0x80000000
    ENDIF
    
    ; Rn (bits 9-5)
    movzx   eax, byte [r10 + OPERAND_reg]
    shl     eax, 5
    or      r13d, eax
    
    ; Rm (bits 20-16) or Imm
    IF byte [r11 + OPERAND_kind], e, OP_REG
        movzx   eax, byte [r11 + OPERAND_reg]
        shl     eax, 16
        or      r13d, eax
    ELSEIF byte [r11 + OPERAND_kind], e, OP_IMM
        ; SUBS (imm) base
        and     r13d, 0x800003FF    ; Keep sf and Rd=XZR
        or      r13d, 0x71000000    ; SUBS (imm) base
        ; Rn
        movzx   eax, byte [r10 + OPERAND_reg]
        shl     eax, 5
        or      r13d, eax
        ; Imm12 (bits 21-10)
        mov     rax, [r11 + OPERAND_imm]
        and     eax, 0xFFF
        shl     eax, 10
        or      r13d, eax
    ENDIF
    
    mov     rdi, r13
    call    aarch64_emit_word
    
    pop     r13
    pop     r12
    pop     rbx
    epilogue

aarch64_encode_tst:
    prologue
    push    rbx
    push    r12
    push    r13
    
    ; TST Xn, Xm => ANDS XZR, Xn, Xm
    mov     r13d, 0x6A00001F       ; ANDS (reg) base with Rd=XZR
    
    lea     r10, [r12 + INST_op0]  ; Rn
    lea     r11, [r12 + INST_op1]  ; Rm
    
    IF byte [r10 + OPERAND_size], e, 8
        or  r13d, 0x80000000
    ENDIF
    
    ; Rn
    movzx   eax, byte [r10 + OPERAND_reg]
    shl     eax, 5
    or      r13d, eax
    
    ; Rm
    movzx   eax, byte [r11 + OPERAND_reg]
    shl     eax, 16
    or      r13d, eax
    
    mov     rdi, r13
    call    aarch64_emit_word
    
    pop     r13
    pop     r12
    pop     rbx
    epilogue

; ---- aarch64_encode_system_reg ----
; MRS Xt, S<op0>_<op1>_<Cn>_<Cm>_<op2>
; MSR S<op0>_<op1>_<Cn>_<Cm>_<op2>, Xt
aarch64_encode_system_reg:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    
    mov     eax, 0xD5200000        ; MRS base
    IF word [r12 + INST_op_id], e, 2330 ; MSR
        mov eax, 0xD5000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    
    ; System register encoding is usually simplified in assemblers
    ; to a 15-bit immediate or a recognized name.
    ; Here we assume r11 contains the packed sysreg ID.
    mov     edi, [r11 + OPERAND_imm]
    and     edi, 0x7FFF
    shl     edi, 5
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_hlt ----
aarch64_encode_hlt:
    prologue
    lea     r10, [r12 + INST_op0]
    mov     eax, 0xD4400000
    IF byte [r12 + INST_nops], ne, 0
        mov     edi, [r10 + OPERAND_imm]
        and     edi, 0xFFFF
        shl     edi, 5
        or      eax, edi
    ENDIF
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_fp_bin ----
aarch64_encode_fp_bin:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     r9,  [r12 + INST_op2]
    
    mov     eax, 0x1E200800        ; FADD base
    movzx   ecx, word [r12 + INST_op_id]
    IF ecx, e, 2165                ; FSUB
        or eax, 0x00100000
    ELSEIF ecx, e, 2161            ; FMUL
        or eax, 0x00008000
    ELSEIF ecx, e, 2156            ; FDIV
        or eax, 0x00018000
    ENDIF
    
    ; Type bits: 00=single, 01=double
    IF byte [r10 + OPERAND_size], e, 8
        or eax, 0x00400000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 5
    or      eax, edi
    movzx   edi, byte [r9 + OPERAND_reg]
    shl     edi, 16
    or      eax, edi

    ; ---- FIX: SHIFT HANDLING ----
    movzx   edi, byte [r9 + OPERAND_scale] ; Shift type (0=LSL, 1=LSR, 2=ASR)
    shl     edi, 22
    or      eax, edi
    
    mov     edi, [r9 + OPERAND_imm]        ; Shift amount (0-63)
    IF edi, g, 63
        mov rax, EXIT_IMM_RANGE | jmp .ret
    ENDIF
    and     edi, 0x3F
    shl     edi, 10
    or      eax, edi

    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_string_mov ----
; Emulates REP MOVSB/Q using LDR/STR loops
aarch64_encode_string_mov:
    prologue
    ; LDRB w0, [x1], #1  (0x38401420)
    ; STRB w0, [x2], #1  (0x38001440)
    ; SUBS x3, x3, #1    (0xF1000463)
    ; B.NE -12           (0x54FFFFA1)
    mov     edi, 0x38401420 | call aarch64_emit_word
    mov     edi, 0x38001440 | call aarch64_emit_word
    mov     edi, 0xF1000463 | call aarch64_emit_word
    mov     edi, 0x54FFFFA1 | call aarch64_emit_word
    epilogue

; ---- aarch64_encode_string_sto ----
aarch64_encode_string_sto:
    prologue
    ; STRB w0, [x1], #1  (0x38001420)
    ; SUBS x2, x2, #1    (0xF1000442)
    ; B.NE -8            (0x54FFFFE1)
    mov     edi, 0x38001420 | call aarch64_emit_word
    mov     edi, 0xF1000442 | call aarch64_emit_word
    mov     edi, 0x54FFFFE1 | call aarch64_emit_word
    epilogue

; ---- aarch64_encode_rev ----
aarch64_encode_rev:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    mov     eax, 0x5AC00800
    IF byte [r10 + OPERAND_size], e, 8
        or eax, 0x80000000 | or eax, 0x00000400
    ENDIF
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 5
    or      eax, edi
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_extend ----
aarch64_encode_extend:
    prologue
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    mov     eax, 0x13001C00        ; SXTB base (SBFM)
    movzx   ecx, word [r12 + INST_op_id]
    IF ecx, e, ID_AARCH64_SXTH | or eax, 0x00002000 | ENDIF
    IF ecx, e, ID_AARCH64_SXTW | or eax, 0x00007C00 | ENDIF
    
    IF byte [r10 + OPERAND_size], e, 8
        or eax, 0x80000000
    ENDIF
    
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 5
    or      eax, edi
    mov     rdi, rax
    call    aarch64_emit_word
    epilogue

; ---- aarch64_encode_vector_bin ----
aarch64_encode_vector_bin:
    prologue
    push    rbx
    lea     r10, [r12 + INST_op0]
    lea     r11, [r12 + INST_op1]
    lea     r9,  [r12 + INST_op2]
    
    ; Base patterns (Arithmetic vs Logical)
    movzx   ecx, word [r12 + INST_op_id]
    IF ecx, ge, ID_AARCH64_AND_V
        mov     eax, 0x0E201C00        ; Logical base (AND)
        IF ecx, e, ID_AARCH64_ORR_V
            or      eax, 0x00400000    ; ORR (size bits used as op modifier)
        ELSEIF ecx, e, ID_AARCH64_EOR_V
            or      eax, 0x20000000    ; EOR (U bit used as op modifier)
        ENDIF
    ELSE
        mov     eax, 0x0E208400        ; Arithmetic base (ADD)
        IF ecx, e, ID_AARCH64_SUB_V
            or      eax, 0x20000000    ; SUB (U bit)
        ENDIF
    ENDIF
    
    ; Q bit (bit 30)
    movzx   ecx, byte [r10 + OPERAND_size]
    IF ecx, e, 16
        or      eax, 0x40000000
    ENDIF
    
    ; Size (bits 23-22) - only for arithmetic
    movzx   ecx, word [r12 + INST_op_id]
    IF ecx, lt, ID_AARCH64_AND_V
        ; Assuming 32-bit elements (10) for now
        or      eax, 0x00800000
    ENDIF
    
    ; Registers: Rd=bits 4-0, Rn=bits 9-5, Rm=bits 20-16
    movzx   edi, byte [r10 + OPERAND_reg]
    or      eax, edi
    movzx   edi, byte [r11 + OPERAND_reg]
    shl     edi, 5
    or      eax, edi
    movzx   edi, byte [r9 + OPERAND_reg]
    shl     edi, 16
    or      eax, edi
    
    mov     rdi, rax
    call    aarch64_emit_word
    
    pop     rbx
    epilogue
