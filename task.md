# utasm Task Tracking

## 🎯 Current Goal
Industrializing the `utasm` assembler pipeline for multi-arch sovereign kernel development.

## 🟢 Completed (Phase 1 & 2: Pipeline & Industrialization)
- [x] **Core Headers**: `register.s`, `syscall.s`, `elf.s` (Full ABI coverage).
- [x] **Compiler Core**: Expanded `preprocessor.s` with `%struc` support.
- [x] **Encoders**: AMD64, AArch64, and RISC-V 64 (**ABSOLUTE PARITY**).
- [x] **Audit Fixes (Round 4)**: 
    - [x] 16-byte ABI Stack Alignment.
    - [x] Local Label Scoping (`global.local`).
    - [x] Data Directives (`db`, `dw`, `dd`, `dq`).
    - [x] Section-Aware Emission (`SECTION .text/.data`).
    - [x] Bit-Perfect Relocation Offsets.
- [x] **Linker**: ELF64, Binary, and Relocation engines.
- [x] **Diagnostics**: Materialized `listing.s` and `mapfile.s`.

- [x] **Industrialization Audit (Rounds 5-14)**: 
    - [x] R5: PEMDAS Expression Engine.
    - [x] R6: AMD64 Symbol/Addend Relocations.
    - [x] R7: AArch64 ADRP/ADR Pipeline.
    - [x] R8: Data & Section Materialization.
    - [x] R9: RISC-V Pseudo-Call Expansion.
    - [x] R10: Preprocessor Recursion Shield.
- [ ] **Test Suites**: Implement comprehensive test suites for each architecture.
- [ ] **Error Reporting**: Enhance ANSI color-coded diagnostic messages.

## 🔴 Future (Phase 4: Optimization & Sovereignty)
- [ ] **Self-Hosting**: Assemble `utasm` using `utasm`.
- [ ] **QEMU Integration**: Automated boot testing for `.bin` output.
- [ ] **Performance**: Replace linear symbol scan with hash tables.

---
*Last Updated: 2026-04-27*
