# `CPU_top_tb.v` — CPU Testbench (Cycle Monitor + Verification Suite)

## Overview
`CPU_top_tb` is the simulation testbench for `CPU_top.v`. It instantiates the full processor, generates a clock and reset sequence, and provides **eight self-contained test blocks** (`PART 1`–`PART 8`) — one matching each demo program in `Instruction_Memory.v` — that run the simulation for an appropriate duration and then automatically check the resulting register/memory state against hand-computed expected values, printing a `PASS`/`FAIL` verdict.

It also includes a **cycle-by-cycle monitor** for live debugging and, for the Fibonacci test specifically, a specialized **change-triggered table logger** that prints a formatted row every time the Fibonacci state registers update.

---

## Structure

### DUT Instantiation
```verilog
CPU_top dut (.clk(clk), .rst(rst));
```
The entire processor is instantiated as `dut`, with only `clk`/`rst` as external ports — everything else is inspected via **hierarchical signal taps** into the DUT's internals.

### Clock Generation
```verilog
initial clk = 0;
always #5 clk = ~clk;
```
A standard 10 ns period (100 MHz) free-running clock, toggled every 5 ns.

### Register File Taps
Signed and unsigned aliases are taken directly from the register file's internal storage array for nearly every register used across the 8 test programs:
```verilog
wire signed [31:0] sx3 = $signed(dut.core.rf.regfile[3]);
...
wire [31:0] x10 = dut.core.rf.regfile[10];
```
Signed (`sx*`) variants are used for tests involving negative numbers (ALU test, sorting); unsigned (`x*`) variants are used where magnitude comparisons or hex/decimal display without sign interpretation are more natural (loop counters, sums).

### Data Memory Taps
```verilog
wire signed [31:0] mem0 = $signed(dut.core.dmem.mem[0]);
...
```
Direct hierarchical access into `Data_Memory`'s internal `mem` array — needed because the sorting tests (Parts 7 & 8) verify their result **in memory**, not in a register.

### PC / Instruction Taps
```verilog
wire [31:0] cur_PC    = dut.PC;
wire [31:0] cur_instr = dut.instr;
```
Exposes the live fetch-stage state for the cycle monitor.

---

## Cycle Monitor
```verilog
always @(posedge clk) begin
    cycle_count = cycle_count + 1;
    if (MONITOR_ON && !rst) begin
        $display("  [cyc%4d] PC=0x%04X  instr=0x%08X  x5=%0d x6=%0d x8=%0d x10=%0d", ...);
    end
end
```
A generic, always-running cycle counter and optional per-cycle trace printer, gated by the `MONITOR_ON` flag (toggled inside whichever `PART` block is active). Prints `PC`, raw instruction hex, and four commonly-used loop/counter registers (`x5`, `x6`, `x8`, `x10`) — covering the register roles used across most of the test programs' loop bookkeeping.

---

## Test Blocks (PART 1–8)
Each `PART` block is a separate `initial` block wrapped in `/* ... */` block comments; **exactly one is active (uncommented) at a time**, matching whichever program is active in `Instruction_Memory.v`. Currently **PART 7 (Bubble Sort)** is active.

| Part | Verifies | Pass Condition | Sim Duration |
|---|---|---|---|
| 1 | ALU + negative-number ops | `sx3==-5 && sx9==1 && sx12==-5 && sx13==120 && sx17==1` | 250 ns |
| 2 | Array Sum (loop/JAL) | `x10 == 97` | 600 ns |
| 3 | Count Negatives | `x10 == 4` | 800 ns |
| 4 | Factorial (5!) | `x10 == 120` | 1500 ns |
| 5 | GCD(48,18) | `x10 == 6` | 600 ns |
| 6 | Fibonacci (32-bit overflow-bounded) | `x24 == 2971215073` | 4000 ns |
| 7 | Bubble Sort (signed) — **active** | `mem0..4 == {-5,-3,-1,8,12}` | 3000 ns |
| 8 | Insertion Sort (signed) | `mem0..4 == {-5,-3,-1,8,12}` | 2000 ns |

Each block follows the same pattern:
1. Set up waveform dumping (`$dumpfile`/`$dumpvars`) for GTKWave inspection.
2. Optionally enable `MONITOR_ON` for live cycle tracing.
3. Pulse `rst` high for 20 ns, then release it.
4. Wait a fixed duration long enough for the program to reach `HALT` (estimated from the cycle counts documented in `Instruction_Memory.v`).
5. Print expected-vs-actual values for every relevant register/memory location.
6. Evaluate a pass/fail condition and print a clear `>>> PASS <<<` or `>>> FAIL <<<` banner.
7. `$finish` to end simulation.

---

## Key Design Notes

### Hierarchical Signal Access for Verification
Rather than exposing internal state through dedicated debug ports on `CPU_top`, this testbench uses Verilog's **hierarchical name referencing** (`dut.core.rf.regfile[N]`, `dut.core.dmem.mem[N]`) to reach directly into nested module instances. This is a common and convenient simulation-only technique — it requires no changes to the DUT's actual interface, but does depend on the internal instance names (`core`, `rf`, `dmem`) staying consistent with `CPU_top.v`/`ID_EX_MEM_WB_top.v`'s instantiation names (`core`, `rf`, `dmem`).

### Change-Triggered Fibonacci Logger (PART 6)
Unlike the other parts, PART 6 doesn't rely solely on the generic cycle monitor. It adds a dedicated `always @(posedge clk)` block that detects whenever `x24` (the "next" Fibonacci value) changes, and only then prints a formatted table row — showing the iteration count, cycle count, PC, instruction, and the sliding window `x22`/`x23`/`x24`. This produces a compact, readable log of exactly the 46 meaningful iterations rather than ~100+ cycle-by-cycle lines, most of which would be redundant.

It also uses a **one-cycle-delayed PC/instruction latch**:
```verilog
always @(posedge clk) begin
    latch_PC    <= cur_PC;
    latch_instr <= cur_instr;
end
```
This compensates for the fact that a register's *new* value becomes visible on the same edge that the *next* instruction's PC/instr are already latched — using the delayed values aligns the printed PC/instruction with the state that actually produced the register change being reported.

### Signed vs. Unsigned Display Discipline
The testbench is careful to use `$signed()`/`$unsigned()` casts appropriately per test:
- ALU test (Part 1) and sorting tests (Parts 7/8) use **signed** display, since their programs explicitly manipulate negative numbers.
- Sum/count/GCD/factorial tests use **unsigned** display where the values are inherently non-negative results, even though the underlying registers are plain 32-bit words either way.

### Generous Timing Margins
Each `PART`'s wait duration is set noticeably longer than the documented expected cycle count (e.g. Bubble Sort's ~111 cycles × 10 ns ≈ 1110 ns, but the testbench waits 3000 ns). This is a deliberate safety margin, explicitly noted in-line ("wait 3000 for safety"), to avoid flaky test failures from off-by-a-few-cycles estimation errors, since the simulation checks final state after a fixed wall-clock delay rather than detecting `HALT` dynamically.

### No Explicit Halt Detection
None of the test blocks detect the `HALT` condition (a `jal x0, 0` infinite self-loop) directly — they simply wait a fixed time believed to be well past when `HALT` is reached, then sample state. This is simple and robust as long as the timing margins remain generous, though it means simulation time is not minimized and a genuinely hung/incorrect program (never reaching the expected state) would still run for the full fixed duration before reporting `FAIL`.

---

## Compilation
The header comment documents the exact `iverilog` invocation needed to build the simulation, listing every source file required:
```
iverilog -o sim ALU.v ALUDecoder.v ALU_MUX.v SrcA_MUX.v \
  CPU_top.v CPU_top_tb.v Data_Memory.v ID_EX_MEM_WB_top.v \
  IF_top.v Imm_Gen.v Instruction_Decoder.v \
  Instruction_Memory.v MainDSecoder.v PC.v PC_Mux.v \
  PC_Plus_4.v PC_Target.v PC_Top.v Register_Set.v \
  WriteBack_MUX.v && vvp sim
```

---

## Relationship to Other Modules
- **`CPU_top.v`** — the DUT being tested.
- **`Instruction_Memory.v`** — must have the **matching** `PART` block uncommented for whichever test is active here; the two files are coupled and must be kept in sync manually.
- **`Data_Memory.v`** / **`Register_Set.v`** — their internal arrays (`mem`, `regfile`) are accessed hierarchically for verification.
- **`CPU_Display_Top.v`** — a separate, non-testbench wrapper likely used for physical/FPGA demonstration rather than automated simulation checking.
