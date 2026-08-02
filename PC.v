module PC #(parameter N = 32)
(
    //------Input-------
    input clk,rst,
    input [N-1:0]PCNext,
    //------Output-------
    output reg [N-1:0]PC
    
);
always @(posedge clk or posedge rst) 
begin
    if(rst)
        PC<=0;
    else
        PC<=PCNext;
end
endmodule
