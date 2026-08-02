# `CPU_Display_Top.v` — Unified Basys-3 Display Wrapper

## Overview
`CPU_Display_Top.v` is the **FPGA demonstration wrapper** for the RISC-V core, targeting a Digilent Basys-3 board. Rather than being a single module, this file bundles **four cooperating modules**:

1. **`CPU_Display_Top`** — the synthesis top module: decodes board switches, generates a variable-speed clock-enable, instantiates the tapped CPU, multiplexes which register/memory value to show, and drives the 7-segment display.
2. **`CPU_Tapped`** — a structural near-copy of `CPU_top.v`, rebuilt with a `clk_en` (clock-enable) input instead of relying on `CPU_top`'s always-running clock, and with every register/memory value needed across all 8 demo programs exposed as output ports.
3. **`IF_top_CE`** — a clock-enabled variant of `IF_top.v`, where the PC register only advances on ticks where `clk_en` is asserted.
4. **`SevenSeg_Unified`** — a 4-digit time-multiplexed 7-segment display driver.

Together, these let a single bitstream demonstrate **any** of the 8 test programs (selected at compile-time via the `` `PROGRAM_ID `` macro) on real hardware, with switch-controlled reset, speed, and value selection.

---

## Top-Level Ports (`CPU_Display_Top`)
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | 100 MHz board oscillator (Basys-3 pin `W5`) |
| `sw` | 5 | Switches `SW[4:0]` |
| `seg` | 7 | 7-segment cathode outputs (active-low) |
| `dp` | 1 | Decimal point (active-low) |
| `an` | 4 | Digit anode selects (active-low, one-hot) |

### Switch Map
| Switch | Function |
|---|---|
| `SW[0]` | Reset (toggle up then down to restart the CPU) |
| `SW[2:1]` | Speed select — only meaningful for `PROGRAM_ID` 6–8 (Fibonacci/sorts); ignored (full speed) for Parts 1–5 |
| `SW[3]` | Register/value select (program-specific — see table below) |
| `SW[4]` | `0` = show lower 16 bits, `1` = show upper 16 bits (decimal point lights when showing upper half) |

### Speed Encoding (`SW[2:1]`, Parts 6–8 only)
| `speed_sel` | Approx. Rate | Clock Divisor |
|:---:|---|---|
| `00` | ~1 Hz | 100,000,000 |
| `01` | ~4 Hz | 25,000,000 |
| `10` | ~8 Hz | 12,500,000 |
| `11` | Full speed (instant) | 1 |

### `SW[3]` Meaning Per Program
| `PROGRAM_ID` | `SW[3]=0` | `SW[3]=1` |
|:---:|---|---|
| 1 (ALU Test) | `x3` (`-5`) | `x9`/`x12`/`x13` (cycling) |
| 2 (Array Sum) | `x10` (`97`, always shown regardless) | — |
| 3 (Count Neg) | `x10` (`4`, always shown) | — |
| 4 (Factorial) | `x10` (`120`, always shown) | — |
| 5 (GCD) | `x10` (result `6`) | `x5` (`a` at halt) |
| 6 (Fibonacci) | `x22` (`prev`) | `x23` (`curr`, recommended) |
| 7 (Bubble Sort) | `mem[0]` | `mem[1]` |
| 8 (Insertion Sort) | `mem[0]` | `mem[1]` |

---

## Compile-Time Program Selection
```verilog
`define PROGRAM_ID 6
```
This macro must be manually set to match whichever `PART` block is active in `Instruction_Memory.v` (1–8). It drives both the display multiplexer logic and the clock-enable divisor selection (only Parts 6–8 use variable speed; 1–5 always run at full speed since they halt almost instantly and only their final frozen result matters).

---

## Clock-Enable Tick Generator
```verilog
if (`PROGRAM_ID >= 6) begin
    case (speed_sel) ... endcase   // variable divisor
end else begin
    divisor = 27'd1;               // always full speed
end
```
A free-running counter compares against `divisor - 1` and pulses `cpu_tick` high for one clock when it rolls over. For **Parts 1–5**, since these programs execute in tens of cycles and halt near-instantly relative to human perception, there's no benefit to slowing them down — they always run at full 100 MHz speed and the display simply shows the frozen final result. For **Parts 6–8** (long-running loops — Fibonacci's ~46 iterations, sort's ~80–110 cycles), a human-visible step-by-step rate is genuinely useful for live demonstration, hence the switch-selectable divisor.

---

## `CPU_Tapped` — Structural Copy of `CPU_top` with Clock-Enable

### Why a Separate Module Instead of Reusing `CPU_top`
The header comment explains the key design decision: rather than **gating the clock signal itself** (which is common in ASIC design but creates clock-domain-crossing (CDC) analysis headaches and timing-closure warnings in FPGA tools like Vivado), this module uses a proper **clock-enable** pattern — the clock (`clk`) stays free-running and untouched, and a separate `clk_en` signal gates *which cycles' results actually commit*:

```verilog
wire RegWrite_g = RegWrite & clk_en;
wire MemWrite_g = MemWrite & clk_en;
```

The register file and data memory only write when both their normal write-enable condition **and** `clk_en` are true. The PC register (inside `IF_top_CE`) is gated the same way. This means on cycles where `clk_en` is low, the CPU's combinational logic still evaluates every cycle (harmlessly), but no state-holding element (registers, memory, PC) actually updates — effectively "pausing" the CPU without touching the clock tree, which synthesizes and times cleanly.

### Structure
Internally, `CPU_Tapped` is essentially line-for-line the same datapath as `CPU_top.v` + `ID_EX_MEM_WB_top.v` merged into one flattened module (rather than nested instantiation), with the same branch-condition decoder and `pc_sel` logic duplicated here. It instantiates:
`Instruction_Decoder`, `MainDecoder`, `Register_Set` (as `rf`), `Imm_Gen`, `SrcA_MUX`, `ALU_MUX`, `ALUDecoder`, `ALU`, `Data_Memory` (as `dmem`), `WriteBack_MUX`, and `IF_top_CE`.

### Register & Memory Taps
Every register/memory value needed by **any** of the 8 programs is exposed as a dedicated output port, read directly from the internal arrays:
```verilog
assign x3_out  = rf.regfile[3];
...
assign mem0_out = dmem.mem[0];
```
This avoids the display wrapper needing hierarchical references into the DUT (as the testbench does) — instead, all needed signals are proper ports, appropriate for a synthesizable top-level design.

---

## `IF_top_CE` — Clock-Enabled Fetch Stage
Nearly identical to `IF_top.v`, with one change: the PC register only updates when `clk_en` is high.
```verilog
always @(posedge clk or posedge reset) begin
    if (reset)       PC_reg <= {N{1'b0}};
    else if (clk_en) PC_reg <= PCNext;
    // when clk_en=0, PC_reg holds — CPU paused
end
```
Instruction memory access remains combinational/unchanged, exactly as in the base `IF_top.v` — only the PC register itself needs gating, since that's the only state element in the fetch stage.

---

## Display Value Multiplexing (`CPU_Display_Top`)
```verilog
case (`PROGRAM_ID)
    1: display_word = val_sel ? x9  : x3;
    2: display_word = x10;
    ...
    6: display_word = val_sel ? x23 : x22;
    7: display_word = val_sel ? mem1 : mem0;
    8: display_word = val_sel ? mem1 : mem0;
    default: display_word = 32'hDEAD_BEEF; // should never happen
endcase
```
A compile-time `` `PROGRAM_ID `` selects which case is live (synthesis tools will optimize away the unused branches), and within that case, `val_sel` (`SW[3]`) picks between two candidate values where applicable. The resulting 32-bit `display_word` is then windowed down to 16 bits by `show_upper` (`SW[4]`) before being handed to the display driver:
```verilog
wire [15:0] display_val = show_upper ? display_word[31:16] : display_word[15:0];
```
The sentinel `32'hDEAD_BEEF` default is a debugging aid — if it ever appears on the display, it signals `` `PROGRAM_ID `` was set to an invalid value (not 1–8).

### Display Always Runs at Full Speed
Note that `SevenSeg_Unified` is driven directly by `clk` (100 MHz), **not** by `cpu_tick` — this is intentional: the 7-segment scanning/multiplexing must refresh fast enough to avoid visible flicker regardless of how slowly the CPU itself is stepping, so the display refresh rate and the CPU execution rate are two independent clock domains sharing only the same physical oscillator.

---

## `SevenSeg_Unified` — 4-Digit Display Driver
A simplified variant of `SevenSeg_Display.v` (see that file's documentation for the shared time-multiplexing/hex-decoding logic), specialized for this wrapper's needs:
- Takes an already-selected 16-bit `value` (the display mux has already picked the right register/memory word upstream).
- `show_upper` doubles as a single-purpose decimal-point indicator: `dp = show_upper ? 0 : 1'b1` — i.e., **all digits'** decimal point context is really just one shared `dp` output lit whenever the *upper* half is being displayed, giving the user a simple visual cue for which 16-bit window they're looking at.
- Same scan-divider, anode one-hot, and hex-to-7-segment decode logic as `SevenSeg_Display.v`.

---

## Key Design Notes

### Clock-Enable vs. Gated Clock
This is the most important architectural decision in the file, called out explicitly in the header comments: gating `clk` itself (e.g., `wire gated_clk = clk & cpu_tick;`) is a common source of **hold-time violations and CDC warnings** in FPGA synthesis/timing tools, because the gated signal is not a "clean" clock the tool's clock-tree analysis recognizes. Using `clk_en` as a synchronous enable on every register instead keeps the single physical clock domain intact and lets Vivado's static timing analysis run without special-casing.

### Single File, Multiple Modules
Unlike most files in this project (one module per file), this file intentionally bundles 4 tightly-coupled modules together, since they only exist to support this one FPGA demo wrapper and aren't reused independently elsewhere.

### Manual Synchronization Requirement
Just like `CPU_top_tb.v`, this module requires **manual coordination**: whichever `PART` is active in `Instruction_Memory.v` must match the `` `PROGRAM_ID `` macro here, or the display will show data from registers/memory that the running program never actually populates meaningfully.

---

## Relationship to Other Modules
- **`CPU_top.v`** — the non-tapped, non-gated reference implementation this module structurally mirrors (but does not directly instantiate — `CPU_Tapped` is a parallel rebuild, not a wrapper around `CPU_top`).
- **`IF_top.v`** — the ungated original that `IF_top_CE` is derived from.
- **`Instruction_Memory.v`** — must have the matching `PART` uncommented for the active `` `PROGRAM_ID ``.
- **`SevenSeg_Display.v`** — a more general-purpose, switch-mode-driven variant of the same 7-segment driving logic used here in a simplified `SevenSeg_Unified` form.
- **`Master Constraint.pdf`** — expected to define the physical pin mappings (`clk`, `sw`, `seg`, `an`, `dp`) for the Basys-3 board that this module's ports correspond to.
