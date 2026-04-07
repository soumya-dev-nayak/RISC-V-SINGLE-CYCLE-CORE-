//=============================================================
// SrcA MUX
// Selects ALU operand A:
//   ALUSrcA = 0  →  rs1_data  (normal register read)
//   ALUSrcA = 1  →  PC_reg    (for AUIPC: result = PC + U-imm)
//
// This was the missing piece that made AUIPC produce wrong results.
// Without this mux, SrcA was always rs1_data, so AUIPC would compute
// rs1+imm instead of PC+imm.
//=============================================================
module SrcA_MUX #(parameter N = 32)
(
    input  wire [N-1:0] rs1_data,   // register file read port 1
    input  wire [N-1:0] PC_reg,     // current program counter
    input  wire         ALUSrcA,    // 0=rs1, 1=PC

    output wire [N-1:0] SrcA        // to ALU port A
);

assign SrcA = ALUSrcA ? PC_reg : rs1_data;

endmodule
