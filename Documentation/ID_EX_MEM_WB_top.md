# `ID_EX_MEM_WB_top.v` — Decode / Execute / Memory / Writeback Core Datapath

## Overview
`ID_EX_MEM_WB_top` is the **second major top-level block** of the single-cycle CPU (paired with `IF_top.v`, the fetch stage). It wires together everything downstream of instruction fetch: **decoding** the instruction and reading registers, **executing** on the ALU, accessing **data memory**, and selecting the **writeback** value — all within a single clock cycle, since this is a single-cycle (not pipelined) design despite the "ID/EX/MEM/WB" naming (the name reflects the classic RISC *stages of work*, not actual pipeline registers).

This module also exposes several signals back to `CPU_top.v` that are needed purely for **next-PC selection** — `Branch_out`/`zero_out` (conditional branch outcome), and `jump_jal`/`jump_jalr`/`jalr_target` (unconditional jump target selection).

---

## Module Interface

### Parameter
| Parameter | Default | Description |
|-----------|---------|--------------|
| `N` | 32 | Data width in bits |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | Clock |
| `rst` | 1 | Reset |
| `instr` | 32 | Instruction fetched by `IF_top` |
| `PC` | 32 | Current PC value — **new** addition, needed for AUIPC (`SrcA`) and the JAL/JALR link address (`PC+4`) |

### Outputs
| Signal | Width | Description |
|--------|-------|--------------|
| `ALU_result` | 32 | ALU output (also doubles as the memory address and the JALR target) |
| `read_data` | 32 | Data read from `Data_Memory` |
| `write_data` | 32 | Final value written back to the register file |
| `Branch_out` | 1 | Passthrough of the `Branch` control signal |
| `zero_out` | 1 | Passthrough of the ALU `zero` flag (branch condition outcome) |
| `Imm_out` | 32 | Passthrough of the generated immediate (used for branch/JAL target calc in `IF_top`) |
| `funct3_out` | 3 | Passthrough of `funct3` (branch-type discrimination, e.g. `beq` vs `blt`) |
| `jump_jal` | 1 | High when the current instruction is JAL |
| `jump_jalr` | 1 | High when the current instruction is JALR |
| `jalr_target` | 32 | The computed JALR target (`rs1 + imm`, i.e. `ALU_result`) |

---

## Internal Structure & Data Flow

```
instr ──► Instruction_Decoder ──► opcode, rd, rs1, rs2, funct3, funct7
              │
              ▼
           MainDecoder ──► RegWrite, ImmSrc, ALUSrc, ALUSrcA, MemWrite,
                            ResultSrc, Branch, ALUop, Jump, JalrSel
              │
   ┌──────────┼─────────────────────────────┐
   ▼          ▼                             ▼
Register_Set  Imm_Gen(instr,ImmSrc)     ALUDecoder(ALUop,funct3,funct7)
(rs1,rs2,rd)       │                          │
   │               │                          ▼
   │          SrcA_MUX(rs1_data,PC,ALUSrcA)  ALUControl
   │               │  ALU_MUX(rs2_data,imm,ALUSrc)
   │               ▼        ▼
   │              ALU(SrcA, SrcB, ALUControl) ──► ALU_result, zero
   │                        │
   │                        ▼
   │                  Data_Memory(addr=ALU_result, write_data=rs2_data)
   │                        │
   │                        ▼
   │                 WriteBack_MUX(ALU_result, read_data, PC+4, ResultSrc)
   │                        │
   └────────────────────────┴──► write_data ──► Register_Set.rd_data
```

### Stage Breakdown

**ID (Instruction Decode)**
- `Instruction_Decoder` splits `instr` into `opcode`/`rd`/`funct3`/`rs1`/`rs2`/`funct7`.
- `MainDecoder` turns `opcode` into all high-level control signals.
- `Register_Set` reads `rs1_data`/`rs2_data` from the register file (and, at the end of the cycle, writes `write_data` back to `rd`).
- `Imm_Gen` reconstructs the sign-extended immediate from `instr` using `ImmSrc`.

**EX (Execute)**
- `ALUDecoder` refines `ALUop` (plus `funct3`/`funct7`) into the precise `ALUControl` code.
- `SrcA_MUX` selects ALU operand A: `rs1_data` normally, or `PC` for AUIPC.
- `ALU_MUX` selects ALU operand B: `rs2_data` normally, or `imm` when `ALUSrc` is set.
- `ALU` computes `ALU_result` and the `zero` flag (used for branch condition evaluation).

**MEM (Memory Access)**
- `Data_Memory` is addressed by `ALU_result` (the computed effective address for loads/stores), written with `rs2_data` when `MemWrite` is set, and read whenever `ResultSrc == 2'b01` (i.e., the current instruction is a load).

**WB (Writeback)**
- `PC_plus4 = PC + 4` is computed locally as the real link address.
- `WriteBack_MUX` picks between `ALU_result`, `read_data`, and `PC_plus4` based on `ResultSrc`, producing the final `write_data` fed back into `Register_Set`.

---

## Key Design Notes

### `PC` as a New Input — Two Reasons It Was Needed
1. **AUIPC** requires `PC + upper-immediate`. Since the ALU is the only adder in the datapath, `PC` must reach it as an operand — via `SrcA_MUX`, gated by `ALUSrcA`.
2. **JAL/JALR link address** (`PC+4`) needs the *actual* current PC of the instruction being executed, not a hardcoded placeholder.

### Real `PC+4` Forwarding — Bug Fix
The header comment explicitly notes this was previously **hardwired to `32'b0`**. That means any JAL/JALR instruction would have written `0` into its destination register instead of the correct return address — a **silent correctness bug** that would only surface if the program actually tried to use the link register (e.g. implementing a function call/return convention). The fix computes `PC_plus4 = PC + 32'd4` locally in this module and forwards it into `WriteBack_MUX`.

### `SrcA_MUX` and `ALUSrcA` — Also a Bug Fix
As documented in `SrcA_MUX.v`, ALU operand A was previously hardwired to `rs1_data` unconditionally. This module now instantiates `SrcA_MUX`, gated by the `ALUSrcA` control bit generated by `MainDecoder`, allowing AUIPC to correctly use `PC` instead of `rs1` as its ALU input.

### `jump_jal` / `jump_jalr` Split
Rather than exposing the raw `Jump` and `JalrSel` signals separately and making `CPU_top.v` recompute their combination, this module does the decomposition itself:
```verilog
assign jump_jal  = Jump & ~JalrSel;  // JAL:  target = PC + Imm  (computed in IF stage)
assign jump_jalr = Jump &  JalrSel;  // JALR: target = ALU_result (computed here)
```
This gives the PC-selection mux in `IF_top.v`/`PC_Top.v` two clean, mutually exclusive signals to drive `pc_sel`, without needing to re-derive jump-type logic in multiple places.

### `jalr_target = ALU_result`
Since JALR's target address (`rs1 + I-type imm`) is *exactly* what the ALU already computes as `ALU_result` for this instruction, no separate adder is needed — the same ALU output is reused both as the "result" (irrelevant for JALR, since `ResultSrc` selects `PC+4` instead) and as the forwarded jump target for the fetch stage.

### `ImmSrc` Now 3 Bits
Reflects the corresponding widening in `MainDecoder.v` and `Imm_Gen.v` to support the U-type immediate format required by LUI/AUIPC.

### Data Memory Expanded to 256 Words
`Data_Memory` (`DEPTH=256`) provides enough address space (1024 bytes) for the multi-array test programs in `Instruction_Memory.v` (array sum, count negatives, sorting), which use byte offsets up to ~96 plus scratch space.

---

## Relationship to Other Modules
This module is essentially the **integration point** for the majority of the core's combinational logic and the register file/data memory state elements. It directly instantiates:
- `Instruction_Decoder.v`
- `MainDecoder.v`
- `Register_Set.v`
- `Imm_Gen.v`
- `ALUDecoder.v`
- `SrcA_MUX.v`
- `ALU_MUX.v`
- `ALU.v`
- `Data_Memory.v`
- `WriteBack_MUX.v`

And it is itself instantiated by:
- **`CPU_top.v`** — the overall top-level module, which pairs this block with `IF_top.v` and wires `Branch_out`/`zero_out`/`Imm_out`/`funct3_out`/`jump_jal`/`jump_jalr`/`jalr_target` into the PC-selection logic that determines `pc_sel` for the next fetch.
