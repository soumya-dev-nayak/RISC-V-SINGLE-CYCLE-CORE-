//----------SOUMYAAA---------

module ALUDecoder(

    input [1:0] ALUop,
    input [2:0] funct3, 
    input [6:0] funct7,

    output reg [3:0] ALUControl
);

always @(*) begin

    ALUControl = 4'b0000; // default

    case(ALUop)

    //--------------------------------------------------
    // Load / Store / AUIPC → ADD
    //--------------------------------------------------
    2'b00: ALUControl = 4'b0000;

    //--------------------------------------------------
    // Branch
    //--------------------------------------------------
    2'b01: begin
        case(funct3)
            3'b000: ALUControl = 4'b0001; // BEQ
            3'b001: ALUControl = 4'b0001; // BNE
            3'b100: ALUControl = 4'b0101; // BLT
            3'b101: ALUControl = 4'b0101; // BGE
            3'b110: ALUControl = 4'b0110; // BLTU
            3'b111: ALUControl = 4'b0110; // BGEU
        endcase
    end

    //--------------------------------------------------
    // R-type / I-type
    //--------------------------------------------------
    2'b10: begin
        case(funct3)

        3'b000: begin
            if(funct7 == 7'b0100000)
                ALUControl = 4'b0001; // SUB
            else
                ALUControl = 4'b0000; // ADD
        end

        3'b111: ALUControl = 4'b0010; // AND
        3'b110: ALUControl = 4'b0011; // OR
        3'b100: ALUControl = 4'b0100; // XOR
        3'b010: ALUControl = 4'b0101; // SLT
        3'b011: ALUControl = 4'b0110; // SLTU

        3'b001: ALUControl = 4'b1010; // SLL

        3'b101: begin
            if(funct7 == 7'b0100000)
                ALUControl = 4'b1011; // SRA
            else
                ALUControl = 4'b1100; // SRL
        end

        endcase
    end

    //--------------------------------------------------
    // LUI
    //--------------------------------------------------
    2'b11: ALUControl = 4'b0111;

    endcase
end

endmodule
