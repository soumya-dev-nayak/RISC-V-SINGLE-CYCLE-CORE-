// PC Subsystem  –  drives 3-way PC mux
// CHANGE: branch input replaced by pc_sel[1:0] to support
// sequential / branch+JAL / JALR selection.
module PC_Top #(parameter N=32)
(
    input wire        clk,
    input wire        rst,
    input wire [1:0]  pc_sel,      // 2-bit mux select (was 1-bit branch)
    input wire [N-1:0] Imm,
    input wire [N-1:0] jalr_target, // ALU result for JALR  (NEW)
    output wire [N-1:0] PC
);

wire [N-1:0] PCNext, PCPlus4, PCTarget, PC_reg;

PC #(.N(N)) PC_inst (
    .clk(clk), .rst(rst),
    .PCNext(PCNext),
    .PC(PC_reg)
);

PC_Plus_4 #(.N(N)) PP_4_inst (
    .PC(PC_reg),
    .PCPlus4(PCPlus4)
);

PC_Target #(.N(N)) PT_inst (
    .PC(PC_reg),
    .Imm(Imm),
    .PcTarget(PCTarget)
);

// 3:1 mux replacing the old 2:1
PC_MUX #(.N(N)) mux_inst (
    .pc_sel(pc_sel),
    .PCPlus4(PCPlus4),
    .PcTarget(PCTarget),
    .JalrTarget(jalr_target),
    .PCNext(PCNext)
);

assign PC = PC_reg;

endmodule
