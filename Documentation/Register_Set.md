# Register File (Register_Set)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-4%20Read%20source%20operand%20from%20register%20file.png" width="1100">
</p>

<p align="center">
  <em>Figure: Read Source Operands from Register File</em><br>
  <em>Register Fetch (RF) stage illustrating source operand read operation from the register file</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/RegisterFile.png" width="200">
</p>

<p align="center">
  <em>Figure: Register File Architecture</em><br>
  <em>32 × 32-bit register file with dual read ports and a single write port for the RISC-V processor</em>
</p>

## Overview
The **Register_Set** module implements the RISC-V general-purpose register file — a bank of 32 registers, each 32 bits wide (`x0`–`x31`), that serves as the primary fast-access storage for operand data throughout the datapath. It supports simultaneous **dual-read** (for `rs1` and `rs2`) and **single-write** (for `rd`) access within the same cycle, which is essential for a single-cycle datapath where an instruction's source operands must be read and (potentially) a prior instruction's result written back, all inside one clock period.

This module is **sequential** for writes (synchronous, clocked) and **combinational** for reads (asynchronous read ports).

---

## Module Declaration

```verilog
module Register_Set
(
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    input  wire        reg_write
);
```

## Ports

| Port | Direction | Width | Description |
|------|-----------|-------|--------------|
| `clk` | Input | 1 bit | System clock. Register writes occur on the rising edge. |
| `rst` | Input | 1 bit | Asynchronous reset. Clears all 32 registers to `0` when asserted. |
| `rs1_addr` | Input | 5 bits | Address of the first source register (`rs1`) to read, selecting one of 32 registers. |
| `rs2_addr` | Input | 5 bits | Address of the second source register (`rs2`) to read. |
| `rs1_data` | Output (wire) | 32 bits | Data read from the register addressed by `rs1_addr`. |
| `rs2_data` | Output (wire) | 32 bits | Data read from the register addressed by `rs2_addr`. |
| `rd_addr` | Input | 5 bits | Address of the destination register (`rd`) to write. |
| `rd_data` | Input | 32 bits | Data to be written into the register addressed by `rd_addr`. |
| `reg_write` | Input | 1 bit | Control signal enabling a write to the register file this cycle (asserted for instructions that produce a register result). |

## Internal Storage

| Signal | Type | Description |
|--------|------|--------------|
| `regfile` | `reg [31:0] [31:0]` | The register array itself — 32 entries, each 32 bits wide, representing `x0` through `x31`. |
| `i` | `integer` | Loop variable used only during the reset initialization loop. |

---

## Behavioral Logic

### Write Port (Synchronous, with Asynchronous Reset)
```verilog
always @(posedge clk or posedge rst) begin
    if (rst) begin
        for (i = 0; i < 32; i = i + 1)
            regfile[i] <= 32'b0;
    end else begin
        if (reg_write && (rd_addr != 5'b00000))
            regfile[rd_addr] <= rd_data;
    end
end
```

- **Reset behavior**: When `rst` is asserted, a `for` loop iterates over all 32 registers and clears each to `0`. This is an asynchronous reset — it takes effect immediately, independent of the clock edge, matching the `posedge rst` sensitivity.
- **Normal write behavior**: On each rising clock edge (when not in reset), if `reg_write` is asserted **and** the destination address is not `x0` (`5'b00000`), the value on `rd_data` is latched into `regfile[rd_addr]`.
- **`x0` write protection**: The explicit check `rd_addr != 5'b00000` enforces the RISC-V architectural guarantee that **register `x0` is hardwired to zero and can never be written**, even if an instruction nominally targets it (e.g., certain NOP encodings like `ADDI x0, x0, 0`, or intentional writes-to-zero used as "discard result" idioms).

### Read Ports (Combinational, Asynchronous)
```verilog
assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 : regfile[rs1_addr];
assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 : regfile[rs2_addr];
```

- Both read ports are **combinational** — data appears on `rs1_data`/`rs2_data` immediately based on the current `rs1_addr`/`rs2_addr`, with no clock delay. This is essential for single-cycle operation, where the ALU and other downstream logic need operand data within the same cycle the instruction is fetched and decoded.
- **Redundant `x0` safeguard on reads**: Even though `regfile[0]` is already guaranteed to be `0` (since writes to it are blocked), the read logic explicitly forces `0` whenever the requested address is `x0`. This provides a defensive, belt-and-suspenders guarantee that reading `x0` always yields `0`, regardless of any edge case in the write-blocking logic — a good defensive design practice, even if technically redundant given the write protection already in place.

---

## Design Notes & Observations

- **32×32 register array**: Modeled as `reg [31:0] regfile [31:0]` — a standard Verilog 2D memory array construct, synthesizable as a small register-based memory bank (typical for register files of this size, rather than using true RAM macros).
- **Same-cycle write-then-read hazard**: This module does **not** implement any special "write-first"/forwarding behavior for the case where the same cycle writes to a register that is also being read (`rd_addr == rs1_addr` or `rs2_addr`). In a single-cycle processor, this scenario doesn't actually arise as a hazard in the way it would in a pipelined design, since each instruction fully completes (including register write-back) before the next instruction's fetch/read begins — the write from the *current* instruction and the read for the *current* instruction's operands are for logically different points in program order. However, if a testbench or datapath composition allows `rd_addr` and `rs1_addr`/`rs2_addr` to reference the same address **within the same evaluation**, the read output would reflect the **old** value (pre-write), since the write is synchronous (`<=`, takes effect only at the next clock edge) while the read is combinational (reflects current stored state, not the pending write).
- **`x0` handling done twice**: Both the write path (`rd_addr != 5'b00000` guard) and the read path (`rs1_addr == 0`/`rs2_addr == 0` forced-zero mux) enforce the zero-register invariant, providing redundant protection — a reasonable robustness choice for correctness-critical infrastructure like the register file.
- **Asynchronous reset for all 32 registers**: Using a `for` loop inside the always block is a common and synthesis-friendly way to describe bulk reset of an array in Verilog; most synthesis tools will unroll this into 32 parallel reset paths in hardware.
- **No parameterization**: Unlike other modules in this design (`ALU`, `PC`, etc.), this module hardcodes the data width (`32'b0`, `[31:0]`) rather than using a parameter like `N`. This is a minor inconsistency relative to the rest of the codebase's parameterized style, though it's harmless as long as the processor remains fixed at RV32.

---

## Usage in the Datapath

```
                     ┌───────────────────┐
   rs1_addr ────────►│                   │──── rs1_data ────► ALU_MUX / ALU (A input)
   rs2_addr ────────►│   Register_Set    │──── rs2_data ────► ALU_MUX (rs2_data input) / Store data
    rd_addr ────────►│      (this)       │
    rd_data ────────►│                   │
  reg_write ────────►│                   │
        clk ────────►│                   │
        rst ────────►│                   │
                     └───────────────────┘
```

- **`rs1_addr`/`rs2_addr`** are extracted from the instruction's `rs1`/`rs2` fields by the Instruction Decode logic.
- **`rs1_data`** typically feeds the ALU's `A` input (or a PC-vs-register mux for `AUIPC`/`JAL` cases).
- **`rs2_data`** feeds the `ALU_MUX` (as the register-operand alternative to the immediate) and also serves as the data to be stored for `S`-type (store) instructions.
- **`rd_addr`/`rd_data`/`reg_write`** form the write-back interface, driven by the Write-Back stage's result-selection mux (choosing among ALU result, memory read data, or `PC+4` for link instructions) and the `RegWrite` control signal from the Main Control unit.
