# `MainDecoder.v` — Main Control Decoder

## Overview
The **Main Decoder** is the primary control unit of the single-cycle RISC-V core. It takes the 7-bit `opcode` field of the currently fetched instruction and generates all the high-level control signals that steer the datapath — register writes, immediate format selection, ALU operand sourcing, memory access, branching, and jump handling.

It works alongside the **ALU Decoder** (which further refines `ALUControl` based on `funct3`/`funct7`) to fully decode an instruction in one cycle.

---

## Module Interface

### Input
| Signal | Width | Description |
|--------|-------|--------------|
| `op` | 7 bits | Opcode field of the instruction (`instr[6:0]`) |

### Outputs
| Signal | Width | Description |
|--------|-------|--------------|
| `RegWrite` | 1 | Enables write to the register file |
| `ImmSrc` | 3 bits | Selects immediate format for the Immediate Generator |
| `ALUSrc` | 1 | ALU operand B mux: `0` = `rs2`, `1` = immediate |
| `ALUSrcA` | 1 | ALU operand A mux: `0` = `rs1`, `1` = `PC` (for AUIPC) |
| `MemWrite` | 1 | Enables write to data memory |
| `ResultSrc` | 2 bits | Selects value written back to register file |
| `Branch` | 1 | Indicates a branch instruction |
| `ALUop` | 2 bits | High-level ALU operation class, passed to ALU Decoder |
| `Jump` | 1 | Indicates an unconditional jump (JAL/JALR) |
| `JalrSel` | 1 | Distinguishes JALR (`1`) from JAL (`0`) for PC-target mux |

---

## ImmSrc Encoding
| Code | Format | Used By |
|------|--------|---------|
| `000` | I-type | Loads, I-type ALU ops, JALR |
| `001` | S-type | Stores |
| `010` | B-type | Branches |
| `011` | J-type | JAL |
| `100` | U-type | LUI, AUIPC |

> **Note:** `ImmSrc` was expanded from 2 bits to 3 bits specifically to support the U-type immediate required by `LUI`/`AUIPC`.

## ResultSrc Encoding
| Code | Meaning |
|------|---------|
| `00` | ALU result |
| `01` | Memory read data |
| `10` | PC + 4 (link address, for JAL/JALR) |

---

## Opcode → Control Signal Table

| Opcode (bin) | Instruction Type | RegWrite | ImmSrc | ALUSrc | ALUSrcA | MemWrite | ResultSrc | Branch | ALUop | Jump | JalrSel |
|---|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| `0000011` | Load (lw/lh/lb/...) | 1 | `000` | 1 | 0 | 0 | `01` | 0 | `00` | 0 | 0 |
| `0100011` | Store (sw/sh/sb) | 0 | `001` | 1 | 0 | 1 | `00` | 0 | `00` | 0 | 0 |
| `0110011` | R-type ALU | 1 | (default `000`) | 0 | 0 | 0 | `00` | 0 | `10` | 0 | 0 |
| `0010011` | I-type ALU | 1 | `000` | 1 | 0 | 0 | `00` | 0 | `10` | 0 | 0 |
| `1100011` | Branch | 0 | `010` | 0 | 0 | 0 | `00` | 1 | `01` | 0 | 0 |
| `1101111` | JAL | 1 | `011` | 0 | 0 | 0 | `10` | 0 | `00` | 1 | 0 |
| `1100111` | JALR | 1 | `000` | 1 | 0 | 0 | `10` | 0 | `00` | 1 | 1 |
| `0110111` | LUI | 1 | `100` | 1 | 0 | 0 | `00` | 0 | `11` | 0 | 0 |
| `0010111` | AUIPC | 1 | `100` | 1 | 1 | 0 | `00` | 0 | `00` | 0 | 0 |

---

## Key Design Notes

### Latch-Free Defaults
Every signal is assigned a safe default value at the top of the combinational `always @(*)` block before the `case` statement. This guarantees the block is purely combinational and avoids unintended latch inference for opcodes not explicitly handled by the `case`.

### LUI (`0110111`)
- Uses a **U-type** immediate (`ImmSrc = 3'b100`) — a fix over an earlier version that incorrectly used the I-type immediate, which corrupted the upper-20-bit value.
- `ALUop = 2'b11` tells the ALU Decoder to configure the ALU as a pass-through for `SrcB`, so the ALU result is simply the shifted-in immediate (`{imm[31:12], 12'b0}`).
- `ALUSrc = 1` so operand B is the immediate, not `rs2`.
- `ResultSrc = 2'b00` writes back the ALU result (i.e., the immediate) directly to the register file.

### AUIPC (`0010111`)
- Also uses the **U-type** immediate (`ImmSrc = 3'b100`).
- `ALUSrcA = 1` is the key addition: it switches ALU operand A from `rs1` to the current `PC`, so the ALU computes `PC + {imm[31:12], 12'b0}`.
- `ALUop = 2'b00` selects a plain ADD operation.
- Without `ALUSrcA`, AUIPC would incorrectly add the immediate to `rs1` instead of `PC`.

### JAL (`1101111`)
- `Jump = 1` drives the PC-source mux to select the jump target instead of `PC+4` or the branch target.
- `JalrSel = 0` tells the PC-target mux that the jump target is `PC + J-type immediate` (computed in the IF stage by `PC_Target.v`), **not** the ALU result.
- `ResultSrc = 2'b10` writes `PC+4` back to the destination register — this is the "link" address for returning from the jump.
- `ImmSrc = 3'b011` selects the J-type immediate format (needed because J-type immediates have a uniquely scrambled bit layout for `imm[20|10:1|11|19:12]`).

### JALR (`1100111`)
- Also sets `Jump = 1`, but `JalrSel = 1` — this tells the PC-target mux that the jump target comes from the **ALU result** (`rs1 + I-type immediate`), not `PC + immediate`.
- `ALUSrc = 1` and `ImmSrc = 3'b000` (I-type) so the ALU computes `rs1 + imm`.
- `ResultSrc = 2'b10` writes back `PC+4`, same linking behavior as JAL.

### Why `JalrSel` Exists
Both JAL and JALR are "jump" instructions (`Jump = 1`), but they compute their target address completely differently:
- **JAL** → target = `PC + imm` (PC-relative, computed early in the IF stage)
- **JALR** → target = `rs1 + imm` (register-relative, only available after the ALU computes it)

`JalrSel` lets the PC-source mux (`PC_Mux.v` / `PC_Top.v`) pick the correct source for the next `PC` value without needing a separate opcode check downstream.

---

## Relationship to Other Modules
- **`ALUDecoder.v`** — consumes `ALUop` (plus `funct3`/`funct7`) to generate the precise `ALUControl` signal for the ALU.
- **`Imm_Gen.v`** — consumes `ImmSrc` to select which immediate-encoding rules to apply to the raw instruction bits.
- **`PC_Mux.v` / `PC_Top.v`** — consume `Jump`, `Branch` (combined with the ALU zero flag), and `JalrSel` to select the next PC value.
- **`SrcA_MUX.v`** — consumes `ALUSrcA` to select between `rs1` and `PC` as ALU operand A.
- **`ALU_MUX.v`** — consumes `ALUSrc` to select between `rs2` and the immediate as ALU operand B.
- **`WriteBack_MUX.v`** — consumes `ResultSrc` to select the value written back to the register file.
