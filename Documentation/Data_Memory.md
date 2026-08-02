# `Data_Memory.v` — Data Memory (RAM)

## Overview
The **Data Memory** module models the data-storage (RAM) portion of the single-cycle RISC-V core's memory system. It supports word-aligned **synchronous writes** and **asynchronous (combinational) reads**, and is pre-loaded at simulation start with four labeled test arrays that back the load/store-based test programs in `Instruction_Memory.v` (array sum, count negatives, bubble sort, insertion sort).

---

## Module Interface

### Parameters
| Parameter | Default | Description |
|-----------|---------|--------------|
| `N` | 32 | Data word width in bits |
| `DEPTH` | 256 | Number of memory words |

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `clk` | 1 | Clock — drives synchronous writes |
| `rst` | 1 | Reset (present in interface; memory contents are set once via `initial`, not reset here) |
| `MemWrite` | 1 | Write enable |
| `MemRead` | 1 | Read enable |
| `addr` | 32 | Byte address (from ALU result) |
| `write_data` | 32 | Data to store (typically `rs2`) |

### Output
| Signal | Width | Description |
|--------|-------|--------------|
| `read_data` | 32 | Data read from memory, or `0` if `MemRead` is deasserted |

### Internal
| Signal | Description |
|--------|--------------|
| `mem [0:DEPTH-1]` | The memory array — `DEPTH` words of `N` bits |

---

## Addressing Scheme
Like `Instruction_Memory.v`, this module is addressed **byte-wise** by the core (matching RISC-V's byte-addressed memory model) but stores data **word-indexed** internally:

```verilog
mem[addr[9:2]]
```

- Bits `[1:0]` of `addr` are dropped (assumed `00` — word-aligned accesses only; this design does not support byte/halfword loads/stores at the memory-array level).
- Bits `[9:2]` (8 bits) index the 256-word array, giving a valid byte-address range of **0–1023**.

---

## Key Design Notes

### Asynchronous Read, Synchronous Write
This mirrors the same reasoning as `Instruction_Memory.v`'s combinational-read fix:
- **Read** (`always @(*)`) is purely combinational — in a single-cycle design, a `lw` instruction must produce `read_data` within the *same* clock cycle it is fetched and decoded, since there is no pipeline register to hold the address across cycles.
- **Write** (`always @(posedge clk)`) is properly synchronous — this is correct and necessary, since a write must commit at a clean clock edge to avoid write-during-read race conditions and to give the rest of the combinational datapath (which may depend on old memory contents) a stable value throughout the cycle.

### Read Defaults to Zero When Disabled
When `MemRead` is low, `read_data` is explicitly driven to `32'b0` rather than left floating/latched. This keeps the block fully combinational (no inferred latch) and ensures the writeback mux (`WriteBack_MUX.v`) sees a defined value even on non-load instructions.

### No Reset Logic on Memory Contents
`rst` is declared in the port list but is **not** used to clear or reload `mem` — memory contents are established once via the `initial` block at simulation start (synthesis tools/FPGA flows would instead rely on a memory initialization file or `$readmemh`). This is expected for a simulation/teaching-oriented design where memory is treated as pre-loaded ROM-like test data rather than something reset mid-run.

---

## Pre-Loaded Data Layout

| Word Range | Byte Range | Contents | Purpose |
|---|---|---|---|
| `0–4` | `0–16` | `{-5, 12, -3, 8, -1}` (signed) | Bubble Sort / Insertion Sort input (sorts to `{-5,-3,-1,8,12}`) |
| `5–9` | `20–36` | `{10, 25, 7, 40, 15}` | Legacy/compatibility array (older branchless test programs) |
| `10–17` | `40–68` | `{-5,12,-3,8,-1,20,-7,4}` (8-element, mixed sign) | Count Negatives (expects 4 negatives) |
| `20–24` | `80–96` | `{10, 25, 7, 40, 15}` | Array Sum (expects sum = 97) |
| `25–255` | `100–1023` | `0` | Scratch / output area |

Negative values are stored in **two's-complement hex** form directly (e.g. `-5` as `32'hFFFFFFFB`), which is the correct bit pattern the ALU and branch comparators (`BLT`/`BGE`, signed) expect.

---

## Relationship to Other Modules
- **`ALU.v`** — computes the effective byte `addr` for loads/stores (`rs1 + immediate`).
- **`MainDecoder.v`** — generates `MemWrite`/`MemRead`(via `ResultSrc`) control signals based on opcode (loads/stores).
- **`Register_Set.v`** — supplies `write_data` (from `rs2`) for stores.
- **`WriteBack_MUX.v`** — selects `read_data` as the value written back to the register file for load instructions (`ResultSrc = 2'b01`).
- **`Instruction_Memory.v`** — the paired program ROM whose test programs (Array Sum, Count Negatives, Bubble Sort, Insertion Sort) directly operate on the arrays pre-loaded here.
