# `Instruction_Memory.v` — Instruction Memory (Program ROM)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-3%20Fetch%20instruction%20from%20memory.png" width="1100">
</p>

<p align="center">
  <em>Figure: Instruction Fetch from Memory</em><br>
  <em>Instruction Fetch (IF) stage showing program counter access and instruction memory read operation</em>
</p>


## Overview
The **Instruction Memory** module models the program storage of the single-cycle RISC-V core. It is a simple asynchronous (combinational-read) ROM-like array that holds a hand-assembled RV32I machine-code program and returns the instruction word at the requested address every cycle, with no clock delay.

This particular file doubles as a **test-program suite**: it ships with **8 complete demo programs** covering ALU behavior, loops, sorting, and math algorithms, of which **one is active at a time** (the rest are commented out) so the CPU can be validated against a known, hand-traced expected result.

---

## Module Interface

### Parameters
| Parameter | Default | Description |
|-----------|---------|--------------|
| `N` | 32 | Instruction/data word width in bits |
| `M` | 512 | Number of memory words (depth) |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | Clock (present for interface consistency; read logic is combinational) |
| `reset` | 1 | Synchronous/combinational reset — forces output to NOP |
| `instr_req` | 1 | Instruction fetch request/enable |
| `addr` | 32 | Byte address of the instruction to fetch (from `PC`) |

### Outputs
| Signal | Width | Description |
|--------|-------|--------------|
| `instr_valid` | 1 | High when `instr` holds a valid fetched instruction |
| `instr` | `N` (32) | The fetched instruction word |

### Internal
| Signal | Description |
|--------|--------------|
| `Imem [0:M-1]` | The instruction memory array, `M` words of `N` bits |
| `Index_Width` | `$clog2(M)` — number of address bits needed to index `Imem` |

---

## Addressing Scheme
Instructions are addressed **byte-wise** from the `PC` (as required by the RISC-V ISA — `PC` increments by 4 per instruction), but the memory array `Imem` is **word-indexed**. The conversion is:

```verilog
instr = Imem[addr[Index_Width+1 : 2]];
```

- `addr[1:0]` is dropped (always `00` for word-aligned instructions).
- `addr[Index_Width+1 : 2]` extracts just enough bits above that to index all `M` words.

---

## Key Design Notes

### Asynchronous (Combinational) Read — Critical Fix
This module deliberately uses a **combinational** `always @(*)` block instead of a registered (`posedge clk`) read. This was a **fix over an earlier, buggy version**.

**Why synchronous read was wrong:** with a registered read, by the time an instruction (e.g. a branch) is latched into `instr`, the `PC` register (`PC_reg`) has already advanced to `PC+4`. Any PC-relative target calculation (`PC_Target.v`) using `PC_reg` at that point would compute `(PC+4) + imm` instead of the correct `PC + imm` — an off-by-4 error on every branch and jump target.

**Why async read is correct:** with combinational read, `instr` reflects `Imem[addr]` in the *same* cycle that `PC_reg` holds the address of that instruction — so `PC_Target = PC_reg + imm` is computed against the correct `PC`, matching the single-cycle datapath's expectation that everything resolves within one clock period.

### Reset Behavior
On `reset`, the module forces `instr = 32'h00000013` (the RV32I encoding for `addi x0, x0, 0`, i.e. a **NOP**) and drops `instr_valid`, ensuring the pipeline doesn't execute garbage during/after reset.

### Uninitialized Memory Defaults to NOP
The `initial` block first fills the **entire** `Imem` array with NOP (`32'h00000013`) before loading any program. This guarantees that any addresses beyond the loaded program (e.g. after a `HALT`) safely execute as no-ops rather than random synthesis garbage.

---

## Program Suite
Eight self-contained test programs are provided in the `initial` block, each toggled via block comments (`/* ... */`). Only **one** should be active (uncommented) at a time — currently **PART 7 (Bubble Sort)** is active.

| Part | Program | Expected Result | Approx. Cycles |
|------|---------|------------------|-----------------|
| 1 | ALU + Negative Numbers | Various registers (`x3=-5`, `x9=1`, `x12=-5`, `x13=120`, `x17=1`) | ~18 |
| 2 | Array Sum (loop) | `x10 = 97` | ~36 |
| 3 | Count Negatives | `x10 = 4` | ~58 |
| 4 | Factorial (5! via shift-add multiply) | `x10 = 120` | ~103 |
| 5 | GCD(48,18) — Euclidean algorithm | `x10 = 6` | ~32 |
| 6 | Fibonacci (full 32-bit range, overflow-detected exit) | `x24 = 2,971,215,073` (F(47)) | ~103 |
| 7 | Bubble Sort (signed array) | `mem[0..4] = {-5,-3,-1,8,12}` | ~111 |
| 8 | Insertion Sort (signed array) | `mem[0..4] = {-5,-3,-1,8,12}` | ~81 |

### Data Memory Layout Assumed by These Programs
(see `Data_Memory.v` for the actual initialization)

| Words | Byte Range | Contents | Used By |
|-------|-----------|----------|---------|
| 0–4 | 0–16 | `{-5, 12, -3, 8, -1}` (signed) | Sorting (Parts 7, 8) |
| 5–9 | 20–36 | `{10, 25, 7, 40, 15}` (positive) | — |
| 10–17 | 40–68 | 8-element mixed array | Count Negatives (Part 3) |
| 20–24 | 80–96 | `{10, 25, 7, 40, 15}` | Array Sum (Part 2) |

### Algorithmic Notes Worth Highlighting
- **Part 4 (Factorial)** avoids a hardware multiplier by implementing **shift-and-add binary multiplication** (`O(log b)` additions per multiply) using a nested nested loop of ADD/SLLI/SRLI/ANDI on general-purpose registers.
- **Part 6 (Fibonacci)** needs no hard-coded upper bound — it detects the natural **32-bit unsigned overflow** of the Fibonacci recurrence using `BLTU` (branch-if-less-than-unsigned): once `next = prev + curr` wraps around and becomes numerically smaller than `prev`, overflow has occurred and the loop exits, having computed the largest Fibonacci number representable in 32 bits, `F(47) = 2,971,215,073`.
- **Parts 7 & 8 (Sorting)** both use **signed** comparisons (`BLT`, not `BLTU`) since the array contains negative values — this is an important distinction from unsigned magnitude comparisons used elsewhere (e.g. Part 6's overflow check).

---

## Relationship to Other Modules
- **`PC.v` / `PC_Top.v`** — supply the fetch `addr` (current `PC`) each cycle.
- **`IF_top.v`** — likely wraps this module together with `PC_Top.v` as the fetch stage.
- **`Instruction_Decoder.v`** — consumes the fetched `instr` output to extract opcode/register/immediate fields.
- **`Data_Memory.v`** — holds the data arrays these test programs operate on (sum, sort, count negatives, etc.).
- **`CPU_top_tb.v`** — the testbench that runs whichever program is active and checks the expected final register/memory values listed above.
