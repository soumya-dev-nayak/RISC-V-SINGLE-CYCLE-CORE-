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
