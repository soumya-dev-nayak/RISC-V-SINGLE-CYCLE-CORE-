# Program Counter (PC)

## Overview
The **Program Counter (PC)** is a sequential register that holds the address of the instruction currently being fetched. It is the sole stateful element that drives instruction sequencing in the processor — every cycle, it updates to `PCNext`, which is computed externally (typically `PC + 4` for sequential execution, or a branch/jump target when control flow changes).

This module is **sequential**, updating synchronously on the rising edge of the clock, with an asynchronous reset.

---

## Module Declaration

```verilog
module PC #(parameter N = 32)
(
    input clk, rst,
    input [N-1:0] PCNext,
    output reg [N-1:0] PC
);
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 32 | Width of the PC register, matching the processor's address/word width (RV32). |

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|--------------|
| `clk` | Input | 1 bit | System clock. PC updates on the rising edge. |
| `rst` | Input | 1 bit | Asynchronous reset. When asserted, forces `PC` to `0` regardless of clock. |
| `PCNext` | Input | `N` bits | The next PC value, computed by external datapath logic (PC+4 adder, branch target adder, jump target mux, etc.). |
| `PC` | Output (reg) | `N` bits | The current instruction address, fed to the Instruction Memory and used throughout the datapath (e.g., for `AUIPC`, `JAL` link address calculation). |

---

## Behavioral Logic

```verilog
always @(posedge clk or posedge rst) begin
    if(rst)
        PC <= 0;
    else
        PC <= PCNext;
end
```

| Condition | Behavior |
|-----------|----------|
| `rst` asserted (any time) | `PC` is asynchronously forced to `0` — takes effect immediately, not waiting for a clock edge. |
| `rst` de-asserted, rising edge of `clk` | `PC` is updated to `PCNext` — a normal synchronous register update. |

**Sensitivity list note:** The `always @(posedge clk or posedge rst)` construct describes an **asynchronous reset** flip-flop — `rst` is treated as an independent trigger for the block, not sampled only at the clock edge. This means reset takes effect immediately when asserted, without needing to wait for `clk` to tick.

---

## Design Notes & Observations

- **Single point of sequential state for fetch**: The PC is the canonical "single source of truth" for instruction address sequencing in a single-cycle processor. All fetch-stage logic depends on its current value.
- **Reset value of `0`**: On reset, execution always begins at address `0x00000000`, following the common convention that the first instruction resides at the base of the instruction memory/reset vector.
- **`PCNext` is externally computed**: This module contains **no adder or branch logic itself** — it purely stores whatever value is presented at `PCNext`. The actual "what's next" decision (sequential +4, branch target, jump target, `JALR` target) is resolved by a separate PC-next mux/adder chain elsewhere in the datapath. This keeps the PC module minimal and reusable.
- **Non-blocking assignment (`<=`)**: Correctly used for sequential/clocked logic, ensuring proper register-transfer-level (RTL) semantics and avoiding race conditions in simulation.
- **Naming convention note**: The header comment references "pulpino" — likely indicating this PC module is adapted from or inspired by the PULPino open-source RISC-V core project, though the implementation here is simplified for a single-cycle design (pulpino itself is a more complex multi-stage/pipelined core).

---

## Usage in the Datapath

```
                    ┌──────────────────────────────┐
                    │                               │
                    ▼                               │
     rst ──────►┌────────┐                          │
     clk ──────►│   PC   │──── PC ────► Instruction Memory
  PCNext ──────►│ (this) │──── PC ────► PC+4 Adder / AUIPC / JAL target calc
                └────────┘                          │
                    ▲                               │
                    └────── PCNext ◄─── Next-PC Mux ◄┘ (branch/jump/sequential)
```

The PC's output feeds:
1. **Instruction Memory** — to fetch the instruction at the current address.
2. **PC+4 Adder** — to compute the default sequential next address.
3. **Branch/Jump Target Logic** — as the base for PC-relative address calculations (`AUIPC`, `JAL`, branches).

Its input (`PCNext`) is driven by a mux that selects among these candidate next-PC values based on control signals (`PCSrc`, branch taken, etc.) determined later in the same cycle (since this is a single-cycle design with no pipelining).
