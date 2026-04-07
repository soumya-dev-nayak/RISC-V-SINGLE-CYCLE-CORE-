//=============================================================
// ID / EX / MEM / WB  Core Datapath
//   1. Accepts PC input (needed for AUIPC and PC+4 link writeback)
//   2. ImmSrc expanded to 3 bits (U-type for LUI/AUIPC)
//   3. SrcA_MUX added: ALU port A = rs1 or PC (for AUIPC)
//   4. ALUSrcA control signal added from MainDecoder
//   5. Real PC+4 forwarded to WriteBack_MUX (was hardwired 32'b0)
//   6. Outputs jump_jal and jump_jalr for PC mux selection in CPU_top
//   7. jalr_target output = ALU_result (used for JALR PC target)
//   8. Data memory expanded to 256 words (DEPTH=256)
//=============================================================
module ID_EX_MEM_WB_top #(parameter N = 32)
(
    input  wire        clk,
    input  wire        rst,
    input  wire [N-1:0] instr,
    input  wire [N-1:0] PC,         // current PC (NEW – for AUIPC + PC+4 link)

    // Outputs back to CPU_top (for PC mux)
    output wire [N-1:0] ALU_result,
    output wire [N-1:0] read_data,
    output wire [N-1:0] write_data,
    output wire         Branch_out,
    output wire         zero_out,
    output wire [N-1:0] Imm_out,
    output wire [2:0]   funct3_out,
    output wire         jump_jal,   // NEW: JAL  instruction active
    output wire         jump_jalr,  // NEW: JALR instruction active
    output wire [N-1:0] jalr_target // NEW: ALU_result = rs1+imm for JALR
);

    //----------------------------------------------------------
    // ID STAGE – Decode
    //----------------------------------------------------------
    wire [6:0] opcode;
    wire [4:0] rd, rs1, rs2;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire Branch, zero;

    Instruction_Decoder idec (
        .instr(instr),
        .opcode(opcode), .rd(rd),
        .funct3(funct3), .rs1(rs1),
        .rs2(rs2),       .funct7(funct7)
    );

    wire        RegWrite, ALUSrc, ALUSrcA, MemWrite, Jump, JalrSel;
    wire [2:0]  ImmSrc;
    wire [1:0]  ResultSrc, ALUop;

    MainDecoder mdec (
        .op(opcode),
        .RegWrite(RegWrite),   .ImmSrc(ImmSrc),
        .ALUSrc(ALUSrc),       .ALUSrcA(ALUSrcA),
        .MemWrite(MemWrite),   .ResultSrc(ResultSrc),
        .Branch(Branch),       .ALUop(ALUop),
        .Jump(Jump),           .JalrSel(JalrSel)
    );

    //----------------------------------------------------------
    // Register File
    //----------------------------------------------------------
    wire [N-1:0] rs1_data, rs2_data;

    Register_Set rf (
        .clk(clk),         .rst(rst),
        .rs1_addr(rs1),    .rs2_addr(rs2),
        .rs1_data(rs1_data), .rs2_data(rs2_data),
        .rd_addr(rd),      .rd_data(write_data),
        .reg_write(RegWrite)
    );

    //----------------------------------------------------------
    // Immediate Generator (3-bit ImmSrc)
    //----------------------------------------------------------
    wire [N-1:0] imm;
    Imm_Gen immgen (.instr(instr), .ImmSrc(ImmSrc), .imm(imm));

    //----------------------------------------------------------
    // EX STAGE – Execute
    //----------------------------------------------------------
    wire [3:0] ALUControl;
    ALUDecoder aludec (
        .ALUop(ALUop), .funct3(funct3),
        .funct7(funct7), .ALUControl(ALUControl)
    );

    // SrcA mux: rs1_data or PC  (AUIPC fix)
    wire [N-1:0] SrcA;
    SrcA_MUX #(.N(N)) srca_mux (
        .rs1_data(rs1_data),
        .PC_reg(PC),
        .ALUSrcA(ALUSrcA),
        .SrcA(SrcA)
    );

    // SrcB mux: rs2 or immediate
    wire [N-1:0] SrcB;
    ALU_MUX #(.N(N)) mux (
        .rs2_data(rs2_data), .imm(imm),
        .ALUSrc(ALUSrc), .SrcB(SrcB)
    );

    ALU alu (
        .A(SrcA), .B(SrcB), .con(ALUControl),
        .res(ALU_result), .zero(zero),
        .carry(), .overflow(), .negative()
    );

    //----------------------------------------------------------
    // MEM STAGE
    //----------------------------------------------------------
    Data_Memory dmem (
        .clk(clk),          .rst(rst),
        .MemWrite(MemWrite),
        .MemRead(ResultSrc == 2'b01),
        .addr(ALU_result),
        .write_data(rs2_data),
        .read_data(read_data)
    );

    //----------------------------------------------------------
    // WB STAGE  – real PC+4 forwarded (was 32'b0)
    //----------------------------------------------------------
    wire [N-1:0] PC_plus4 = PC + 32'd4;   // FIXED: real return address

    WriteBack_MUX wb (
        .ALU_result(ALU_result),
        .Mem_data(read_data),
        .PC_plus4(PC_plus4),
        .ResultSrc(ResultSrc),
        .Result(write_data)
    );

    //----------------------------------------------------------
    // Outputs to CPU_top
    //----------------------------------------------------------
    assign Branch_out   = Branch;
    assign zero_out     = zero;
    assign Imm_out      = imm;
    assign funct3_out   = funct3;
    assign jump_jal     = Jump & ~JalrSel;  // JAL:  use PC+Imm target
    assign jump_jalr    = Jump &  JalrSel;  // JALR: use ALU_result target
    assign jalr_target  = ALU_result;       // rs1 + I-imm computed by ALU

endmodule
