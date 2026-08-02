# `CPU_top.v` — Top-Level CPU Integration

## Overview
`CPU_top` is the **overall top-level module** of the single-cycle RISC-V core. It connects the two major halves of the processor — the **Instruction Fetch stage** (`IF_top.v`) and the **Decode/Execute/Memory/Writeback core** (`ID_EX_MEM_WB_top.v`) — and contains the **branch condition decoder** and **PC-select logic** that ties them together into a working control-flow loop.

This is the module where **branches, JAL, and JALR all converge** into a single, correct next-PC decision every cycle.

---

## Module Interface

### Parameter
| Parameter | Default | Description |
|-----------|---------|--------------|
| `N` | 32 | Data width in bits |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | Clock |
| `rst` | 1 | Reset |

*(No other external ports — this is a self-contained core; memory contents and outputs are visible only internally or via a testbench/display wrapper.)*

---

## Internal Structure

```
                    +----------------------------+
        PC ◄────────┤                            │
                    │      IF_top (Fetch)         │
   pc_sel ─────────►│  PC_Top + Instruction_Memory│
     Imm ───────────►│                            │
jalr_target ────────►│                            ├──► instr
                    +----------------------------+       │
                                                          ▼
                    +-----------------------------------------+
              PC ──►│                                         │
           instr ──►│      ID_EX_MEM_WB_top (Core)            │
                    │  Decode → Register File → Imm_Gen →     │
                    │  ALU → Data Memory → WriteBack           │
                    +-----------------------------------------+
                      │        │       │        │      │    │
                 ALU_result  Branch  zero   Imm   funct3  jump_jal
                                                          jump_jalr
                                                          jalr_target
                                                          │
                    +----------------------------------- ▼ -+
                    |   Branch Condition Decoder (funct3)    |
                    +---------------------- ------------------+
                                    │
                              branch_taken
                                    │
                    +--------------- ▼ ------------------+
                    |        PC Select Logic (pc_sel)     |
                    +-------------------------------------+
                                    │
                                (feeds back into IF_top.pc_sel)
```

`PC`, `Imm`, `jalr_target` flow from core→IF and IF→core in a tight combinational loop, resolved once per clock cycle (true to the single-cycle design philosophy — no signal here waits for a future clock edge to settle).

---

## Branch Condition Decoder
A dedicated combinational block maps `funct3` (which distinguishes the 6 RISC-V branch instructions) to a single `branch_cond` bit, using the ALU outputs already computed by the core:

| `funct3` | Instruction | Condition | Mechanism |
|:---:|---|---|---|
| `000` | `BEQ` | `rs1 == rs2` | `zero` flag directly (ALU performed a subtract; zero result ⇒ equal) |
| `001` | `BNE` | `rs1 != rs2` | `~zero` |
| `100` | `BLT` | `rs1 < rs2` (signed) | `ALU_result[0]` — ALU computed `SLT`, whose result's LSB is the comparison bit |
| `101` | `BGE` | `rs1 >= rs2` (signed) | `~ALU_result[0]` (inverse of BLT) |
| `110` | `BLTU` | `rs1 < rs2` (unsigned) | `ALU_result[0]` — ALU computed `SLTU` |
| `111` | `BGEU` | `rs1 >= rs2` (unsigned) | `~ALU_result[0]` (inverse of BLTU) |
| other | — | `1'b0` | Latch-free safe default |

```verilog
wire branch_taken = Branch & branch_cond;
```

`Branch` (from `MainDecoder`, high for *any* branch opcode) is ANDed with `branch_cond` (the funct3-specific comparison result) so that `branch_taken` is only asserted for **branch instructions whose condition is actually satisfied** — not merely because the current instruction happens to be a branch.

### Why the ALU Computes Both `zero` and the Comparison
This design cleverly **reuses the ALU** for branch comparisons instead of adding dedicated comparator hardware: `ALUDecoder.v` configures the ALU to perform a subtraction (for `BEQ`/`BNE`, checking `zero`) or an `SLT`/`SLTU` (for `BLT`/`BGE`/`BLTU`/`BGEU`, checking the result's LSB) based on `funct3`, and this module simply reads off the appropriate ALU output bit per branch type.

---

## PC Select Logic

```verilog
wire [1:0] pc_sel = jump_jalr  ? 2'b10 :
                    (branch_taken | jump_jal) ? 2'b01 : 2'b00;
```

| Condition | `pc_sel` | Next PC |
|---|:---:|---|
| `jump_jalr` (JALR instruction) | `10` | `jalr_target` (`rs1 + imm`, from ALU) |
| `branch_taken` OR `jump_jal` | `01` | `PC + Imm` |
| otherwise | `00` | `PC + 4` |

**Priority order matters here**: JALR is checked *first*, ahead of branch/JAL, in this ternary chain. Since `jump_jalr` and `jump_jal`/`branch_taken` are architecturally mutually exclusive (only one instruction executes per cycle, and JALR/JAL/branch are distinct opcodes), the priority encoding is a safety/clarity choice rather than a functional necessity — but it does mean if these signals were ever asserted simultaneously (e.g. due to a decoder bug elsewhere), JALR would win.

---

## Key Design Notes

### `pc_sel[1:0]` Replacing a Single `branch_taken` Wire
The header comment highlights this as the central upgrade of this module: a 1-bit "branch or not" signal cannot represent **three** distinct next-PC sources (sequential, PC-relative, register-relative). Expanding to 2 bits and adding the branch condition decoder, JAL wiring, and JALR wiring together is what makes all three RISC-V control-flow mechanisms (conditional branches, JAL, JALR) function correctly in the same core.

### JAL and JALR Previously Broken
The comments note explicitly that **"JAL now properly changes PC"** and **"JALR now properly changes PC"** — implying that in an earlier version of this design, `jump_jal`/`jump_jalr` either didn't exist or weren't wired into PC selection at all, meaning JAL/JALR would execute (writing a possibly-wrong link value, per the `ID_EX_MEM_WB_top.v` fix) but **not actually redirect control flow** — the CPU would silently continue executing sequentially instead of jumping. This module's `pc_sel` logic is the fix that closes that gap.

### `PC` Round-Trips Between the Two Top-Level Blocks
`IF_top` owns and outputs the current `PC`; `CPU_top` feeds that same `PC` value into `ID_EX_MEM_WB_top` (needed there for AUIPC and PC+4 link-address computation); the core in turn produces `Imm`, `jalr_target`, `jump_jal`, `jump_jalr`, `Branch`, and `zero`, which `CPU_top` uses to decide the *next* `PC`, fed back into `IF_top`. This is the single combinational loop that makes the "single-cycle" architecture work — everything resolves within one clock period, with `PC` only updating at the clock edge inside `PC_Top`/`PC.v`.

---

## Relationship to Other Modules
- **`IF_top.v`** — instantiated as `if_stage`; supplies `PC`/`instr`/`instr_valid`, consumes `pc_sel`/`Imm`/`jalr_target`.
- **`ID_EX_MEM_WB_top.v`** — instantiated as `core`; supplies `ALU_result`/`read_data`/`write_data`/`Branch`/`zero`/`Imm`/`funct3`/`jump_jal`/`jump_jalr`/`jalr_target`, consumes `PC`/`instr`.
- **`ALUDecoder.v`** (indirectly, via `core`) — determines whether the ALU performs subtraction or SLT/SLTU for a given branch, which this module's branch condition decoder depends on.
- **`CPU_Display_Top.v`** / **`CPU_top_tb.v`** — expected wrapper/testbench modules that instantiate `CPU_top` and either drive a physical display or run simulation checks against expected register/memory results.
