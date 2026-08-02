# PC Subsystem (PC_Top)

## Overview
The **PC_Top** module is a structural wrapper that integrates the four PC-related submodules — the **PC register**, the **PC+4 adder**, the **PC-relative target adder**, and the **3:1 PC MUX** — into a single cohesive "PC Subsystem." It encapsulates all logic responsible for determining and storing the address of the instruction to be fetched next, presenting a clean top-level interface (`pc_sel`, `Imm`, `jalr_target`, `PC`) to the rest of the datapath.

This module is **structural** (an interconnection of submodules) with no combinational or sequential logic of its own beyond wiring and one continuous pass-through assignment.

---

## Revision History (per source comments)

### Change Summary
The `branch` input (a single bit, from the earlier 2:1 mux design) has been **replaced by `pc_sel[1:0]`**, a 2-bit selector, to support three distinct next-PC sources: **sequential execution**, **branch/JAL target**, and **JALR target**. This mirrors the upgrade already documented in the `PC_MUX` module — this top-level wrapper has been updated in lockstep to expose the new 2-bit control signal and the new `jalr_target` input required to support `JALR`.

### New Port
`jalr_target` — a newly added input carrying the ALU-computed `JALR` target address (`rs1 + I-immediate`), which did not exist in the prior 2-way-branch-only version of this subsystem.

---

## Module Declaration

```verilog
module PC_Top #(parameter N=32)
(
    input wire        clk,
    input wire        rst,
    input wire [1:0]  pc_sel,
    input wire [N-1:0] Imm,
    input wire [N-1:0] jalr_target,
    output wire [N-1:0] PC
);
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 32 | Address/data width, matching the processor's word size (RV32). |

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|--------------|
| `clk` | Input | 1 bit | System clock, forwarded to the internal `PC` register. |
| `rst` | Input | 1 bit | Asynchronous reset, forwarded to the internal `PC` register. |
| `pc_sel` | Input | 2 bits | Next-PC source selector, forwarded to the internal `PC_MUX`. See `PC_MUX` documentation for encoding details. |
| `Imm` | Input | `N` bits | Sign-extended branch/JAL immediate, used to compute the PC-relative target. |
| `jalr_target` | Input | `N` bits | ALU-computed `JALR` target address (`rs1 + imm`), sourced externally from the main datapath ALU. |
| `PC` | Output (wire) | `N` bits | The current Program Counter value, exposed to the rest of the processor (Instruction Memory, PC+4 use for link addresses, `AUIPC`, etc.). |

---

## Internal Signals

| Signal | Width | Purpose |
|--------|-------|---------|
| `PCNext` | `N` bits | The selected next-PC value, output of `PC_MUX`, fed into the `PC` register's input. |
| `PCPlus4` | `N` bits | Sequential next address, output of `PC_Plus_4`. |
| `PCTarget` | `N` bits | PC-relative branch/JAL target, output of `PC_Target`. |
| `PC_reg` | `N` bits | The registered current PC value, output of the `PC` submodule; also driven out as the top-level `PC` output. |

---

## Internal Structure & Instantiated Submodules

```
PC_Top
 ├── PC          (PC_inst)     — sequential register holding current PC
 ├── PC_Plus_4   (PP_4_inst)   — computes PC + 4 (sequential next address)
 ├── PC_Target   (PT_inst)     — computes PC + Imm (branch/JAL target)
 └── PC_MUX      (mux_inst)    — 3:1 mux selecting PCNext from the above + jalr_target
```

### 1. `PC` (`PC_inst`)
```verilog
PC #(.N(N)) PC_inst (
    .clk(clk), .rst(rst),
    .PCNext(PCNext),
    .PC(PC_reg)
);
```
Holds the current instruction address as a clocked register. Receives its next value (`PCNext`) from the output of the internal `PC_MUX`, and outputs the registered value as `PC_reg`.

### 2. `PC_Plus_4` (`PP_4_inst`)
```verilog
PC_Plus_4 #(.N(N)) PP_4_inst (
    .PC(PC_reg),
    .PCPlus4(PCPlus4)
);
```
Computes the default sequential next-instruction address from the current registered PC value.

### 3. `PC_Target` (`PT_inst`)
```verilog
PC_Target #(.N(N)) PT_inst (
    .PC(PC_reg),
    .Imm(Imm),
    .PcTarget(PCTarget)
);
```
Computes the PC-relative branch/JAL target address using the current registered PC and the externally supplied immediate.

### 4. `PC_MUX` (`mux_inst`)
```verilog
PC_MUX #(.N(N)) mux_inst (
    .pc_sel(pc_sel),
    .PCPlus4(PCPlus4),
    .PcTarget(PCTarget),
    .JalrTarget(jalr_target),
    .PCNext(PCNext)
);
```
Selects among the three next-PC candidates (`PCPlus4`, `PCTarget`, `jalr_target`) based on `pc_sel`, producing `PCNext`, which feeds back into the `PC` register on the next clock edge.

### Final Output
```verilog
assign PC = PC_reg;
```
The internal registered PC value is passed through unchanged as the module's top-level `PC` output.

---

## Design Notes & Observations

- **Clean separation of concerns via composition**: This module demonstrates good hardware design hygiene by composing four single-purpose submodules (register, two adders, and a mux) rather than folding all logic into one large block — improving readability, testability, and reusability of each piece independently.
- **Feedback loop structure**: Note the cyclical data dependency: `PC_reg` (from the `PC` register) feeds both adders (`PC_Plus_4`, `PC_Target`), whose outputs feed the `PC_MUX`, whose output (`PCNext`) feeds back into the `PC` register's input for the *next* clock edge. This is the expected and correct feedback topology for a program counter subsystem — the loop is "broken" safely by the register's clocked update, ensuring no combinational loop exists.
- **`jalr_target` sourced from outside this subsystem**: Unlike `PCPlus4` and `PCTarget`, which are computed internally, `jalr_target` is expected to be computed by the **main datapath ALU** (as `rs1 + I-type immediate`) and passed in from outside. This reflects a deliberate design choice to avoid duplicating ALU adder hardware inside the PC subsystem — the main ALU is reused for this address calculation.
- **Consistent evolution with `PC_MUX`**: This module's `pc_sel` upgrade directly parallels the earlier `PC_MUX` upgrade (2:1 → 3:1) documented separately — the two modules were updated together to fix the same underlying bug (missing `JAL`/`JALR` PC redirection).
- **Encapsulation benefit**: By exposing only `clk`, `rst`, `pc_sel`, `Imm`, `jalr_target`, and `PC` at the top level, this module hides the internal wiring complexity (four submodules, four internal wires) from the rest of the processor's top-level integration, making the overall CPU top-level module simpler to read and connect.

---

## Usage in the Datapath

```
                          ┌─────────────────────────────────────┐
                          │              PC_Top                 │
                          │                                     │
   clk ────────────────────────► PC_inst.clk                    │
   rst ────────────────────────► PC_inst.rst                    │
                          │        │                            │
                          │        ▼ PC_reg                     │
                          │   ┌────┴─────┬───────────┐          │
                          │   ▼          ▼           │          │
                          │ PC_Plus_4  PC_Target      │          │
                          │   │          │  ▲Imm◄─────┼───────── Imm (from Immediate Gen)
                          │   ▼          ▼             │
                          │ PCPlus4   PCTarget          │
                          │   │          │   jalr_target◄────── jalr_target (from ALU)
                          │   └────┬─────┴──────┬──────┘
                          │        ▼            │
                          │      PC_MUX ◄────────┘ (pc_sel)
                          │        │
                          │        ▼ PCNext
                          │   (feeds back to PC_inst)
                          │                                     │
                          └──────────────────── PC (output) ────┘
                                                   │
                                                   ▼
                                          Instruction Memory, etc.
```

`PC_Top` serves as the **complete fetch-address generation subsystem** for the single-cycle processor, integrating storage (the `PC` register), the two candidate address computations (`PC_Plus_4`, `PC_Target`), external `JALR` target input, and final selection (`PC_MUX`) behind a single clean interface used by the top-level CPU module.
