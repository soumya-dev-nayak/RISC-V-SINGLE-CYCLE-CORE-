`timescale 1ns/1ps
//=============================================================
// Testbench  –  CPU_top  RISC-V RV32I Single-Cycle
// FULLY UPGRADED with Cycle Monitor + Negative Number Display
//
// HOW TO USE:
//   1. In Instruction_Memory.v uncomment exactly ONE PART block
//   2. In this file uncomment the matching PART initial block
//   3. Compile all .v files and run with vvp
//
// Compile:
//   iverilog -o sim ALU.v ALUDecoder.v ALU_MUX.v SrcA_MUX.v   \
//     CPU_top.v CPU_top_tb.v Data_Memory.v ID_EX_MEM_WB_top.v  \
//     IF_top.v Imm_Gen.v Instruction_Decoder.v                  \
//     Instruction_Memory.v MainDSecoder.v PC.v PC_Mux.v         \
//     PC_Plus_4.v PC_Target.v PC_Top.v Register_Set.v           \
//     WriteBack_MUX.v && vvp sim
//=============================================================

module CPU_top_tb;

    reg clk;
    reg rst;

    CPU_top dut (.clk(clk), .rst(rst));

    //----------------------------------------------------------
    // REGISTER FILE TAPS
    //----------------------------------------------------------
    wire signed [31:0] sx1  = $signed(dut.core.rf.regfile[1]);
    wire signed [31:0] sx2  = $signed(dut.core.rf.regfile[2]);
    wire signed [31:0] sx3  = $signed(dut.core.rf.regfile[3]);
    wire signed [31:0] sx4  = $signed(dut.core.rf.regfile[4]);
    wire signed [31:0] sx5  = $signed(dut.core.rf.regfile[5]);
    wire signed [31:0] sx6  = $signed(dut.core.rf.regfile[6]);
    wire signed [31:0] sx7  = $signed(dut.core.rf.regfile[7]);
    wire signed [31:0] sx8  = $signed(dut.core.rf.regfile[8]);
    wire signed [31:0] sx9  = $signed(dut.core.rf.regfile[9]);
    wire signed [31:0] sx10 = $signed(dut.core.rf.regfile[10]);
    wire signed [31:0] sx11 = $signed(dut.core.rf.regfile[11]);
    wire signed [31:0] sx12 = $signed(dut.core.rf.regfile[12]);
    wire signed [31:0] sx13 = $signed(dut.core.rf.regfile[13]);
    wire signed [31:0] sx14 = $signed(dut.core.rf.regfile[14]);
    wire signed [31:0] sx15 = $signed(dut.core.rf.regfile[15]);
    wire signed [31:0] sx16 = $signed(dut.core.rf.regfile[16]);
    wire signed [31:0] sx17 = $signed(dut.core.rf.regfile[17]);
    wire signed [31:0] sx20 = $signed(dut.core.rf.regfile[20]);
    wire signed [31:0] sx21 = $signed(dut.core.rf.regfile[21]);
    wire signed [31:0] sx22 = $signed(dut.core.rf.regfile[22]);
    wire signed [31:0] sx23 = $signed(dut.core.rf.regfile[23]);
    wire signed [31:0] sx24 = $signed(dut.core.rf.regfile[24]);
    wire signed [31:0] sx25 = $signed(dut.core.rf.regfile[25]);
    wire signed [31:0] sx28 = $signed(dut.core.rf.regfile[28]);

    // Unsigned aliases for comparison checks
    wire [31:0] x5  = dut.core.rf.regfile[5];
    wire [31:0] x6  = dut.core.rf.regfile[6];
    wire [31:0] x10 = dut.core.rf.regfile[10];
    wire [31:0] x24 = dut.core.rf.regfile[24];

    //----------------------------------------------------------
    // DATA MEMORY TAPS  (for sorting result verification)
    //----------------------------------------------------------
    wire signed [31:0] mem0 = $signed(dut.core.dmem.mem[0]);
    wire signed [31:0] mem1 = $signed(dut.core.dmem.mem[1]);
    wire signed [31:0] mem2 = $signed(dut.core.dmem.mem[2]);
    wire signed [31:0] mem3 = $signed(dut.core.dmem.mem[3]);
    wire signed [31:0] mem4 = $signed(dut.core.dmem.mem[4]);

    //For the Monitoring of the Fibonacci Series:
    wire [31:0] reg_x22 = dut.core.rf.regfile[22];
    wire [31:0] reg_x23 = dut.core.rf.regfile[23];
    wire [31:0] reg_x24 = dut.core.rf.regfile[24];

    //----------------------------------------------------------
    // CURRENT PC AND INSTRUCTION (for monitor)
    //----------------------------------------------------------
    wire [31:0] cur_PC    = dut.PC;
    wire [31:0] cur_instr = dut.instr;

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    // ============================================================
    // CYCLE MONITOR  –  active whenever MONITOR_ON = 1
    // Prints every posedge: cycle#, PC, raw hex instruction,
    // and the four most commonly changing loop registers.
    // Toggle by setting MONITOR_ON = 1/0 in the active PART block.
    // ============================================================
    integer        cycle_count;
    reg            MONITOR_ON;

    initial begin
        cycle_count = 0;
        MONITOR_ON  = 0;
    end

    always @(posedge clk) begin
        cycle_count = cycle_count + 1;
        if (MONITOR_ON && !rst) begin
            $display("  [cyc%4d] PC=0x%04X  instr=0x%08X  x5=%0d x6=%0d x8=%0d x10=%0d",
                     cycle_count, cur_PC, cur_instr,
                     $signed(x5), $signed(x6),
                     $signed(dut.core.rf.regfile[8]),
                     $signed(x10));
        end
    end

    // ============================================================
    // PART 1 : ALU + NEGATIVE NUMBERS
    //   Instruction_Memory PART 1 must be active.
    //   Tests: add, sub, and, or, xor, slt, sltu, srai, slli with negatives
    //   Expected: x3=-5  x9=1  x12=-5  x13=120  x17=1
    // ============================================================
    /*
    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;
        rst = 1; #20; rst = 0;
        #250;
        $display("\n================================================");
        $display("  PART 1 : ALU + NEGATIVE NUMBERS TEST");
        $display("  x1=-20, x2=15");
        $display("================================================");
        $display("  x3  = %4d  (expect    -5) [add  x1+x2]",  sx3);
        $display("  x4  = %4d  (expect    35) [sub  x2-x1]",  sx4);
        $display("  x5  = %4d  (expect   -35) [sub  x1-x2]",  sx5);
        $display("  x6  = %4d  (expect    12) [and  x1&x2]",  sx6);
        $display("  x7  = %4d  (expect   -17) [or   x1|x2]",  sx7);
        $display("  x8  = %4d  (expect   -29) [xor  x1^x2]",  sx8);
        $display("  x9  = %4d  (expect     1) [slt  x1<x2]",  sx9);
        $display("  x10 = %4d  (expect     0) [slt  x2<x1]",  sx10);
        $display("  x11 = %4d  (expect     0) [sltu x1<x2 unsigned]", sx11);
        $display("  x12 = %4d  (expect    -5) [srai x1>>2]",  sx12);
        $display("  x13 = %4d  (expect   120) [slli x2<<3]",  sx13);
        $display("  x16 = %4d  (expect   -63) [add  -100+37]",sx16);
        $display("  x17 = %4d  (expect     1) [slt  -100<-63]",sx17);
        $display("------------------------------------------------");
        if (sx3==-5 && sx9==1 && sx12==-5 && sx13==120 && sx17==1)
            $display("  >>> PASS <<<");
        else $display("  >>> FAIL <<<");
        $display("================================================\n");
        $finish;
    end
    */

    // ============================================================
    // PART 2 : ARRAY SUM  (loop with JAL)
    //   Instruction_Memory PART 2 must be active.
    //   Array at byte 80: {10,25,7,40,15}  sum=97 → x10
    // ============================================================
    /*
    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;  // watch loop iterations
        rst = 1; #20; rst = 0;
        #600;
        $display("\n================================================");
        $display("  PART 2 : ARRAY SUM  (loop using JAL)");
        $display("  Array = {10, 25, 7, 40, 15}");
        $display("================================================");
        $display("  x10 = %0d  (sum, expect 97)",  $unsigned(x10));
        $display("  x11 = %0d  (i,   expect  5)",  $signed(dut.core.rf.regfile[11]));
        $display("  x6  = %0d  (N,   expect  5)",  $signed(x6));
        $display("------------------------------------------------");
        if (x10 == 32'd97) $display("  >>> PASS: sum = 97 <<<");
        else               $display("  >>> FAIL: got %0d <<<", x10);
        $display("================================================\n");
        $finish;
    end
    */

    // ============================================================
    // PART 3 : COUNT NEGATIVES
    //   Instruction_Memory PART 3 must be active.
    //   Array at byte 40: {-5,12,-3,8,-1,20,-7,4}  → count=4 → x10
    // ============================================================
    /*
    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;
        rst = 1; #20; rst = 0;
        #800;
        $display("\n================================================");
        $display("  PART 3 : COUNT NEGATIVES IN ARRAY");
        $display("  Array = {-5,12,-3,8,-1,20,-7,4}");
        $display("================================================");
        $display("  x10 = %0d  (count, expect 4)", $unsigned(x10));
        $display("  x11 = %0d  (i,     expect 8)", $signed(dut.core.rf.regfile[11]));
        $display("------------------------------------------------");
        if (x10 == 32'd4) $display("  >>> PASS: count = 4 <<<");
        else              $display("  >>> FAIL: got %0d <<<", x10);
        $display("================================================\n");
        $finish;
    end
    */

    // ============================================================
    // PART 4 : FACTORIAL  5! = 120
    //   Instruction_Memory PART 4 must be active.
    //   Uses shift-and-add multiply (no MUL instruction in RV32I base)
    //   Result in x10 = 120
    // ============================================================
    /*
    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;
        rst = 1; #20; rst = 0;
        #1500;
        $display("\n================================================");
        $display("  PART 4 : FACTORIAL  5! = 120");
        $display("  Uses binary shift-and-add multiply");
        $display("================================================");
        $display("  x10 = %0d  (result, expect 120)", $unsigned(x10));
        $display("  x6  = %0d  (i,      expect  6 at halt)", $signed(x6));
        $display("------------------------------------------------");
        if (x10 == 32'd120) $display("  >>> PASS: 5! = 120 <<<");
        else                $display("  >>> FAIL: got %0d <<<", x10);
        $display("================================================\n");
        $finish;
    end
    */

    // ============================================================
    // PART 5 : GCD  gcd(48,18) = 6
    //   Instruction_Memory PART 5 must be active.
    //   Euclidean algorithm; result in x10 = 6
    // ============================================================
    /*
    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;
        rst = 1; #20; rst = 0;
        #600;
        $display("\n================================================");
        $display("  PART 5 : GCD(48, 18) = 6  [Euclidean]");
        $display("================================================");
        $display("  x5  = %0d  (a at halt, expect 6)", $signed(x5));
        $display("  x6  = %0d  (b at halt, expect 6)", $signed(x6));
        $display("  x10 = %0d  (result,    expect 6)", $unsigned(x10));
        $display("------------------------------------------------");
        if (x10 == 32'd6) $display("  >>> PASS: GCD = 6 <<<");
        else              $display("  >>> FAIL: got %0d <<<", x10);
        $display("================================================\n");
        $finish;
    end
    */

    // ============================================================
    // PART 6 : FIBONACCI  –  FULL 32-BIT RANGE  (UPGRADED)
    //   Instruction_Memory PART 6 must be active.
    //
    //   No limit register.  Loop stops when unsigned overflow is
    //   detected:  x24 = x22+x23 wraps → x24 < x22 (BLTU fires).
    //
    //   Register roles every iteration:
    //     x22 = F(n-1)  "prev"  — slides:  x22 ← x23
    //     x23 = F(n)    "curr"  — slides:  x23 ← x24
    //     x24 = F(n+1)  "next"  — computed: x24 = x22 + x23
    //
    //   $monitor fires automatically whenever x22, x23, or x24
    //   changes value — you can see the sliding window grow.
    //   (No manual per-cycle trigger needed; Verilog $monitor
    //    fires on any change of the watched signals.)
    //
    //   Expected final values:
    //     F(46) = 1,836,311,903  in x22
    //     F(47) = 2,971,215,073  in x23
    //     F(47) = 2,971,215,073  in x24  (copied at exit)
    //   Testbench PART 6: check x24 == 2971215073
    // ============================================================
    /*
integer fib_iter;
    reg [31:0] last_x24;
    reg [31:0] latch_PC, latch_instr;

    initial begin
        fib_iter = 0;
        last_x24 = 0;
    end

    // Latch PC and instr every cycle — always one cycle behind
    always @(posedge clk) begin
        latch_PC    <= cur_PC;
        latch_instr <= cur_instr;
    end

    // On posedge, if x24 changed, print using LAST cycle's PC/instr
    always @(posedge clk) begin
        if (!rst && dut.core.rf.regfile[24] !== last_x24) begin
            fib_iter = fib_iter + 1;
            last_x24 = dut.core.rf.regfile[24];
            $display("║  %4d  ║ %5d ║ 0x%08X ║ 0x%08X ║ %12d ║ %12d ║ %12d ║",
                     fib_iter, cycle_count,
                     latch_PC, latch_instr,
                     $unsigned(dut.core.rf.regfile[22]),
                     $unsigned(dut.core.rf.regfile[23]),
                     $unsigned(dut.core.rf.regfile[24]));
        end
    end

    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 0;

        $display("\n╔══════════════════════════════════════════════════════════════════════════════════════════╗");
        $display(  "║        PART 6 : FIBONACCI  (full 32-bit unsigned, loop stops on overflow)             ║");
        $display(  "╠════════╦═══════╦════════════╦════════════╦══════════════╦══════════════╦════════════╣");
        $display(  "║  Iter  ║ Cycle ║     PC     ║   Instr    ║  x22 F(n-1)  ║  x23  F(n)   ║ x24 F(n+1) ║");
        $display(  "╠════════╬═══════╬════════════╬════════════╬══════════════╬══════════════╬════════════╣");

        rst = 1; #20; rst = 0;
        #4000;

        $display(  "╠════════╩═══════╩════════════╩════════════╩══════════════╩══════════════╩════════════╣");
        $display(  "║  x22 = %10d  (F46, expect 1836311903)                                      ║", $unsigned(dut.core.rf.regfile[22]));
        $display(  "║  x23 = %10d  (F47, expect 2971215073)                                      ║", $unsigned(dut.core.rf.regfile[23]));
        $display(  "║  x24 = %10d  (result,  expect 2971215073)                                  ║", $unsigned(x24));
        $display(  "║  F48 = 4807526976 overflows uint32, loop stopped                                    ║");
        $display(  "║  Total cycles : %0d                                                              ║", cycle_count);
        $display(  "╠══════════════════════════════════════════════════════════════════════════════════════╣");
        if (x24 == 32'd2971215073)
            $display("║  >>>  PASS : Largest 32-bit Fibonacci = 2971215073 (F47)  <<<                       ║");
        else
            $display("║  >>>  FAIL : got %0d (expect 2971215073)  <<<                                ║", $unsigned(x24));
        $display(  "╚══════════════════════════════════════════════════════════════════════════════════════╝\n");
        $finish;
    end

    */
    // ============================================================
    // PART 7 : BUBBLE SORT  (signed array)  [ACTIVE]
    //   Instruction_Memory PART 7 must be active.
    //   Input  mem[0..4] = {-5, 12, -3, 8, -1}
    //   Output mem[0..4] = {-5, -3, -1, 8, 12}  (ascending, signed)
    //
    //   Monitor shows inner loop j counter (x8) and byte_addr (x9)
    //   to verify swap logic and iteration counts.
    // ============================================================

    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;  // show every cycle's state
        rst = 1; #20; rst = 0;

        $display("\n================================================");
        $display("  PART 7 : BUBBLE SORT  (signed)");
        $display("  Input:  mem[0..4] = {-5, 12, -3, 8, -1}");
        $display("  Sorting ascending using signed BLT comparison...");
        $display("  [cyc####] PC=0xXXXX  instr=0xXXXXXXXX  x5=N-1  x6=i  x8=j  x10=arr[j]");
        $display("================================================");

        #3000;  // ~111 cycles @ 10 ns = 1110 ns, wait 3000 for safety

        $display("================================================");
        $display("  RESULT  (Data Memory after sort):");
        $display("  mem[0] = %4d  (expect -5)",  mem0);
        $display("  mem[1] = %4d  (expect -3)",  mem1);
        $display("  mem[2] = %4d  (expect -1)",  mem2);
        $display("  mem[3] = %4d  (expect  8)",  mem3);
        $display("  mem[4] = %4d  (expect 12)",  mem4);
        $display("  Total cycles executed: %0d", cycle_count);
        $display("------------------------------------------------");
        if (mem0==-5 && mem1==-3 && mem2==-1 && mem3==8 && mem4==12)
            $display("  >>> PASS: Array sorted correctly {-5,-3,-1,8,12} <<<");
        else begin
            $display("  >>> FAIL: Got {%0d,%0d,%0d,%0d,%0d} <<<",
                     mem0, mem1, mem2, mem3, mem4);
            $display("            Expected {-5,-3,-1,8,12}");
        end
        $display("================================================\n");
        $finish;
    end


    // ============================================================
    // PART 8 : INSERTION SORT  (signed array)
    //   Instruction_Memory PART 8 must be active.
    //   Input  mem[0..4] = {-5, 12, -3, 8, -1}
    //   Output mem[0..4] = {-5, -3, -1, 8, 12}
    //   Faster than bubble sort (~81 cycles vs ~111)
    // ============================================================
    /*
    initial begin
        $dumpfile("cpu_top.vcd"); $dumpvars(0, CPU_top_tb);
        MONITOR_ON = 1;
        rst = 1; #20; rst = 0;

        $display("\n================================================");
        $display("  PART 8 : INSERTION SORT  (signed)");
        $display("  Input:  mem[0..4] = {-5, 12, -3, 8, -1}");
        $display("  [cyc####] PC=0xXXXX  instr=0xXXXXXXXX  x5=i  x6=j  x8=curr  x10=N");
        $display("================================================");

        #2000;

        $display("================================================");
        $display("  RESULT  (Data Memory after sort):");
        $display("  mem[0] = %4d  (expect -5)",  mem0);
        $display("  mem[1] = %4d  (expect -3)",  mem1);
        $display("  mem[2] = %4d  (expect -1)",  mem2);
        $display("  mem[3] = %4d  (expect  8)",  mem3);
        $display("  mem[4] = %4d  (expect 12)",  mem4);
        $display("  Total cycles executed: %0d", cycle_count);
        $display("------------------------------------------------");
        if (mem0==-5 && mem1==-3 && mem2==-1 && mem3==8 && mem4==12)
            $display("  >>> PASS: Array sorted correctly {-5,-3,-1,8,12} <<<");
        else begin
            $display("  >>> FAIL: Got {%0d,%0d,%0d,%0d,%0d} <<<",
                     mem0, mem1, mem2, mem3, mem4);
            $display("            Expected {-5,-3,-1,8,12}");
        end
        $display("================================================\n");
        $finish;
    end
    */

endmodule
