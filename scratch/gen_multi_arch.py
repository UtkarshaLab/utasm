import re
import os

def gen_arm():
    files = ['scratch/arm/simd.txt', 'scratch/arm/sme.txt', 'scratch/arm/sve.txt']
    mnemonics = set()
    
    # Improved ARM pattern
    # 1. Capture primary mnemonics at start of line: MNEMONIC: or MNEMONIC (qual):
    # 2. Capture comma-separated lists: MN1, MN2:
    # 3. Capture aliases: ... an alias of MNEMONIC
    
    prim_pattern = re.compile(r'^([A-Z0-9_<>, ]+)(?:\s*\(.*?\))?\s*:')
    alias_pattern = re.compile(r': an alias of ([A-Z0-9_<>, ]+)(?:\s*\(.*?\))?')
    
    for f in files:
        if not os.path.exists(f):
            continue
        with open(f, 'r', encoding='utf-8') as src:
            for line in src:
                line = line.strip()
                # Try primary
                m_prim = prim_pattern.match(line)
                if m_prim:
                    parts = m_prim.group(1).split(',')
                    for p in parts:
                        mnem = p.strip().split()[0].lower() # Handle things like "CMP<cc>" -> "cmp"
                        if mnem and not mnem.startswith('a64'):
                            # Handle <cc> or <r> variants by adding them as base
                            mnem = mnem.replace('<cc>', '').replace('<r>', '')
                            mnemonics.add(mnem)
                
                # Try alias
                m_alias = alias_pattern.search(line)
                if m_alias:
                    parts = m_alias.group(1).split(',')
                    for p in parts:
                        mnem = p.strip().split()[0].lower()
                        mnem = mnem.replace('<cc>', '').replace('<r>', '')
                        mnemonics.add(mnem)
                        
    # Add some common base A64 instructions if missing (just to be safe)
    base_a64 = ['mov', 'add', 'sub', 'mul', 'sdiv', 'udiv', 'and', 'orr', 'eor', 'ldr', 'str', 'stp', 'ldp', 'ret', 'br', 'blr', 'b', 'cbz', 'cbnz', 'tst', 'cmp']
    for b in base_a64:
        mnemonics.add(b)

    return sorted(list(mnemonics))

def gen_riscv():
    f = 'scratch/riscv.txt'
    mnemonics = set()
    
    if not os.path.exists(f):
        return []

    # RISC-V pattern:
    # 1. Starts with lowercase word (maybe with dots)
    # 2. Followed by \t or multiple spaces
    # 3. Rest of line looks like args (rs1, rd, imm, or empty)
    # 4. Or specifically in "Operation Arguments" tables
    
    # This pattern catches lines like "addi  rd, rs1, imm" or "wfi"
    # We allow optional leading whitespace
    pattern = re.compile(r'^\s*([a-z0-9\.]+)\s+(?:[a-z0-9, \t\(\)]+|$)')
    
    # Blacklist common words that might appear at start of lines in descriptions
    blacklist = {'the', 'a', 'an', 'if', 'for', 'switch', 'case', 'default', 'throw', 'require', 'note', 'spike', 'implementation', 'operation', 'arguments', 'description', 'rv32', 'rv64'}

    with open(f, 'r', encoding='utf-8') as src:
        for line in src:
            line = line.strip()
            if not line: continue
            
            # Special check for pseudo-ops in descriptions
            if 'Psuedo Opcode, Equivalent Operations:' in line:
                # The next few lines might contain pseudo-ops
                continue
                
            match = pattern.match(line)
            if match:
                mnem = match.group(1)
                if len(mnem) > 1 and mnem not in blacklist and not mnem.isdigit():
                    mnemonics.add(mnem)
            
            # Also catch instructions in Operation | Arguments tables specifically
            if ' \t' in line:
                parts = line.split('\t')
                first = parts[0].strip().lower()
                if first and len(first) > 1 and first not in blacklist and ' ' not in first:
                    mnemonics.add(first)

    return sorted(list(mnemonics))

def write_table(arch, mnemonics, start_id):
    output_path = f'src/arch/{arch}/table.s'
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write(f'; Technical Instruction Table for {arch.upper()}\n')
        f.write(f'; Generated from exhaustive source lists\n\n')
        f.write('%include "core/macro.s"\n')
        f.write(f'%include "arch/{arch}.s"\n\n')
        f.write('section .data\n')
        f.write(f'global mnemonic_table_{arch}\n\n')
        f.write(f'mnemonic_table_{arch}:\n')
        
        curr_id = start_id
        for m in mnemonics:
            f.write(f'    define_mnemonic "{m}", {curr_id}, 0\n')
            curr_id += 1
        
        f.write('    dq 0 ; Sentinel\n')
    print(f"Generated {output_path} with {len(mnemonics)} instructions.")

if __name__ == "__main__":
    arm_mnems = gen_arm()
    write_table('aarch64', arm_mnems, 2000)
    
    rv_mnems = gen_riscv()
    write_table('riscv64', rv_mnems, 3000)
