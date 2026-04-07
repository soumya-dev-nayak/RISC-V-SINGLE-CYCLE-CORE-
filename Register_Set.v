module Register_Set
(
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_data,
    input  wire        reg_write
);
    reg [31:0] regfile [31:0];
    integer i;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 32; i = i + 1)
                regfile[i] <= 32'b0;
        end else begin
            if (reg_write && (rd_addr != 5'b00000))
                regfile[rd_addr] <= rd_data;
        end
    end

    assign rs1_data = (rs1_addr == 5'b00000) ? 32'b0 : regfile[rs1_addr];
    assign rs2_data = (rs2_addr == 5'b00000) ? 32'b0 : regfile[rs2_addr];
endmodule
