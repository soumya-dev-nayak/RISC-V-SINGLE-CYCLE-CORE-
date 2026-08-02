# `Imm_Gen.v` — Immediate Generator

## Overview
`Imm_Gen` reconstructs the correctly **sign-extended, 32-bit immediate value** from a raw RISC-V instruction word, based on which of the five RV32I immediate formats applies (I, S, B, J, U). Because each instruction format scatters its immediate bits across different, non-contiguous positions of the 32-bit word (to keep `rs1`/`rs2`/`rd`/`opcode` fields aligned across formats), this module is responsible for re-assembling those bits into a single usable signed value.

This version represents a **fix/expansion** over an earlier design: `ImmSrc` was widened from 2 bits to 3 bits specifically to add **U-type** support, since LUI/AUIPC immediates were previously being silently computed as zero.

---

## Module Interface

### Inputs
| Signal | Width | Description |
|--------|-------|--------------|
| `instr` | 32 bits | The full instruction word |
| `ImmSrc` | 3 bits | Selects which immediate format to decode (from `MainDecoder.v`) |

### Output
| Signal | Width | Description |
|--------|-------|--------------|
| `imm` | 32 bits | The reconstructed, sign-extended immediate |

---

## `ImmSrc` Encoding and Format Reconstruction

| `ImmSrc` | Format | Instructions | Bit Reconstruction |
|:---:|---|---|---|
| `000` | I-type | `addi`, `lw`, `jalr`, `slti`, `andi`, `ori`, `xori`, `slli`, `srli`, `srai` | `{ {20{instr[31]}}, instr[31:20] }` |
| `001` | S-type | `sw`, `sh`, `sb` | `{ {20{instr[31]}}, instr[31:25], instr[11:7] }` |
| `010` | B-type | `beq`, `bne`, `blt`, `bge`, `bltu`, `bgeu` | `{ {19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0 }` |
| `011` | J-type | `jal` | `{ {11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0 }` |
| `100` | U-type | `lui`, `auipc` | `{ instr[31:12], 12'b0 }` |
| (other) | — | — | `imm = 32'b0` (safe default) |

---

## Format Details

### I-Type
The simplest case: bits `[31:20]` of the instruction directly hold a 12-bit immediate, sign-extended from bit 31 up to bit 31 of the result. Straightforward because the immediate occupies one contiguous field.

### S-Type
The 12-bit immediate is **split** across two non-adjacent fields — `instr[31:25]` (upper 7 bits) and `instr[11:7]` (lower 5 bits) — because the lower 5 bits share their instruction-word position with the `rd` field in other formats (keeping `rs1`/`rs2` decode uniform). The generator concatenates them back into a single 12-bit value before sign-extending.

### B-Type
Branch offsets are **always even** (branches target 2-byte-aligned addresses, and in practice word-aligned in this core), so bit 0 of the immediate is always `0` and is **not stored** in the instruction at all — it's synthesized as a literal `1'b0` at the end of the concatenation. The remaining 12 significant bits are scattered as `instr[31]` (sign bit), `instr[7]`, `instr[30:25]`, and `instr[11:8]`, in a scrambled order that maximizes overlap with the S-type field positions (a hardware-design optimization from the RISC-V spec, not arbitrary).

### J-Type
Similarly, JAL's 20-bit offset has its LSB implicitly `0` (not stored) and its remaining bits scattered even more dramatically: `instr[31]` (sign), `instr[19:12]`, `instr[20]`, `instr[30:21]`. This unusual bit order is intentional in the RISC-V ISA — it was chosen so that the J-type and B-type immediate encodings share as many bit positions with the U-type immediate as possible, simplifying hardware sign-extension logic and instruction encoding hardware in general.

### U-Type
The simplest format of all in terms of bit placement: the upper 20 bits of the instruction (`instr[31:12]`) become the upper 20 bits of the result directly, with the lower 12 bits forced to zero — no sign extension is needed since the value is already the full upper portion of a 32-bit word. This directly implements `LUI`'s "load upper immediate" semantics and forms half of `AUIPC`'s `PC + upper-immediate` computation.

---

## Key Design Notes

### Why `ImmSrc` Grew from 2 Bits to 3 Bits
The original design supported only I/S/B/J-type immediates (4 formats → 2-bit select was sufficient). Adding **U-type** support for `LUI`/`AUIPC` required a 5th distinct case, which no longer fits in 2 bits — hence the expansion to 3 bits (`ImmSrc = 3'b100` for U-type), matching the corresponding change in `MainDecoder.v`.

### The Bug This Fixed
Before this expansion, `LUI` and `AUIPC` had no correct `ImmSrc` encoding available to select — they would fall through to whatever the (2-bit) `default` case computed, which was typically `imm = 0`. This means `LUI rd, imm20` would silently write `0` to `rd` instead of the intended upper-immediate value, and `AUIPC` would compute `PC + 0` instead of `PC + upper-immediate` — both **silent** correctness bugs that would only surface when specifically testing those two instructions.

### Latch-Free Default
The `default: imm = 32'b0;` branch ensures every possible `ImmSrc` value (including unused encodings like `3'b101`–`3'b111`) produces a defined output, keeping the block purely combinational with no inferred latches.

---

## Relationship to Other Modules
- **`MainDecoder.v`** — generates `ImmSrc` based on the current instruction's opcode.
- **`Instruction_Decoder.v`** — the raw `instr` this module reads from is the same instruction word decoded elsewhere for `opcode`/`rs1`/`rs2`/`rd`/`funct3`/`funct7`.
- **`ALU_MUX.v`** — consumes this module's `imm` output as one candidate for ALU operand B (selected via `ALUSrc`).
- **`SrcA_MUX.v`** — for AUIPC, this module's `imm` is added to `PC` (via `ALUSrcA`) rather than to `rs1`.
- **`PC_Target.v`** — for branches and JAL, this module's `imm` is added to the current `PC` to compute the branch/jump target.
