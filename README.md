# RISC-V RV32I Single-Cycle CPU

> A from-scratch, fully documented **single-cycle RV32I processor core** written in Verilog — complete with a working ALU, control unit, PC subsystem, register file, instruction/data memory, an 8-program test suite (ALU ops, array sum, counting, factorial, GCD, Fibonacci, bubble sort, insertion sort), a simulation testbench, and a live FPGA demo (Basys-3, 7-segment display).

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-28%20Complete%20Multucycle%20Processor.png" width="1100">
</p>

<p align="center">
  <em>Figure: Complete Multicycle Processor</em><br>
  <em>Complete datapath and control architecture of the multicycle RISC-V processor</em>
</p>

---

## 📖 How to Read This Repository

This README is the **front door** — every module in this core has its own dedicated write-up under [`/Documentation`](./Documentation), and every link below jumps straight to that file, the way a table of contents in a book takes you straight to a chapter.

The documentation is arranged **bottom-up**: we start with the small, foundational building blocks (decoders, the register file, the ALU) and work our way up through the wiring subsystems (PC, fetch stage, datapath) to the fully integrated CPU, its testbench, and finally its FPGA demo shell. Read it in order if you're learning the design for the first time; jump straight to any chapter if you already know what you're looking for.

Every `.v` source file in the repo root has a matching `.md` file in `/Documentation` with the **same name** — if you're staring at `ALU.v` and want the explanation, look for `ALU.md`.

### Suggested Reading Paths
Not everyone landing on this repo wants the same thing, so here are three reasonable ways to work through it depending on what you're after:

- **"I want to understand computer architecture from scratch."** Start at Chapter 1 and read straight through to Chapter 6. Each chapter builds directly on the last — decoding, then storage, then execution, then control flow, then integration, then verification — so by the end you'll have watched a CPU assemble itself piece by piece, the same way a textbook would walk you through it, except every claim is backed by real, runnable Verilog instead of a diagram.
- **"I already know RISC-V and just want to see how this codebase implements it."** Skim the [Repository Structure](#-repository-structure) below, then jump directly to [`CPU_top.md`](./Documentation/CPU_top.md) and [`Datapath.md`](./Documentation/Datapath.md) — those two describe the full integration and will point you back to any submodule chapter you need for details.
- **"I just want to see it run and understand what it computes."** Skip straight to Chapter 8, [`ALGORITHMS.md`](./Documentation/ALGORITHMS.md), which needs no Verilog background at all, then follow the [Running the Simulation](#-running-the-simulation) steps below to watch it execute yourself.

---

## 📂 Repository Structure

```
RISC-V-SINGLE-CYCLE-CORE-/
├── README.md                    ← you are here
├── Master Constraint.pdf        ← Basys-3 FPGA pin constraints
│
├── ── RTL Source (Verilog) ──
├── Instruction_Decoder.v
├── MainDSecoder.v                (Main Control Decoder)
├── ALUDecoder.v
├── Imm_Gen.v
├── Register_Set.v
├── Instruction_Memory.v
├── Data_Memory.v
├── ALU.v
├── SrcA_MUX.v
├── ALU_MUX.v
├── WriteBack_MUX.v
├── PC.v
├── PC_Plus_4.v
├── PC_Target.v
├── PC_Mux.v
├── PC_Top.v
├── IF_top.v
├── ID_EX_MEM_WB_top.v
├── CPU_top.v
├── CPU_top_tb.v                  (simulation testbench)
├── CPU_Display_Top.v             (FPGA demo wrapper)
├── SevenSeg_Display.v
│
└── Documentation/
    ├── ALGORITHMS.md
    ├── ALU.md
    ├── ALUDecoder.md
    ├── ALU_MUX.md
    ├── CPU_Display_Top.md
    ├── CPU_top.md
    ├── CPU_top_tb.md
    ├── Data_Memory.md
    ├── Datapath.md
    ├── IF_top.md
    ├── Imm_Gen.md
    ├── Instruction_Decoder.md
    ├── Instruction_Memory.md
    ├── MainDecoder.md
    ├── PC.md
    ├── PC_MUX.md
    ├── PC_Plus_4.md
    ├── PC_Target.md
    ├── PC_Top.md
    ├── Register_Set.md
    ├── SevenSeg_Display.md
    ├── SrcA_MUX.md
    └── WriteBack_MUX.md
```

---

## ✨ What This Core Can Do

- Implements a working subset of the **RV32I base integer ISA**: R-type, I-type, S-type, B-type, U-type (`LUI`/`AUIPC`), and both jump forms (`JAL`/`JALR`).
- Runs entirely **single-cycle** — every instruction fetches, decodes, executes, accesses memory, and writes back within one clock period.
- Ships with **8 hand-written, hand-traced demo programs** covering signed arithmetic, loops, counting, a software multiply, the Euclidean GCD algorithm, 32-bit-overflow-bounded Fibonacci, and two sorting algorithms — see [`ALGORITHMS.md`](./Documentation/ALGORITHMS.md) for the full breakdown of each.
- Includes a **self-checking simulation testbench** (`CPU_top_tb.v`) with automatic PASS/FAIL verdicts for every program.
- Includes a **real FPGA demo path** for the Digilent Basys-3 board, with switch-selectable program values shown live on the 7-segment display.

### Instruction Set Support
| Format | Example Instructions | Handled By |
|---|---|---|
| R-type | `ADD`, `SUB`, `AND`, `OR`, `XOR`, `SLT`, `SLTU`, `SLL`, `SRL`, `SRA` | [ALU.md](./Documentation/ALU.md), [ALUDecoder.md](./Documentation/ALUDecoder.md) |
| I-type | `ADDI`, `ANDI`, `ORI`, `XORI`, `SLTI`, `SLTIU`, `SLLI`, `SRLI`, `SRAI`, `LW`, `JALR` | [Imm_Gen.md](./Documentation/Imm_Gen.md), [MainDecoder.md](./Documentation/MainDecoder.md) |
| S-type | `SW` | [Data_Memory.md](./Documentation/Data_Memory.md) |
| B-type | `BEQ`, `BNE`, `BLT`, `BGE`, `BLTU`, `BGEU` | [CPU_top.md](./Documentation/CPU_top.md) (branch condition decoder) |
| U-type | `LUI`, `AUIPC` | [SrcA_MUX.md](./Documentation/SrcA_MUX.md), [Imm_Gen.md](./Documentation/Imm_Gen.md) |
| J-type | `JAL` | [PC_MUX.md](./Documentation/PC_MUX.md), [PC_Target.md](./Documentation/PC_Target.md) |

### Why Single-Cycle?
A single-cycle design is the classic starting point for learning processor architecture, and this core leans into that intentionally. Every instruction — no matter how simple (`ADDI`) or how involved (`JALR`) — completes fetch, decode, execute, memory access, and writeback within **one** clock period. There are no pipeline registers, no hazards to forward around, and no branch prediction to reason about, which means every signal in the datapath can be understood by asking "what value does this wire carry *this cycle*?" rather than tracking state across multiple overlapping instructions.

The tradeoff, of course, is clock speed: because every instruction must ripple all the way through the ALU, memory, and writeback logic before the next clock edge, the clock period is bounded by the *slowest* instruction (typically a load or store), even though most instructions (like register-to-register ALU ops) could safely run much faster on their own. Real-world CPUs solve this with pipelining, out-of-order execution, and branch prediction — but those techniques only make sense once the single-cycle model is second nature, which is exactly what this repository is designed to teach. If you're comparing this core against a pipelined design elsewhere, that's the fundamental difference to keep in mind: this one trades raw throughput for a datapath that's fully traceable, cycle by cycle, with nothing hidden.

---

## 🧭 Documentation Index 

### Chapter 1 — Instruction Decoding
The logic that looks at a raw 32-bit instruction word and figures out *what it means* and *what the datapath should do about it*.

| Chapter | File | What it covers |
|---|---|---|
| 1.1 | [Instruction_Decoder.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/Instruction_Decoder.md) | Slices the raw instruction into `opcode`, `rd`, `funct3`, `rs1`, `rs2`, `funct7` |
| 1.2 | [MainDecoder.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/MainDecoder.md) | Opcode → all top-level control signals (`RegWrite`, `ImmSrc`, `ALUSrc`, `Branch`, `Jump`, etc.) |
| 1.3 | [ALUDecoder.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/ALUDecoder.md) | `ALUop` + `funct3`/`funct7` → the precise 4-bit `ALUControl` code |
| 1.4 | [Imm_Gen.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/Imm_Gen.md) | Reconstructs the correctly sign-extended immediate for all 5 RISC-V formats |

### Chapter 2 — Storage Elements
Where the CPU keeps its state: registers, program instructions, and data.

> 🖼️ **[INSERT IMAGE HERE — Register File (32×32-bit) Block Diagram]**

> 🖼️ **[INSERT IMAGE HERE — Instruction Memory & Data Memory Layout Diagram]**

| Chapter | File | What it covers |
|---|---|---|
| 2.1 | [Register_Set.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/Register_Set.md) | The 32×32-bit register file — dual combinational read, single clocked write, `x0` hardwired to zero |
| 2.2 | [Instruction_Memory.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/Instruction_Memory.md) | The program ROM, asynchronous read, and the full 8-program test suite |
| 2.3 | [Data_Memory.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/Data_Memory.md) | The 256-word data RAM, its pre-loaded test arrays, and its addressing scheme |

### Chapter 3 — Execution Unit
Where the actual computing happens.

| Chapter | File | What it covers |
|---|---|---|
| 3.1 | [ALU.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/ALU.md) | The full arithmetic/logic/shift/compare unit — every `con` code explained |
| 3.2 | [SrcA_MUX.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/SrcA_MUX.md) | Selects ALU operand A: `rs1` normally, or `PC` for `AUIPC` |
| 3.3 | [ALU_MUX.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/ALU_MUX.md) | Selects ALU operand B: `rs2` or the decoded immediate |
| 3.4 | [WriteBack_MUX.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/WriteBack_MUX.md) | Selects what gets written back to the register file: ALU result, memory data, or `PC+4` |

### Chapter 4 — Program Counter Subsystem
How the CPU decides which instruction to fetch next — sequential, branch/JAL, or JALR.

> 🖼️ **[INSERT IMAGE HERE — PC Subsystem / Next-PC Selection Diagram]**

| Chapter | File | What it covers |
|---|---|---|
| 4.1 | [PC.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/PC.md) | The clocked program counter register itself |
| 4.2 | [PC_Plus_4.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/PC_Plus_4.md) | Computes the default sequential next address (`PC + 4`) |
| 4.3 | [PC_Target.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/PC_Target.md) | Computes the PC-relative branch/JAL target (`PC + Imm`) |
| 4.4 | [PC_MUX.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/PC_MUX.md) | The 3:1 mux that picks the next PC — and the JAL/JALR bug fix that made this a 3-way (not 2-way) decision |
| 4.5 | [PC_Top.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/PC_Top.md) | The structural wrapper tying 4.1–4.4 together into one PC subsystem |

### Chapter 5 — Stage Integration
Where the individual pieces above get wired into full pipeline **stages** (still single-cycle — no pipeline registers, just logical grouping).

> 🖼️ **[INSERT IMAGE HERE — Full Datapath Diagram: IF → ID → EX → MEM → WB, all buses labeled]**

| Chapter | File | What it covers |
|---|---|---|
| 5.1 | [IF_top.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/IF_top.md) | The Instruction Fetch stage — pairs the PC subsystem with instruction memory |
| 5.2 | [Datapath.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/Datapath.md) | The Decode → Execute → Memory → Writeback core — decoders, register file, ALU, data memory, and writeback all wired together |
| 5.3 | [CPU_top.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/CPU_top.md) | The top-level module — joins fetch + core, and hosts the branch-condition decoder and final `pc_sel` logic |

### Chapter 6 — Verification
How we prove the CPU actually works.

| Chapter | File | What it covers |
|---|---|---|
| 6.1 | [CPU_top_tb.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/CPU_top_tb.md) | The testbench — cycle monitor, per-program PASS/FAIL checks, and the exact `iverilog` build command |

### Chapter 7 — FPGA Deployment
Taking the core off the simulator and onto real silicon (Basys-3).

> 🖼️ **[INSERT IMAGE HERE — Basys-3 Board Photo / Switch & 7-Segment Layout Diagram]**

| Chapter | File | What it covers |
|---|---|---|
| 7.1 | [CPU_Display_Top.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/CPU_Display_Top.md) | The synthesizable top module — clock-enable (not gated-clock) speed control, switch decoding, and the `CPU_Tapped`/`IF_top_CE` clock-enabled CPU variant |
| 7.2 | [SevenSeg_Display.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/SevenSeg_Display.md) | The general-purpose 4-digit 7-segment scanning/hex-decoding driver |

Pin assignments for the board (clock, switches, segments, anodes) live in **`Master Constraint.pdf`** at the repo root.

### Chapter 8 — Algorithms & Test Programs
*Prefer to start here?* This chapter needs no Verilog background — it's a plain-English, classroom-friendly walkthrough of all 8 demo programs, cross-verified line-by-line against the real machine code and the real testbench pass conditions.

| Chapter | File | What it covers |
|---|---|---|
| 8.1 | [ALGORITHMS.md](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-/blob/main/Documentation/ALGORITHMS.md) | ALU + negatives, array sum, count negatives, factorial, GCD, Fibonacci (32-bit overflow), bubble sort, insertion sort — pseudocode, register maps, hand-traced walkthroughs, and exact memory addresses/cycle counts for each |

---

## 🚀 Running the Simulation

1. In [`Instruction_Memory.v`](./Instruction_Memory.v), uncomment **exactly one** `PART` block (the demo program you want to run).
2. In [`CPU_top_tb.v`](./CPU_top_tb.v), uncomment the **matching** `PART` block (its checker).
3. Compile and run with Icarus Verilog:
   ```bash
   iverilog -o sim ALU.v ALUDecoder.v ALU_MUX.v SrcA_MUX.v \
     CPU_top.v CPU_top_tb.v Data_Memory.v ID_EX_MEM_WB_top.v \
     IF_top.v Imm_Gen.v Instruction_Decoder.v \
     Instruction_Memory.v MainDSecoder.v PC.v PC_Mux.v \
     PC_Plus_4.v PC_Target.v PC_Top.v Register_Set.v \
     WriteBack_MUX.v && vvp sim
   ```
4. Watch the console for a `>>> PASS <<<` or `>>> FAIL <<<` banner, and optionally open the generated `cpu_top.vcd` in GTKWave for a full waveform trace.

Full details on what each program checks and why: [`CPU_top_tb.md`](./Documentation/CPU_top_tb.md).

## 🔌 Running on FPGA (Basys-3)

1. Set `` `define PROGRAM_ID `` at the top of [`CPU_Display_Top.v`](./CPU_Display_Top.v) to match whichever `PART` is active in `Instruction_Memory.v`.
2. Synthesize with `CPU_Display_Top` as the top module, using the pin constraints in `Master Constraint.pdf`.
3. Program the bitstream, then use the on-board switches to control reset, speed, and which value is shown.

Full switch map and per-program display details: [`CPU_Display_Top.md`](./Documentation/CPU_Display_Top.md).

---

## 🧩 Quick Reference — The 8 Demo Programs

| # | Program | Result | Details |
|---|---|---|---|
| 1 | ALU + Negative Numbers | 15 register results, all verified | [ALGORITHMS.md §1](./Documentation/ALGORITHMS.md) |
| 2 | Array Sum (loop) | `x10 = 97` | [ALGORITHMS.md §2](./Documentation/ALGORITHMS.md) |
| 3 | Count Negatives | `x10 = 4` | [ALGORITHMS.md §3](./Documentation/ALGORITHMS.md) |
| 4 | Factorial (5! via shift-add multiply) | `x10 = 120` | [ALGORITHMS.md §4](./Documentation/ALGORITHMS.md) |
| 5 | GCD (Euclidean algorithm) | `x10 = 6` | [ALGORITHMS.md §5](./Documentation/ALGORITHMS.md) |
| 6 | Fibonacci (32-bit, overflow-bounded) | `x24 = 2,971,215,073` | [ALGORITHMS.md §6](./Documentation/ALGORITHMS.md) |
| 7 | Bubble Sort (signed) | `mem[0..4] = {-5,-3,-1,8,12}` | [ALGORITHMS.md §7](./Documentation/ALGORITHMS.md) |
| 8 | Insertion Sort (signed) | `mem[0..4] = {-5,-3,-1,8,12}` | [ALGORITHMS.md §8](./Documentation/ALGORITHMS.md) |

---

## 🛠️ Notable Design Fixes Along the Way
This core evolved through several rounds of bug-fixing that are worth knowing about if you're reading the source history — each is documented in full in its module's chapter:

- **`AUIPC` computing `rs1 + imm` instead of `PC + imm`** — fixed by adding `SrcA_MUX` ([details](./Documentation/SrcA_MUX.md)).
- **`LUI`/`AUIPC` immediates silently computing as zero** — fixed by expanding `ImmSrc` from 2 bits to 3 bits to add U-type support ([details](./Documentation/Imm_Gen.md), [details](./Documentation/MainDecoder.md)).
- **`JAL`/`JALR` not actually redirecting the PC** — fixed by expanding the PC mux from a single `branch` bit to a 2-bit `pc_sel` ([details](./Documentation/PC_MUX.md), [details](./Documentation/CPU_top.md)).
- **`JAL`/`JALR` link address hardwired to `0`** — fixed by forwarding the real `PC+4` into the writeback mux ([details](./Documentation/WriteBack_MUX.md)).
- **Branch targets off by 4 bytes** — fixed by making instruction memory read asynchronously instead of on the clock edge ([details](./Documentation/Instruction_Memory.md), [details](./Documentation/IF_top.md)).

---

## 📌 Notes for Maintainers
- `Instruction_Memory.v` and `CPU_top_tb.v` must always have the **same** `PART` uncommented — they are not automatically synchronized.
- `CPU_Display_Top.v`'s `` `PROGRAM_ID `` macro must match that same `PART` for the FPGA display to show meaningful values.
- Image placeholders throughout this README are marked `INSERT IMAGE HERE` — search for that phrase to find every spot still waiting on a diagram or board photo.

---

## 📄 License
*(Add your chosen license here — MIT, Apache 2.0, GPL, etc.)*

## 🙌 Author
**Soumya Dev Nayak** — [RISC-V-SINGLE-CYCLE-CORE-](https://github.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE-)
