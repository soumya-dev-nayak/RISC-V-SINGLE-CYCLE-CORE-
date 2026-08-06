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

### Example Execution of the `beq` Instruction

In the sample program, after the execution of the `or` instruction, the Program Counter contains:

```text
PC = 0x100C
```

The Instruction Memory fetches the following instruction:

```text
beq x4, x4, L7
Machine Code : 0xFE420AE3
```

The processor executes the instruction as follows:

1. The Register File reads both source operands.
   - `rs1 = x4 = 14`
   - `rs2 = x4 = 14`

2. Since `beq` compares two registers, the Control Unit configures the ALU to perform subtraction.

   ```text
   ALUControl = 001
   ```

3. The ALU computes:

   ```text
   14 - 14 = 0
   ```

4. Because the subtraction result is zero, the ALU asserts the **`Zero`** flag, indicating that both registers are equal.

5. Simultaneously, the **Immediate Extension Unit** extracts the B-type immediate and sign-extends it to 32 bits.

   ```text
   ImmExt = 0xFFFFFFF4
          = -12
   ```

   > **Note:** The instruction stores the branch immediate in a rearranged (B-type) format. Before sign extension, the upper 12 bits of the immediate are effectively represented as **`0xFFA`**.

6. The branch target address is calculated using the dedicated branch adder.

   ```text
   PCTarget = PC + ImmExt
            = 0x100C + (-12)
            = 0x1000
   ```

7. Since the current instruction is `beq` and the **`Zero`** flag is asserted, the **PCNext Multiplexer** selects **`PCTarget`** instead of `PC + 4`.

8. On the rising edge of the clock, the Program Counter is updated to:

   ```text
   PC = 0x1000
   ```

The processor therefore branches back to the beginning of the program, causing the instruction sequence to repeat.

---

## Completed Single-Cycle Datapath

With the addition of support for **`lw`**, **`sw`**, **R-type instructions**, and **`beq`**, the single-cycle datapath is now capable of executing the complete subset of RISC-V instructions implemented in this project.

The datapath includes all essential hardware components required for instruction execution, including:

- Instruction Memory
- Program Counter (PC)
- Register File
- Immediate Extension Unit
- Arithmetic Logic Unit (ALU)
- Data Memory
- Adders for `PC + 4` and branch target calculation
- Multiplexers for ALU source selection, write-back selection, and next Program Counter selection

The processor has been constructed by first identifying the architectural state elements and then systematically introducing the necessary combinational logic to connect them. This modular design approach results in a complete single-cycle datapath capable of fetching, decoding, executing, accessing memory, writing back results, and updating the Program Counter within a single clock cycle.

The remaining component required for a fully functional processor is the **Control Unit**, which generates the control signals that direct the operation of the datapath during the execution of each instruction. The next section describes how these control signals are generated.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-13%20Complete%20single-cycle%20processor.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-12 Complete single-cycle processor</em>
</p>

## Single-Cycle Control Unit

The **Control Unit** is responsible for generating all the control signals required to correctly execute each instruction in the single-cycle processor. These control signals are derived from specific fields of the fetched instruction and determine how the datapath components operate during a clock cycle.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-14%20Single-Cycle%20Processor%20Control%20unit.png" width="500">
</p>

<p align="center">
  <em>Figure: Fig-13 Single-Cycle Processor Control unit</em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-2%20Main%20Decoder(single%20Cycle)%20truth%20table.png" width="1000">
</p>

<p align="center">
  <em>Table-2 Main Decoder (Single-Cycle) truth table</em>
</p>

For the **RV32I** instruction subset implemented in this project, the Control Unit examines the following instruction fields:

- **Opcode (`op`)** → `Instr[6:0]`
- **Function 3 (`funct3`)** → `Instr[14:12]`
- **Function 7 Bit 5 (`funct7[5]`)** → `Instr[30]`

Since only **bit 5** of the `funct7` field is required for the implemented instructions, the Control Unit only needs these three inputs to generate all necessary control signals.

The complete single-cycle processor consists of the datapath together with the Control Unit, which is also commonly referred to as the **Controller** or **Instruction Decoder**, because it interprets each instruction and determines how the processor should execute it.

To simplify the design, the Control Unit is divided into two major blocks:

- **Main Decoder**
- **ALU Decoder**

---

## Main Decoder

The **Main Decoder** identifies the instruction type using the **opcode** field and generates most of the control signals required by the datapath.

These control signals determine how data flows through the processor by controlling:

- Register File write operations
- Data Memory write operations
- Immediate generation
- ALU operand selection
- Result write-back selection
- Branch execution

In addition to the datapath control signals, the Main Decoder also generates two internal controller signals:

- **Branch**
- **ALUOp**

These signals are used internally by the Control Unit to determine branching behavior and the ALU operation.

The logic of the Main Decoder can be implemented directly from its truth table using standard combinational logic design techniques.

---

## ALU Decoder

The **ALU Decoder** generates the final **`ALUControl`** signal that selects the operation performed by the Arithmetic Logic Unit.

Instead of decoding the instruction directly, it uses:

- **`ALUOp`** from the Main Decoder
- **`funct3`**
- **`funct7[5]`** (when required)
- **`op[5]`** (for distinguishing certain R-type instructions)

The ALU Decoder interprets these fields and produces the correct ALU operation for each instruction.

---

## ALUOp Encoding

The **`ALUOp`** signal generated by the Main Decoder simplifies the design of the ALU Decoder.

Its meaning is summarized below:

| `ALUOp` | Operation |
|----------|-----------|
| `00` | Perform Addition |
| `01` | Perform Subtraction |
| `10` | Decode R-type ALU operation |

### ALUOp = `00`

This mode is used by instructions that require the ALU to compute an address.

Examples:

- `lw`
- `sw`

In these instructions, the ALU simply adds the base address and the sign-extended immediate.

---

### ALUOp = `01`

This mode is used for branch instructions.

Example:

- `beq`

The ALU performs a subtraction between the two source registers. If the subtraction result is zero, the **Zero** flag is asserted, indicating that the branch condition has been satisfied.

---

### ALUOp = `10`

This mode is used for **R-type instructions**.

In this case, the Main Decoder delegates the operation selection to the ALU Decoder.

The ALU Decoder examines:

- `funct3`
- `funct7[5]`
- `op[5]` (when necessary)

to determine the required ALU operation, such as:

- `add`
- `sub`
- `and`
- `or`
- `slt`

The resulting **`ALUControl`** signal is then forwarded to the ALU, allowing it to execute the appropriate arithmetic or logical operation.

By separating the Control Unit into the **Main Decoder** and the **ALU Decoder**, the overall processor design becomes more modular, easier to understand, and simpler to implement. The Main Decoder identifies the instruction class and generates the primary control signals, while the ALU Decoder focuses solely on selecting the correct ALU operation based on the instruction's function fields.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-3%20ALU%20Decoder%20truth%20table.png" width="1000">
</p>

<p align="center">
  <em>Table-3 ALU Decoder truth table</em>
</p>

## Example: Single-Cycle Processor Operation for an `and` Instruction

This example demonstrates how the **single-cycle RISC-V processor** executes an **`and`** instruction and illustrates the corresponding control signals and datapath components involved during execution.

The Program Counter (**PC**) initially points to the memory location containing the `and` instruction. The Instruction Memory fetches this instruction and forwards it to the Control Unit and Register File for decoding and execution.

The primary data flow during the execution of an `and` instruction is as follows:

1. The **Instruction Memory** fetches the instruction using the current value of the Program Counter.

2. The **Register File** reads the two source operands specified by the instruction fields:
   - `rs1`
   - `rs2`

3. Since both operands originate from the Register File, the second ALU operand (**`SrcB`**) must come from **`RD2`** instead of the sign-extended immediate.

   Therefore,

   ```text
   ALUSrc = 0
   ```

4. The **ALU** performs a **bitwise AND** operation on the two register operands.

   Therefore,

   ```text
   ALUControl = 010
   ```

5. The output of the ALU represents the final computation result.

   Since the result comes directly from the ALU,

   ```text
   ResultSrc = 0
   ```

6. The computed result is written back into the destination register.

   Therefore,

   ```text
   RegWrite = 1
   ```

7. The `and` instruction does not access or modify Data Memory.

   Therefore,

   ```text
   MemWrite = 0
   ```

8. At the same time, the Program Counter is incremented by four to fetch the next sequential instruction.

   Since execution continues normally without branching,

   ```text
   PCSrc = 0
   ```

   causing the processor to select **`PC + 4`** as the next Program Counter value.

### Control Signals for the `and` Instruction

| Control Signal | Value | Purpose |
|----------------|-------|---------|
| `ALUSrc` | `0` | Select second register operand (`RD2`) |
| `ALUControl` | `010` | Perform bitwise AND operation |
| `ResultSrc` | `0` | Select ALU result for write-back |
| `RegWrite` | `1` | Enable writing to the Register File |
| `MemWrite` | `0` | Disable Data Memory write |
| `PCSrc` | `0` | Select `PC + 4` as the next Program Counter |

### Datapath Observation

Although only a portion of the datapath actively contributes to the execution of the `and` instruction, the remaining hardware continues to operate.

For example:

- The **Immediate Extension Unit** still generates an immediate value.
- The **Data Memory** may still produce a value on its read output.

However, these values are **ignored** because they are not selected by the datapath multiplexers and therefore do not influence the processor's next state.

This demonstrates an important characteristic of the single-cycle datapath: multiple hardware components may operate simultaneously, but only the outputs selected by the control signals affect the execution of the current instruction.
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-15%20Control%20signals%20and%20data%20flow%20while%20executing%20an%20and%20instruction.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-14 Control signals and data flow while executing an <code>and</code> instruction</em>
</p>

### Supporting the `addi` Instruction

The `addi` (*Add Immediate*) instruction is an **I-type** instruction that adds the contents of the source register `rs1` to a **sign-extended 12-bit immediate** and stores the result in the destination register `rd`.

```assembly
addi rd, rs1, imm
```

One of the advantages of the existing single-cycle datapath is that it already contains all the necessary hardware required to execute the `addi` instruction. Since the ALU is already capable of adding a register operand with a sign-extended immediate (as used by the `lw` and `sw` instructions), **no modifications to the datapath are required**. Only the **Main Decoder** needs to be updated with the appropriate control signals.

The required control signal values for the `addi` instruction are summarized below.

| Control Signal | Value | Description |
|---------------|:-----:|-------------|
| `RegWrite` | `1` | Enables writing the ALU result back to the destination register `rd`. |
| `ImmSrc` | `00` | Selects the I-type immediate (`Instr[31:20]`) and sign-extends it. |
| `ALUSrc` | `1` | Selects the sign-extended immediate as the second ALU operand (`SrcB`). |
| `MemWrite` | `0` | No data memory write operation is performed. |
| `Branch` | `0` | The instruction does not perform a branch operation. |
| `ResultSrc` | `0` | The value written back to the register file comes directly from the ALU. |
| `ALUOp` | `10` | Allows the ALU Decoder to determine the required ALU operation. |

For the `addi` instruction:

- `funct3 = 000`
- `op5 = 0`

These values are decoded by the **ALU Decoder**, which generates:

```text
ALUControl = 000
```

This configures the ALU to perform an **addition** operation between the register operand and the sign-extended immediate.

An additional benefit of this implementation is that it automatically supports several other **I-type ALU instructions**, including:

- `andi`
- `ori`
- `slti`

These instructions share the same opcode (`0010011`) and require identical Main Decoder control signals. They differ only in the `funct3` field, which is already interpreted by the **ALU Decoder** to generate the appropriate `ALUControl` signal. Consequently, once the Main Decoder recognizes the I-type ALU opcode, these instructions are supported without requiring any additional datapath modifications.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-4%20Main%20Decoder%20truth%20table%20enhanced%20to%20support%20addi.png" width="1000">
</p>

<p align="center">
  <em>Table-4 Main Decoder truth table enhanced to support <code>addi</code></em>
</p>

### Supporting the `jal` Instruction

The `jal` (*Jump and Link*) instruction performs two operations simultaneously:

1. Stores the return address (`PC + 4`) into the destination register `rd`.
2. Updates the **Program Counter (`PC`)** to the jump target address.

```assembly
jal rd, imm
```

The jump target address is computed as:

```text
PC + imm
```

where `imm` is a **21-bit signed immediate** encoded within the instruction.

Unlike the `addi` instruction, supporting `jal` requires **both datapath and control unit enhancements**, since the processor must generate a new immediate format, write `PC + 4` back to the register file, and update the Program Counter with the jump target address.

#### Datapath Modifications

Most of the hardware required to execute the `jal` instruction already exists in the datapath. The processor is already capable of:

- Computing `PC + 4`.
- Adding the Program Counter (`PC`) to a sign-extended immediate.
- Selecting the computed target address as the next Program Counter (`PCNext`).
- Writing a value back to the register file.

Therefore, only two modifications are required:

- **Extend Unit Enhancement:** Modify the **Immediate Generator (Extend Unit)** to support the **21-bit J-type immediate** used by the `jal` instruction. The least significant bit (`LSB`) of this immediate is always `0`, while the remaining 20 bits are assembled from the instruction fields (`Instr[31:12]`) before being sign-extended.

- **Result Multiplexer Enhancement:** Expand the **Result Multiplexer** to include `PCPlus4` (`PC + 4`) as an additional input. This allows the processor to write the return address into the destination register `rd`.

#### Control Unit Modifications

The Control Unit must also be updated to support the `jal` instruction.

A new control signal, **`Jump`**, is introduced. This signal is ORed with the existing branch logic to generate the **`PCSrc`** signal.

When:

- `Jump = 1`

the processor selects **`PCTarget`** (the computed jump target address) as the next value of the Program Counter.

This enables unconditional jumps while reusing the existing PC selection hardware.

#### Control Signals for `jal`

A new entry is added to the **Main Decoder** truth table with the following control signal values:

| Control Signal | Value | Description |
|---------------|:-----:|-------------|
| `RegWrite` | `1` | Writes the return address (`PC + 4`) into register `rd`. |
| `ResultSrc` | `10` | Selects `PCPlus4` as the value written back to the register file. |
| `ImmSrc` | `11` | Selects the 21-bit J-type immediate for sign extension. |
| `ALUSrc` | `X` | Don't care, since the ALU is not used. |
| `ALUOp` | `XX` | Don't care, as no ALU operation is required. |
| `MemWrite` | `0` | No memory write operation is performed. |
| `Branch` | `0` | The instruction is not a conditional branch. |
| `Jump` | `1` | Selects the jump target address as the next Program Counter (`PC`). |

With these datapath and controller enhancements, the processor can correctly execute the `jal` instruction by storing the return address in the destination register while simultaneously transferring control to the specified jump target.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-16%20Enhanced%20datapath%20for%20jal.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-i-6 Enhanced datapath for <code>jal</code></em>
</p>
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-5%20ImmSrc%20encoding..png" width="1000">
</p>

<p align="center">
  <em>Table-5 <code>ImmSrc</code> encoding</em>
</p>


## Performance Analysis

The execution time of a processor depends on three primary factors:

- **Instruction Count (IC)** – Total number of instructions executed.
- **Cycles Per Instruction (CPI)** – Average number of clock cycles required to execute each instruction.
- **Clock Cycle Time (`T<sub>c</sub>`)** – Duration of one clock cycle.

The overall execution time is therefore given by:

```text
Execution Time = Instruction Count × CPI × Clock Cycle Time
```

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-17%20Enhanced%20control%20unit%20for%20jal.png" width="500">
</p>

<p align="center">
  <em>Figure: Fig-i-7 Enhanced control unit for <code>jal</code></em>
</p>

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-6%20Main%20Decoder%20truth%20table%20enhanced%20to%20support%20jal.png" width="1000">
</p>

<p align="center">
  <em>Table-6 Main Decoder truth table enhanced to support <code>jal</code></em>
</p>
For the implemented **single-cycle RISC-V processor**, every instruction completes within **one clock cycle**. Therefore,

- **CPI = 1**

Since every instruction must finish within a single clock period, the clock cycle must be long enough to accommodate the **slowest instruction**. Consequently, the processor's operating frequency is determined by the **critical path** of the datapath.

### Critical Path

Among all supported instructions, the **`lw` (Load Word)** instruction has the longest execution path because it accesses both the instruction memory and the data memory while also performing address calculation and register write-back.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-18%20Critical%20path%20for%20lw.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-i-8 Critical path for <code>lw</code></em>
</p>

The critical path follows the sequence below:

1. The **Program Counter (`PC`)** updates on the rising edge of the clock.
2. **Instruction Memory** fetches the instruction.
3. The **Register File** reads the source register (`rs1`) to produce `SrcA`.
4. Simultaneously, the **Immediate Generator (Extend Unit)** sign-extends the immediate selected by `ImmSrc`, and the **Source B Multiplexer** selects it as `SrcB`.
5. The **ALU** computes the effective memory address by adding `SrcA` and `SrcB`.
6. **Data Memory** reads the data stored at the computed address.
7. The **Result Multiplexer** selects the memory output (`ReadData`) as the value to be written back.
8. Finally, the data must satisfy the **Register File setup time** before the next rising clock edge so that it can be written correctly.

> **Note:** The `lw` instruction does not use the second read port (`A2/RD2`) of the Register File.

The complete clock cycle time for the single-cycle processor is therefore expressed as:

```text
Tc_single = tPCQ + tIMEM + tRFread + tDecoder + tExtend + tMUX
          + tALU + tDMEM + tMUX + tRFsetup
```

In most hardware implementations, the **ALU**, **memories**, and **Register File** contribute significantly more delay than the decoder, immediate generator, or multiplexers. As a result, the actual critical path is dominated by these major components, allowing the clock cycle time to be approximated as:

```text
Tc_single = tPCQ + tIMEM + tRFread + tALU
          + tDMEM + tMUX + tRFsetup
```

The exact propagation delays depend on the target fabrication technology and hardware implementation.

### Impact on Processor Performance

Although other instructions, such as **R-type arithmetic instructions**, have shorter execution paths because they do not access the data memory, the processor still operates with a **fixed clock period**.

Since the design follows **synchronous sequential principles**, every instruction must execute within the same clock period. Therefore, the clock frequency is always determined by the **slowest instruction (`lw`)**, causing faster instructions to complete earlier but still wait until the next clock edge before execution can continue.

---

## Single-Cycle Processor Performance Example

Consider a **7 nm CMOS** implementation of the single-cycle RISC-V processor with the component delays specified in **Table 7.7**.

Using the simplified critical path equation:

```text
Tc_single = tPCQ + tIMEM + tRFread + tALU
          + tDMEM + tMUX + tRFsetup
```

Substituting the given delays:

```text
Tc_single = 40 + 200 + 200 + 100 + 120 + 30 + 60
          = 750 ps
```

Thus, the processor requires **750 ps** to complete each instruction.

For a program consisting of **100 billion instructions**:

- **Instruction Count = 100 × 10⁹**
- **CPI = 1**
- **Clock Cycle Time = 750 ps**

The total execution time becomes:

```text
Execution Time
= (100 × 10⁹) × (1) × (750 × 10⁻¹²)

= 75 seconds
```

Therefore, the program requires **75 seconds** to execute on the single-cycle processor.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Table-7%20Delay%20of%20circuit%20elements.png" width="600">
</p>

<p align="center">
  <em>Table-7 Delay of circuit elements</em>
</p>

# Multicycle Processor

The **single-cycle processor** provides a simple and straightforward implementation of the RISC-V architecture. However, this simplicity comes with several limitations that reduce its overall efficiency and increase hardware cost.

## Limitations of the Single-Cycle Processor

The single-cycle design has three major drawbacks:

- **Separate Instruction and Data Memories:** The processor requires independent memories for instructions and data, whereas most practical systems use a **single unified memory** to store both.

- **Long Clock Cycle:** Every instruction must complete within a single clock cycle. Consequently, the clock period is determined by the **slowest instruction** (`lw`), forcing simpler instructions to wait unnecessarily even though they could finish much sooner.

- **Higher Hardware Cost:** The datapath requires **three separate adders**—one inside the **ALU** and two dedicated to **Program Counter (PC)** calculations. Since fast adders are relatively expensive hardware components, this increases the overall implementation cost.

## Motivation for a Multicycle Processor

The **multicycle processor** overcomes these limitations by dividing the execution of each instruction into **multiple shorter steps** rather than completing the entire instruction in a single clock cycle.

Instead of performing every operation simultaneously, hardware resources are **reused across multiple clock cycles**. This approach significantly reduces hardware requirements while allowing each clock cycle to be much shorter.

Since the **memory**, **ALU**, and **Register File** contribute the largest propagation delays, the multicycle processor is designed so that **only one of these major functional units is used during each execution step**. This helps keep the duration of every clock cycle approximately equal.

As a result:

- A **single memory** can be shared for both instruction fetches and data accesses, since these operations occur during different clock cycles.
- A **single ALU** can be reused for arithmetic operations, address calculations, branch target computation, and Program Counter updates.
- Only **one adder** is required, eliminating the additional dedicated PC adders used in the single-cycle implementation.

## Variable Instruction Execution Time

Unlike the single-cycle processor, different instructions require **different numbers of execution steps**.

- **Simple instructions** complete in fewer clock cycles.
- **More complex instructions**, such as memory accesses, require additional execution steps.

This allows simpler instructions to finish sooner instead of waiting for the worst-case execution time of more complex instructions.

## Design Methodology

The multicycle processor is developed using the same overall design methodology as the single-cycle processor.

The design process consists of the following stages:

1. **Datapath Design**
   - Connect the architectural state elements and memory using combinational logic.
   - Introduce additional **non-architectural state elements** to temporarily store intermediate values between execution steps.

2. **Controller Design**
   - Since the control signals change during each step of instruction execution, the controller is implemented as a **Finite State Machine (FSM)** rather than simple combinational logic.

3. **Performance Analysis**
   - Evaluate the performance of the multicycle processor.
   - Compare its execution characteristics, hardware utilization, and efficiency with those of the single-cycle processor.

 ## Multicycle Datapath

As with the single-cycle processor, the design of the multicycle processor begins with the **architectural state elements** and the processor memory. These state elements form the foundation of the datapath and are gradually connected with combinational logic to support the execution of every instruction.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-19%20State%20Elements%20with%20unified%20instruction_%26Data%20memory.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-17 State elements with unified Instruction &amp; Data Memory</em>
</p>

A significant difference from the single-cycle design is the organization of memory. Instead of using **separate instruction and data memories**, the multicycle processor employs a **single unified memory** for storing both instructions and data.

This approach is possible because instruction fetch and data access occur in **different clock cycles**, allowing the same memory hardware to be reused without conflicts. Consequently, the processor no longer requires two independent memory blocks, making the design more practical and reducing hardware cost.

The **Program Counter (`PC`)** and the **Register File** remain unchanged from the single-cycle implementation and continue to represent the architectural state of the processor.

## Instruction Fetch

The execution of every instruction begins with the **Instruction Fetch (IF)** stage.

During this stage:

1. The **Program Counter (`PC`)** supplies the address of the instruction to be executed.
2. This address is connected directly to the address input of the unified memory.
3. The memory reads the instruction stored at that address.
4. Instead of being used immediately, the fetched instruction is stored in a new **non-architectural register** called the **Instruction Register (`IR`)**.

The **Instruction Register (`IR`)** preserves the fetched instruction for subsequent execution stages, allowing the unified memory to be reused later for data accesses while the processor continues decoding and executing the current instruction.

To control when a new instruction is loaded, the `IR` includes a dedicated **write enable** signal:

- **`IRWrite`** – When asserted, the fetched instruction from memory is loaded into the Instruction Register (`IR`). When deasserted, the current instruction stored in the `IR` is retained for the remaining execution cycles.


## Datapath for the `lw` Instruction

As with the single-cycle processor, the **`lw` (Load Word)** instruction is used as the starting point for constructing the multicycle datapath. Rather than completing the entire instruction in a single clock cycle, the multicycle processor divides its execution into several sequential stages, each performing a specific task.

### Step 1: Instruction Fetch

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-20%20Fetch%20instruction%20from%20memory_multicycle.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-19 Fetch instruction from memory (Multicycle)</em>
</p>

The execution begins by fetching the instruction from the unified memory.

- The **Program Counter (`PC`)** provides the instruction address.
- The unified memory reads the instruction stored at that address.
- The fetched instruction is loaded into the **Instruction Register (`IR`)** when the `IRWrite` signal is asserted.
- During this same clock cycle, the processor also computes **`PC + 4`** using the ALU, preparing the address of the next sequential instruction.

---

### Step 2: Register Read and Immediate Generation

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-21%20Read%20one%20source%20from%20register%20file%20and%20extend%20second%20source%20%20from%20imediate%20field.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-20 Read one source from Register File and extend second source from immediate field</em>
</p>

After the instruction has been fetched, the processor decodes the required operands.

The source register is specified by the **`rs1`** field (`Instr[19:15]`), which is connected to the **`A1`** input of the Register File.

During this stage:

- The Register File reads the contents of register `rs1`.
- The output (`RD1`) is stored in a new **non-architectural register** called **`A`**.
- The instruction's **12-bit immediate** (`Instr[31:20]`) is sign-extended by the **Immediate Generator (Extend Unit)** to produce **`ImmExt`**.

As in the single-cycle processor, the Extend Unit uses the **`ImmSrc`** control signal to determine whether the instruction contains a:

- 12-bit immediate
- 13-bit immediate
- 21-bit immediate

Although `ImmExt` is used across multiple execution stages, it is **not stored in a separate register**. Since it is generated directly from the instruction stored in the `IR`, its value remains constant throughout the execution of the current instruction.

---

### Step 3: Effective Address Calculation

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-22%20Add%20base%20address%20to%20offset.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-21 Add base address to offset</em>
</p>

The effective memory address is obtained by adding the base address from register `rs1` to the sign-extended immediate.

During this stage:

- The ALU receives:
  - `A` as the first operand.
  - `ImmExt` as the second operand.
- `ALUControl` is set to `000` to perform an addition.
- The computed address is stored in another **non-architectural register** called **`ALUOut`**.

This register preserves the calculated address for the subsequent memory access stage.

---

### Step 4: Data Memory Access

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-23%20Load%20data%20from%20memory.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-22 Load data from memory</em>
</p>

Once the effective address has been computed, the processor accesses the unified memory to read the required data.

To allow the same memory to be used for both instruction fetches and data accesses, an **Address Multiplexer** is placed before the memory.

The memory address (`Adr`) is selected from:

- `PC` during the **Instruction Fetch** stage.
- `ALUOut` during the **Data Memory Access** stage.

This selection is controlled by the **`AdrSrc`** signal.

The data read from memory is then stored in another **non-architectural register** called **`Data`**.

The addition of the Address Multiplexer enables the unified memory to be reused efficiently during different stages of instruction execution. Consequently, the value of `AdrSrc` changes across different clock cycles under the control of the processor's **Finite State Machine (FSM)**.

---

### Step 5: Write Back

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-24%20Write%20data%20back%20to%20register%20file.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-23 Write data back to Register File</em>
</p>

In the final stage, the loaded data is written back to the destination register.

The destination register is specified by the **`rd`** field (`Instr[11:7]`).

Instead of connecting the **`Data`** register directly to the Register File, a **Result Multiplexer** is introduced. This multiplexer selects the value to be written back from either:

- `ALUOut`
- `Data`

The selected value appears on the **`Result`** bus and is connected to the Register File write-data input (`WD3`).

This additional multiplexer makes the datapath more flexible, allowing future instructions to write either an ALU result or memory data back to the Register File using the same write-back path.

During this stage:

- `RegWrite = 1`

allowing the selected result to be written into the destination register.

---

### Program Counter Update

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-25%20Increment%20PC%20by%204.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-24 Increment Program Counter (<code>PC</code>) by 4</em>
</p>

While the `lw` instruction progresses through its execution stages, the processor must also update the **Program Counter (`PC`)** to point to the next instruction.

Unlike the single-cycle processor, which requires a dedicated adder for this purpose, the multicycle processor **reuses the existing ALU** during the **Instruction Fetch** stage because it is otherwise idle.

To support this reuse, two additional multiplexers are introduced at the ALU inputs.

The first multiplexer (**`ALUSrcA`**) selects between:

- `PC`
- Register `A`

The second multiplexer selects between:

- Constant `4`
- `ImmExt`
- Additional inputs required by other instructions

During instruction fetch:

- `SrcA = PC`
- `SrcB = 4`

The ALU computes:

```text
PC + 4
```

The computed value is selected by the **Result Multiplexer** and written back into the **Program Counter**.

The **`PCWrite`** control signal enables the Program Counter to be updated only during the appropriate execution cycles.

With these additions, the multicycle datapath fully supports the execution of the **`lw`** instruction while efficiently reusing hardware resources across multiple clock cycles.


## Extending the Datapath for the `sw` Instruction

The **`sw` (Store Word)** instruction shares much of its execution flow with the **`lw`** instruction. Both instructions compute the effective memory address in the same manner by adding a base address to a sign-extended immediate. However, instead of reading data from memory, the `sw` instruction writes data from the Register File into memory.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-26%20Enhanced%20datapath%20for%20sw%20instruction.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-25 Enhanced datapath for <code>sw</code> instruction</em>
</p>

### Step 1: Instruction Fetch

The processor begins by fetching the `sw` instruction from the unified memory and storing it in the **Instruction Register (`IR`)**. During the same clock cycle, the ALU computes `PC + 4`, preparing the address of the next sequential instruction.

---

### Step 2: Register Read and Immediate Generation

During the second execution stage, the processor reads both source registers from the Register File.

- The **`rs1`** field (`Instr[19:15]`) provides the **base address**.
- The **`rs2`** field (`Instr[24:20]`) specifies the register containing the data to be stored.

The Register File outputs:

- `RD1` → Stored in the **`A`** register.
- `RD2` → Stored in a new **non-architectural register** called **`WriteData`**.

At the same time, the **Immediate Generator (Extend Unit)** sign-extends the instruction's immediate field to produce **`ImmExt`**.

The `WriteData` register temporarily stores the value that will later be written into memory.

---

### Step 3: Effective Address Calculation

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-27%20Enhanced%20datapath%20for%20beq%20target%20address%20calculation.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-26 Enhanced datapath for <code>beq</code> target address calculation</em>
</p>

The processor computes the effective memory address using the ALU.

The ALU performs:

```text
Effective Address = Base Address + ImmExt
```

where:

- Base Address is obtained from register **`A`**.
- `ImmExt` is the sign-extended immediate.

The resulting address is stored in the **`ALUOut`** register for use during the memory access stage.

---

### Step 4: Store Data to Memory

In the final execution stage, the processor writes the data stored in the **`WriteData`** register into memory.

During this stage:

- The **Address Multiplexer** selects **`ALUOut`** as the memory address.
- The contents of the **`WriteData`** register are connected to the memory write-data input (`WD`).
- The **`MemWrite`** control signal is asserted, enabling the memory write operation.

As a result, the value originally stored in register `rs2` is written into the memory location computed during the previous stage.

Unlike the `lw` instruction, the `sw` instruction **does not perform a register write-back**, since its purpose is to update memory rather than the Register File.

## Supporting R-Type Instructions

The datapath developed so far already contains all the hardware required to execute **R-type instructions**.

These instructions:

- Read two source operands from the Register File.
- Perform an arithmetic or logical operation using the ALU.
- Write the computed result back to the destination register.

Since all of the necessary datapath connections already exist, **no additional hardware modifications are required** to support R-type instructions. The execution simply involves selecting the appropriate ALU operation and writing the result back to the Register File.

---

## Extending the Datapath for the `beq` Instruction

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-27%20Enhanced%20datapath%20for%20beq%20target%20address%20calculation.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-26 Enhanced datapath for <code>beq</code> target address calculation</em>
</p>

The **`beq` (Branch if Equal)** instruction compares the contents of two registers and, if they are equal, transfers control to the branch target address.

The branch target address is calculated as:

```text
PCTarget = PC + ImmExt
```

where `ImmExt` is the sign-extended **13-bit branch immediate**.

The datapath already includes the ALU hardware required to compare two register values by performing a subtraction. Therefore, no additional comparison hardware is required.

### Step 1: Preserve the Current Program Counter

During the **Instruction Fetch** stage, the Program Counter is immediately updated to `PC + 4`.

However, the `beq` instruction requires the **original Program Counter** to compute the branch target address.

To preserve this value, the current `PC` is stored in a new **non-architectural register** called **`OldPC`** before the Program Counter is updated.

---

### Step 2: Branch Target Address Calculation

The ALU is not required for register comparison during the second execution stage. Therefore, it is reused to calculate the branch target address.

During this stage:

- **`OldPC`** is selected as `SrcA`.
- **`ImmExt`** is selected as `SrcB`.
- `ALUControl` is set to `000` to perform an addition.

The ALU computes:

```text
PCTarget = OldPC + ImmExt
```

The calculated branch target address is then stored in the **`ALUOut`** register for later use.

---

### Step 3: Register Comparison

In the third execution stage, the ALU compares the two source registers.

The ALU performs:

```text
RD1 - RD2
```

If both register values are equal, the ALU asserts the **`Zero`** signal.

When:

- `Zero = 1`

the Control Unit asserts **`PCWrite`**, allowing the Program Counter to be updated.

The **Result Multiplexer** selects the value stored in **`ALUOut`**, which contains the previously computed branch target address, and writes it into the Program Counter.

If the registers are not equal, the Program Counter retains its sequential value (`PC + 4`), and execution continues with the next instruction.

---

## Completed Multicycle Datapath

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-28%20Complete%20Multucycle%20Processor.png" width="1200">
</p>

<p align="center">
  <em>Figure: Fig-27 Complete Multicycle Processor</em>
</p>

With support for **`lw`**, **`sw`**, **R-type instructions**, and **`beq`**, the multicycle datapath is complete.

The overall design methodology closely follows that of the single-cycle processor, where hardware components are systematically connected to execute each instruction. The primary difference is that instruction execution is divided into multiple clock cycles.

To support this multicycle execution:

- **Non-architectural registers** are introduced to store intermediate results between execution stages.
- A **single unified memory** is shared for both instruction fetches and data accesses.
- The **ALU** is reused across different stages for address calculation, arithmetic operations, Program Counter updates, and branch target computation.

By reusing hardware resources across multiple execution steps, the multicycle processor significantly reduces hardware cost while maintaining support for the required instruction set.

The next step is to design the **Finite State Machine (FSM)** controller, which generates the appropriate sequence of control signals for each execution stage of every instruction.

--- 

## Multicycle Control and FSM Execution

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-29%20Multicycle%20Control%20Unit.png" width="450">
</p>

<p align="center">
  <em>Figure: Fig-28 Multicycle Control Unit</em>
</p>

Unlike the single-cycle processor, where the control signals are generated entirely by a **combinational Main Decoder**, the multicycle processor requires the control signals to change from one execution stage to another. As a result, the control unit is implemented using a **Finite State Machine (FSM)** that generates the appropriate sequence of control signals across multiple clock cycles.

The multicycle control unit consists of three primary components:

- **Main FSM**
- **ALU Decoder**
- **Instruction Decoder (`Instr Decoder`)**

The **ALU Decoder** remains identical to that used in the single-cycle processor. It receives the `ALUOp` control signal along with the instruction function fields and generates the appropriate **`ALUControl`** signal required by the ALU.

The major change is the replacement of the **Main Decoder** with the **Main FSM**. Instead of producing all control signals simultaneously, the Main FSM generates different control signals for each execution stage of an instruction.

An additional **Instruction Decoder** is also introduced. This combinational block generates the **`ImmSrc`** control signal directly from the instruction opcode, allowing the **Immediate Generator (Extend Unit)** to select the appropriate immediate format for each instruction.

### Moore Machine Implementation

The **Main FSM** is designed as a **Moore Machine**, meaning that all control outputs depend **only on the current state** of the FSM and not directly on the current inputs.

This approach provides stable control signals throughout each clock cycle and simplifies the overall controller design.

### Control Signals Generated by the Main FSM

The Main FSM generates all of the control signals required by the datapath, including:

- Multiplexer select signals
- Register enable signals
- Memory write enable signals
- Program Counter update signals
- Branch control signals

To simplify the FSM state diagrams presented in the following sections:

- **Multiplexer select signals** are shown **only when their values are significant** for a particular state. Otherwise, they are treated as **don't care** conditions.
- **Enable signals** are shown **only when asserted**. When omitted from a state, they are implicitly assumed to be deasserted (`0`).

The primary enable signals include:

- `RegWrite`
- `MemWrite`
- `IRWrite`
- `PCWrite`
- `Branch`

The following sections develop the complete **state transition diagram** of the Main FSM, illustrating how the processor progresses through the various execution stages for each supported instruction while generating the appropriate sequence of control signals.

## FSM State: Fetch (`S0`)

Every instruction begins execution in the **Fetch** state. After a processor reset, the **Main FSM** enters this state to fetch the next instruction from memory.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-1%20Fetch.png" width="300">
</p>

<p align="center">
  <em>FSM-1 Fetch State (<code>S0</code>)</em>
</p>

During this stage:

- The **Program Counter (`PC`)** supplies the memory address.
- `AdrSrc = 0`, selecting the **PC** as the memory address input.
- The instruction stored at that address is read from the unified memory.
- `IRWrite` is asserted, allowing the fetched instruction to be loaded into the **Instruction Register (`IR`)**.
- Simultaneously, the current value of the **Program Counter** is stored in the **`OldPC`** register. This preserved value is later required by branch and jump instructions for target address calculations.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `AdrSrc` | `0` | Selects the Program Counter (`PC`) as the memory address. |
| `IRWrite` | `1` | Loads the fetched instruction into the Instruction Register (`IR`). |

At the completion of the **Fetch** state, the processor has successfully fetched the instruction while preserving the original Program Counter value for subsequent execution stages.

---

## FSM State: Decode (`S1`)

After the instruction has been fetched, the processor enters the **Decode** state.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-2%20Decode.png" width="550">
</p>

<p align="center">
  <em>FSM-2 Decode State (<code>S1</code>)</em>
</p>

During this stage, the instruction is decoded to determine the operation that must be performed based on its:

- Opcode (`op`)
- Function field (`funct3`)
- Function bit (`funct7[5]`)

At the same time, the processor reads the required source operands from the Register File.

The Register File outputs are stored in the non-architectural registers:

- `RD1` → `A`
- `RD2` → `WriteData`

No explicit control signals are required for these operations, since the Register File and Instruction Decoder operate combinationally.

Once the Decode stage completes, the processor has all the information necessary to determine the appropriate execution path for the current instruction.

---

## FSM State: Memory Address Calculation (`S2`)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-3%20Memory%20Address%20Comupation.png" width="500">
</p>

<p align="center">
  <em>FSM-3 Memory Address Computation State (<code>S2</code>)</em>
</p>

For the **`lw`** instruction, the next execution stage calculates the effective memory address.

The ALU computes:

```text
Effective Address = Base Address + ImmExt
```

where:

- `A` (loaded from `rs1`) is selected as the first ALU operand.
- `ImmExt` is selected as the second ALU operand.

The resulting address is stored in the **`ALUOut`** register for use during the memory access stage.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ALUSrcA` | `10` | Selects register `A` as the first ALU operand. |
| `ALUSrcB` | `01` | Selects the sign-extended immediate (`ImmExt`) as the second ALU operand. |
| `ImmSrc` | `00` | Selects the I-type immediate for sign extension. |
| `ALUOp` | `00` | Configures the ALU to perform an addition. |

At the end of this state, the computed effective memory address is available in the **`ALUOut`** register, preparing the processor for the memory access stage of the `lw` instruction.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-30%20Data%20flow%20during%20Fetch%2C%20Decode%2C%20and%20MemAdr%20states.png" width="1100">
</p>

<p align="center">
  <em>Figure: Fig-29 Data flow during Fetch, Decode, and MemAdr states</em>
</p>


## FSM State: Memory Read (`S3`)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-4%20Memory%20Read%20(MemRead)%20and%20memory%20Write%20back%20(MemWB)%20States.png" width="450">
</p>

<p align="center">
  <em>FSM-4 Memory Read (<code>MemRead</code>) and Memory Write Back (<code>MemWB</code>) States</em>
</p>

Once the effective memory address has been computed and stored in the **`ALUOut`** register, the processor enters the **Memory Read** state.

During this stage:

- The **Address Multiplexer** selects `ALUOut` as the memory address.
- The unified memory performs a read operation using the calculated address.
- The value returned by memory is stored in the **`Data`** register for use during the next stage.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `AdrSrc` | `1` | Selects `ALUOut` as the memory address. |

At the end of this state, the requested memory data is available in the **`Data`** register.

---

## FSM State: Memory Write Back (`S4`)

The **Memory Write Back (MemWB)** state completes the execution of the **`lw`** instruction.

During this stage, the data previously loaded into the **`Data`** register is written back to the destination register specified by the **`rd`** field (`Instr[11:7]`).

The **Result Multiplexer** selects the contents of the `Data` register, and the Register File writes the selected value into the destination register.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ResultSrc` | `01` | Selects the `Data` register as the write-back source. |
| `RegWrite` | `1` | Enables writing the loaded data into the Register File. |

After the write-back operation is complete, the **`lw`** instruction has finished execution, and the FSM returns to the **Fetch (`S0`)** state to begin executing the next instruction.

---

## Updating the Program Counter During Fetch

Before fetching the next instruction, the processor must increment the **Program Counter (`PC`)**.

One possible solution would be to introduce a dedicated FSM state for updating the Program Counter. However, this would unnecessarily increase the number of execution cycles.

Instead, the multicycle processor takes advantage of the fact that the **ALU is idle during the Fetch state** and reuses it to compute **`PC + 4`** while the instruction is simultaneously being fetched from memory.

During the **Fetch** state:

- `ALUSrcA = 00` selects the **Program Counter (`OldPC`)** as the first ALU operand.
- `ALUSrcB = 10` selects the constant **4** as the second ALU operand.
- `ALUOp = 00` configures the ALU to perform an addition.

The ALU computes:

```text
PC + 4
```

To update the Program Counter:

- `ResultSrc = 10` selects **`ALUResult`** as the value written back.
- `PCUpdate = 1` enables the Program Counter to load the computed value.

By performing the Program Counter update simultaneously with instruction fetch, the processor avoids introducing an additional execution state, thereby improving overall efficiency without requiring any extra hardware.


<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-31%20Data%20flow%20during%20MemRead%20and%20MemWB.png" width="1100">
</p>

<p align="center">
  <em>Figure: Fig-30 Data flow during MemRead and MemWB states</em>
</p>


## Extending the FSM for the `sw` Instruction

After supporting the **`lw`** instruction, the **Main FSM** is extended to execute the **`sw` (Store Word)** instruction.

Like all instructions in the multicycle processor, the `sw` instruction begins by passing through the common **Fetch (`S0`)** and **Decode (`S1`)** states.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-5%20Incrementing%20PC%20in%20the%20Fetch%20State.png" width="300">
</p>

<p align="center">
  <em>FSM-5 Incrementing Program Counter (<code>PC</code>) in the Fetch State</em>
</p>


During these stages:

- The instruction is fetched from memory.
- The source registers are read from the Register File.
- The immediate value is sign-extended.
- The base address and data to be stored are placed into the non-architectural registers.

The processor then enters the **Memory Address Computation (`S2`)** state, which is shared with the `lw` instruction.

During this state, the ALU computes the effective memory address:

```text
Effective Address = Base Address + ImmExt
```

The calculated address is stored in the **`ALUOut`** register.

---

## FSM State: Memory Write (`S5`)

After the memory address has been computed, the `sw` instruction proceeds to the **Memory Write (`MemWrite`)** state.

During this stage:

- The **Address Multiplexer** selects **`ALUOut`** as the memory address.
- The contents of the **`WriteData`** register, which holds the value originally read from register `rs2`, are connected directly to the memory write-data input (`WD`).
- The **`MemWrite`** control signal is asserted, enabling the memory write operation.

As a result, the value stored in register `rs2` is written into the memory location specified by the effective address.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `AdrSrc` | `1` | Selects `ALUOut` as the memory address. |
| `MemWrite` | `1` | Enables writing data into memory. |

Unlike the **`lw`** instruction, the `sw` instruction **does not perform a write-back stage**, since its purpose is to update memory rather than the Register File.

After the memory write operation is complete, the instruction has finished execution, and the **Main FSM** transitions directly back to the **Fetch (`S0`)** state to begin processing the next instruction.

The first two FSM states (**Fetch** and **Decode**) remain unchanged, while the newly added **Memory Write (`S5`)** state extends the controller to support store operations.


<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-32%20Data%20flow%20while%20incrementing%20PC%20in%20the%20Fetch%20state.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-31 Data flow while incrementing Program Counter (<code>PC</code>) in the Fetch state</em>
</p>

## Extending the FSM for R-Type Instructions

After completing the common **Fetch (`S0`)** and **Decode (`S1`)** states, **R-type instructions** proceed to the **ExecuteR** state, where the required arithmetic or logical operation is performed by the ALU.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-6%20Memory%20write.png" width="450">
</p>

<p align="center">
  <em>FSM-6 Memory Write (<code>MemWrite</code>) State</em>
</p>

During this stage, the processor selects the two source operands read from the Register File and forwards them to the ALU.

- `A`, containing the value of `rs1`, is selected as the first ALU operand.
- `WriteData`, containing the value of `rs2`, is selected as the second ALU operand.

Unlike load and store instructions, the specific ALU operation depends on the instruction being executed. Therefore, the **ALU Decoder** uses the instruction's function fields (`funct3` and `funct7`) together with `ALUOp` to generate the appropriate **`ALUControl`** signal.

The computed result is stored in the **`ALUOut`** register at the end of the execution stage.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-33%20Data%20flow%20during%20the%20memory%20write%20(MemWrite)%20state.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-32 Data flow during the Memory Write (<code>MemWrite</code>) state</em>
</p>

### FSM State: ExecuteR (`S6`)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-7%20Execute%20R-type(ExecuteR)%20and%20ALU%20%20wtiteBack%20(ALUWB)%20States.png" width="450">
</p>

<p align="center">
  <em>FSM-7 Execute R-type (<code>ExecuteR</code>) and ALU Write Back (<code>ALUWB</code>) States</em>
</p>

During the **ExecuteR** state:

- `ALUSrcA = 10` selects register `A` (`rs1`) as the first ALU operand.
- `ALUSrcB = 00` selects `WriteData` (`rs2`) as the second ALU operand.
- `ALUOp = 10` enables the ALU Decoder to determine the required arithmetic or logical operation.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ALUSrcA` | `10` | Selects register `A` (`rs1`) as the first ALU operand. |
| `ALUSrcB` | `00` | Selects `WriteData` (`rs2`) as the second ALU operand. |
| `ALUOp` | `10` | Allows the ALU Decoder to determine the required ALU operation. |

---

## FSM State: ALU Write Back (`S7`)

After the ALU operation is completed, the processor enters the **ALU Write Back (`ALUWB`)** state.

The value stored in the **`ALUOut`** register is selected as the write-back result and written into the destination register specified by the `rd` field.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ResultSrc` | `00` | Selects `ALUOut` as the write-back source. |
| `RegWrite` | `1` | Enables writing the ALU result into the Register File. |

Once the result has been written back, the instruction is complete, and the FSM transitions back to the **Fetch (`S0`)** state.

---

# Extending the FSM for the `beq` Instruction

The **`beq` (Branch if Equal)** instruction requires two operations:

1. Compute the branch target address.
2. Compare the two source registers.

To improve efficiency, the multicycle processor performs the branch target address calculation during the **Decode** state, since the ALU is otherwise unused at that time.

---

## Branch Target Address Calculation During Decode

While decoding the instruction, the ALU computes:

```text
Branch Target = OldPC + ImmExt
```

where:

- `OldPC` contains the Program Counter value before it was incremented.
- `ImmExt` is the sign-extended 13-bit branch offset.

The computed branch target address is stored in the **`ALUOut`** register for later use.

### Control Signals During Decode

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ALUSrcA` | `01` | Selects `OldPC` as the first ALU operand. |
| `ALUSrcB` | `01` | Selects the branch immediate (`ImmExt`) as the second ALU operand. |
| `ALUOp` | `00` | Configures the ALU to perform addition. |

By performing this computation during the Decode stage, no additional execution cycle is required solely for branch address calculation.

---

## FSM State: BEQ (`S8`)

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-9%20Enhanced%20Decode%20state%2C%20with%20branch%20target%20address%20calculation%2C%20and%20BEQ%20state.png" width="600">
</p>

<p align="center">
  <em>FSM-9 Enhanced Decode State with Branch Target Address Calculation and <code>BEQ</code> State</em>
</p>

After the Decode stage, the processor enters the **BEQ** state.

During this state, the ALU compares the two source registers by performing a subtraction:

```text
rs1 - rs2
```

If both operands are equal, the subtraction result becomes zero, causing the ALU to assert the **`Zero`** signal.

The **Branch** control signal is asserted during this state. If both:

- `Branch = 1`
- `Zero = 1`

then the Program Counter is updated with the branch target address previously stored in **`ALUOut`**.

The branch target address reaches the Program Counter through the **Result Multiplexer**, which selects `ALUOut` as the next Program Counter value.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ALUSrcA` | `10` | Selects register `A` (`rs1`) as the first ALU operand. |
| `ALUSrcB` | `00` | Selects `WriteData` (`rs2`) as the second ALU operand. |
| `ALUOp` | `01` | Configures the ALU to perform subtraction. |
| `Branch` | `1` | Enables conditional Program Counter update when `Zero = 1`. |
| `ResultSrc` | `00` | Selects `ALUOut` as the next Program Counter value. |

If the registers are equal, execution continues from the computed branch target. Otherwise, the Program Counter retains its sequential value (`PC + 4`), and execution proceeds with the next instruction.

With the addition of the **ExecuteR**, **ALU Write Back**, and **BEQ** states, the Main FSM is capable of controlling the execution of all supported instructions in the multicycle processor.


<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Data%20flow%20during%20the%20ExecuteR%20and%20ALUWB%20states.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-33 Data flow during the <code>ExecuteR</code> and <code>ALUWB</code> states</em>
</p>

# Supporting Additional Instructions

After completing the multicycle datapath and FSM for the basic instruction set, the processor can be extended to support additional instructions with only minor modifications. As with the single-cycle processor, we now consider two important instruction groups:

- **I-type ALU instructions** (`addi`, `andi`, `ori`, `slti`)
- **Jump and Link (`jal`)**
- 
<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-34%20Data%20flow%20during%20Decode%20and%20BEQ%20states.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-34 Data flow during Decode and <code>BEQ</code> states</em>
</p>

One of the major advantages of the multicycle processor is that these instructions can be supported **without introducing any additional datapath hardware**. Only the **Main FSM** requires new execution states and state transitions.

---

## Supporting I-Type ALU Instructions

The **I-type ALU instructions** (`addi`, `andi`, `ori`, and `slti`) are very similar to their corresponding **R-type** instructions.

The only difference is the source of the second ALU operand:

- **R-type instructions** use the contents of register `rs2`.
- **I-type instructions** use the sign-extended immediate (`ImmExt`).

Since the datapath already contains the necessary multiplexers and immediate generation hardware, no new hardware components are required.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-10%20Enhanced%20Main%20FSM%20ExecuteI%20and%20JAL%20states.png" width="700">
</p>

<p align="center">
  <em>FSM-10 Enhanced Main FSM with <code>ExecuteI</code> and <code>JAL</code> States</em>
</p>

### FSM State: ExecuteI (`S9`)

To support these instructions, the Main FSM introduces a new **ExecuteI** state.

This state performs the required arithmetic or logical operation using:

- Register `A` (`rs1`) as the first ALU operand.
- `ImmExt` as the second ALU operand.

Unlike the `ExecuteR` state, where the second operand comes from the Register File, the ExecuteI state selects the sign-extended immediate.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ALUSrcA` | `10` | Selects register `A` (`rs1`) as the first ALU operand. |
| `ALUSrcB` | `01` | Selects `ImmExt` as the second ALU operand. |
| `ALUOp` | `10` | Allows the ALU Decoder to determine the required ALU operation from the instruction fields. |

After completing the ALU operation, the computed result is stored in the **`ALUOut`** register.

The instruction then proceeds to the existing **ALU Write Back (`ALUWB`)** state, where the value in `ALUOut` is written into the destination register.

By introducing only a single new execution state, the processor is able to support all four I-type ALU instructions.

---

## Supporting the `jal` Instruction

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-35%20Data%20flow%20during%20the%20JAL%20state.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-34 Data flow during the <code>JAL</code> state</em>
</p>

The **`jal` (Jump and Link)** instruction can also be supported without modifying the datapath.

Only the **Main FSM** requires additional execution states.

Like every other instruction, `jal` begins with the common:

- **Fetch (`S0`)**
- **Decode (`S1`)**

states.

---

### Jump Target Address Calculation

During the **Decode** state, the processor computes the jump target address.

The **Instruction Decoder** sets:

```text
ImmSrc = 11
```

so that the Immediate Generator produces the **21-bit jump immediate**.

The ALU then computes:

```text
Jump Target = OldPC + ImmExt
```

The computed jump target address is stored in the **`ALUOut`** register.

---

## FSM State: JAL (`S10`)

After the Decode stage, execution proceeds to the **JAL** state.

This state performs two operations simultaneously:

1. Updates the Program Counter with the jump target address.
2. Computes the return address (`PC + 4`).

The ALU calculates:

```text
PC + 4 = OldPC + 4
```

using:

- `OldPC` as the first operand.
- Constant `4` as the second operand.

At the same time:

- `ResultSrc = 00` selects the jump target address stored in `ALUOut`.
- `PCUpdate = 1` enables the Program Counter to load the jump target.

### Control Signals

| Control Signal | Value | Purpose |
|---------------|:-----:|---------|
| `ALUSrcA` | `01` | Selects `OldPC` as the first ALU operand. |
| `ALUSrcB` | `10` | Selects the constant `4` as the second ALU operand. |
| `ALUOp` | `00` | Configures the ALU to perform addition. |
| `ResultSrc` | `00` | Selects the jump target address (`ALUOut`) for updating the Program Counter. |
| `PCUpdate` | `1` | Enables the Program Counter update. |

The jump target address is loaded into the Program Counter, while the computed return address (`PC + 4`) is stored in **`ALUOut`**.

---

## Return Address Write Back

After the **JAL** state, execution proceeds to the existing **ALU Write Back (`ALUWB`)** state.

During this stage, the return address (`PC + 4`), stored in **`ALUOut`**, is written into the destination register (`rd`).

This completes execution of the `jal` instruction, after which the FSM returns to the **Fetch (`S0`)** state to begin processing the next instruction.

---

## Complete Multicycle Main FSM

With the addition of:

- **ExecuteI** for I-type ALU instructions
- **JAL** for jump-and-link instructions

the Main FSM now supports all instructions implemented in the multicycle processor.

The complete FSM state transition diagram illustrates how the controller progresses through the required execution stages for each instruction while generating the appropriate sequence of control signals.

Although the FSM can be implemented manually using conventional finite-state machine design techniques, it is more practical to describe the controller using a **Hardware Description Language (HDL)** such as **Verilog** or **SystemVerilog**, allowing synthesis tools to automatically generate the required hardware implementation.

---

# Performance Analysis

The execution time of a program depends on both the **number of clock cycles required to execute each instruction** and the **duration of each clock cycle**.

Unlike the single-cycle processor, where every instruction completes in exactly one clock cycle, the **multicycle processor** executes different instructions in different numbers of cycles. Although this increases the **Cycles Per Instruction (CPI)**, each clock cycle is significantly shorter because only a portion of the instruction is executed during a single cycle.

## Cycles Per Instruction (CPI)

The number of execution cycles depends on the instruction type.

| Instruction Type | Number of Cycles |
|------------------|:----------------:|
| `beq` | **3** |
| R-type ALU | **4** |
| I-type ALU | **4** |
| `jal` | **4** |
| `sw` | **4** |
| `lw` | **5** |

Since different instructions require different execution times, the **average CPI** depends on the instruction mix of the program being executed.

---

## Average CPI Calculation

For the **SPECINT2000** benchmark, the approximate instruction distribution is:

| Instruction Type | Percentage |
|------------------|-----------:|
| `lw` | 25% |
| `sw` | 10% |
| `beq` | 11% |
| `jal` | 2% |
| R-type and I-type ALU | 52% |

The average CPI is calculated as the weighted sum of the CPI of each instruction multiplied by its occurrence in the benchmark.

```text
Average CPI =
(0.11 × 3)
+ (0.10 + 0.02 + 0.52) × 4
+ (0.25 × 5)
```

Substituting the values,

```text
Average CPI = 4.14
```

Although the worst-case instruction (`lw`) requires **5 cycles**, the average CPI is only **4.14** because the remaining instructions complete in fewer cycles.

---

## Critical Path of the Multicycle Processor

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/Fig-36%20Multicycle%20processor%20potential%20critical%20paths.png" width="1000">
</p>

<p align="center">
  <em>Figure: Fig-36 Multicycle processor potential critical paths</em>
</p>

The multicycle processor was designed so that each execution stage performs only **one major operation**, such as:

- Register File access
- Memory access
- ALU operation

As a result, each clock cycle is significantly shorter than that of the single-cycle processor.

Examining the datapath reveals **two possible critical paths**.

### 1. Program Counter Update Path

This path computes:

```text
PC + 4
```

The critical path passes through:

```text
PC
→ SrcA Multiplexer
→ ALU
→ Result Multiplexer
→ PC
```

This path is responsible for updating the Program Counter during the Fetch stage.

---

### 2. Memory Read Path

The second possible critical path occurs during a load operation.

The path passes through:

```text
ALUOut
→ Result Multiplexer
→ Address Multiplexer
→ Memory
→ Data Register
```

This path determines the delay associated with reading data from memory.

---

## Multicycle Clock Period

After every state transition, the controller must decode the current state and generate the required control signals before the datapath can proceed.

Therefore, the clock period of the multicycle processor is given by:

```text
Tc_multi =
tpcq
+ tdec
+ max(tmux + tALU, tmux + tmem)
+ tsetup
```

or,

```text
Tc_multi =
tpcq + tdec + max(tALU, tmem) + tmux + tsetup
```

The actual numerical value depends on the implementation technology and the delays of the individual hardware components.

---

## Performance Comparison

Using the delays obtained for the **7 nm CMOS** implementation:

```text
Tc_multi =
40 + 25 + 2(30) + 200 + 50
= 375 ps
```

Using:

- **100 billion instructions**
- **Average CPI = 4.14**

the total execution time becomes:

```text
Tmulti =
(100 × 10⁹ instructions)
× (4.14 cycles/instruction)
× (375 × 10⁻¹² s/cycle)

= 155 seconds
```

For comparison, the previously calculated execution time of the **single-cycle processor** was:

```text
Tsingle = 75 seconds
```

Therefore,

```text
Multicycle Processor : 155 seconds
Single-Cycle Processor : 75 seconds
```

Under these assumptions, the **single-cycle processor executes the benchmark faster** than the multicycle processor.

---

## Why is the Multicycle Processor Slower?

One of the primary motivations for designing a multicycle processor was to prevent simple instructions from taking as long as the slowest instruction (`lw`).

However, this example shows that the multicycle processor can still be slower.

There are two main reasons:

- The execution stages are **not perfectly balanced**, meaning some stages still require considerably more time than others.
- Every execution stage incurs additional **clocking overhead**, including the **clock-to-Q delay** and **setup time** of the intermediate registers.

In this implementation, the **90 ps** overhead associated with register clocking is paid during **every execution stage**, rather than once per instruction as in the single-cycle processor.

As a result, the reduction in clock period is not sufficient to compensate for the increase in the number of execution cycles.

---

## Hardware Cost Comparison

Although the multicycle processor is slower in this performance example, it offers several hardware advantages over the single-cycle design.

### Advantages

- Uses a **single unified memory** for both instructions and data.
- Reuses a single **ALU** for multiple operations.
- Eliminates two dedicated adders used in the single-cycle datapath.
- Reduces overall hardware cost by sharing functional units.

### Additional Hardware Required

To support multicycle execution, the processor introduces several extra components:

- Five **non-architectural registers** for storing intermediate results.
- Additional multiplexers for selecting operands, memory addresses, and write-back data.
- A more sophisticated **Finite State Machine (FSM)** controller.

Overall, the multicycle processor represents a trade-off between **hardware cost** and **execution performance**, sacrificing speed in exchange for improved hardware resource utilization and a more economical implementation.

<p align="center">
  <img src="https://raw.githubusercontent.com/soumya-dev-nayak/RISC-V-SINGLE-CYCLE-CORE/main/pics/FSM-11%20Complete%20multicycle%20control%20FSM.png" width="800">
</p>

<p align="center">
  <em>FSM-11 Complete Multicycle Control FSM</em>
</p>
