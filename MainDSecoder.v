//=============================================================
// Main Decoder  –  FULLY UPGRADED
//
// CHANGES from original:
//   1. ImmSrc expanded to 3 bits (supports U-type for LUI/AUIPC)
//   2. LUI: ImmSrc=3'b100 (U-type), ALUSrc=1, ResultSrc=2'b00 (ALU result = imm)
//   3. AUIPC: ImmSrc=3'b100 (U-type), ALUSrcA=1 (use PC as ALU operand A)
//   4. JAL:  Jump=1, ImmSrc=3'b011 (J-type), ResultSrc=2'b10 (PC+4 link)
//   5. JALR: Jump=1, JalrSel=1, ImmSrc=3'b000 (I-type), ResultSrc=2'b10
//   6. Added ALUSrcA: 0=rs1_data (normal), 1=PC_reg (for AUIPC)
//   7. Added JalrSel: distinguishes JALR from JAL for PC-mux selection
//=============================================================
module MainDecoder(
    input  [6:0] op,

    output reg        RegWrite,
    output reg [2:0]  ImmSrc,     // 3-bit (was 2-bit)
    output reg        ALUSrc,     // SrcB mux: 0=rs2, 1=imm
    output reg        ALUSrcA,    // SrcA mux: 0=rs1, 1=PC  (NEW for AUIPC)
    output reg        MemWrite,
    output reg [1:0]  ResultSrc,
    output reg        Branch,
    output reg [1:0]  ALUop,
    output reg        Jump,
    output reg        JalrSel     // NEW: 1=JALR (target=ALU result), 0=JAL (target=PC+Imm)
);

always @(*) begin

    // Safe defaults (prevent latches)
    RegWrite  = 1'b0;
    ImmSrc    = 3'b000;
    ALUSrc    = 1'b0;
    ALUSrcA   = 1'b0;
    MemWrite  = 1'b0;
    ResultSrc = 2'b00;
    Branch    = 1'b0;
    ALUop     = 2'b00;
    Jump      = 1'b0;
    JalrSel   = 1'b0;

    case (op)

    //--------------------------------------------------
    // LOAD  (lw, lh, lb, lhu, lbu)
    //--------------------------------------------------
    7'b0000011: begin
        RegWrite  = 1'b1;
        ImmSrc    = 3'b000;   // I-type
        ALUSrc    = 1'b1;
        ResultSrc = 2'b01;    // WB = Mem_data
    end

    //--------------------------------------------------
    // STORE  (sw, sh, sb)
    //--------------------------------------------------
    7'b0100011: begin
        ImmSrc    = 3'b001;   // S-type
        ALUSrc    = 1'b1;
        MemWrite  = 1'b1;
    end

    //--------------------------------------------------
    // R-TYPE  (add, sub, and, or, xor, slt, sltu, sll, srl, sra)
    //--------------------------------------------------
    7'b0110011: begin
        RegWrite  = 1'b1;
        ALUSrc    = 1'b0;     // SrcB = rs2
        ALUop     = 2'b10;
    end

    //--------------------------------------------------
    // I-TYPE ALU  (addi, slti, sltiu, andi, ori, xori, slli, srli, srai)
    //--------------------------------------------------
    7'b0010011: begin
        RegWrite  = 1'b1;
        ImmSrc    = 3'b000;   // I-type
        ALUSrc    = 1'b1;
        ALUop     = 2'b10;
    end

    //--------------------------------------------------
    // BRANCH  (beq, bne, blt, bge, bltu, bgeu)
    //--------------------------------------------------
    7'b1100011: begin
        ImmSrc    = 3'b010;   // B-type
        Branch    = 1'b1;
        ALUop     = 2'b01;
    end

    //--------------------------------------------------
    // JAL  – FIXED: now properly drives Jump=1 which is wired to PC mux
    // PC_target = PC + J-type_imm (handled in IF stage)
    // Link register = PC+4 via ResultSrc=2'b10
    //--------------------------------------------------
    7'b1101111: begin
        RegWrite  = 1'b1;
        ImmSrc    = 3'b011;   // J-type
        ResultSrc = 2'b10;    // WB = PC+4 (link address)
        Jump      = 1'b1;
        JalrSel   = 1'b0;     // target = PC + imm (not ALU result)
    end

    //--------------------------------------------------
    // JALR  – FIXED: Jump=1 now wired, JalrSel=1 selects ALU result as target
    // PC_next = rs1 + I-imm (computed by ALU); link = PC+4
    //--------------------------------------------------
    7'b1100111: begin
        RegWrite  = 1'b1;
        ImmSrc    = 3'b000;   // I-type
        ALUSrc    = 1'b1;
        ResultSrc = 2'b10;    // WB = PC+4 (link address)
        Jump      = 1'b1;
        JalrSel   = 1'b1;     // target = ALU_result (rs1+imm)
    end

    //--------------------------------------------------
    // LUI  – FIXED: now uses U-type immediate (ImmSrc=3'b100)
    // ALU passes imm through; WB takes ALU result = {imm[31:12],12'b0}
    //--------------------------------------------------
    7'b0110111: begin
        RegWrite  = 1'b1;
        ImmSrc    = 3'b100;   // U-type  (FIXED: was 3'b000 I-type → gave wrong imm)
        ALUSrc    = 1'b1;
        ResultSrc = 2'b00;    // WB = ALU result (which is just imm for LUI)
        ALUop     = 2'b11;    // ALUDecoder: LUI → pass-through SrcB
    end

    //--------------------------------------------------
    // AUIPC  – FIXED: uses U-type imm + PC as ALU SrcA
    // result = PC + {imm[31:12], 12'b0}
    //--------------------------------------------------
    7'b0010111: begin
        RegWrite  = 1'b1;
        ImmSrc    = 3'b100;   // U-type  (FIXED: was 3'b000)
        ALUSrc    = 1'b1;
        ALUSrcA   = 1'b1;     // SrcA = PC_reg  (FIXED: was always rs1)
        ResultSrc = 2'b00;    // WB = ALU result = PC + imm
        ALUop     = 2'b00;    // ADD
    end

    endcase
end

endmodule
