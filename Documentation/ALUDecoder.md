# ALU Decoder

## Overview
The **ALU Decoder** translates the coarse-grained `ALUop` signal (produced by the Main Control unit) along with instruction fields `funct3` and `funct7` into the precise 4-bit `ALUControl` code consumed by the ALU. This two-stage decoding scheme (Main Control → ALUop → ALU Decoder → ALUControl) is a standard technique in RISC-V single-cycle datapaths that keeps the Main Control unit simple while pushing instruction-specific ALU operation selection into a dedicated module.

This module is **purely combinational**.

---

## Module Declaration

```verilog
module ALUDecoder(
    input [1:0] ALUop,
    input [2:0] funct3, 
    input [6:0] funct7,
    output reg [3:0] ALUControl
);
```

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|--------------|
| `ALUop` | Input | 2 bits | Coarse operation class from the Main Control unit, indicating the instruction category (Load/Store, Branch, R/I-type, LUI). |
| `funct3` | Input | 3 bits | The `funct3` field extracted from the instruction, further specifying the operation within a category. |
| `funct7` | Input | 7 bits | The `funct7` field extracted from the instruction, used to disambiguate ADD/SUB and SRL/SRA. |
| `ALUControl` | Output (reg) | 4 bits | Final ALU control code, directly fed into the ALU's `con` input. |

---

## `ALUop` Encoding (Instruction Category)

| `ALUop` | Category | Description |
|---------|----------|-------------|
| `2'b00` | Load / Store / AUIPC | Address calculation — always requires ADD. |
| `2'b01` | Branch | Comparison operations (equality or relational). |
| `2'b10` | R-type / I-type | Full arithmetic/logical instruction set, disambiguated by `funct3`/`funct7`. |
| `2'b11` | LUI | Load Upper Immediate — direct pass-through operation. |

---

## Decoding Logic by Category

### `ALUop = 2'b00` → Load / Store / AUIPC
```verilog
ALUControl = 4'b0000; // ADD
```
These instruction types always compute a memory address or PC-relative offset, so the ALU is fixed to **ADD** regardless of `funct3`/`funct7`.

> **Note:** AUIPC is grouped here for ADD-based base-offset computation. Depending on the datapath design, a separate dedicated `AUIPC` ALUControl (`4'b1000`, per the ALU module) may instead be selected upstream if the Main Control differentiates AUIPC explicitly. In this decoder, AUIPC is treated identically to Load/Store (ADD).

### `ALUop = 2'b01` → Branch
| `funct3` | Instruction | `ALUControl` | ALU Operation |
|----------|-------------|--------------|----------------|
| `3'b000` | BEQ | `4'b0001` | SUB (result compared via `zero` flag) |
| `3'b001` | BNE | `4'b0001` | SUB (result compared via `zero` flag) |
| `3'b100` | BLT | `4'b0101` | SLT (signed less-than) |
| `3'b101` | BGE | `4'b0101` | SLT (signed less-than, inverted externally) |
| `3'b110` | BLTU | `4'b0110` | SLTU (unsigned less-than) |
| `3'b111` | BGEU | `4'b0110` | SLTU (unsigned less-than, inverted externally) |

**Design insight:**
- `BEQ`/`BNE` both map to **SUB**; the branch decision itself (equal vs. not-equal) is resolved downstream by inspecting the ALU's `zero` flag combined with the branch type, not by the ALU control code itself.
- `BLT`/`BGE` and `BLTU`/`BGEU` pairs share the same ALU operation (`SLT`/`SLTU` respectively) — the "greater-or-equal" variants are computed by taking the **logical inverse** of the "less-than" result in the branch decision logic outside the ALU, since `BGE = !BLT` and `BGEU = !BLTU` for valid comparisons.

### `ALUop = 2'b10` → R-type / I-type
| `funct3` | `funct7` | Instruction | `ALUControl` | ALU Operation |
|----------|----------|-------------|--------------|----------------|
| `3'b000` | `7'b0100000` | SUB | `4'b0001` | SUB |
| `3'b000` | other | ADD / ADDI | `4'b0000` | ADD |
| `3'b111` | — | AND / ANDI | `4'b0010` | AND |
| `3'b110` | — | OR / ORI | `4'b0011` | OR |
| `3'b100` | — | XOR / XORI | `4'b0100` | XOR |
| `3'b010` | — | SLT / SLTI | `4'b0101` | SLT |
| `3'b011` | — | SLTU / SLTIU | `4'b0110` | SLTU |
| `3'b001` | — | SLL / SLLI | `4'b1010` | SLL |
| `3'b101` | `7'b0100000` | SRA / SRAI | `4'b1011` | SRA |
| `3'b101` | other | SRL / SRLI | `4'b1100` | SRL |

**Design insight:**
- The classic RISC-V ambiguity — where `funct3 = 3'b000` can mean either `ADD`/`ADDI` or `SUB` — is resolved by checking **bit 5 of `funct7`** (`7'b0100000`). This same bit pattern also disambiguates `SRL` vs. `SRA` under `funct3 = 3'b101`.
- Immediate-form instructions (`ADDI`, `ANDI`, etc.) share the same `funct3` encoding as their register-form counterparts and are **not distinguished by `funct7`** at this stage — for I-type instructions, `funct7` is typically not a valid subtract/shift-type discriminator (except for shift-immediate instructions `SLLI`/`SRLI`/`SRAI`, which do encode a `funct7`-like field in bits `31:25` and are handled identically to their R-type counterparts here).

### `ALUop = 2'b11` → LUI
```verilog
ALUControl = 4'b0111; // LUI
```
Direct mapping; no further decoding based on `funct3`/`funct7` needed since LUI has a fixed format.

---

## Default Behavior
```verilog
ALUControl = 4'b0000; // default at top of always block
```
The output is defaulted to `ADD` (`4'b0000`) at the start of every evaluation. This prevents unintended latch inference for any `funct3`/`funct7` combinations not explicitly covered by the nested `case` statements (e.g., reserved/illegal encodings).

---

## Design Notes & Observations

- **Two-level decoding hierarchy**: This module exemplifies the standard "Main Decoder → ALU Decoder" split used in Harris & Harris-style single-cycle RISC-V implementations, keeping the Main Control's job limited to identifying instruction *category*, while this module handles the *fine-grained* operation selection.
- **Shared ALU codes for branch pairs**: Reusing the same `ALUControl` for `BEQ`/`BNE` and for `BLT`/`BGE` (and their unsigned counterparts) minimizes the ALU's operation set — the branch condition polarity is resolved in the branch comparator/control logic, not duplicated in the ALU.
- **`funct7` bit-5 convention**: Relying on `funct7[5]` (via the `7'b0100000` check) to distinguish ADD/SUB and SRL/SRA mirrors the actual RISC-V ISA encoding, where this bit is the sole differentiator between these instruction pairs.
- **No explicit AUIPC-specific code path**: Since AUIPC is grouped under `ALUop = 2'b00`, this decoder does not use the ALU's dedicated `4'b1000` (AUIPC) control code — it relies on plain ADD instead. This should be cross-checked against the Main Control and ALU source operand muxing to ensure the immediate is upper-immediate-formatted correctly *before* reaching the ALU, since a plain ADD would need the caller to have already shifted `B` (i.e., `{imm[31:12], 12'b0}`) rather than relying on the ALU's internal AUIPC formatting logic.
- **Combinational, single always block**: No clock; purely a function of `ALUop`, `funct3`, `funct7`.

---

## Usage in the Datapath

The ALU Decoder sits between the **Main Control Unit** and the **ALU**, forming part of the overall **Control Unit** hierarchy:

```
Instruction ─┬─→ opcode ──────→ Main Control ──→ ALUop ──┐
             ├─→ funct3 ───────────────────────────────────┼─→ ALU Decoder ──→ ALUControl ──→ ALU
             └─→ funct7 ───────────────────────────────────┘
```

Its output (`ALUControl`) directly drives the `con` input of the `ALU` module, completing the control path that determines which arithmetic/logical operation the datapath executes each cycle.
