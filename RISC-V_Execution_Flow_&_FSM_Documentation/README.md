# Microarchitecture

## Introduction

This section explores how a complete RISC-V microprocessor is constructed by integrating the fundamental digital design concepts discussed in previous chapters. We examine different microarchitecture implementations, each representing a unique trade-off between **performance**, **hardware cost**, and **design complexity**.

At first glance, designing a microprocessor may appear to be a highly complex task. However, once the underlying principles of digital system design are understood, the process becomes much more systematic. By this stage, the essential building blocks required for processor design have already been introduced:

- Design of **combinational logic circuits** based on functional specifications.
- Design of **sequential logic circuits** based on timing requirements.
- Arithmetic circuits such as **adders**, **multipliers**, and **Arithmetic Logic Units (ALUs)**.
- Memory structures for storing instructions and data.
- The **RISC-V Instruction Set Architecture (ISA)**, which defines the programmer's view of the processor through registers, instructions, and memory operations.

## What is Microarchitecture?

Microarchitecture serves as the bridge between digital logic design and computer architecture. It defines the internal organization of hardware components required to implement a given instruction set architecture.

A processor's microarchitecture specifies how different hardware blocks work together to execute instructions. These hardware components typically include:

- Registers
- Arithmetic Logic Unit (**ALU**)
- Finite State Machine (**FSM**)
- Instruction Memory
- Data Memory
- Multiplexers
- Control Logic
- Other datapath components

While the **RISC-V ISA** defines **what** operations a processor must perform, the microarchitecture defines **how** those operations are implemented in hardware.

## Multiple Microarchitectures for the Same ISA

A single instruction set architecture can be implemented using multiple microarchitectures.

For example, several processors may support the same RISC-V instruction set while having completely different internal designs. Although these processors execute the same programs and produce identical results, they differ in terms of:

- Performance
- Hardware resource utilization
- Power consumption
- Design complexity
- Implementation cost

Throughout this documentation, we focus on the microarchitecture of the implemented **RISC-V Single-Cycle Processor**, explaining the datapath, control logic, instruction execution flow, and finite state machine (FSM) operation in detail.

## Architectural State and Instruction Set

A computer architecture is fundamentally defined by two key components:

- **Instruction Set Architecture (ISA)**
- **Architectural State**

For the **RISC-V** processor, the architectural state consists of:

- **Program Counter (`PC`)** – Holds the address of the next instruction to be executed.
- **32 General-Purpose Registers (`x0`–`x31`)** – Each register is **32 bits wide** and stores operands, addresses, or computation results.

Every RISC-V microarchitecture must include this architectural state because it represents the programmer-visible state of the processor. During execution, the processor reads the current architectural state, executes the specified instruction using the required operands, and updates the architectural state accordingly.

In addition to the architectural state, some processor implementations may include **non-architectural state**. These internal hardware elements are not visible to the programmer but are introduced to simplify the hardware design or improve processor performance. Examples include temporary registers, pipeline registers, caches, or other internal control structures.

## Supported Instruction Set

To keep the processor design simple and easy to understand, this implementation focuses on a subset of the **RISC-V RV32I** instruction set. These instructions are sufficient to demonstrate the complete execution flow of a single-cycle processor while supporting meaningful programs.

The implemented instructions are grouped as follows:

### R-Type Instructions

These instructions perform arithmetic and logical operations using two source registers and store the result in a destination register.

| Instruction | Description |
|-------------|-------------|
| `add` | Addition |
| `sub` | Subtraction |
| `and` | Bitwise AND |
| `or` | Bitwise OR |
| `slt` | Set Less Than |

### Memory Instructions

These instructions transfer data between the processor registers and data memory.

| Instruction | Description |
|-------------|-------------|
| `lw` | Load Word |
| `sw` | Store Word |

### Branch Instruction

This instruction changes the program flow based on a comparison between two registers.

| Instruction | Description |
|-------------|-------------|
| `beq` | Branch if Equal |

Although this implementation supports only a subset of the RV32I instruction set, the same datapath and control logic can be extended to implement additional instructions with relatively minor hardware modifications.
## Design Process

To simplify the design of the processor, the microarchitecture is divided into two major components:

- **Datapath**
- **Control Unit**

These two blocks work together to execute every instruction.

### Datapath

The **datapath** is responsible for processing and transferring data throughout the processor. Since this implementation targets the **32-bit RISC-V (RV32I)** architecture, all primary datapath components operate on **32-bit data**.

The datapath consists of several hardware blocks, including:

- Program Counter (`PC`)
- Register File
- Arithmetic Logic Unit (`ALU`)
- Instruction Memory
- Data Memory
- Multiplexers
- Adders
- Immediate Generator
- Other combinational logic required for instruction execution

These components perform arithmetic operations, memory accesses, register reads and writes, and data routing during instruction execution.

### Control Unit

The **Control Unit** determines how the datapath should operate for each instruction.

It receives the current instruction from the datapath, decodes its opcode and function fields, and generates the necessary control signals required to execute that instruction.

Typical control signals generated by the control unit include:

- Multiplexer select signals
- Register write enable (`RegWrite`)
- Memory write enable (`MemWrite`)
- ALU operation control (`ALUControl`)
- ALU source selection (`ALUSrc`)
- Result source selection (`ResultSrc`)
- Branch and jump control signals
- Other datapath control signals

These control signals coordinate the operation of every datapath component during a single clock cycle.

## Processor Design Methodology

A structured approach to processor design is to begin with the hardware blocks that store the processor state. These **state elements** preserve information across clock cycles and form the foundation of the processor.

The primary state elements include:

- Program Counter (`PC`)
- Register File
- Instruction Memory
- Data Memory

Once these state elements are established, **combinational logic** is added between them to compute the next processor state based on the current state and the instruction being executed.

During execution:

1. The **Program Counter (`PC`)** provides the address of the current instruction.
2. The instruction is fetched from **Instruction Memory**.
3. The instruction is decoded by the **Control Unit**.
4. The datapath performs the required arithmetic, logical, branch, or memory operation.
5. The resulting data is written back to the **Register File**, **Data Memory**, or **Program Counter**, depending on the instruction.

## Memory Organization

Although memory can be implemented as a single unified block, it is often more convenient to separate it into two independent memories:

- **Instruction Memory** – Stores program instructions.
- **Data Memory** – Stores application data used by load and store instructions.

This separation allows the processor to fetch an instruction while independently accessing data memory during the same execution cycle, simplifying the datapath design.

## Bus Representation

Throughout this documentation, different line widths are used to represent signals of varying sizes:

| Line Type | Represents |
|-----------|------------|
| **Thick lines** | 32-bit data buses |
| **Medium lines** | Narrow buses (e.g., 5-bit register addresses) |
| **Thin lines** | Single-bit control or data wires |
| **Control lines** | Signals generated by the Control Unit (e.g., `RegWrite`, `MemWrite`) |

For simplicity, reset connections to registers are omitted from the diagrams, although they are typically present in practical hardware implementations.

## Program Counter (PC)

The **Program Counter (`PC`)** holds the address of the current instruction being executed.

Its input, **`PCNext`**, represents the address of the next instruction that will be loaded into the Program Counter on the next clock edge. During every clock cycle, the processor computes `PCNext` based on the current instruction, allowing sequential execution, branching, or jumping to the appropriate instruction address.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-1%20State%20elements%20of%20a%20RISC-V%20processor.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-1 State elements of a RISC-V processor</em>
</p>

## State Elements

The processor is built around four primary state elements:

- Instruction Memory
- Register File
- Data Memory
- Program Counter (`PC`)

These components store the architectural state of the processor and are updated synchronously with the system clock.

### Instruction Memory

The **Instruction Memory** stores the program instructions to be executed by the processor.

It provides a **single read port**, which accepts:

- **`A`** – A 32-bit instruction address input.

Based on this address, the memory outputs:

- **`RD`** – The corresponding 32-bit instruction stored at that address.

Instruction memory is **read-only** during processor execution and is accessed combinationally, allowing the instruction to appear at the output after a small propagation delay whenever the address changes.

### Register File

The **Register File** contains **32 general-purpose registers (`x0`–`x31`)**, each **32 bits wide**.

One special register is:

- **`x0`**, which is permanently hardwired to the constant value **0** and cannot be modified.

The register file provides:

- **Two read ports**
- **One write port**

#### Read Ports

The two read ports use:

- **`A1`** – 5-bit address of the first source register.
- **`A2`** – 5-bit address of the second source register.

Since there are **32 registers**, a **5-bit address (`2⁵ = 32`)** is sufficient to uniquely select any register.

The corresponding register contents are available on:

- **`RD1`** – Data from the register selected by `A1`.
- **`RD2`** – Data from the register selected by `A2`.

#### Write Port

The write port consists of:

- **`A3`** – 5-bit destination register address.
- **`WD3`** – 32-bit data to be written.
- **`WE3`** – Register write enable signal.
- **Clock** – Synchronizes the write operation.

When **`WE3`** is asserted, the value on **`WD3`** is written into the register specified by **`A3`** on the **rising edge of the clock**.

### Data Memory

The **Data Memory** stores program data and is used by **load (`lw`)** and **store (`sw`)** instructions.

It provides a **single read/write port**.

The interface includes:

- **`A`** – Memory address.
- **`WD`** – Data to be written.
- **`RD`** – Data read from memory.
- **`WE`** – Memory write enable signal.

Its operation is as follows:

- If **`WE = 1`**, the data on **`WD`** is written to address **`A`** on the **rising edge of the clock**.
- If **`WE = 0`**, the memory performs a read operation, and the data stored at address **`A`** appears on **`RD`**.

### Combinational Read Operation

The **Instruction Memory**, **Register File**, and **Data Memory** all perform **read operations combinationally**.

This means:

- Changing the address input automatically updates the output data after the corresponding propagation delay.
- No clock signal is required for read operations.

As a result, the processor can immediately access instructions, register values, and memory contents whenever their addresses change.

### Synchronous Write Operation

Although reads are combinational, **all write operations are synchronous**.

Data is written only on the **rising edge of the clock**, ensuring that the processor state changes only at well-defined clock boundaries.

For a successful write operation:

- Address signals must be valid before the clock edge.
- Write data must be stable before the clock edge.
- The write enable signal must be asserted.
- These signals must remain stable for the required **setup** and **hold** times around the clock edge.

This synchronous behavior guarantees predictable and reliable processor operation.

### Synchronous Sequential Operation

Since the processor's state elements update only on the **rising edge of the clock**, they are classified as **synchronous sequential circuits**.

Consequently, the entire RISC-V processor is also a **synchronous sequential system**, composed of:

- Clocked state elements that store processor state.
- Combinational logic that computes the next state and generates control signals between clock cycles.

From a system perspective, the processor can be viewed either as:

- A single large **Finite State Machine (FSM)**, or
- A collection of smaller interacting state machines that work together to execute each instruction.

## Types of Microarchitectures

A single **Instruction Set Architecture (ISA)**, such as **RISC-V**, can be implemented using multiple microarchitectures. While each implementation executes the same set of instructions and produces identical results, they differ significantly in terms of **performance**, **hardware cost**, **resource utilization**, and **design complexity**.

The three most common RISC-V microarchitecture implementations are:

- Single-Cycle Microarchitecture
- Multicycle Microarchitecture
- Pipelined Microarchitecture

The primary difference between these architectures lies in how the processor's state elements are interconnected and how much additional **non-architectural state** is introduced to improve performance or reduce hardware requirements.

### Single-Cycle Microarchitecture

In a **single-cycle processor**, every instruction is completed within a **single clock cycle**. All stages of instruction execution—including instruction fetch, decode, execution, memory access, and write-back—occur during the same clock period.

#### Characteristics

- Executes one complete instruction per clock cycle.
- Simple datapath and straightforward control unit.
- Does not require any additional non-architectural registers.
- Easy to design, understand, and verify.

#### Advantages

- Simple hardware organization.
- Simple control logic.
- No intermediate storage required between execution stages.

#### Limitations

- The clock period must be long enough to accommodate the **slowest instruction**.
- Faster instructions must wait for the longest instruction to complete, reducing overall performance.
- Requires separate **Instruction Memory** and **Data Memory** so that instruction fetch and data access can occur within the same clock cycle.

> **This project implements a Single-Cycle RISC-V Processor**, where every instruction completes in one clock cycle.

### Multicycle Microarchitecture

A **multicycle processor** divides instruction execution into several shorter clock cycles. Instead of completing an instruction in one long cycle, each instruction progresses through multiple execution stages.

Simple instructions require fewer clock cycles, while more complex instructions require additional cycles.

#### Characteristics

- One instruction is executed over multiple clock cycles.
- Different instructions require different numbers of cycles.
- Hardware resources are reused across multiple stages of execution.
- Intermediate results are stored in additional non-architectural registers.

#### Advantages

- Shorter clock period compared to a single-cycle processor.
- Better hardware utilization through resource sharing.
- Reduced hardware cost by reusing components such as adders and memory.

#### Limitations

- Increased control complexity.
- Requires additional registers to store intermediate values.
- Each instruction requires multiple clock cycles to complete.

Unlike the single-cycle processor, the multicycle architecture can use **a single memory** for both instruction fetch and data access because these operations occur during different clock cycles.

### Pipelined Microarchitecture

A **pipelined processor** improves processor throughput by allowing multiple instructions to execute simultaneously in different stages of execution.

Instead of waiting for one instruction to complete before starting the next, pipelining overlaps the execution of consecutive instructions.

#### Characteristics

- Multiple instructions execute concurrently.
- Each instruction progresses through independent pipeline stages.
- Requires pipeline registers between stages.
- Includes additional hazard detection and forwarding logic.

#### Advantages

- Significantly higher instruction throughput.
- Improved processor performance without increasing the complexity of individual instructions.
- Widely used in modern high-performance processors.

#### Limitations

- More complex datapath and control logic.
- Requires hazard detection and resolution mechanisms.
- Introduces pipeline registers and additional control hardware.

Since instruction fetch and data memory access can occur during the same clock cycle, pipelined processors typically use separate **Instruction Cache** and **Data Cache** (Harvard Architecture) to avoid memory access conflicts.

## Microarchitecture Comparison

| Feature | Single-Cycle | Multicycle | Pipelined |
|---------|--------------|------------|------------|
| Clock cycles per instruction | 1 | Multiple | Multiple (overlapped) |
| Clock period | Long | Short | Short |
| Hardware complexity | Low | Medium | High |
| Additional registers | No | Yes | Yes (Pipeline Registers) |
| Hardware reuse | No | Yes | Limited |
| Throughput | Low | Medium | High |
| Control complexity | Simple | Moderate | Complex |
| Memory organization | Separate Instruction & Data Memory | Single Memory Possible | Separate Instruction & Data Cache |

This documentation focuses on the **Single-Cycle RISC-V Microarchitecture**, providing a detailed explanation of its datapath, control logic, instruction execution flow, and finite state machine (FSM) operation.


$$
\text{Execution Time} =
(\text{Instruction Count})
\left(
\frac{\text{Cycles}}{\text{Instruction}}
\right)
\left(
\frac{\text{Seconds}}{\text{Cycle}}
\right)
$$

## Sample Program

To better understand the execution of the single-cycle RISC-V processor, we consider a simple program that exercises several commonly used instruction types, including **load (`lw`)**, **store (`sw`)**, an **R-type instruction (`or`)**, and a **branch instruction (`beq`)**.

The program is assumed to be stored in **Instruction Memory**, beginning at address **`0x1000`**. Each instruction includes its corresponding memory address, instruction type, instruction fields, and hexadecimal machine code representation.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-2%20Sample%20program%20exercising%20different%20types%20of%20instructions.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-2 Sample program exercising different types of instructions</em>
</p>

### Initial Conditions

Before execution begins, the processor is assumed to have the following initial state:

| Component | Initial Value |
|-----------|---------------|
| `PC` | `0x1000` |
| `x5` | `6` |
| `x9` | `0x2004` |
| Memory[`0x2000`] | `10` |

### Program Execution

The execution of the sample program proceeds as follows:

1. **`lw x6, -4(x9)`**
   - Calculates the effective address:
     ```
     0x2004 - 4 = 0x2000
     ```
   - Reads the value **10** from memory location **`0x2000`**.
   - Stores the loaded value into register **`x6`**.

2. **`sw x6, 8(x9)`**
   - Calculates the effective address:
     ```
     0x2004 + 8 = 0x200C
     ```
   - Stores the value **10** from register **`x6`** into memory location **`0x200C`**.

3. **`or x4, x5, x6`**
   - Performs a bitwise OR operation:
     ```
     x5 = 6  = 0110₂
     x6 = 10 = 1010₂

     0110₂ OR 1010₂ = 1110₂ = 14
     ```
   - The result (**14**) is written into register **`x4`**.

4. **`beq`**
   - The branch instruction compares the specified registers.
   - Since the branch condition is satisfied, execution jumps back to the label **`L7`**, causing the program to execute repeatedly in an infinite loop.

---

## Single-Cycle Datapath

The single-cycle datapath is developed incrementally by adding one hardware component at a time to the basic state elements introduced earlier. Each new component is integrated into the existing datapath until the processor is capable of executing the complete instruction set.

During the construction of the datapath:

- Newly introduced hardware components are highlighted.
- Previously discussed hardware remains unchanged.
- The instruction currently being executed is shown to illustrate how data flows through the processor.

### Instruction Fetch

Instruction execution always begins with the **Instruction Fetch (IF)** stage.

The **Program Counter (`PC`)** stores the address of the instruction that is to be executed. Its output is connected directly to the address input of the **Instruction Memory**.

The Instruction Memory uses this address to fetch the corresponding **32-bit instruction**, commonly referred to as **`Instr`**.

For the sample program shown above:

- Initial `PC` = **`0x1000`**
- The instruction stored at address **`0x1000`** is fetched from Instruction Memory.
- This fetched instruction is then forwarded to the remaining stages of the datapath for decoding and execution.

> **Note:** Although the processor is 32 bits wide, addresses such as `0x1000` are commonly written without leading zeros (for example, `0x00001000`) to improve readability.
>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-3%20Fetch%20instruction%20from%20memory.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-3 Fetch instruction from memory</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-4%20Read%20source%20operand%20from%20register%20file.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-4 Read source operand from register file</em>
</p>

## Instruction Decode and Register Read (`lw`)

After the instruction is fetched from the **Instruction Memory**, the processor determines the required operation by decoding the instruction fields.

For the example shown in **Figure 3**, the fetched instruction is:

```text
Instr = 0xFFC4A303
```

The datapath shown in the figures highlights these example values to illustrate the flow of data during execution.

Since the fetched instruction is a **`lw` (Load Word)** instruction, the processor must first read the **base address register** from the Register File.

The `lw` instruction follows the **I-type instruction format**, where the source register (`rs1`) is stored in the instruction bits **`Instr[19:15]`**.

These bits are connected directly to the **`A1`** input of the Register File, causing the specified register to be read through output **`RD1`**.

For the sample program:

- `rs1 = x9`
- `x9 = 0x2004`

Therefore, the Register File outputs:

```text
RD1 = 0x2004
```

The datapath for this operation is illustrated in **Figure 4**.

## Immediate Generation

Unlike R-type instructions, the `lw` instruction also requires a **12-bit immediate offset**, stored in the instruction field:

```text
Instr[31:20]
```

Since this immediate represents a **signed value**, it must be extended to the processor's 32-bit datapath before it can be used.

This is accomplished by the **Immediate Generator**, which performs **sign extension**.

The sign extension operation is defined as:

```text
ImmExt[31:12] = Instr[31]
ImmExt[11:0]  = Instr[31:20]
```

In other words, the most significant bit of the immediate (the sign bit) is replicated into the upper 20 bits, preserving the value for both positive and negative offsets.

For the sample instruction:

```text
Immediate = -4
```

After sign extension:

```text
ImmExt = 0xFFFFFFFC
```

## Effective Address Calculation

The processor must now calculate the **effective memory address** from which the data will be loaded.

This address is computed by the **Arithmetic Logic Unit (ALU)** using:

```text
Effective Address = Base Address + Sign-Extended Immediate
```

For a `lw` instruction, the ALU is configured to perform **addition**, so the control signal:

```text
ALUControl = 000
```

The ALU receives:

- Operand A = `RD1`
- Operand B = `ImmExt`

For the running example:

```text
RD1    = 0x2004
ImmExt = 0xFFFFFFFC

ALUResult = 0x2004 + 0xFFFFFFFC
          = 0x2000
```

The resulting **`ALUResult`** becomes the memory address supplied to the **Data Memory**.

## Data Memory Read

The computed address (`ALUResult`) is connected to the address input (`A`) of the **Data Memory**.

Since `lw` performs a **read operation**, the memory returns the data stored at the specified address through the **`ReadData`** output.

For the sample program:

```text
Address = 0x2000

ReadData = 10
```

The retrieved data is then forwarded to the Register File for write-back.

## Register Write-Back

The final stage of the `lw` instruction is writing the loaded data into the destination register.

The destination register is specified by the **`rd`** field:

```text
Instr[11:7]
```

This field is connected to the Register File write address input (`A3`).

The connections are:

| Register File Port | Source |
|--------------------|--------|
| `A3` | `Instr[11:7]` (`rd`) |
| `WD3` | `ReadData` |
| `WE3` | `RegWrite` |

During execution of a `lw` instruction:

- `RegWrite = 1`

Therefore, on the **rising edge of the clock**, the value on `ReadData` is written into the destination register.

For the running example:

```text
ReadData = 10

Destination Register = x6

x6 ← 10
```

This completes the memory read and register write-back stages of the `lw` instruction.

## Program Counter Update

While the instruction is executing, the processor simultaneously computes the address of the next instruction.

Since every RV32I instruction occupies **32 bits (4 bytes)**, sequential execution simply increments the Program Counter by four.

The next Program Counter value is calculated as:

```text
PCNext = PC + 4
```

For the sample program:

```text
PC      = 0x1000

PCNext  = 0x1004
```

A dedicated adder computes this value, and on the **next rising edge of the clock**, `PCNext` is written into the Program Counter.

After updating the Program Counter, execution proceeds with the next instruction stored at address **`0x1004`**, completing the execution flow of the **`lw` instruction** in the single-cycle datapath.

## Execution Flow of the `lw` Instruction

Assume that the fetched instruction is:

```text
lw x6, -4(x9)
Machine Code : 0xFFC4A303
```

As shown in **Figure 3**, the Program Counter (`PC`) initially contains the value **`0x1000`**, which is supplied to the Instruction Memory. The corresponding 32-bit instruction (`0xFFC4A303`) is fetched and forwarded to the datapath for decoding and execution.

The execution of the `lw` instruction is carried out through the following sequence of operations.

### Step 1: Read the Base Register

The `lw` instruction is an **I-type** instruction. Its base register is specified by the **`rs1`** field (`Instr[19:15]`).

These five bits are connected directly to the **`A1`** input of the Register File, causing the processor to read the contents of the specified source register onto output **`RD1`**.

In the sample program:

- `rs1 = x9`
- `x9 = 0x2004`

Therefore,

```text
RD1 = 0x2004
```

This value serves as the base address for the memory access.

### Step 2: Generate the Immediate Offset

The `lw` instruction also contains a **12-bit signed immediate**, stored in bits **`Instr[31:20]`**.

Since the datapath operates on 32-bit values, this immediate must first be **sign-extended** to 32 bits using the **Immediate Extension (`Extend`)** unit.

The sign-extension process copies the sign bit (`Instr[31]`) into the upper 20 bits.

Mathematically,

```text
ImmExt[31:12] = Instr[31]
ImmExt[11:0]  = Instr[31:20]
```

For the sample instruction,

```text
12-bit Immediate  = 0xFFC
Decimal Value     = -4
```

After sign extension,

```text
ImmExt = 0xFFFFFFFC
```

The processor now has both operands required to calculate the effective memory address.

### Step 3: Calculate the Effective Address

The effective memory address is calculated using the **Arithmetic Logic Unit (ALU)**.

The ALU receives:

- **`SrcA`** = Base address from the Register File (`RD1`)
- **`SrcB`** = Sign-extended immediate (`ImmExt`)

For a `lw` instruction, the ALU performs an **addition** operation.

Therefore,

```text
ALUControl = 000
```

The ALU computes

```text
ALUResult = SrcA + SrcB
```

Substituting the sample values,

```text
ALUResult = 0x2004 + 0xFFFFFFFC
          = 0x2000
```

This result represents the effective address from which the data will be loaded.

### Step 4: Read Data Memory

The ALU output (`ALUResult`) is connected directly to the **address input (`A`)** of the Data Memory.

Since this is a **load** instruction:

- Data Memory performs a **read** operation.
- The data stored at address **`0x2000`** appears on the **`ReadData`** bus.

For the sample program,

```text
Memory[0x2000] = 10
```

Therefore,

```text
ReadData = 10
```

### Step 5: Write Back to the Register File

The loaded value is written back into the destination register specified by the **`rd`** field (`Instr[11:7]`).

The write port of the Register File consists of:

- **`A3`** – Destination register address (`rd`)
- **`WD3`** – Data to be written (`ReadData`)
- **`WE3`** – Register write enable (`RegWrite`)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-6%20Sign-extend%20the%20immediate.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-5 Sign-extend the immediate</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-7%20Compute%20memory%20address.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-6 Compute memory address</em>
</p>

During the execution of the `lw` instruction,

```text
RegWrite = 1
```

On the rising edge of the clock, the value on `ReadData` is written into the destination register.

For the sample instruction,

```text
Destination Register = x6
Data Written         = 10
```

Thus,

```text
x6 ← 10
```

### Step 6: Update the Program Counter

While the current instruction is executing, the processor simultaneously computes the address of the next instruction.

Since every RISC-V instruction occupies **32 bits (4 bytes)**, the next sequential instruction is located at:

```text
PCNext = PC + 4
```

A dedicated adder increments the Program Counter by four.

For the sample execution,

```text
PC      = 0x1000
PCNext  = 0x1004
```

At the rising edge of the clock, the Program Counter is updated with this new address, completing the execution of the `lw` instruction.

### Summary of `lw` Execution

| Stage | Operation |
|--------|-----------|
| Instruction Fetch | Fetch instruction `0xFFC4A303` from Instruction Memory |
| Register Read | Read base register `x9 = 0x2004` |
| Immediate Generation | Sign-extend `0xFFC` to `0xFFFFFFFC` |
| ALU Execution | Compute effective address `0x2004 + (-4) = 0x2000` |
| Memory Access | Read value `10` from Data Memory |
| Write Back | Write `10` into register `x6` |
| PC Update | Increment `PC` from `0x1000` to `0x1004` |

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-8%20Read%20memory%20and%20write%20result%20back%20to%20register%20file.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-7 Read memory and write result back to register file</em>
</p>


<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-9%20Increment%20program%20counter.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-8 Increment program counter</em>
</p>

## Execution Flow of the `sw` Instruction

The **`sw` (Store Word)** instruction is an **S-type** instruction that stores a 32-bit word from a register into Data Memory. Similar to the `lw` instruction, it computes the effective memory address by adding a base register value to a signed immediate offset. However, instead of reading data from memory, it writes data into memory.

The execution of the `sw` instruction proceeds through the following steps.

### Step 1: Read the Base Register

The base address is specified by the **`rs1`** field (`Instr[19:15]`).

These bits are connected to the **`A1`** input of the Register File, causing the contents of the selected register to appear on output **`RD1`**.

This value serves as the base address for the memory write operation.

### Step 2: Generate the Immediate Offset

Unlike the `lw` instruction, the **`sw`** instruction stores its **12-bit signed immediate** in two separate fields:

- `Instr[31:25]`
- `Instr[11:7]`

The **Immediate Extension (`Extend`)** unit combines these two fields and performs sign extension to produce a 32-bit immediate value.

To support multiple instruction formats, the Extend unit receives the complete **`Instr[31:7]`** field. A control signal called **`ImmSrc`** determines how the immediate is extracted.

- **`ImmSrc = 0`** → I-type immediate (`lw`)
- **`ImmSrc = 1`** → S-type immediate (`sw`)

The selected immediate is then sign-extended to 32 bits before being forwarded to the ALU.

### Step 3: Calculate the Effective Address

The **Arithmetic Logic Unit (ALU)** calculates the effective memory address by adding:

- **`SrcA`** = Base address from the Register File (`RD1`)
- **`SrcB`** = Sign-extended immediate (`ImmExt`)

For the `sw` instruction,

```text
ALUControl = 000
```

which configures the ALU to perform an addition.

The resulting address (`ALUResult`) represents the Data Memory location where the word will be stored.

### Step 4: Read the Source Data

Unlike `lw`, which reads data from memory, the `sw` instruction must obtain the data to be written from a second register.

The register specified by the **`rs2`** field (`Instr[24:20]`) is connected to the **`A2`** input of the Register File.

Its contents appear on output **`RD2`**, which is connected directly to the **Write Data (`WD`)** input of the Data Memory.

Thus,

- `rs1` provides the base address.
- `rs2` provides the data that will be stored in memory.

### Step 5: Write Data to Memory

The ALU output (`ALUResult`) is connected to the address input of the Data Memory.

The value from **`RD2`** is supplied to the Data Memory write-data input.

A control signal called **`MemWrite`** determines whether the memory performs a write operation.

For the `sw` instruction:

```text
MemWrite = 1
```

At the rising edge of the clock, the value from `RD2` is written into the memory location specified by `ALUResult`.

Although the Data Memory continues to produce a value on its `ReadData` output, this value is ignored because the processor is performing a write operation.

### Step 6: Register File Remains Unchanged

Unlike the `lw` instruction, the `sw` instruction does **not** write any value back into the Register File.

Therefore,

```text
RegWrite = 0
```

No register is updated during the execution of a store instruction.

### Summary of `sw` Execution

| Stage | Operation |
|--------|-----------|
| Instruction Fetch | Fetch the `sw` instruction from Instruction Memory |
| Register Read | Read base register (`rs1`) and source register (`rs2`) |
| Immediate Generation | Extract and sign-extend the S-type immediate |
| ALU Execution | Compute effective memory address (`Base + Offset`) |
| Memory Access | Write the contents of `rs2` into Data Memory |
| Write Back | No register write (`RegWrite = 0`) |
| PC Update | Increment `PC` to the next instruction (`PC + 4`) |

<p align="center"> <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-10%20Write%20data%20to%20memory%20for%20sw%20instruction.png" width="1000"> </p> <p align="center"> <em>Figure: Fig-9 Write data to memory for sw instruction</em> </p>


### Example Execution of the `sw` Instruction

For the sample program, after the execution of the `lw` instruction, the processor state is as follows:

- `PC = 0x1004`
- `x9 = 0x2004` (Base Address)
- `x6 = 10` (Value loaded by the previous `lw` instruction)

The instruction stored at address **`0x1004`** is:

```text
sw x6, 8(x9)
Machine Code : 0x0064A423
```

The processor executes the instruction as follows:

1. The **Instruction Memory** fetches the instruction `0x0064A423`.
2. The **Register File** reads:
   - `x9 = 0x2004` as the base address (`rs1`).
   - `x6 = 10` as the data to be stored (`rs2`).
3. The **Immediate Extension Unit** sign-extends the 12-bit immediate value **8** to a 32-bit value.
4. The **ALU** computes the effective address:

   ```text
   0x2004 + 8 = 0x200C
   ```

5. The **Data Memory** writes the value **10** into memory location **`0x200C`**.
6. Simultaneously, the Program Counter is incremented:

   ```text
   PCNext = 0x1004 + 4 = 0x1008
   ```

The execution of the `sw` instruction is now complete.

---

## Execution Flow of R-Type Instructions

The processor is next extended to support **R-type instructions**, which perform arithmetic and logical operations using two source registers.

The implemented R-type instructions are:

- `add`
- `sub`
- `and`
- `or`
- `slt`

Although these instructions perform different operations, they all follow the same execution flow. The only difference is the operation selected inside the **Arithmetic Logic Unit (ALU)**.

### Common Execution Flow

Every R-type instruction performs the following operations:

1. Read the first source operand (`rs1`) from the Register File.
2. Read the second source operand (`rs2`) from the Register File.
3. Perform the required ALU operation.
4. Write the ALU result back into the destination register (`rd`).
5. Increment the Program Counter (`PC`) to the next instruction.

### ALU Operations

The ALU operation is determined by the **`ALUControl`** signal.

| Instruction | ALU Operation | `ALUControl` |
|-------------|---------------|--------------|
| `add` | Addition | `000` |
| `sub` | Subtraction | `001` |
| `and` | Bitwise AND | `010` |
| `or` | Bitwise OR | `011` |
| `slt` | Set Less Than | `101` |

### ALU Source Selection

Unlike `lw` and `sw`, which use a sign-extended immediate as the second ALU operand, R-type instructions require two register operands.

To support both instruction types, a **2-to-1 Multiplexer** is placed before the ALU.

The multiplexer is controlled by the **`ALUSrc`** signal.

| `ALUSrc` | Selected ALU Source (`SrcB`) | Instruction Type |
|-----------|------------------------------|------------------|
| `0` | Register File output (`RD2`) | R-Type |
| `1` | Sign-extended Immediate (`ImmExt`) | `lw`, `sw` |

Therefore:

- For **`lw`** and **`sw`**, `ALUSrc = 1`, selecting the sign-extended immediate.
- For **R-type instructions**, `ALUSrc = 0`, selecting the second register operand (`RD2`).

This addition allows the same ALU hardware to execute both memory instructions and arithmetic/logic instructions by simply changing the control signals generated by the Control Unit.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-11%20Datapath%20enhancements%20for%20R-type%20instructions.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-10 Datapath enhancements for R-type instructions</em>
</p>

### Write-Back Selection for R-Type Instructions

The value that is finally written back to the Register File is referred to as **`Result`**.

The source of `Result` depends on the type of instruction being executed:

- For **`lw`**, the value comes from the **`ReadData`** output of the Data Memory.
- For **R-type instructions**, the value comes directly from the **`ALUResult`** output.

To support both cases, a **2-to-1 multiplexer** called the **Result Multiplexer** is introduced before the Register File write port.

The multiplexer is controlled by the **`ResultSrc`** signal.

| `ResultSrc` | Result Source | Instruction Type |
|-------------|---------------|------------------|
| `0` | `ALUResult` | R-type Instructions |
| `1` | `ReadData` | `lw` |

For the **`sw`** instruction, the value of `ResultSrc` is irrelevant because the Register File is not written (`RegWrite = 0`).

### Example Execution of an R-Type Instruction

In the sample program, after completing the `sw` instruction:

```text
PC = 0x1008
```

The Instruction Memory fetches the following instruction:

```text
or x4, x5, x6
Machine Code : 0x0062E233
```

The processor performs the following operations:

1. The Register File reads:
   - `x5 = 6`
   - `x6 = 10`
2. The ALU receives these two operands.
3. The Control Unit sets:

   ```text
   ALUControl = 011
   ```

   selecting the **Bitwise OR** operation.

4. The ALU computes:

   ```text
   6 OR 10

   0110₂
   OR
   1010₂
   ----------
   1110₂ = 14
   ```

5. Since this is an R-type instruction:

   ```text
   ResultSrc = 0
   ```

   the Result Multiplexer selects the **ALUResult**.

6. On the rising edge of the clock, the value **14** is written into destination register **`x4`**.

7. Simultaneously, the Program Counter is updated:

   ```text
   PCNext = 0x1008 + 4 = 0x100C
   ```

This completes the execution of the `or` instruction.

---

## Execution Flow of the `beq` Instruction

The **`beq` (Branch if Equal)** instruction is a **B-type** instruction used to alter the normal program flow based on the comparison of two registers.

If both registers contain the same value, execution branches to the target address. Otherwise, execution continues with the next sequential instruction.

### Step 1: Read the Source Registers

The processor reads the two source registers specified by:

- **`rs1`**
- **`rs2`**

These register values are obtained through the two read ports of the Register File and are forwarded to the ALU.

### Step 2: Generate the Branch Offset

Unlike I-type and S-type instructions, the **B-type** instruction stores its branch offset in a different bit arrangement.

The **Immediate Extension (`Extend`)** unit extracts these bits, rearranges them according to the B-type instruction format, and sign-extends the value to 32 bits.

To support all immediate formats, the **`ImmSrc`** control signal is expanded to **2 bits**.

Its operation is summarized below:

| `ImmSrc` | Immediate Type |
|-----------|----------------|
| `00` | I-type (`lw`) |
| `01` | S-type (`sw`) |
| `10` | B-type (`beq`) |

When executing a `beq` instruction, the Extend unit produces the 32-bit branch offset (`ImmExt`).

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-1%20ImmSrc%20encoding.png" width="1000">
</p>

<p align="center">
  <em>Table-1 ImmSrc encoding</em>
</p>

### Step 3: Compute the Branch Target Address

A dedicated adder computes the target address of the branch.

The target address is calculated as:

```text
PCTarget = PC + ImmExt
```

This value represents the address to which execution will jump if the branch condition is satisfied.

### Step 4: Compare the Registers

The processor determines whether the branch should be taken by comparing the two source registers.

Instead of using a dedicated comparator, the ALU performs a subtraction:

```text
SrcA - SrcB
```

For a `beq` instruction,

```text
ALUControl = 001
```

which selects the subtraction operation.

If the subtraction result is zero, the ALU asserts its **`Zero`** flag, indicating that both registers contain identical values.

### Step 5: Select the Next Program Counter

A multiplexer determines the value of **`PCNext`**.

It selects between:

- **`PCPlus4`** – Continue sequential execution.
- **`PCTarget`** – Branch target address.

The branch target is selected only when:

- The current instruction is `beq`, **and**
- The ALU **Zero** flag is asserted.

Otherwise, the processor simply increments the Program Counter by four.

### Control Signals for `beq`

The Control Unit generates the following control signals during the execution of a `beq` instruction.

| Control Signal | Value | Purpose |
|----------------|-------|---------|
| `ALUControl` | `001` | Perform subtraction |
| `ALUSrc` | `0` | Select second register operand (`RD2`) |
| `RegWrite` | `0` | No register write |
| `MemWrite` | `0` | No memory write |
| `ResultSrc` | Don't Care | Register File is not written |

Since a branch instruction neither writes to memory nor updates the Register File, only the Program Counter may change depending on the comparison result.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-12%20Datapath%20enhancements%20for%20beq%20%26%20also%20showing%20the%20ImmSrc%20Encoding.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-11 Datapath enhancements for <code>beq</code> &amp; also showing the <code>ImmSrc</code> encoding</em>
</p>

