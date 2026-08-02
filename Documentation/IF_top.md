# `IF_top.v` — Instruction Fetch (IF) Stage Wrapper

## Overview
`IF_top` is the **top-level Instruction Fetch stage** wrapper for the single-cycle RISC-V core. It composes the **program counter logic** (`PC_Top.v`) and the **instruction memory** (`Instruction_Memory.v`) into a single fetch-stage block, presenting a clean interface to the rest of the CPU: given the current PC-selection control and any needed branch/jump offsets, it produces the current `PC` and the instruction fetched at that address.

This module represents an **upgrade** from an earlier design that used a single `branch` signal — it now uses a 2-bit `pc_sel` control to properly support **three** distinct next-PC sources: sequential (`PC+4`), PC-relative branch/JAL, and register-relative JALR.

---

## Module Interface

### Parameter
| Parameter | Default | Description |
|-----------|---------|--------------|
| `N` | 32 | Data/address width in bits |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | Clock |
| `reset` | 1 | Synchronous reset |
| `pc_sel` | 2 bits | Next-PC source select (see encoding below) |
| `Imm` | 32 | Sign-extended branch/JAL offset (added to current `PC`) |
| `jalr_target` | 32 | Precomputed JALR target (`rs1 + imm`), forwarded in from the ALU elsewhere in the core |

### Outputs
| Signal | Width | Description |
|--------|-------|--------------|
| `PC` | 32 | Current program counter value (byte address of fetched instruction) |
| `instr` | 32 | Instruction fetched at `PC` |
| `instr_valid` | 1 | High when `instr` is a valid fetch |

---

## `pc_sel` Encoding
| Value | Meaning | Next PC |
|-------|---------|---------|
| `00` | Sequential | `PC + 4` |
| `01` | Branch (taken) / JAL | `PC + Imm` |
| `10` | JALR | `jalr_target` (`rs1 + imm`, computed by ALU) |

---

## Internal Structure

```
                 +------------------+
   pc_sel ------>|                  |
   Imm     ------>|     PC_Top      |----> PC_internal ---+---> PC (output)
   jalr_target -->|  (PC + mux +    |                     |
   reset   ------>|   register)     |                     |
   clk     ------>|                  |                     |
                 +------------------+                     |
                                                            v
                                              +------------------------+
                                    addr ---->|                        |
                                    (always 1)|  Instruction_Memory    |----> instr
                                  instr_req -->|  (async/combinational  |----> instr_valid
                                    clk,reset->|   read)                |
                                              +------------------------+
```

- **`PC_Top`** owns the PC register and next-PC mux logic — it consumes `pc_sel`, `Imm`, and `jalr_target` to compute and register the next `PC` value each cycle.
- **`Instruction_Memory`** is fed the resulting `PC_internal` as its fetch address, with `instr_req` permanently tied high (`1'b1`) since this single-cycle core fetches an instruction every cycle unconditionally.
- `PC_internal` is simply passed through to the module's `PC` output via a continuous assignment, so downstream stages can use the current PC (e.g. for `AUIPC`, JAL linking, or branch/jump target computation).

---

## Key Design Notes

### Why `pc_sel` Replaced a Single `branch` Signal
The earlier design used a 1-bit `branch` input, which could only distinguish "take the sequential PC+4" from "take one alternate target." That's insufficient once **JALR** enters the picture, because the core now needs to choose between **three** genuinely different next-PC computations:
1. `PC + 4` (default, most instructions)
2. `PC + Imm` (taken branches and JAL — both PC-relative)
3. `jalr_target` (JALR — register-relative, and only available after the ALU computes `rs1 + imm`)

A 2-bit `pc_sel` cleanly encodes this 3-way choice without overloading a single bit's meaning.

### `jalr_target` as a Forwarded ALU Result
Because JALR's target depends on a register value (`rs1`) added to an immediate — a computation only the **ALU** can perform — this module does not compute the JALR target itself. Instead, `jalr_target` is **forwarded in** from elsewhere in the core (the ALU output, gated appropriately upstream), and `IF_top`/`PC_Top` simply select it when `pc_sel = 10`. This keeps the fetch stage free of duplicate adder logic.

### Combinational Instruction Memory Read (Reiterated)
As documented in `Instruction_Memory.v`, the instruction read remains **asynchronous/combinational**. This is called out again here because it directly affects this module's correctness: if the read were registered, `PC_internal` would have already advanced by the time `instr` becomes valid, causing any PC-relative branch/jump target computed elsewhere in the core to be off by one instruction (+4 bytes). The async read guarantees `instr` corresponds exactly to `PC_internal` in the same cycle.

### `instr_req` Tied High
Since this is a **single-cycle** (not pipelined or stalling) design, there is no scenario in which the fetch stage should *not* request an instruction every cycle — hence `instr_req` is hardwired to `1'b1` rather than being a dynamically controlled signal.

---

## Relationship to Other Modules
- **`PC_Top.v`** — internally instantiated; owns the PC register and mux logic.
- **`PC.v` / `PC_Mux.v` / `PC_Plus_4.v` / `PC_Target.v`** — the sub-components that `PC_Top.v` itself is built from.
- **`Instruction_Memory.v`** — internally instantiated; supplies the fetched instruction.
- **`Instruction_Decoder.v`** — consumes this module's `instr` output downstream to extract instruction fields.
- **`ALU.v`** — supplies `jalr_target` (the `rs1 + imm` result) back into this module for JALR support.
- **`MainDecoder.v`** — indirectly determines `pc_sel` (via `Jump`, `Branch`, `JalrSel`, and the ALU zero flag) elsewhere in the top-level CPU wiring.
- **`CPU_top.v`** — the parent module expected to instantiate `IF_top` as the fetch stage of the overall single-cycle datapath.
