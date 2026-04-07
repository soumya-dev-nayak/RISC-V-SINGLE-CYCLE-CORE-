module ALU #(parameter N = 32) (

    input  [N-1:0] A,
    input  [N-1:0] B,
    input  [3:0]   con,

    output reg [N-1:0] res,
    output zero,
    output reg carry,
    output reg overflow,
    output negative
);

reg [N:0] temp;   // for carry

always @(*) begin

    // Default assignments (VERY IMPORTANT)
    res = 0;
    carry = 0;
    overflow = 0;

    case(con)

    4'b0000: begin // ADD
        temp = A + B;
        res = temp[N-1:0];
        carry = temp[N];
        overflow = (A[N-1]==B[N-1]) && (res[N-1]!=A[N-1]);
    end

    4'b0001: begin // SUB
        temp = A - B;
        res = temp[N-1:0];
        carry = temp[N];
        overflow = (A[N-1]!=B[N-1]) && (res[N-1]!=A[N-1]);
    end

    4'b0010: res = A & B; // AND

    4'b0011: res = A | B; // OR

    4'b0100: res = A ^ B; // XOR

    4'b0101: res = ($signed(A) < $signed(B)) ? 32'd1 : 32'd0; // SLT

    4'b0110: res = (A < B) ? 32'd1 : 32'd0; // SLTU

    4'b0111: res = {B[31:12],12'b0}; // LUI

    4'b1000: res = A + {B[31:12],12'b0}; // AUIPC

    4'b1001: res = B; // MOVE

    4'b1010: res = A << B[4:0]; // SLL

    4'b1011: res = $signed(A) >>> B[4:0]; // SRA

    4'b1100: res = A >> B[4:0]; // SRL

    default: res = 0;

    endcase
end

assign zero = (res == 0);
assign negative = res[N-1];

endmodule
