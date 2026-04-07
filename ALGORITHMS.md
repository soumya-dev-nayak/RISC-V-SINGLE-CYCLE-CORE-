# RISC-V CPU — Algorithm Explanations
### For Classroom Presentation (Teachers & Students)

---

## How to Use This Document
Each program has four sections:
1. **What it does** — one sentence, plain English
2. **Step-by-step algorithm** — pseudocode anyone can follow
3. **Register map** — which CPU register holds which value
4. **Example walkthrough** — trace through real numbers

---

---

# PART 1 — ALU Operations + Negative Numbers

## What it does
Tests every arithmetic and logic operation of the CPU, including **negative numbers**, to prove the hardware computes correctly.

## Key Concept — Two's Complement
Computers store negative numbers using **Two's Complement**:
- Positive 20 → stored as `0x00000014`
- Negative −20 → stored as `0xFFFFFFEC` (flip bits, add 1)
- Adding them: `0x00000014 + 0xFFFFFFEC = 0x00000000` = 0 ✓

## Register Map
| Register | Value | Meaning |
|---|---|---|
| x1 | −20 | First operand (negative) |
| x2 | 15 | Second operand (positive) |
| x3 | −5 | ADD result (−20 + 15) |
| x4 | 35 | SUB result (15 − (−20)) |
| x5 | −35 | SUB result (−20 − 15) |
| x6 | 12 | AND result (bitwise) |
| x7 | −17 | OR result (bitwise) |
| x8 | −29 | XOR result (bitwise) |
| x9 | 1 | SLT: is (−20 < 15)? Yes → 1 |
| x10 | 0 | SLT: is (15 < −20)? No → 0 |
| x12 | −5 | SRAI: −20 >> 2 (arithmetic right shift) |
| x13 | 120 | SLLI: 15 << 3 = 15 × 8 |

## Algorithm (Pseudocode)
```
x1 ← −20
x2 ← 15
x3 ← x1 + x2          // ADD    = −5
x4 ← x2 − x1          // SUB    = 35
x5 ← x1 − x2          // SUB    = −35
x6 ← x1 AND x2        // AND    = 12
x7 ← x1 OR  x2        // OR     = −17
x8 ← x1 XOR x2        // XOR    = −29
x9 ← (x1 < x2) ? 1:0  // SLT    = 1  (signed)
x12← x1 >> 2           // SRAI   = −5 (sign bit preserved)
x13← x2 << 3           // SLLI   = 120
x14← −100
x15← 37
x16← x14 + x15         // ADD    = −63
x17← (x14 < x16)? 1:0 // SLT    = 1  (−100 < −63)
HALT
```

## Why Arithmetic Right Shift Matters
- Logical shift (SRL): fills with **0s** → −20 >> 2 = 1073741819 (wrong for negatives)
- Arithmetic shift (SRA/SRAI): fills with **sign bit** → −20 >> 2 = −5 ✓

---

---

# PART 2 — Array Sum (Loop)

## What it does
Adds up all 5 numbers in an array stored in memory and puts the total in a register.

## Register Map
| Register | Role |
|---|---|
| x5 | Pointer — current memory address |
| x6 | N = 5 (number of elements) |
| x10 | Accumulator (running sum) |
| x11 | Loop counter i |
| x12 | Current array element |

## Algorithm (Pseudocode)
```
ptr  ← address_of_array    // x5 = 80 (byte address)
N    ← 5                   // x6
sum  ← 0                   // x10
i    ← 0                   // x11

LOOP:
  if i >= N: goto DONE
  current ← Memory[ptr]    // load one word (4 bytes)
  sum     ← sum + current
  ptr     ← ptr + 4        // advance to next element
  i       ← i + 1
  goto LOOP

DONE:
  result is in sum (x10)
HALT
```

## Step-by-Step with Real Numbers
Array = {10, 25, 7, 40, 15}

| Iteration | i | ptr | current | sum |
|---|---|---|---|---|
| Start | 0 | 80 | — | 0 |
| 1 | 0 | 80 | 10 | 10 |
| 2 | 1 | 84 | 25 | 35 |
| 3 | 2 | 88 | 7 | 42 |
| 4 | 3 | 92 | 40 | 82 |
| 5 | 4 | 96 | 15 | **97** |
| Exit | 5 | 100 | — | **97** ✓ |

**Key instruction: `jal x0, −20`** — unconditional jump back to LOOP.

---

---

# PART 3 — Count Negative Numbers

## What it does
Scans an array of 8 numbers and counts how many are negative (less than zero).

## Register Map
| Register | Role |
|---|---|
| x5 | Pointer to current element |
| x6 | N = 8 |
| x10 | Count of negatives |
| x11 | Loop counter i |
| x12 | Current element (signed) |

## Algorithm (Pseudocode)
```
ptr   ← address_of_array    // x5 = 40
N     ← 8                   // x6
count ← 0                   // x10
i     ← 0                   // x11

LOOP:
  if i >= N: goto DONE
  current ← Memory[ptr]
  if current >= 0: goto SKIP    // not negative, skip
  count ← count + 1             // it's negative
SKIP:
  ptr ← ptr + 4
  i   ← i + 1
  goto LOOP

DONE:
  result is in count (x10)
HALT
```

## Step-by-Step with Real Numbers
Array = {−5, 12, −3, 8, −1, 20, −7, 4}

| i | value | negative? | count |
|---|---|---|---|
| 0 | −5 | ✓ Yes | 1 |
| 1 | 12 | ✗ No | 1 |
| 2 | −3 | ✓ Yes | 2 |
| 3 | 8 | ✗ No | 2 |
| 4 | −1 | ✓ Yes | 3 |
| 5 | 20 | ✗ No | 3 |
| 6 | −7 | ✓ Yes | **4** |
| 7 | 4 | ✗ No | **4** |

**Key instruction: `bge x12, x0, SKIP`** — branch if element ≥ 0 (skip counting).

---

---

# PART 4 — Factorial (5! = 120)

## What it does
Computes 5! = 1 × 2 × 3 × 4 × 5 = 120, using a **shift-and-add multiply** because RV32I has no MUL instruction.

## Key Concept — Shift-and-Add Multiplication
To multiply A × B without a multiply instruction:
- Look at each **bit** of B from lowest to highest
- If bit is 1: add current A to product
- Shift A left by 1 (= multiply A by 2)
- Shift B right by 1 (move to next bit)

Example: 6 × 5 (binary 6=110, 5=101)
- bit0 of 5=1 → product += 6 → product=6; A=12, B=2
- bit0 of 2=0 → skip;         A=24, B=1
- bit0 of 1=1 → product += 24 → product=30 ✓

## Register Map (Outer Loop)
| Register | Role |
|---|---|
| x10 | Running factorial result (starts 1) |
| x6 | i (multiplier: 2, 3, 4, 5) |
| x7 | Limit = 6 (stop when i reaches 6) |

## Register Map (Inner Multiply Loop)
| Register | Role |
|---|---|
| x20 | Product accumulator (starts 0) |
| x21 | a (current shifted copy of x10) |
| x22 | b (bit-scan copy of x6, decrements) |
| x23 | Scratch: current bit of b |

## Algorithm (Pseudocode)
```
result ← 1       // x10
i      ← 2       // x6
limit  ← 6       // x7

OUTER:
  if i >= 6: goto DONE
  // --- multiply result × i → result ---
  product ← 0           // x20
  a       ← result      // x21
  b       ← i           // x22
  INNER:
    if b == 0: goto STORE
    bit ← b AND 1        // check lowest bit
    if bit == 0: goto SHIFT
    product ← product + a  // add a if bit is set
  SHIFT:
    a ← a << 1          // double a
    b ← b >> 1          // move to next bit
    goto INNER
  STORE:
    result ← product    // x10 = result × i
  i ← i + 1
  goto OUTER

DONE: x10 = 120
HALT
```

## Trace of Factorial Steps
| Outer i | Operation | result before | result after |
|---|---|---|---|
| 2 | result × 2 | 1 | 2 |
| 3 | result × 3 | 2 | 6 |
| 4 | result × 4 | 6 | 24 |
| 5 | result × 5 | 24 | **120** |

---

---

# PART 5 — GCD (Greatest Common Divisor)

## What it does
Finds the largest number that divides evenly into both 48 and 18, using the **Euclidean algorithm**.

## Key Concept — Euclidean Algorithm
If a > b: replace a with (a − b)
If b > a: replace b with (b − a)
When a == b: that value is the GCD.

## Register Map
| Register | Role |
|---|---|
| x5 | a (starts 48, converges to GCD) |
| x6 | b (starts 18, converges to GCD) |
| x10 | Result (= x5 = x6 at exit) |

## Algorithm (Pseudocode)
```
a ← 48     // x5
b ← 18     // x6

LOOP:
  if a == b: goto DONE     // GCD found
  if a < b:  b ← b − a    // reduce b
  else:      a ← a − b    // reduce a
  goto LOOP

DONE:
  x10 ← a      // = b (they are equal now)
HALT
```

## Step-by-Step Trace
| Step | a | b | Action |
|---|---|---|---|
| Start | 48 | 18 | — |
| 1 | 30 | 18 | a=48−18 |
| 2 | 12 | 18 | a=30−18 |
| 3 | 12 | 6 | b=18−12 |
| 4 | 6 | 6 | a=12−6 |
| **Exit** | **6** | **6** | a==b → GCD = **6** ✓ |

**Proof:** 48 ÷ 6 = 8 ✓, 18 ÷ 6 = 3 ✓

---

---

# PART 6 — Fibonacci Sequence (Full 32-Bit Range)

## What it does
Computes Fibonacci numbers (each = sum of previous two) until the next number would overflow a 32-bit register, then stops. Produces the largest Fibonacci number that fits in a 32-bit register.

## Key Concept — Fibonacci Sequence
F(0)=0, F(1)=1, F(n) = F(n−1) + F(n−2)
Sequence: 0, 1, 1, 2, 3, 5, 8, 13, 21, 34, 55, 89, 144, ...

## Key Concept — Overflow Detection
A 32-bit unsigned register holds at most 2³² − 1 = 4,294,967,295.
When two large numbers are added and the result **wraps around**, the result is **smaller** than one of the inputs.

Example:
- F(47) = 2,971,215,073  ✓ fits in 32 bits
- F(48) = 4,807,526,976  > 2³² → wraps to 512,559,680
- 512,559,680 < 1,836,311,903 (x22) → **BLTU detects this** → stop

## Register Map (Sliding Window)
| Register | Role | Changes each iteration |
|---|---|---|
| x22 | F(n−1) — "previous" | x22 ← x23 (slides forward) |
| x23 | F(n) — "current" | x23 ← x24 (slides forward) |
| x24 | F(n+1) — "next" (computed this step) | x24 = x22 + x23 |

## How the Window Slides (Your Question Answered)
```
Start:          x22=0   x23=1   x24=?
Compute next:           x24 = 0+1 = 1
Check overflow: 1 ≥ 0 → no overflow → continue
Slide window:   x22=1   x23=1

Compute next:           x24 = 1+1 = 2
Slide window:   x22=1   x23=2

Compute next:           x24 = 1+2 = 3
Slide window:   x22=2   x23=3

Compute next:           x24 = 2+3 = 5
Slide window:   x22=3   x23=5
...
```
x22 is ALWAYS the older of the two; x23 is ALWAYS the newer.
After 46 iterations: x22=F(46), x23=F(47)=2,971,215,073

## Algorithm (Pseudocode)
```
prev ← 0     // x22 = F(0)
curr ← 1     // x23 = F(1)

LOOP:
  next ← prev + curr      // x24 = new Fibonacci
  if next < prev (unsigned overflow): goto EXIT
  prev ← curr             // slide window: x22 ← x23
  curr ← next             // slide window: x23 ← x24
  goto LOOP

EXIT:
  x24 ← curr              // = F(47) = 2,971,215,073
HALT
```

## $monitor Output (first few lines)
```
[t=20 ns]  x22(prev)=0    x23(curr)=0    x24(next)=0
[t=30 ns]  x22(prev)=0    x23(curr)=1    x24(next)=0
[t=50 ns]  x22(prev)=0    x23(curr)=1    x24(next)=1    ← F(2)
[t=70 ns]  x22(prev)=1    x23(curr)=1    x24(next)=1
[t=90 ns]  x22(prev)=1    x23(curr)=2    x24(next)=2    ← F(3)
[t=110 ns] x22(prev)=1    x23(curr)=2    x24(next)=3    ← F(4)
...
[t=xxx ns] x22=1836311903  x23=2971215073  x24=2971215073  ← FINAL
```

## Result Summary
- **F(47) = 2,971,215,073** — largest Fibonacci fitting in 32 bits
- Runs **46 iterations** (F(0) through F(47))
- Stops automatically by hardware overflow detection

---

---

# PART 7 — Bubble Sort (Signed Array, Ascending)

## What it does
Sorts the array {−5, 12, −3, 8, −1} into ascending order {−5, −3, −1, 8, 12} by repeatedly comparing adjacent elements and swapping them if they are in the wrong order.

## Key Concept — Bubble Sort
Imagine bubbles rising in water — larger numbers "bubble up" to the end of the array with each pass.

**Pass 1 of {−5, 12, −3, 8, −1}:**
- Compare −5 and 12: −5 < 12 → OK, no swap
- Compare 12 and −3: 12 > −3 → **swap** → {−5, −3, 12, 8, −1}
- Compare 12 and 8:  12 > 8  → **swap** → {−5, −3, 8, 12, −1}
- Compare 12 and −1: 12 > −1 → **swap** → {−5, −3, 8, −1, 12}

After pass 1: largest (12) is at the end ✓

## Register Map
| Register | Role | Example value |
|---|---|---|
| x5 | N−1 = 4 (outer limit constant) | 4 |
| x6 | i (outer pass: 0, 1, 2, 3) | 0 |
| x7 | inner_limit = 4−i | 4 |
| x8 | j (inner pair index: 0…inner_limit−1) | 0 |
| x9 | byte_addr = j × 4 (memory address) | 0 |
| x10 | arr[j] (left element) | −5 |
| x11 | arr[j+1] (right element) | 12 |
| x28 | 4 (word byte size, constant) | 4 |

## Algorithm (Pseudocode)
```
N ← 5
for i from 0 to N−2:          // outer pass
    for j from 0 to (N−2−i):  // inner comparisons
        if arr[j] > arr[j+1]:  // signed comparison (BLT)
            swap arr[j] and arr[j+1]

// in-place swap:
// temp  ← arr[j+1]
// arr[j+1] ← arr[j]
// arr[j]   ← temp
// (CPU uses two SW instructions; x10 and x11 already hold values)
```

## Full Sort Trace
| Pass i | Array state |
|---|---|
| Start | {−5, 12, −3, 8, −1} |
| i=0 | {−5, −3, 8, −1, 12} |
| i=1 | {−5, −3, −1, 8, 12} |
| i=2 | {−5, −3, −1, 8, 12} (already sorted) |
| i=3 | {**−5, −3, −1, 8, 12**} ✓ |

## Why Signed Comparison Matters
BLT (Branch Less Than) uses **signed** comparison — so −3 < 8 correctly.
If unsigned comparison (BLTU) was used: −3 = 0xFFFFFFFD > 8 → wrong sort order.

---

---

# PART 8 — Insertion Sort (Signed Array, Ascending)

## What it does
Sorts the same array {−5, 12, −3, 8, −1} into ascending order, but uses a different strategy — picks each element in turn and **inserts it** into the correct position in the already-sorted left portion.

## Key Concept — Insertion Sort
Think of sorting playing cards in your hand:
- Pick up a new card
- Compare it to cards already in hand (right to left)
- Slide each card that is bigger one position right
- Drop the new card in the gap

## Register Map
| Register | Role |
|---|---|
| x5 | i — outer index (1, 2, 3, 4) |
| x6 | j — inner scan index (i−1 down to 0 or stop) |
| x7 | key — arr[i] (the card being inserted) |
| x8 | current — arr[j] (card being compared/shifted) |
| x9 | j_addr — byte address of arr[j] = j × 4 |
| x10 | N = 5 |
| x11 | i_addr — byte address of arr[i] = i × 4 |
| x28 | 4 (word size constant) |

## Algorithm (Pseudocode)
```
for i from 1 to N−1:
    key ← arr[i]           // pick up element
    j   ← i − 1           // start scanning left

    while j >= 0 AND arr[j] > key:
        arr[j+1] ← arr[j] // shift right (make room)
        j ← j − 1

    arr[j+1] ← key        // insert in correct position
```

## Step-by-Step Trace with {−5, 12, −3, 8, −1}

**i=1: key = 12**
- j=0: arr[0]=−5, is −5 > 12? No → stop
- Insert arr[1] = 12 (no change needed)
- Result: {−5, 12, −3, 8, −1}

**i=2: key = −3**
- j=1: arr[1]=12, is 12 > −3? Yes → arr[2]←12; j=0
- j=0: arr[0]=−5, is −5 > −3? No → stop
- Insert arr[1] = −3
- Result: {−5, −3, 12, 8, −1}

**i=3: key = 8**
- j=2: arr[2]=12, is 12 > 8? Yes → arr[3]←12; j=1
- j=1: arr[1]=−3, is −3 > 8? No → stop
- Insert arr[2] = 8
- Result: {−5, −3, 8, 12, −1}

**i=4: key = −1**
- j=3: arr[3]=12, 12>−1? Yes → arr[4]←12; j=2
- j=2: arr[2]=8,   8>−1? Yes → arr[3]←8;  j=1
- j=1: arr[1]=−3, −3>−1? No → stop
- Insert arr[2] = −1
- Result: {**−5, −3, −1, 8, 12**} ✓

## Bubble Sort vs Insertion Sort Comparison
| Property | Bubble Sort (P7) | Insertion Sort (P8) |
|---|---|---|
| Cycles (this array) | ~111 | ~81 |
| Comparisons | Always N²/2 | Fewer if nearly sorted |
| Swaps | Many (2 stores each) | 1 store per shift |
| Best for | Simple to understand | Faster in practice |
| Instructions | 22 | 20 |

---

---

# Summary Table — All 8 Programs

| Part | Program | Input | Output | Key Instruction |
|---|---|---|---|---|
| 1 | ALU + Negatives | x1=−20, x2=15 | 15 register results | SRAI (arithmetic shift) |
| 2 | Array Sum | {10,25,7,40,15} in memory | x10 = 97 | JAL (loop back) |
| 3 | Count Negatives | {−5,12,−3,8,−1,20,−7,4} | x10 = 4 | BGE (skip if ≥ 0) |
| 4 | Factorial | Compute 5! | x10 = 120 | SLLI/SRLI (binary mul) |
| 5 | GCD | a=48, b=18 | x10 = 6 | BEQ (exit when equal) |
| 6 | Fibonacci | Start: 0,1 | x24 = 2,971,215,073 | BLTU (overflow detect) |
| 7 | Bubble Sort | {−5,12,−3,8,−1} | mem = {−5,−3,−1,8,12} | BLT (signed compare) |
| 8 | Insertion Sort | {−5,12,−3,8,−1} | mem = {−5,−3,−1,8,12} | BLT (signed compare) |

---

# Key CPU Concepts Demonstrated

## 1. Signed vs Unsigned Numbers
The same 32-bit pattern `0xFFFFFFFD` means:
- **Signed interpretation:** −3
- **Unsigned interpretation:** 4,294,967,293

Sorting uses **BLT** (signed) so negatives sort correctly before positives.

## 2. Branch Instructions and Loop Control
| Instruction | Meaning | Used in |
|---|---|---|
| `JAL x0, offset` | Unconditional jump (loop back) | Parts 2,3,4,5,6,7,8 |
| `BEQ rs1,rs2,off` | Jump if rs1 == rs2 | Parts 4,5 |
| `BGE rs1,rs2,off` | Jump if rs1 ≥ rs2 (signed) | Parts 2,3,4,7,8 |
| `BLT rs1,rs2,off` | Jump if rs1 < rs2 (signed) | Parts 5,7,8 |
| `BLTU rs1,rs2,off` | Jump if rs1 < rs2 (unsigned) | Part 6 (overflow) |

## 3. Memory Load/Store
- **LW** (Load Word): reads 4 bytes from memory into a register
- **SW** (Store Word): writes a register value to memory
- Address = base_register + immediate_offset
- Sorting programs read AND write memory (in-place sort)

## 4. The Fibonacci Sliding Window (Part 6)
```
Iteration N:   x22 = F(N-1),  x23 = F(N)
  Step 1:  x24 = x22 + x23       (compute F(N+1))
  Step 2:  x22 = x23             (discard F(N-1), keep F(N))
  Step 3:  x23 = x24             (F(N+1) becomes the new current)
Iteration N+1: x22 = F(N),    x23 = F(N+1)
```
The window always holds **two consecutive** Fibonacci numbers.
x22 is always older, x23 is always newer.
x24 is only valid **during** the computation; the final result is copied from x23.
