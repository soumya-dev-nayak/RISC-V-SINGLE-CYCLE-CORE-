# CORE_TEST

This directory contains all the testbenches, simulation files, waveforms, and result images used to verify the functionality of the RISC-V Single-Cycle and Multicycle Processor implementations.

The purpose of this section is to provide a structured verification flow for each hardware module and the complete processor. Every test includes the corresponding source files, simulation setup, expected behavior, and waveform or output screenshots to demonstrate correct operation.

## Contents

- **Testbench Files** – Verilog testbenches for individual modules and complete processor verification.
- **Simulation Files** – Supporting files required to run simulations.
- **Waveforms** – Simulation waveform screenshots generated during verification.
- **Output Images** – Terminal outputs and simulation result images.
- **Documentation** – Brief explanation of each test case, expected functionality, and observed results.

Each test case is organized in its own directory with all the necessary files, making it easy to reproduce the simulation results.

#### This section demonstrates the implementation and verification of various RISC-V programs through their corresponding hardware modules.

### Test Program Overview

| Part | Program | Expected Result | Approx. Cycles |
|------|----------|-----------------|---------------:|
| 1 | ALU + Negative Numbers | Registers Verification | ~18 |
| 2 | Array Sum (Loop) | `x10 = 97` | ~36 |
| 3 | Count Negatives | `x10 = 4` | ~58 |
| 4 | Factorial (`5! = 120`) | `x10 = 120` | ~103 |
| 5 | GCD (`48, 18`) | `x10 = 6` | ~32 |
| 6 | Fibonacci (`<= 9999`) | `x24 = 6765` | ~103 |
| 7 | Bubble Sort (Signed Array) | `mem[0..4]` Sorted | ~111 |
| 8 | Insertion Sort (Signed Array) | `mem[0..4]` Sorted | ~81 |

### Data Memory Layout

| Word Address | Byte Address | Contents | Purpose |
|--------------|--------------|----------|---------|
| `0..4` | `0..16` | `{-5, 12, -3, 8, -1}` | Signed sort array |
| `5..9` | `20..36` | `{10, 25, 7, 40, 15}` | Positive array |
| `10..17` | `40..68` | 8-element mixed array | Count negatives |
| `20..24` | `80..96` | `{10, 25, 7, 40, 15}` | Array sum |
