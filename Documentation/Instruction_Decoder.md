# `Instruction_Decoder.v` — Instruction Field Decoder

## Overview
The **Instruction Decoder** is a purely combinational module that slices the 32-bit fetched instruction into its constituent RISC-V instruction fields. It does not interpret or classify the instruction in any way — it simply exposes fixed bit-ranges of the instruction word as named signals, which are then consumed by the **Main Decoder**, **ALU Decoder**, **Immediate Generator**, and **Register File**.

This module implements the fixed-field layout common to the RV32I base instruction formats (R, I, S, B, U, J), since the opcode, `rd`, `funct3`, `rs1`, `rs2`, and `funct7` fields always live in the same bit positions regardless of instruction type (fields simply go unused/ignored when not applicable to a given format).

---

## Module Interface

### Input
| Signal | Width | Description |
|--------|-------|--------------|
| `instr` | 32 bits | The full fetched instruction word |

### Outputs
| Signal | Width | Bit Range | Description |
|--------|-------|-----------|--------------|
| `opcode` | 7 bits | `instr[6:0]` | Primary operation code — identifies instruction format/type |
| `rd` | 5 bits | `instr[11:7]` | Destination register index |
| `funct3` | 3 bits | `instr[14:12]` | Minor function/operation selector |
| `rs1` | 5 bits | `instr[19:15]` | Source register 1 index |
| `rs2` | 5 bits | `instr[24:20]` | Source register 2 index |
| `funct7` | 7 bits | `instr[31:25]` | Extended function selector (distinguishes e.g. `ADD`/`SUB`, `SRL`/`SRA`) |

---

## Bit Layout Reference (RV32I)

```
31        25 24     20 19     15 14   12 11      7 6        0
+-----------+---------+---------+-------+---------+---------+
|  funct7   |   rs2   |   rs1   |funct3 |    rd   | opcode  |   R-type
+-----------+---------+---------+-------+---------+---------+
|      imm[11:0]      |   rs1   |funct3 |    rd   | opcode  |   I-type
+-----------+---------+---------+-------+---------+---------+
| imm[11:5] |   rs2   |   rs1   |funct3 | imm[4:0]| opcode  |   S-type
+-----------+---------+---------+-------+---------+---------+
| imm[12|10:5]| rs2   |   rs1   |funct3 |imm[4:1|11]| opcode|   B-type
+-----------+---------+---------+-------+---------+---------+
|              imm[31:12]                |    rd   | opcode  |   U-type
+-----------+---------+---------+-------+---------+---------+
|         imm[20|10:1|11|19:12]          |    rd   | opcode  |   J-type
+-----------+---------+---------+-------+---------+---------+
```

Note that `opcode` (bits `6:0`) and `rd`/`funct3`/`rs1` (where applicable) always occupy the same positions across formats — this is what allows a single flat decoder to extract them unconditionally, before the instruction's format is even known.

---

## Key Design Notes

### Purely Combinational, No Decision Logic
This module contains **no `always` blocks and no `case` statements** — every output is a simple `assign` wire slice. It performs zero interpretation; it is purely a field-extraction/"wire-splitting" stage.

### Fields May Be Unused Depending on Format
- `funct7` and `rs2` are meaningless for I-type, U-type, and J-type instructions — downstream modules simply ignore them when not needed (e.g. the ALU Decoder only reads `funct7` for R-type opcodes).
- `rd` is unused for S-type (stores) and B-type (branches), since neither writes a register.
- The immediate value itself is **not** assembled here — that responsibility belongs to `Imm_Gen.v`, which reads `opcode`/`ImmSrc` and reconstructs the correctly-signed immediate from the scattered instruction bits.

---

## Relationship to Other Modules
- **`MainDecoder.v`** — consumes `opcode` to generate top-level control signals.
- **`ALUDecoder.v`** — consumes `funct3` and `funct7` (along with `ALUop`) to generate the precise `ALUControl` signal.
- **`Imm_Gen.v`** — consumes the raw `instr` (and `ImmSrc`) to build the correctly formatted immediate.
- **`Register_Set.v`** — consumes `rs1`, `rs2` (read addresses) and `rd` (write address).
