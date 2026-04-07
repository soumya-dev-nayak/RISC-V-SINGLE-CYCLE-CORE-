//=============================================================
// Instruction Fetch (IF) Stage
//   - branch input replaced by pc_sel[1:0] to support JAL and JALR
//   - jalr_target added: ALU result forwarded here from core for JALR
//   - Instruction memory read remains ASYNCHRONOUS (combinational)
//     (critical: synchronous read caused branch-offset-by-4 bug)
//=============================================================
module IF_top #(parameter N = 32)
(
    input  wire        clk,
    input  wire        reset,
    input  wire [1:0]  pc_sel,       // 2-bit: 00=PC+4, 01=branch/JAL, 10=JALR
    input  wire [N-1:0] Imm,         // branch/JAL offset (sign-extended)
    input  wire [N-1:0] jalr_target, // JALR target = rs1+imm from ALU  (NEW)

    output wire [N-1:0] PC,
    output wire [N-1:0] instr,
    output wire         instr_valid
);

    wire [N-1:0] PC_internal;

    PC_Top #(.N(N)) pc_inst (
        .clk(clk),
        .rst(reset),
        .pc_sel(pc_sel),         // was: .branch(branch)
        .Imm(Imm),
        .jalr_target(jalr_target),
        .PC(PC_internal)
    );

    Instruction_Memory #(.N(N)) imem_inst (
        .clk(clk),
        .reset(reset),
        .instr_req(1'b1),
        .addr(PC_internal),
        .instr_valid(instr_valid),
        .instr(instr)
    );

    assign PC = PC_internal;

endmodule
