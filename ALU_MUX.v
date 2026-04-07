//---------SOUMYAA---------
//=============================================================
// ALU Input MUX (2:1)
//=============================================================

module ALU_MUX #(parameter N = 32)
(
    input  [N-1:0] rs2_data,   // from register file
    input  [N-1:0] imm,        // from immediate generator
    input          ALUSrc,     // control signal

    output [N-1:0] SrcB        // to ALU
);

assign SrcB = (ALUSrc) ? imm : rs2_data;

endmodule
