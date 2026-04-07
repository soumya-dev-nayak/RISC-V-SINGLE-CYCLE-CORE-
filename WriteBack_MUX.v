// ============================================================
// Writeback MUX (3:1)
// Fixed: added explicit case for ResultSrc=2'b11 (was default->0).
// Note: With MainDecoder fix, LUI now uses ResultSrc=2'b00 (ALU result),
// so 2'b11 is currently unused. The fix is kept for completeness/safety.
// ============================================================
module WriteBack_MUX #(parameter N = 32)
(
    input [N-1:0] ALU_result,
    input [N-1:0] Mem_data,
    input [N-1:0] PC_plus4,
    input [1:0]   ResultSrc,
    output reg [N-1:0] Result
);
always @(*) begin
    case(ResultSrc)
        2'b00: Result = ALU_result; // R-type, I-type, LUI, AUIPC
        2'b01: Result = Mem_data;   // Load
        2'b10: Result = PC_plus4;   // JAL / JALR
        2'b11: Result = ALU_result; // Reserved / fallback to ALU (was 0 -> silent bug)
    endcase
end
endmodule
