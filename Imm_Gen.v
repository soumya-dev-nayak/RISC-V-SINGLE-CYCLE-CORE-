//=============================================================
// Supports all 5 RISC-V immediate formats
// ImmSrc encoding (3-bit, from MainDecoder):
//   3'b000  I-type  : sign-extend instr[31:20]            (addi, lw, jalr)
//   3'b001  S-type  : sign-extend {instr[31:25],instr[11:7]}  (sw)
//   3'b010  B-type  : sign-extend branch offset            (beq, bne, blt, bge)
//   3'b011  J-type  : sign-extend 21-bit JAL offset        (jal)
//   3'b100  U-type  : {instr[31:12], 12'b0}                (lui, auipc)
//
// CHANGE from original: ImmSrc expanded from 2-bit to 3-bit.
// U-type added so LUI and AUIPC now generate the correct 20-bit
// upper immediate instead of being silently computed as zero.
//=============================================================
module Imm_Gen
(
    input  [31:0] instr,
    input  [2:0]  ImmSrc,   // 3-bit – from MainDecoder

    output reg [31:0] imm
);

always @(*) begin
    case (ImmSrc)

        // I-TYPE  (addi, lw, jalr, slti, andi, ori, xori, slli, srli, srai)
        3'b000:
            imm = {{20{instr[31]}}, instr[31:20]};

        // S-TYPE  (sw, sh, sb)
        3'b001:
            imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};

        // B-TYPE  (beq, bne, blt, bge, bltu, bgeu)
        3'b010:
            imm = {{19{instr[31]}}, instr[31], instr[7],
                   instr[30:25], instr[11:8], 1'b0};

        // J-TYPE  (jal)
        3'b011:
            imm = {{11{instr[31]}}, instr[31], instr[19:12],
                   instr[20], instr[30:21], 1'b0};

        // U-TYPE  (lui, auipc)
        3'b100:
            imm = {instr[31:12], 12'b0};

        default:
            imm = 32'b0;
    endcase
end

endmodule
