module PC_Plus_4 #(parameter N=32)
(
    input [N-1:0]PC,
    output [N-1:0]PCPlus4
);
<<<<<<< HEAD
assign PCPlus4=PC+32'd4;
=======

assign PCPlus4=PC+32'd4;

>>>>>>> 3c5a1e1 (Refactor single-cycle RISC-V datapath and update CPU modules)
endmodule
