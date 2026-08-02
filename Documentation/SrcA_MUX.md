# `SrcA_MUX.v` — ALU Operand A Select Mux

## Overview
`SrcA_MUX` is a small combinational multiplexer that selects the **first ALU operand (`SrcA`)** between two sources: the register file's `rs1` read data (the normal case for nearly every instruction) and the current program counter `PC_reg` (needed specifically for **AUIPC**).

This module is a small but functionally critical piece of the datapath — without it, the ALU would have no way to use `PC` as an input operand at all, making `AUIPC` impossible to implement correctly.

---

## Module Interface

### Parameter
| Parameter | Default | Description |
|-----------|---------|--------------|
| `N` | 32 | Operand width in bits |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `rs1_data` | 32 | Register file read port 1 output (value of `rs1`) |
| `PC_reg` | 32 | Current program counter value |
| `ALUSrcA` | 1 | Select: `0` = `rs1_data`, `1` = `PC_reg` |

### Output
| Signal | Width | Description |
|--------|-------|--------------|
| `SrcA` | 32 | Selected value, fed to ALU operand A |

---

## Logic

```verilog
assign SrcA = ALUSrcA ? PC_reg : rs1_data;
```

A single-line ternary continuous assignment — purely combinational, single-cycle propagation, no clock involvement.

| `ALUSrcA` | `SrcA` = |
|:---:|---|
| `0` | `rs1_data` |
| `1` | `PC_reg` |

---

## Key Design Notes

### Why This Mux Was Needed (Bug Fix Context)
Prior to this module's introduction, ALU operand A was **hardwired** to `rs1_data` for every instruction. This is correct for the overwhelming majority of RISC-V instructions (R-type, I-type ALU ops, loads, stores, branches, JALR) — but it is **wrong for AUIPC**, whose defined semantics are:

```
AUIPC rd, imm  →  rd = PC + {imm[31:12], 12'b0}
```

AUIPC does **not** reference `rs1` at all — the instruction encoding doesn't even have a `rs1` field it depends on for the add operation (only `rd` and the U-type immediate matter). Without `SrcA_MUX`, an AUIPC instruction would incorrectly compute `rs1 + imm` (using whatever garbage/unrelated value happened to be in the `rs1` field's register), rather than `PC + imm`. This mux, gated by `ALUSrcA` (driven by `MainDecoder.v` — asserted only for AUIPC), corrects that by routing `PC_reg` into the ALU instead.

### Minimal, Single-Purpose Design
This is intentionally one of the simplest modules in the core — a 2:1 mux with no internal state. Its correctness is easy to verify by inspection, which is valuable given how easy the underlying bug (hardwired `rs1_data`) was to miss until AUIPC was specifically tested.

### All Other Instructions Unaffected
For every opcode other than AUIPC, `ALUSrcA` remains `0` (the default in `MainDecoder.v`'s combinational block), so `SrcA` continues to resolve to `rs1_data` exactly as before — this fix introduces no regression risk for existing instruction support.

---

## Relationship to Other Modules
- **`MainDecoder.v`** — generates the `ALUSrcA` control signal, asserted (`1`) only for the AUIPC opcode (`0010111`).
- **`Register_Set.v`** — supplies `rs1_data` (register file read port 1).
- **`PC.v` / `PC_Top.v`** — supplies `PC_reg`, the current program counter value.
- **`ALU.v`** — consumes this mux's `SrcA` output as one of its two operands (paired with `SrcB` from `ALU_MUX.v`).
- **`ALU_MUX.v`** — the analogous mux for ALU operand **B** (selects between `rs2_data` and the immediate).
