//---------Prakhar / UPGRADED-----------
// PC MUX  (3:1)
//
// CHANGE: Expanded from 2:1 to 3:1 to support JAL, JALR, and branches.
//
// pc_sel encoding:
//   2'b00  →  PCPlus4    (sequential execution)
//   2'b01  →  PCTarget   (branch target = PC + Imm; also used for JAL)
//   2'b10  →  JalrTarget (JALR target = rs1 + I-imm, from ALU result)
//
// OLD code (2:1):
//   assign PCNext = branch ? PCTarget : PCPlus4;
// This caused JAL/JALR to never change PC because the Jump signal
// was generated but never connected to the PC mux.
module PC_MUX #(parameter N = 32)
(
    input  wire [1:0]   pc_sel,       // 2-bit select  (was 1-bit branch)
    input  wire [N-1:0] PCPlus4,      // PC + 4
    input  wire [N-1:0] PcTarget,     // PC + Imm  (branches and JAL)
    input  wire [N-1:0] JalrTarget,   // ALU result  (JALR: rs1 + imm)
    output reg  [N-1:0] PCNext        // next PC value
);

always @(*) begin
    case (pc_sel)
        2'b00:   PCNext = PCPlus4;
        2'b01:   PCNext = PcTarget;
        2'b10:   PCNext = JalrTarget;
        default: PCNext = PCPlus4;
    endcase
end

endmodule
