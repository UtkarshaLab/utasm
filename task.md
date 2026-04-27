# utasm Task Tracking

## 🎯 Current Goal
Industrializing the `utasm` assembler pipeline for multi-arch sovereign kernel development.

## 🟢 Completed (Phase 1: Foundation & Pipeline)
- [x] **Core Headers**: `register.s`, `syscall.s`, `elf.s` (Full ABI coverage).
- [x] **Compiler Core**: Expanded `preprocessor.s` with `%struc` support.
- [x] **Encoders**: `aarch64.s` and `riscv64.s` (**ABSOLUTE PARITY** with AMD64: System/Privileged/Float/String/Conversion added).
- [x] **Linker**: ELF64, Binary, and Relocation engines.
- [x] **Orchestration**: `main.s` full-loop integration.

## 🟡 In Progress (Phase 2: Diagnostics & Quality)
- [ ] **Diagnostics**: Implement `listing.s` for address/hex/source output.
- [ ] **Maps**: Implement `mapfile.s` for linker symbol mapping.
- [ ] **Tests**: Implement comprehensive test suites for each architecture.

## 🔴 Future (Phase 3: Optimization & Sovereignty)
- [ ] **Self-Hosting**: Assemble `utasm` using `utasm`.
- [ ] **QEMU Integration**: Automated boot testing for `.bin` output.
- [ ] **Performance**: Replace linear symbol scan with hash tables.

---
*Last Updated: 2026-04-27*
