//---------rani------------//
//Program Counter for pulpino
module PC #(parameter N = 32)
(
    //------input-------
    input clk,rst,
    input [N-1:0]PCNext,
    //------------------
    //------Output-------
    output reg [N-1:0]PC
    //-------------------
);
//---------Logice-------------------
always @(posedge clk or posedge rst) 
begin
    if(rst)
        PC<=0;
    else
        PC<=PCNext;
end
//-----------------------------------
endmodule
