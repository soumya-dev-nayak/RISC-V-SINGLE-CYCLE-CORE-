# PC Plus 4 (PC_Plus_4)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-9%20Increment%20program%20counter.png" width="1100">
</p>

<p align="center">
  <em>Figure: Increment Program Counter</em><br>
  <em>Program Counter (PC) update stage where the next sequential instruction address (PC + 4) is generated</em>
</p>

## Overview
The **PC_Plus_4** module computes the default sequential next-instruction address by adding a fixed constant of `4` to the current Program Counter value. Since RISC-V instructions in the base ISA are 4 bytes (32 bits) wide, this represents the "advance to the next instruction" address calculation used when no branch or jump is taken.

This module is **purely combinational**, implemented as a single continuous assignment.

---

## Module Declaration

```verilog
module PC_Plus_4 #(parameter N=32)
(
    input [N-1:0] PC,
    output [N-1:0] PCPlus4
);
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 32 | Address width, matching the processor's word size (RV32). |

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|--------------|
| `PC` | Input | `N` bits | The current Program Counter value (current instruction address). |
| `PCPlus4` | Output (wire) | `N` bits | The computed next sequential address, `PC + 4`. |

---

## Behavioral Logic

```verilog
assign PCPlus4 = PC + 32'd4;
```

A simple adder that increments `PC` by a constant `4`. This reflects the fact that each instruction in the base RV32I instruction set occupies exactly 4 bytes in memory, so advancing to the "next" instruction means moving the address forward by 4.

---

## Design Notes & Observations

- **Fixed increment of 4**: This module assumes a fixed 32-bit (4-byte) instruction width. It does **not** account for the RISC-V "C" (Compressed Instructions) extension, where instructions can be 2 bytes wide — this design targets the base RV32I ISA without compressed instruction support.
- **Hardcoded constant width (`32'd4`)**: The literal `32'd4` is hardcoded to 32 bits regardless of the `N` parameter. For the default `N=32` case this is correct, but if `N` were changed (e.g., for a 64-bit variant), this constant would need to be updated to match (e.g., `64'd4`) to avoid width-mismatch truncation/extension issues during synthesis or simulation.
- **No overflow handling**: If `PC` is at its maximum representable value, `PC + 4` will wrap around (unsigned overflow) rather than trigger any exception — consistent with typical simple/educational single-cycle processor designs where address space wraparound is not a concern.
- **Purely combinational**: No clock or state; the output is available immediately from the current `PC` input, well within the constraints of a single-cycle datapath where this value must be ready in the same cycle it's computed.

---

## Usage in the Datapath

```
PC (from PC register) ──► [PC_Plus_4] ──► PCPlus4 ──┬──► PC_MUX (pc_sel = 2'b00, sequential path)
                                                     └──► JAL target adder (PC + Imm), if applicable
```

- **Primary use**: Feeds directly into the **PC MUX** as the default "sequential execution" candidate (`pc_sel = 2'b00`), selected whenever the current instruction is not a taken branch, `JAL`, or `JALR`.
- **Secondary use (implementation-dependent)**: `PCPlus4` is also commonly used as the **link/return address** stored into the destination register for `JAL` and `JALR` instructions (i.e., `rd = PC + 4`), since the link address must point to the instruction immediately following the jump. Depending on the datapath's write-back mux design, this same signal may be routed there as well.
