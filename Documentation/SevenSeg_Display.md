# `SevenSeg_Display.v` — Basys-3 4-Digit 7-Segment Controller (General-Purpose)

## Overview
`SevenSeg_Display` is a general-purpose, **mode-switch-driven** 7-segment display controller for the Basys-3 board. Unlike `SevenSeg_Unified` (bundled inside `CPU_Display_Top.v`, which displays a single pre-selected 16-bit value), this module takes **three raw 32-bit CPU taps directly** — `alu_result`, `pc_in`, `mem_word` — and a 3-bit `mode` select, and internally decides which 16-bit window of which signal to show. This makes it a more flexible, standalone debug-display module suitable for live hardware inspection across arbitrary combinations of ALU/PC/memory state, independent of which of the 8 demo programs is running.

---

## Module Interface

### Parameters
| Parameter | Default | Description |
|-----------|---------|--------------|
| `CLK_FREQ` | 100,000,000 | Input clock frequency (Basys-3's 100 MHz oscillator) |
| `SCAN_FREQ` | 1,000 | Overall 4-digit scan refresh rate (1 kHz ⇒ 250 Hz per digit) |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | 100 MHz board clock |
| `rst` | 1 | Reset |
| `alu_result` | 32 | ALU output tap from the CPU core |
| `pc_in` | 32 | Program counter tap |
| `mem_word` | 32 | A data memory word tap (for sort-result inspection) |
| `mode` | 3 | Display mode select, driven by `SW[4:2]` |

### Outputs
| Signal | Width | Description |
|--------|-------|--------------|
| `seg` | 7 | 7-segment cathode pattern, active-low, `{a,b,c,d,e,f,g}` = bits `[6:0]` |
| `an` | 4 | Digit anode enables, active-low one-hot |
| `dp` | 1 | Decimal point, active-low, used as a visual mode indicator |

---

## Segment Layout Reference
```
      a(6)
     -----
f(1)|     |b(5)
     -g(0)-
e(2)|     |c(4)
     -----
      d(3)
```
`seg[6]` = segment `a` (top), down to `seg[0]` = segment `g` (middle) — standard 7-segment bit convention, driven **active-low** (common-anode display, so a `0` bit lights that segment).

---

## Display Mode Encoding (`mode`, driven by `SW[4:2]`)

| `mode` | Displays | Use Case |
|:---:|---|---|
| `000` | `alu_result[15:0]` | Lower 16 bits of ALU result — general-purpose register/result inspection (Parts 1–6) |
| `001` | `alu_result[31:16]` | Upper 16 bits of ALU result — useful for overflow inspection (e.g. Fibonacci) |
| `010` | `pc_in[15:0]` | Lower 16 bits of the program counter — watch instruction fetch progress live, any program |
| `011` | `mem_word[15:0]` | Lower 16 bits of a tapped memory word — sorted array inspection (Parts 7, 8) |
| `100` | `{alu_result[23:16], alu_result[7:0]}` | A composite "mid-byte" debug view — bytes 2 and 0 of the ALU result shown side-by-side |
| `101` | `{pc_in[23:16], alu_result[7:0]}` | A mixed PC/ALU debug view — byte 2 of PC alongside byte 0 of the ALU result |
| `110` | `alu_result[15:0]` | Labeled as "Fibonacci result (x24) lower 16 bits" — same window as mode `000`, exposed as a distinct, clearly-labeled mode for that specific use case |
| `111` | `16'h8888` | Fixed test pattern — lights every segment on every digit, a quick hardware health check |

### Decimal Point as a Mode Indicator
```verilog
case (mode)
    3'b000: dp = 1'b1;                                // off
    3'b001: dp = (digit_sel == 2'd0) ? 1'b0 : 1'b1;   // dot on digit 0
    3'b010: dp = (digit_sel == 2'd1) ? 1'b0 : 1'b1;   // dot on digit 1
    3'b011: dp = (digit_sel == 2'd2) ? 1'b0 : 1'b1;   // dot on digit 2
    default: dp = 1'b0;                                // all dots on (modes 1xx)
endcase
```
Rather than wiring `dp` to any data signal, this module repurposes it as a **visual at-a-glance mode indicator**: the position (or presence) of the lit decimal point tells the user which of the 8 modes is currently selected, without needing to look at the switches themselves — modes `000`–`011` light the dot on a specific, distinct digit (or not at all), while any `1xx` mode lights all four dots simultaneously as a "high mode range" indicator.

---

## Internal Structure

### Scan Clock Divider
```verilog
localparam integer SCAN_DIV = CLK_FREQ / (SCAN_FREQ * 4);
```
Since 4 digits are multiplexed onto one shared set of segment lines, each digit must be refreshed 4× more often than the overall perceived refresh rate to achieve `SCAN_FREQ` (1 kHz) total — hence dividing by `SCAN_FREQ * 4`. A free-running counter (`clk_cnt`) counts up to `SCAN_DIV - 1` and pulses `tick` for one cycle each time it wraps.

### Digit Counter
```verilog
always @(posedge clk or posedge rst) begin
    if (rst)       digit_sel <= 2'd0;
    else if (tick) digit_sel <= digit_sel + 1'd1;
end
```
Advances through all 4 digit positions (`0`–`3`) once per `tick`, cycling continuously.

### Mode Multiplexer → Nibble Selector → Anode Driver → Hex Decoder
A standard four-stage combinational pipeline for time-multiplexed 7-segment display:
1. **Mode mux** picks which 16-bit `display_val` to show, based on `mode`.
2. **Nibble selector** extracts the 4-bit nibble of `display_val` corresponding to the currently active digit (`digit_sel`).
3. **Anode driver** activates exactly one of the 4 digit positions (active-low one-hot), matching `digit_sel`.
4. **Hex decoder** converts the selected 4-bit nibble into the corresponding active-low 7-segment pattern (supports the full `0`–`F` hex range, since register/memory values are shown in hex, not decimal).

Because all four stages are purely combinational and only `digit_sel` (registered, ticking at ~4 kHz) changes over time, the human eye perceives all 4 digits as continuously lit due to persistence of vision — despite only one physical digit actually being driven at any instant.

---

## Key Design Notes

### Full 0–F Hex Support
Unlike a decimal-only display decoder, this module explicitly supports hex digits `A`–`F` (e.g. `4'hA: seg = 7'b0001000;` for a lowercase-style `A`/`b`/`C`/`d`/`E`/`F` rendering), since raw register and memory values (especially negative numbers in two's-complement, like `-5 = 0xFFFFFFFB`) are far more naturally inspected in hex than forcing a decimal conversion in hardware.

### Composite Debug Modes (`100`, `101`)
Modes `100` and `101` are worth noting as slightly unusual: rather than showing a single contiguous 16-bit slice of one signal, they **splice together non-contiguous byte ranges from different sources** (`{alu_result[23:16], alu_result[7:0]}` and `{pc_in[23:16], alu_result[7:0]}`). These exist purely as ad-hoc hardware debug aids — letting a developer eyeball two otherwise-hidden byte lanes side-by-side on a single 4-digit display without needing 3 separate display passes.

### Relationship to `SevenSeg_Unified`
This module and the `SevenSeg_Unified` module (defined inside `CPU_Display_Top.v`) share nearly identical scan-divider, digit-counter, anode-driver, and hex-decoder logic — the core difference is **where the mode-selection decision happens**: `SevenSeg_Display` takes 3 raw signals plus a `mode` and does its own internal muxing (general-purpose, reusable across projects); `SevenSeg_Unified` expects the caller (`CPU_Display_Top`) to have already picked the exact `value` to show, and only handles the final display/scan mechanics (simpler, tightly coupled to that one specific top-level demo).

---

## Relationship to Other Modules
- **`CPU_top.v` / `CPU_Tapped`** — expected source of the `alu_result`, `pc_in`, and `mem_word` taps this module displays.
- **`CPU_Display_Top.v`** — the sibling FPGA display wrapper; likely an alternative/earlier design to this module, or usable interchangeably depending on which display approach (raw-mode-select vs. pre-selected-value) a given demo build prefers.
- **`Master Constraint.pdf`** — expected to define the physical Basys-3 pin constraints for `seg`, `an`, `dp`, `mode` (switches), and `clk`.
