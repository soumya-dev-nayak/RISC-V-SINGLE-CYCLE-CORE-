# PC Target (PC_Target)

## Overview
The **PC_Target** module computes a PC-relative branch/jump target address by adding the current Program Counter value to a decoded immediate offset. This is used for **conditional branches** (`BEQ`, `BNE`, `BLT`, etc.) and **`JAL`**, both of which specify their destination as an offset relative to the address of the branching/jumping instruction itself — a defining characteristic of RISC-V's PC-relative control-flow addressing.

This module is **purely combinational**, implemented as a single continuous assignment.

---

## Module Declaration

```verilog
module PC_Target #(parameter N=32)
(
    input [N-1:0] PC,
    input [N-1:0] Imm,
    output [N-1:0] PcTarget
);
```

## Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `N` | 32 | Address/data width, matching the processor's word size (RV32). |

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|--------------|
| `PC` | Input | `N` bits | The current Program Counter value (address of the branch/jump instruction). |
| `Imm` | Input | `N` bits | The sign-extended immediate offset, already decoded and formatted by the Immediate Generator (B-type format for branches, J-type format for `JAL`). |
| `PcTarget` | Output (wire) | `N` bits | The computed target address, `PC + Imm`. |

---

## Behavioral Logic

```verilog
assign PcTarget = PC + Imm;
```

A simple adder combining the current instruction address with its associated immediate offset to produce the destination address for PC-relative control transfers.

---

## Design Notes & Observations

- **Reused for both branches and `JAL`**: Since RISC-V branches (B-type) and `JAL` (J-type) both compute their targets identically as `PC + immediate` (just with different immediate encodings/bit layouts, which are resolved upstream by the Immediate Generator), a single adder module can serve both instruction types — this is exactly the output later selected via `pc_sel = 2'b01` in the `PC_MUX` module.
- **Immediate must already be correctly formatted**: This module performs no bit-slicing or sign-extension itself — it assumes `Imm` has already been properly assembled (sign-extended, with the appropriate zero-padding for the low-order bit(s) per the B-type/J-type immediate encoding rules) by the upstream Immediate Generator module.
- **No alignment masking**: Unlike `JALR`, which requires explicit LSB clearing per the RISC-V spec, PC-relative targets from B-type/J-type immediates are inherently even (their immediate encodings never produce an odd offset), so no additional masking is needed here.
- **Purely combinational**: No clocking or state; target computation completes within the same cycle it's needed, consistent with single-cycle datapath timing requirements.
- **Potential overflow/wraparound**: As with `PC_Plus_4`, address wraparound on overflow is not explicitly handled — acceptable in a simple/educational single-cycle design.

---

## Usage in the Datapath

```
PC ──────┐
         ├──► [PC_Target] ──► PcTarget ──► PC_MUX (pc_sel = 2'b01: taken branch / JAL)
Imm ─────┘
```

- **Branches**: When a conditional branch's condition evaluates true (determined via the ALU's `zero`/comparison flags and branch-type logic), `PcTarget` is selected by the `PC_MUX` to redirect control flow.
- **`JAL`**: Always redirects control flow unconditionally to `PcTarget`, in addition to writing the link address (`PC+4`) back to the destination register.

This module works in tandem with `PC_MUX` and `PC_Plus_4` to form the complete set of candidate next-PC values evaluated each cycle in the single-cycle datapath's fetch/control-flow logic.
