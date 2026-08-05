module PC_Plus_4 #(parameter N=32)
(
    input [N-1:0]PC,
    output [N-1:0]PCPlus4
);

assign PCPlus4=PC+32'd4;

endmodule
