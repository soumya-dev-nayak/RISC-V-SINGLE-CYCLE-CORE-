//=============================================================
//   1. pc_sel[1:0] replaces single branch_taken wire
//      00=sequential, 01=branch/JAL, 10=JALR
//   2. JAL now properly changes PC (jump_jal wired to pc_sel)
//   3. JALR now properly changes PC (jump_jalr wired to pc_sel)
//   4. jalr_target forwarded from core to IF stage
//   5. PC forwarded from IF stage to core (for AUIPC, PC+4 link)
//   6. Branch condition decoder handles all 6 RISC-V branches
//=============================================================
module CPU_top #(parameter N = 32)
(
    input clk,
    input rst
);

wire [N-1:0] PC;
wire [N-1:0] instr;
wire         instr_valid;
wire [N-1:0] ALU_result, read_data, write_data;
wire         Branch, zero;
wire [N-1:0] Imm;
wire [2:0]   funct3;
wire         jump_jal, jump_jalr;
wire [N-1:0] jalr_target;

//----------------------------------------------------------
// Core Datapath (ID + EX + MEM + WB)
//----------------------------------------------------------
ID_EX_MEM_WB_top core (
    .clk(clk),          .rst(rst),
    .instr(instr),
    .PC(PC),            // PC fed in for AUIPC and PC+4 link
    .ALU_result(ALU_result),
    .read_data(read_data),
    .write_data(write_data),
    .Branch_out(Branch),
    .zero_out(zero),
    .Imm_out(Imm),
    .funct3_out(funct3),
    .jump_jal(jump_jal),
    .jump_jalr(jump_jalr),
    .jalr_target(jalr_target)
);

//----------------------------------------------------------
// Branch Condition Decoder
// Maps funct3 → branch condition using ALU outputs
//
// BEQ  (000): zero=1  when rs1==rs2
// BNE  (001): zero=0
// BLT  (100): ALU does SLT: result[0]=1 when rs1<rs2 (signed)
// BGE  (101): ~result[0]
// BLTU (110): ALU does SLTU: result[0]=1 when rs1<rs2 (unsigned)
// BGEU (111): ~result[0]
//----------------------------------------------------------
reg branch_cond;
always @(*) begin
    case (funct3)
        3'b000: branch_cond =  zero;              // BEQ
        3'b001: branch_cond = ~zero;              // BNE
        3'b100: branch_cond =  ALU_result[0];     // BLT  (SLT)
        3'b101: branch_cond = ~ALU_result[0];     // BGE
        3'b110: branch_cond =  ALU_result[0];     // BLTU (SLTU)
        3'b111: branch_cond = ~ALU_result[0];     // BGEU
        default: branch_cond = 1'b0;
    endcase
end

wire branch_taken = Branch & branch_cond;

//----------------------------------------------------------
// PC Select Logic
//   2'b00: sequential   (PC+4)
//   2'b01: branch or JAL (PC + Imm)
//   2'b10: JALR          (rs1 + imm  via ALU)
//----------------------------------------------------------
wire [1:0] pc_sel = jump_jalr  ? 2'b10 :
                    (branch_taken | jump_jal) ? 2'b01 : 2'b00;

//----------------------------------------------------------
// Instruction Fetch Stage
//----------------------------------------------------------
IF_top if_stage (
    .clk(clk),          .reset(rst),
    .pc_sel(pc_sel),
    .Imm(Imm),
    .jalr_target(jalr_target),
    .PC(PC),
    .instr(instr),
    .instr_valid(instr_valid)
);

endmodule
