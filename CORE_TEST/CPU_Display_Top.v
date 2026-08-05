// ============================================================
// CPU_Display_Top.v  –  Unified Basys-3 Display for All 8 Programs
//
// HOW TO USE:
//   1. Uncomment ONE PART in Instruction_Memory.v
//   2. Change PROGRAM_ID parameter below to match that part (1–8)
//   3. Synthesise with CPU_Display_Top as the top module
//   4. Program the bitstream
//   5. Use the switches as described in the SWITCH MAP below
//
// PROGRAM_ID → Program
//   1  ALU + Negative Numbers   (x3,x9,x12,x13,x17)
//   2  Array Sum                (x10 = 97)
//   3  Count Negatives          (x10 = 4)
//   4  Factorial 5!=120         (x10 = 120)
//   5  GCD(48,18)=6             (x10 = 6)
//   6  Fibonacci 32-bit         (x22,x23,x24 live)
//   7  Bubble Sort              (mem[0..4] sorted)
//   8  Insertion Sort           (mem[0..4] sorted)
//
// SWITCH MAP (same layout for every program):
//   SW[0]   Reset  (push UP then DOWN to restart CPU)
//   SW[1]   Speed bit 0  ─┐  (Programs 6,7,8 only — others instant)
//   SW[2]   Speed bit 1  ─┘
//             SW[2:1]=00 → ~1 Hz   (step-by-step)
//             SW[2:1]=01 → ~4 Hz
//             SW[2:1]=10 → ~8 Hz
//             SW[2:1]=11 → full speed (instant result)
//   SW[3]   Register/value select  (program-specific, see below)
//   SW[4]   Half select: 0=lower 16 bits, 1=upper 16 bits
//             Decimal point lights when showing upper half
//
// SW[3] PER PROGRAM:
//   P1  ALU Test  : 0=x3(-5)  1=x9(1)/x12(-5)/x13(120) cycling
//   P2  ArraySum  : ignored   (x10=97 always shown)
//   P3  CountNeg  : ignored   (x10=4  always shown)
//   P4  Factorial : ignored   (x10=120 always shown)
//   P5  GCD       : 0=x10(6)  1=x5(a at halt)
//   P6  Fibonacci : 0=x22(prev)  1=x23(curr)
//   P7  BubbleSort: 0=mem[0]  1=mem[1]  (toggle to read sorted words)
//   P8  InsertSort: 0=mem[0]  1=mem[1]
// ============================================================

// ── CHANGE THIS NUMBER TO MATCH YOUR ACTIVE Instruction_Memory PART ──
`define PROGRAM_ID 6
// ─────────────────────────────────────────────────────────────────────

module CPU_Display_Top (
    input  wire        clk,      // W5  100 MHz
    input  wire [4:0]  sw,       // SW[4:0]
    output wire [6:0]  seg,
    output wire        dp,
    output wire [3:0]  an
);

    // ----------------------------------------------------------
    // Switch decode
    // ----------------------------------------------------------
    wire        rst        = sw[0];
    wire [1:0]  speed_sel  = sw[2:1];
    wire        val_sel    = sw[3];   // selects which value to display
    wire        show_upper = sw[4];   // 0=lower 16-bit, 1=upper 16-bit

    // ----------------------------------------------------------
    // Clock-enable tick generator
    // Programs 1-5: run at full speed (tick always high)
    // Programs 6-8: user-selectable slow tick for live viewing
    //
    // For instant programs (1-5) speed is irrelevant because the
    // CPU halts at jal x0,0 and the result is frozen on display.
    // ----------------------------------------------------------
    reg [26:0] slow_cnt;
    reg        cpu_tick;

    reg [26:0] divisor;
    always @(*) begin
        // Programs 6,7,8: respect speed_sel
        // Programs 1-5:   always full speed (divisor=1)
        `ifdef PROGRAM_ID
            if (`PROGRAM_ID >= 6) begin
                case (speed_sel)
                    2'b00: divisor = 27'd100_000_000; // ~1  Hz
                    2'b01: divisor = 27'd25_000_000;  // ~4  Hz
                    2'b10: divisor = 27'd12_500_000;  // ~8  Hz
                    2'b11: divisor = 27'd1;            // 100 MHz
                    default: divisor = 27'd100_000_000;
                endcase
            end else begin
                divisor = 27'd1; // always full speed
            end
        `else
            divisor = 27'd1;
        `endif
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            slow_cnt <= 0;
            cpu_tick <= 1'b0;
        end else begin
            cpu_tick <= 1'b0;
            if (slow_cnt >= divisor - 1) begin
                slow_cnt <= 0;
                cpu_tick <= 1'b1;
            end else
                slow_cnt <= slow_cnt + 1;
        end
    end

    // ----------------------------------------------------------
    // CPU instance — exposes all register & memory taps
    // ----------------------------------------------------------
    wire [31:0] x3,  x5,  x6;
    wire [31:0] x9,  x10, x12, x13, x17;
    wire [31:0] x22, x23, x24;
    wire [31:0] mem0, mem1, mem2, mem3, mem4;
    wire [31:0] pc_wire;

    CPU_Tapped #(.N(32)) cpu_inst (
        .clk      (clk),
        .rst      (rst),
        .clk_en   (cpu_tick),
        // register taps
        .x3_out   (x3),   .x5_out  (x5),   .x6_out  (x6),
        .x9_out   (x9),   .x10_out (x10),  .x12_out (x12),
        .x13_out  (x13),  .x17_out (x17),
        .x22_out  (x22),  .x23_out (x23),  .x24_out (x24),
        // memory taps
        .mem0_out (mem0), .mem1_out(mem1),  .mem2_out(mem2),
        .mem3_out (mem3), .mem4_out(mem4),
        // pc
        .pc_out   (pc_wire)
    );

    // ----------------------------------------------------------
    // Display value multiplexer
    // Selects the right register or memory word based on PROGRAM_ID
    // and the val_sel switch. Result is always a 32-bit word;
    // show_upper then picks which 16-bit half goes to the display.
    // ----------------------------------------------------------
    reg [31:0] display_word;

    always @(*) begin
        case (`PROGRAM_ID)
            // ── Part 1: ALU Test ────────────────────────────
            // val_sel=0 → x3  (add: -5)
            // val_sel=1 → x9  (slt: 1)  — user can toggle SW[3]
            //   also check x12(-5), x13(120), x17(1) by changing here
            1: display_word = val_sel ? x9  : x3;

            // ── Part 2: Array Sum ───────────────────────────
            // x10 = 97 = 0x0061
            2: display_word = x10;

            // ── Part 3: Count Negatives ─────────────────────
            // x10 = 4 = 0x0004
            3: display_word = x10;

            // ── Part 4: Factorial ───────────────────────────
            // x10 = 120 = 0x0078
            4: display_word = x10;

            // ── Part 5: GCD ─────────────────────────────────
            // val_sel=0 → x10 (result = 6)
            // val_sel=1 → x5  (a register at halt = 6)
            5: display_word = val_sel ? x5 : x10;

            // ── Part 6: Fibonacci ───────────────────────────
            // val_sel=0 → x22  F(n-1) "prev" — older term
            // val_sel=1 → x23  F(n)   "curr" — newer term  ← recommended
            // SW[4]=0 → lower 16 bits (fits up to F(23)=28657)
            // SW[4]=1 → upper 16 bits (needed for F(24) onward)
            6: display_word = val_sel ? x23 : x22;

            // ── Part 7: Bubble Sort ─────────────────────────
            // Toggle SW[3] to inspect sorted memory words:
            // val_sel=0 → mem[0] (expect -5  = 0xFFFFFFFB)
            // val_sel=1 → mem[1] (expect -3  = 0xFFFFFFFD)
            // Use SW[4]=1 to confirm upper half = 0xFFFF (sign extended)
            7: display_word = val_sel ? mem1 : mem0;

            // ── Part 8: Insertion Sort ──────────────────────
            // Same layout as Part 7
            8: display_word = val_sel ? mem1 : mem0;

            default: display_word = 32'hDEAD_BEEF; // should never happen
        endcase
    end

    // Pick 16-bit window
    wire [15:0] display_val = show_upper ? display_word[31:16]
                                         : display_word[15:0];

    // ----------------------------------------------------------
    // 7-Segment Display Controller
    // Always on 100 MHz — never flickers regardless of cpu_tick speed
    // ----------------------------------------------------------
    SevenSeg_Unified #(
        .CLK_FREQ  (100_000_000),
        .SCAN_FREQ (1_000)
    ) display_inst (
        .clk        (clk),
        .rst        (rst),
        .value      (display_val),
        .show_upper (show_upper),
        .seg        (seg),
        .an         (an),
        .dp         (dp)
    );

endmodule


// ============================================================
// CPU_Tapped.v
//
// Structural copy of CPU_top that exposes every register and
// memory word needed by all 8 programs as output ports.
// Uses clock-enable (clk_en) instead of a gated clock so that
// Vivado timing analysis runs cleanly with no CDC warnings.
//
// RegWrite and MemWrite are gated with clk_en so the register
// file and data memory only commit results on enabled cycles.
// The PC register is similarly gated via IF_top_CE.
// ============================================================

module CPU_Tapped #(parameter N = 32)
(
    input  wire        clk,
    input  wire        rst,
    input  wire        clk_en,

    // Register taps (all programs combined)
    output wire [N-1:0] x3_out,   // Part 1: add result
    output wire [N-1:0] x5_out,   // Part 5: GCD a-register
    output wire [N-1:0] x6_out,   // Parts 2,4: loop counter
    output wire [N-1:0] x9_out,   // Part 1: slt result
    output wire [N-1:0] x10_out,  // Parts 2,3,4,5: main result
    output wire [N-1:0] x12_out,  // Part 1: srai result
    output wire [N-1:0] x13_out,  // Part 1: slli result
    output wire [N-1:0] x17_out,  // Part 1: final slt
    output wire [N-1:0] x22_out,  // Part 6: Fibonacci prev
    output wire [N-1:0] x23_out,  // Part 6: Fibonacci curr
    output wire [N-1:0] x24_out,  // Part 6: Fibonacci next

    // Data memory taps (Parts 7,8 sort result)
    output wire [N-1:0] mem0_out,
    output wire [N-1:0] mem1_out,
    output wire [N-1:0] mem2_out,
    output wire [N-1:0] mem3_out,
    output wire [N-1:0] mem4_out,

    // PC tap
    output wire [N-1:0] pc_out
);

    // ----------------------------------------------------------
    // Internal wires (exact copy of CPU_top)
    // ----------------------------------------------------------
    wire [N-1:0] PC, instr;
    wire         instr_valid;
    wire [N-1:0] ALU_result, read_data, write_data;
    wire         Branch, zero;
    wire [N-1:0] Imm;
    wire [2:0]   funct3;
    wire         jump_jal, jump_jalr;
    wire [N-1:0] jalr_target;

    // Branch condition decoder (identical to CPU_top)
    reg branch_cond;
    always @(*) begin
        case (funct3)
            3'b000: branch_cond =  zero;
            3'b001: branch_cond = ~zero;
            3'b100: branch_cond =  ALU_result[0];
            3'b101: branch_cond = ~ALU_result[0];
            3'b110: branch_cond =  ALU_result[0];
            3'b111: branch_cond = ~ALU_result[0];
            default: branch_cond = 1'b0;
        endcase
    end

    wire branch_taken = Branch & branch_cond;
    wire [1:0] pc_sel = jump_jalr             ? 2'b10 :
                        (branch_taken | jump_jal) ? 2'b01 : 2'b00;

    // ----------------------------------------------------------
    // Decode stage (combinational — no gating needed)
    // ----------------------------------------------------------
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3_w;
    wire [6:0] funct7;

    Instruction_Decoder idec (
        .instr(instr),
        .opcode(opcode), .rd(rd),
        .funct3(funct3_w), .rs1(rs1),
        .rs2(rs2),         .funct7(funct7)
    );

    wire        RegWrite, ALUSrc, ALUSrcA, MemWrite, Jump, JalrSel;
    wire [2:0]  ImmSrc;
    wire [1:0]  ResultSrc, ALUop;
    wire        Branch_sig;

    MainDecoder mdec (
        .op(opcode),
        .RegWrite(RegWrite),  .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrc),      .ALUSrcA(ALUSrcA),
        .MemWrite(MemWrite),  .ResultSrc(ResultSrc),
        .Branch(Branch_sig),  .ALUop(ALUop),
        .Jump(Jump),          .JalrSel(JalrSel)
    );

    // Gate write enables with clk_en
    wire RegWrite_g = RegWrite & clk_en;
    wire MemWrite_g = MemWrite & clk_en;

    // ----------------------------------------------------------
    // Register file
    // ----------------------------------------------------------
    wire [N-1:0] rs1_data, rs2_data;

    Register_Set rf (
        .clk(clk),         .rst(rst),
        .rs1_addr(rs1),    .rs2_addr(rs2),
        .rs1_data(rs1_data), .rs2_data(rs2_data),
        .rd_addr(rd),      .rd_data(write_data),
        .reg_write(RegWrite_g)
    );

    // ----------------------------------------------------------
    // Immediate generator
    // ----------------------------------------------------------
    wire [N-1:0] imm;
    Imm_Gen immgen (.instr(instr), .ImmSrc(ImmSrc), .imm(imm));

    // ----------------------------------------------------------
    // ALU
    // ----------------------------------------------------------
    wire [N-1:0] SrcA, SrcB;

    SrcA_MUX #(.N(N)) srca_mux (
        .rs1_data(rs1_data), .PC_reg(PC),
        .ALUSrcA(ALUSrcA), .SrcA(SrcA)
    );

    ALU_MUX #(.N(N)) srcb_mux (
        .rs2_data(rs2_data), .imm(imm),
        .ALUSrc(ALUSrc), .SrcB(SrcB)
    );

    wire [3:0] ALUControl;
    ALUDecoder aludec (
        .ALUop(ALUop), .funct3(funct3_w),
        .funct7(funct7), .ALUControl(ALUControl)
    );

    wire zero_sig;
    ALU alu (
        .A(SrcA), .B(SrcB), .con(ALUControl),
        .res(ALU_result), .zero(zero_sig),
        .carry(), .overflow(), .negative()
    );

    // ----------------------------------------------------------
    // Data memory
    // ----------------------------------------------------------
    wire [N-1:0] read_data_sig;

    Data_Memory dmem (
        .clk(clk),              .rst(rst),
        .MemWrite(MemWrite_g),
        .MemRead(ResultSrc == 2'b01),
        .addr(ALU_result),
        .write_data(rs2_data),
        .read_data(read_data_sig)
    );

    // ----------------------------------------------------------
    // Writeback
    // ----------------------------------------------------------
    wire [N-1:0] PC_plus4 = PC + 32'd4;

    WriteBack_MUX wb (
        .ALU_result(ALU_result),
        .Mem_data(read_data_sig),
        .PC_plus4(PC_plus4),
        .ResultSrc(ResultSrc),
        .Result(write_data)
    );

    // ----------------------------------------------------------
    // IF stage with clock-enabled PC
    // ----------------------------------------------------------
    IF_top_CE #(.N(N)) if_stage (
        .clk(clk),           .reset(rst),
        .clk_en(clk_en),
        .pc_sel(pc_sel),
        .Imm(imm),
        .jalr_target(ALU_result),
        .PC(PC),
        .instr(instr),
        .instr_valid(instr_valid)
    );

    // ----------------------------------------------------------
    // Assign internal signals to module outputs
    // ----------------------------------------------------------
    assign Branch     = Branch_sig;
    assign zero       = zero_sig;
    assign Imm        = imm;
    assign funct3     = funct3_w;
    assign jump_jal   = Jump & ~JalrSel;
    assign jump_jalr  = Jump &  JalrSel;
    assign jalr_target = ALU_result;
    assign read_data  = read_data_sig;

    // Register taps — direct reads from regfile array
    assign x3_out  = rf.regfile[3];
    assign x5_out  = rf.regfile[5];
    assign x6_out  = rf.regfile[6];
    assign x9_out  = rf.regfile[9];
    assign x10_out = rf.regfile[10];
    assign x12_out = rf.regfile[12];
    assign x13_out = rf.regfile[13];
    assign x17_out = rf.regfile[17];
    assign x22_out = rf.regfile[22];
    assign x23_out = rf.regfile[23];
    assign x24_out = rf.regfile[24];

    // Memory taps — direct reads from dmem array
    assign mem0_out = dmem.mem[0];
    assign mem1_out = dmem.mem[1];
    assign mem2_out = dmem.mem[2];
    assign mem3_out = dmem.mem[3];
    assign mem4_out = dmem.mem[4];

    assign pc_out = PC;

endmodule


// ============================================================
// IF_top_CE.v  –  IF stage with clock-enabled PC register
//
// Identical to IF_top except the PC register only latches
// PCNext when clk_en=1. Instruction memory read stays
// combinational — no change needed there.
// ============================================================

module IF_top_CE #(parameter N = 32)
(
    input  wire        clk,
    input  wire        reset,
    input  wire        clk_en,
    input  wire [1:0]  pc_sel,
    input  wire [N-1:0] Imm,
    input  wire [N-1:0] jalr_target,
    output wire [N-1:0] PC,
    output wire [N-1:0] instr,
    output wire         instr_valid
);
    // PC register — gated by clk_en
    reg [N-1:0] PC_reg;

    wire [N-1:0] PCPlus4  = PC_reg + 32'd4;
    wire [N-1:0] PCTarget = PC_reg + Imm;
    wire [N-1:0] PCNext   = (pc_sel == 2'b10) ? jalr_target :
                             (pc_sel == 2'b01) ? PCTarget    : PCPlus4;

    always @(posedge clk or posedge reset) begin
        if (reset)         PC_reg <= {N{1'b0}};
        else if (clk_en)   PC_reg <= PCNext;
        // when clk_en=0, PC_reg holds — CPU paused
    end

    assign PC = PC_reg;

    // Instruction memory — combinational (unchanged from original)
    Instruction_Memory #(.N(N)) imem (
        .clk(clk),       .reset(reset),
        .instr_req(1'b1), .addr(PC_reg),
        .instr_valid(instr_valid), .instr(instr)
    );

endmodule


// ============================================================
// SevenSeg_Unified.v  –  4-digit hex display, 100 MHz safe
//
// Takes a pre-selected 16-bit value and shows it as 4 hex
// digits. Decimal point lights when show_upper=1.
// ============================================================

module SevenSeg_Unified #(
    parameter CLK_FREQ  = 100_000_000,
    parameter SCAN_FREQ = 1_000
)(
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] value,
    input  wire        show_upper,  // dp indicator

    output reg  [6:0]  seg,
    output reg  [3:0]  an,
    output reg         dp
);
    localparam integer SCAN_DIV = CLK_FREQ / (SCAN_FREQ * 4);

    reg [$clog2(SCAN_DIV)-1:0] cnt;
    reg tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin cnt <= 0; tick <= 0; end
        else begin
            tick <= 0;
            if (cnt == SCAN_DIV - 1) begin cnt <= 0; tick <= 1; end
            else cnt <= cnt + 1;
        end
    end

    reg [1:0] dsel;
    always @(posedge clk or posedge rst) begin
        if (rst)       dsel <= 0;
        else if (tick) dsel <= dsel + 1;
    end

    // Anode (active-low one-hot)
    always @(*) begin
        case (dsel)
            2'd0: an = 4'b1110;
            2'd1: an = 4'b1101;
            2'd2: an = 4'b1011;
            2'd3: an = 4'b0111;
            default: an = 4'b1111;
        endcase
    end

    // Nibble select (digit 0 = rightmost = LSB)
    reg [3:0] nib;
    always @(*) begin
        case (dsel)
            2'd0: nib = value[3:0];
            2'd1: nib = value[7:4];
            2'd2: nib = value[11:8];
            2'd3: nib = value[15:12];
            default: nib = 4'h0;
        endcase
    end

    // Hex → 7-segment (active-low)
    always @(*) begin
        case (nib)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000;
            4'hB: seg = 7'b0000011;
            4'hC: seg = 7'b1000110;
            4'hD: seg = 7'b0100001;
            4'hE: seg = 7'b0000110;
            4'hF: seg = 7'b0001110;
            default: seg = 7'b1111111;
        endcase
    end

    // Decimal point = upper-half indicator
    always @(*) dp = show_upper ? 1'b0 : 1'b1;

endmodule
