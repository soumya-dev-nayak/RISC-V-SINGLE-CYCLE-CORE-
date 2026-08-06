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

## Part 1: ALU Test with Negative Numbers

### Description

This program verifies the functionality of the RISC-V ALU using both positive and negative operands. It tests arithmetic, logical, comparison, and shift instructions.

### Expected Results

| Register | Operation | Expected Value |
|----------|-----------|---------------:|
| `x3` | `add(x1, x2)` | `-5` |
| `x4` | `sub(x2, x1)` | `35` |
| `x5` | `sub(x1, x2)` | `-35` |
| `x6` | `and(x1, x2)` | `12` |
| `x7` | `or(x1, x2)` | `-17` |
| `x8` | `xor(x1, x2)` | `-29` |
| `x9` | `slt(x1, x2)` | `1` |
| `x10` | `slt(x2, x1)` | `0` |
| `x11` | `sltu(x1, x2)` | `0` |
| `x12` | `srai(x1, 2)` | `-5` |
| `x13` | `slli(x2, 3)` | `120` |
| `x16` | `add(x14, x15)` | `-63` |
| `x17` | `slt(x14, x16)` | `1` |

### Testbench Verification

- `x3 == -5`
- `x9 == 1`
- `x12 == -5`
- `x13 == 120`
- `x17 == 1`

### Instruction Memory Program

```verilog
Imem[0]  = 32'hFEC00093; // addi  x1, x0, -20
Imem[1]  = 32'h00F00113; // addi  x2, x0,  15
Imem[2]  = 32'h002081B3; // add   x3, x1,  x2    ; -5
Imem[3]  = 32'h40110233; // sub   x4, x2,  x1    ; 35
Imem[4]  = 32'h402082B3; // sub   x5, x1,  x2    ; -35
Imem[5]  = 32'h0020F333; // and   x6, x1,  x2    ; 12
Imem[6]  = 32'h0020E3B3; // or    x7, x1,  x2    ; -17
Imem[7]  = 32'h0020C433; // xor   x8, x1,  x2    ; -29
Imem[8]  = 32'h0020A4B3; // slt   x9, x1,  x2    ; 1
Imem[9]  = 32'h00112533; // slt   x10,x2,  x1    ; 0
Imem[10] = 32'h0020B5B3; // sltu  x11,x1,  x2    ; 0
Imem[11] = 32'h4020D613; // srai  x12,x1,  2     ; -5
Imem[12] = 32'h00311693; // slli  x13,x2,  3     ; 120
Imem[13] = 32'hF9C00713; // addi  x14,x0, -100
Imem[14] = 32'h02500793; // addi  x15,x0,  37
Imem[15] = 32'h00F70833; // add   x16,x14, x15   ; -63
Imem[16] = 32'h010728B3; // slt   x17,x14, x16   ; 1
Imem[17] = 32'h0000006F; // jal   x0, 0          ; HALT
```
### Simulation Output

```text
[cyc   3] PC=0x00000000  instr=0xfec00093  x5=0 x6=0 x8=0 x10=0
[cyc   4] PC=0x00000004  instr=0x00f00113  x5=0 x6=0 x8=0 x10=0
[cyc   5] PC=0x00000008  instr=0x002081b3  x5=0 x6=0 x8=0 x10=0
[cyc   6] PC=0x0000000c  instr=0x40110233  x5=0 x6=0 x8=0 x10=0
[cyc   7] PC=0x00000010  instr=0x402082b3  x5=0 x6=0 x8=0 x10=0
[cyc   8] PC=0x00000014  instr=0x0020f333  x5=-35 x6=0 x8=0 x10=0
[cyc   9] PC=0x00000018  instr=0x0020e3b3  x5=-35 x6=12 x8=0 x10=0
[cyc  10] PC=0x0000001c  instr=0x0020c433  x5=-35 x6=12 x8=0 x10=0
[cyc  11] PC=0x00000020  instr=0x0020a4b3  x5=-35 x6=12 x8=-29 x10=0
[cyc  12] PC=0x00000024  instr=0x00112533  x5=-35 x6=12 x8=-29 x10=0
[cyc  13] PC=0x00000028  instr=0x0020b5b3  x5=-35 x6=12 x8=-29 x10=0
[cyc  14] PC=0x0000002c  instr=0x4020d613  x5=-35 x6=12 x8=-29 x10=0
[cyc  15] PC=0x00000030  instr=0x00311693  x5=-35 x6=12 x8=-29 x10=0
[cyc  16] PC=0x00000034  instr=0xf9c00713  x5=-35 x6=12 x8=-29 x10=0
[cyc  17] PC=0x00000038  instr=0x02500793  x5=-35 x6=12 x8=-29 x10=0
[cyc  18] PC=0x0000003c  instr=0x00f70833  x5=-35 x6=12 x8=-29 x10=0
[cyc  19] PC=0x00000040  instr=0x010728b3  x5=-35 x6=12 x8=-29 x10=0
[cyc  20] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  21] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  22] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  23] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  24] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  25] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  26] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
[cyc  27] PC=0x00000044  instr=0x0000006f  x5=-35 x6=12 x8=-29 x10=0
```

### Verification Results

```text
================================================
  PART 1 : ALU + NEGATIVE NUMBERS TEST
  x1=-20, x2=15
================================================
  x3  =   -5  (expect    -5) [add  x1+x2]
  x4  =   35  (expect    35) [sub  x2-x1]
  x5  =  -35  (expect   -35) [sub  x1-x2]
  x6  =   12  (expect    12) [and  x1&x2]
  x7  =  -17  (expect   -17) [or   x1|x2]
  x8  =  -29  (expect   -29) [xor  x1^x2]
  x9  =    1  (expect     1) [slt  x1<x2]
  x10 =    0  (expect     0) [slt  x2<x1]
  x11 =    0  (expect     0) [sltu x1<x2 unsigned]
  x12 =   -5  (expect    -5) [srai x1>>2]
  x13 =  120  (expect   120) [slli x2<<3]
  x16 =  -63  (expect   -63) [add  -100+37]
  x17 =    1  (expect     1) [slt  -100<-63]
------------------------------------------------
  >>> PASS <<<
================================================
```
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-1%20ALU%20Operations%20op.png" width="1200">
</p>

<p align="center">
  <em>Figure: PART 1 – ALU Operations Test Output</em><br>
  <em>Simulation results verifying arithmetic, logical, comparison, and shift operations using positive and negative operands.</em>
</p>

## Part 2: Array Sum Using a Loop

### Description

This program computes the sum of an array stored in Data Memory using a loop implemented with the `jal` instruction. The processor iterates through all array elements, accumulates the sum, and stores the final result in register `x10`.

### Array Contents

| Index | Value |
|------:|------:|
| 0 | 10 |
| 1 | 25 |
| 2 | 7 |
| 3 | 40 |
| 4 | 15 |

### Expected Results

| Register | Description | Expected Value |
|----------|-------------|---------------:|
| `x10` | Sum of all array elements | `97` |
| `x11` | Loop counter (`i`) | `5` |
| `x6` | Number of elements (`N`) | `5` |

### Simulation Output

```text
VCD info: dumpfile cpu_top.vcd opened for output.

[cyc   3] PC=0x00000000  instr=0x05000293  x5=0 x6=0 x8=0 x10=0
[cyc   4] PC=0x00000004  instr=0x00500313  x5=80 x6=0 x8=0 x10=0
...
[cyc  38] PC=0x00000028  instr=0x0000006f  x5=100 x6=5 x8=0 x10=97
...
[cyc  62] PC=0x00000028  instr=0x0000006f  x5=100 x6=5 x8=0 x10=97
```

### Verification Results

```text
================================================
  PART 2 : ARRAY SUM  (loop using JAL)
  Array = {10, 25, 7, 40, 15}
================================================
  x10 = 97  (sum, expect 97)
  x11 = 5   (i,   expect  5)
  x6  = 5   (N,   expect  5)
------------------------------------------------
  >>> PASS: sum = 97 <<<
================================================
```
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-2%20Array%20Sum.png" width="1300">
</p>

<p align="center">
  <em>Figure: PART 2 – Array Sum Using a Loop</em><br>
  <em>Simulation results verifying array traversal, accumulation, loop control using <code>jal</code>, and the final sum of 97 stored in register <code>x10</code>.</em>
</p>

## Part 3: Count Negative Numbers in an Array

### Description

This program traverses an array stored in Data Memory and counts the number of negative elements. The final count is accumulated in register `x10` using a loop controlled by the `jal` instruction.

### Array Contents

| Index | Value |
|------:|------:|
| 0 | -5 |
| 1 | 12 |
| 2 | -3 |
| 3 | 8 |
| 4 | -1 |
| 5 | 20 |
| 6 | -7 |
| 7 | 4 |

### Expected Results

| Register | Description | Expected Value |
|----------|-------------|---------------:|
| `x10` | Number of negative elements | `4` |
| `x11` | Loop counter (`i`) | `8` |

### Simulation Output

```text
VCD info: dumpfile cpu_top.vcd opened for output.

[cyc   3] PC=0x00000000  instr=0x02800293  x5=0 x6=0 x8=0 x10=0
[cyc   4] PC=0x00000004  instr=0x00800313  x5=40 x6=0 x8=0 x10=0
...
[cyc  60] PC=0x0000002c  instr=0x0000006f  x5=72 x6=8 x8=0 x10=4
...
[cyc  82] PC=0x0000002c  instr=0x0000006f  x5=72 x6=8 x8=0 x10=4
```

### Verification Results

```text
================================================
  PART 3 : COUNT NEGATIVES IN ARRAY
  Array = {-5,12,-3,8,-1,20,-7,4}
================================================
  x10 = 4  (count, expect 4)
  x11 = 8  (i,     expect 8)
------------------------------------------------
  >>> PASS: count = 4 <<<
================================================
```

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-3%20COUNT%20NEGATIVES.png" width="1100">
</p>

<p align="center">
  <em>Figure: PART 3 – Count Negative Numbers in an Array</em><br>
  <em>Simulation results verifying array traversal, signed comparison, loop execution, and the correct count of negative elements (<code>x10 = 4</code>).</em>
</p>

## Part 4: Factorial Using a Loop

### Description

This program computes the factorial of `5` using iterative multiplication. A loop controlled by the `jal` instruction repeatedly multiplies the accumulated result until the counter exceeds the input value. The final factorial is stored in register `x10`.

### Expected Results

| Register | Description | Expected Value |
|----------|-------------|---------------:|
| `x10` | Factorial of `5` | `120` |
| `x6` | Loop Counter | `6` |

### Simulation Output

```text
VCD info: dumpfile cpu_top.vcd opened for output.

[cyc   3] PC=0x00000000  instr=0x00100513  x5=0 x6=0 x8=0 x10=0
[cyc   4] PC=0x00000004  instr=0x00200313  x5=0 x6=0 x8=0 x10=1
...
[cyc 103] PC=0x00000040  instr=0xfcdff06f  x5=0 x6=6 x8=0 x10=120
...
[cyc 152] PC=0x00000044  instr=0x0000006f  x5=0 x6=6 x8=0 x10=120
```

### Verification Results

```text
================================================
  PART 4 : FACTORIAL
  Input = 5
================================================
  x10 = 120  (expect 120)
  x6  =   6  (loop counter)
------------------------------------------------
  >>> PASS: 5! = 120 <<<
================================================
```
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-4%20Factorial%20op1.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 4 – Factorial Computation</em><br>
  <em>Simulation results showing the execution of the factorial algorithm using nested loops, conditional branches, arithmetic operations, and <code>jal</code>-based control flow. The processor correctly computes <code>5! = 120</code> and stores the result in <code>x10</code>.</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-4%20Factorial%20op2.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 4 – Factorial Computation</em><br>
  <em>Final simulation output confirming successful completion of the factorial program. Register values verify the expected result (<code>x10 = 120</code>), demonstrating correct implementation of iterative multiplication, loop execution, and program termination.</em>
</p>

## Part 5: Greatest Common Divisor (GCD) Using Euclidean Algorithm

### Description

This program computes the **Greatest Common Divisor (GCD)** of two positive integers using the **Euclidean subtraction algorithm**. The algorithm repeatedly subtracts the smaller value from the larger until both values become equal. The final GCD is stored in register `x10`.

### Input Values

| Register | Value |
|---------:|------:|
| `x5` (`a`) | `48` |
| `x6` (`b`) | `18` |

### Expected Results

| Register | Description | Expected Value |
|----------|-------------|---------------:|
| `x5` | Final value of `a` | `6` |
| `x6` | Final value of `b` | `6` |
| `x10` | GCD Result | `6` |

### Simulation Output

```text
VCD info: dumpfile cpu_top.vcd opened for output.

[cyc   3] PC=0x00000000  instr=0x03000293  x5=0  x6=0  x8=0 x10=0
[cyc   4] PC=0x00000004  instr=0x01200313  x5=48 x6=0  x8=0 x10=0
...
[cyc  33] PC=0x00000020  instr=0x00028513  x5=6  x6=6  x8=0 x10=0
[cyc  34] PC=0x00000024  instr=0x0000006f  x5=6  x6=6  x8=0 x10=6
...
[cyc  62] PC=0x00000024  instr=0x0000006f  x5=6  x6=6  x8=0 x10=6
```

### Verification Results

```text
================================================
  PART 5 : GCD(48, 18) = 6  [Euclidean]
================================================
  x5  = 6  (a at halt, expect 6)
  x6  = 6  (b at halt, expect 6)
  x10 = 6  (result,    expect 6)
------------------------------------------------
  >>> PASS: GCD = 6 <<<
================================================
```
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-5%20GCD.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 5 – Greatest Common Divisor (GCD)</em><br>
  <em>Simulation results verifying the Euclidean algorithm using conditional branches, subtraction, and <code>jal</code> instructions. The processor correctly computes <code>GCD(48, 18) = 6</code>.</em>
</p>

# Part 6: 32-bit Fibonacci Sequence Generation
## Execution Trace - Complete Fibonacci Sequence

| Iter | Cycle | PC | Instruction | x22 (F(n-1)) | x23 (F(n)) | x24 (F(n+1)) | Status |
|-----:|------:|----------|----------|-------------:|-------------:|-------------:|--------|
| 1 | 6 | 0x00000008 | 0x017b0c33 | 0 | 1 | 1 | Running |
| 2 | 10 | 0x00000008 | 0x017b0c33 | 1 | 1 | 2 | Running |
| 3 | 16 | 0x00000008 | 0x017b0c33 | 1 | 2 | 3 | Running |
| 4 | 20 | 0x00000008 | 0x017b0c33 | 2 | 3 | 5 | Running |
| 5 | 26 | 0x00000008 | 0x017b0c33 | 3 | 5 | 8 | Running |
| 6 | 30 | 0x00000008 | 0x017b0c33 | 5 | 8 | 13 | Running |
| 7 | 36 | 0x00000008 | 0x017b0c33 | 8 | 13 | 21 | Running |
| 8 | 40 | 0x00000008 | 0x017b0c33 | 13 | 21 | 34 | Running |
| 9 | 46 | 0x00000008 | 0x017b0c33 | 21 | 34 | 55 | Running |
| 10 | 50 | 0x00000008 | 0x017b0c33 | 34 | 55 | 89 | Running |
| 11 | 56 | 0x00000008 | 0x017b0c33 | 55 | 89 | 144 | Running |
| 12 | 60 | 0x00000008 | 0x017b0c33 | 89 | 144 | 233 | Running |
| 13 | 66 | 0x00000008 | 0x017b0c33 | 144 | 233 | 377 | Running |
| 14 | 70 | 0x00000008 | 0x017b0c33 | 233 | 377 | 610 | Running |
| 15 | 76 | 0x00000008 | 0x017b0c33 | 377 | 610 | 987 | Running |
| 16 | 80 | 0x00000008 | 0x017b0c33 | 610 | 987 | 1597 | Running |
| 17 | 86 | 0x00000008 | 0x017b0c33 | 987 | 1597 | 2584 | Running |
| 18 | 90 | 0x00000008 | 0x017b0c33 | 1597 | 2584 | 4181 | Running |
| 19 | 96 | 0x00000008 | 0x017b0c33 | 2584 | 4181 | 6765 | Running |
| 20 | 100 | 0x00000008 | 0x017b0c33 | 4181 | 6765 | 10946 | Running |
| 21 | 106 | 0x00000008 | 0x017b0c33 | 6765 | 10946 | 17711 | Running |
| 22 | 110 | 0x00000008 | 0x017b0c33 | 10946 | 17711 | 28657 | Running |
| 23 | 116 | 0x00000008 | 0x017b0c33 | 17711 | 28657 | 46368 | Running |
| 24 | 120 | 0x00000008 | 0x017b0c33 | 28657 | 46368 | 75025 | Running |
| 25 | 126 | 0x00000008 | 0x017b0c33 | 46368 | 75025 | 121393 | Running |
| 26 | 130 | 0x00000008 | 0x017b0c33 | 75025 | 121393 | 196418 | Running |
| 27 | 136 | 0x00000008 | 0x017b0c33 | 121393 | 196418 | 317811 | Running |
| 28 | 140 | 0x00000008 | 0x017b0c33 | 196418 | 317811 | 514229 | Running |
| 29 | 146 | 0x00000008 | 0x017b0c33 | 317811 | 514229 | 832040 | Running |
| 30 | 150 | 0x00000008 | 0x017b0c33 | 514229 | 832040 | 1346269 | Running |
| 31 | 156 | 0x00000008 | 0x017b0c33 | 832040 | 1346269 | 2178309 | Running |
| 32 | 160 | 0x00000008 | 0x017b0c33 | 1346269 | 2178309 | 3524578 | Running |
| 33 | 166 | 0x00000008 | 0x017b0c33 | 2178309 | 3524578 | 5702887 | Running |
| 34 | 170 | 0x00000008 | 0x017b0c33 | 3524578 | 5702887 | 9227465 | Running |
| 35 | 176 | 0x00000008 | 0x017b0c33 | 5702887 | 9227465 | 14930352 | Running |
| 36 | 180 | 0x00000008 | 0x017b0c33 | 9227465 | 14930352 | 24157817 | Running |
| 37 | 186 | 0x00000008 | 0x017b0c33 | 14930352 | 24157817 | 39088169 | Running |
| 38 | 190 | 0x00000008 | 0x017b0c33 | 24157817 | 39088169 | 63245986 | Running |
| 39 | 196 | 0x00000008 | 0x017b0c33 | 39088169 | 63245986 | 102334155 | Running |
| 40 | 200 | 0x00000008 | 0x017b0c33 | 63245986 | 102334155 | 165580141 | Running |
| 41 | 206 | 0x00000008 | 0x017b0c33 | 102334155 | 165580141 | 267914296 | Running |
| 42 | 210 | 0x00000008 | 0x017b0c33 | 165580141 | 267914296 | 433494437 | Running |
| 43 | 216 | 0x00000008 | 0x017b0c33 | 267914296 | 433494437 | 701408733 | Running |
| 44 | 220 | 0x00000008 | 0x017b0c33 | 433494437 | 701408733 | 1134903170 | Running |
| 45 | 226 | 0x00000008 | 0x017b0c33 | 701408733 | 1134903170 | 1836311903 | Running |
| 46 | 230 | 0x00000008 | 0x017b0c33 | 1134903170 | 1836311903 | 2971215073 | Running |
| 47 | 236 | 0x00000008 | 0x017b0c33 | 1836311903 | 2971215073 | 512559680 | Overflow |
| 48 | 238 | 0x0000001c | 0x000b8c13 | 1836311903 | 2971215073 | 2971215073 | **Exit** |

## Fibonacci Sequence Analysis

| Index | Fibonacci Value | Decimal | Hex | Binary | Status | Notes |
|------:|----------------:|-----------|----------|---------|--------|-------|
| F1 | 1 | `1` | `0x00000001` | `00000000000000000000000000000001` | Valid | First term |
| F2 | 1 | `1` | `0x00000001` | `00000000000000000000000000000001` | Valid | Second term |
| F3 | 2 | `2` | `0x00000002` | `00000000000000000000000000000010` | Valid | 1+1 |
| F5 | 5 | `5` | `0x00000005` | `00000000000000000000000000000101` | Valid | |
| F10 | 55 | `55` | `0x00000037` | `00000000000000000000000000110111` | Valid | |
| F15 | 610 | `610` | `0x00000262` | `00000000000000000000001001100010` | Valid | |
| F20 | 10946 | `10946` | `0x00002AA2` | `00000000000000101010101010100010` | Valid | |
| F25 | 121393 | `121393` | `0x0001D9F1` | `00000000000111011001111111110001` | Valid | |
| F30 | 1346269 | `1346269` | `0x0014882D` | `00000000010100100010000010101101` | Valid | |
| F35 | 14930352 | `14930352` | `0x00E3D5D0` | `00001110001111010101110110110000` | Valid | |
| F40 | 165580141 | `165580141` | `0x0A000D5D` | `00001010000000000000110101011101` | Valid | |
| F43 | 701408733 | `701408733` | `0x29E4A57D` | `00101001111001001010010101111101` | Valid | |
| F45 | 1134903170 | `1134903170` | `0x438A6D42` | `01000011100010100110110101000010` | Valid | |
| **F46** | **1836311903** | **`1836311903`** | **`0x6D59264F`** | **`01101101010110010010011001001111`** | **Valid** | **2nd Largest** |
| **F47** | **2971215073** | **`2971215073`** | **`0xB1164977`** | **`10110001000101100100100101110111`** | **Valid** | **🏆 Largest 32-bit** |
| F48 | 4807526976 | `4807526976` | `0x11E771F0` | `00010001111001110111000111110000` | **Overflow** | **Exceeds uint32** |

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-6%20FIBONACI%20op1.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 6 – 32-bit Fibonacci Sequence Generation (Execution Trace)</em><br>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-6%20FIBONACI%20op2.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 6 – 32-bit Fibonacci Sequence Verification</em><br>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-6%20FIBONACI%20op3.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 6 – Timing Diagram for overflow-controlled termination of the Fibonacci algorithm</em><br>
</p>

## PART 7: Bubble Sort (Signed Integers)

### Simulation Output

```text
VCD info: dumpfile cpu_top.vcd opened for output.

================================================
  PART 7 : BUBBLE SORT  (signed)
  Input:  mem[0..4] = {-5, 12, -3, 8, -1}
  Sorting ascending using signed BLT comparison...
  [cyc####] PC=0xXXXX  instr=0xXXXXXXXX  x5=N-1  x6=i  x8=j  x10=arr[j]
================================================
  [cyc   3] PC=0x00000000  instr=0x00400293  x5=0 x6=0 x8=0 x10=0
  [cyc   4] PC=0x00000004  instr=0x00000313  x5=4 x6=0 x8=0 x10=0
  [cyc   5] PC=0x00000008  instr=0x00400e13  x5=4 x6=0 x8=0 x10=0
  ...
  [cyc 300] PC=0x00000054  instr=0x0000006f  x5=4 x6=4 x8=1 x10=-5
  [cyc 301] PC=0x00000054  instr=0x0000006f  x5=4 x6=4 x8=1 x10=-5
  [cyc 302] PC=0x00000054  instr=0x0000006f  x5=4 x6=4 x8=1 x10=-5

================================================
  RESULT  (Data Memory after sort):
  mem[0] =   -5  (expect -5)
  mem[1] =   -3  (expect -3)
  mem[2] =   -1  (expect -1)
  mem[3] =    8  (expect  8)
  mem[4] =   12  (expect 12)
  Total cycles executed: 302
------------------------------------------------
  >>> PASS: Array sorted correctly {-5,-3,-1,8,12} <<<
================================================
```

### Result

| Parameter | Value |
|-----------|-------|
| **Input Array** | `{-5, 12, -3, 8, -1}` |
| **Sorted Array** | `{-5, -3, -1, 8, 12}` |
| **Total Cycles** | `302` |

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-7%20BUBBLE%20SORT%20op1.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 7 – Bubble Sort Execution and Successful Array Sorting Process op1</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-7%20BUBBLE%20SORT%20op2.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 7 – Bubble Sort Execution and Successful Array Sorting Process op2</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-7%20BUBBLE%20SORT%20op3.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 7 – Bubble Sort Execution and Successful Array Sorting Process op3</em>
</p>

## PART 8 : INSERTION SORT (SIGNED)

### Console Output

```text
VCD info: dumpfile cpu_top.vcd opened for output.

================================================
  PART 8 : INSERTION SORT  (signed)
  Input:  mem[0..4] = {-5, 12, -3, 8, -1}
  [cyc####] PC=0xXXXX  instr=0xXXXXXXXX  x5=i  x6=j  x8=curr  x10=N
================================================
  [cyc   3] PC=0x00000000  instr=0x00100293  x5=0 x6=0 x8=0 x10=0
  [cyc   4] PC=0x00000004  instr=0x00500513  x5=1 x6=0 x8=0 x10=0
  [cyc   5] PC=0x00000008  instr=0x00400e13  x5=1 x6=0 x8=0 x10=5
  [cyc   6] PC=0x0000000c  instr=0x04a2d063  x5=1 x6=0 x8=0 x10=5
  [cyc   7] PC=0x00000010  instr=0x00229593  x5=1 x6=0 x8=0 x10=5
  [cyc   8] PC=0x00000014  instr=0x0005a383  x5=1 x6=0 x8=0 x10=5
  [cyc   9] PC=0x00000018  instr=0xfff28313  x5=1 x6=0 x8=0 x10=5
  [cyc  10] PC=0x0000001c  instr=0x00231493  x5=1 x6=0 x8=0 x10=5
  [cyc  11] PC=0x00000020  instr=0x00034663  x5=1 x6=0 x8=0 x10=5
  [cyc  12] PC=0x00000024  instr=0x0004a403  x5=1 x6=0 x8=0 x10=5
  [cyc  13] PC=0x00000028  instr=0x0083ca63  x5=1 x6=0 x8=-5 x10=5
  [cyc  14] PC=0x0000002c  instr=0x00448493  x5=1 x6=0 x8=-5 x10=5
  [cyc  15] PC=0x00000030  instr=0x0074a023  x5=1 x6=0 x8=-5 x10=5
  [cyc  16] PC=0x00000034  instr=0x00128293  x5=1 x6=0 x8=-5 x10=5
  [cyc  17] PC=0x00000038  instr=0xfd5ff06f  x5=2 x6=0 x8=-5 x10=5
  [cyc  18] PC=0x0000000c  instr=0x04a2d063  x5=2 x6=0 x8=-5 x10=5
  [cyc  19] PC=0x00000010  instr=0x00229593  x5=2 x6=0 x8=-5 x10=5
  [cyc  20] PC=0x00000014  instr=0x0005a383  x5=2 x6=0 x8=-5 x10=5
  [cyc  21] PC=0x00000018  instr=0xfff28313  x5=2 x6=0 x8=-5 x10=5
  [cyc  22] PC=0x0000001c  instr=0x00231493  x5=2 x6=1 x8=-5 x10=5
  ...

================================================
  RESULT  (Data Memory after sort):
  mem[0] =   -5  (expect -5)
  mem[1] =   -3  (expect -3)
  mem[2] =   -1  (expect -1)
  mem[3] =    8  (expect  8)
  mem[4] =   12  (expect 12)
  Total cycles executed: 202
------------------------------------------------
  >>> PASS: Array sorted correctly {-5,-3,-1,8,12} <<<
================================================
```
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-8%20INSERTION%20SORT%20op2.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 8 – GTKWave timing diagram showing insertion sort execution op1.</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-8%20INSERTION%20SORT%20op3.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 8 – GTKWave timing diagram showing insertion sort execution op2.</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/pics/PART-8%20INSERTION%20SORT%20op1.png" width="1350">
</p>

<p align="center">
  <em>Figure: PART 8 – Final sorted data memory after successful Insertion Sort execution.</em>
</p>

---

## Basys-3 FPGA Hardware Demonstration

To validate the design beyond simulation, the complete RISC-V Single-Cycle Core was synthesized, implemented, and deployed on the Digilent Basys-3 FPGA. The following hardware demonstration confirms the successful execution of the signed Insertion Sort program on the physical FPGA, verifying correct instruction execution, data memory updates, control logic, and overall processor functionality in real hardware.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/Basys-3_Testing/Basys-3%20Board%20Initialisation.jpeg" width="700">
</p>

<p align="center">
  <em>Figure: Digilent Basys-3 FPGA board initialized with the RISC-V Single-Cycle Core design.</em>
</p>

## 🎥 Basys-3 FPGA Hardware Demonstration


<p align="center">
  <a href="https://youtu.be/5Xu6RuB6tUI">
    <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/Basys-3_Testing/Basys-3%20Board%20Initialisation.jpeg" width="820">
  </a>
</p>

<p align="center">
Real-time execution of the custom Single-Cycle RISC-V processor on the Basys-3 FPGA,
showcasing instruction fetch, decode, execution, register updates, and Fibonacci program execution.
</p>

<p align="center">
  <a href="https://youtu.be/5Xu6RuB6tUI">
    <img src="https://img.shields.io/badge/▶%20Watch%20on%20YouTube-FF0000?style=for-the-badge&logo=youtube&logoColor=white">
  </a>
</p>


<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/CORE_TEST/Basys-3_Testing/Basys-3%20Fibonacci%20Implementation(max%20range).jpeg" width="800">
</p>

<p align="center">
  <em>Figure: Basys-3 FPGA demonstrating real-time execution of the RISC-V core running the Fibonacci program.</em>
</p>

