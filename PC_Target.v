//Program Counter Target//
module PC_Target #(parameter N=32)
(
    input [N-1:0]PC,
    input [N-1:0]Imm,
    output [N-1:0]PcTarget
);

    assign PcTarget=PC+Imm;

endmodule
