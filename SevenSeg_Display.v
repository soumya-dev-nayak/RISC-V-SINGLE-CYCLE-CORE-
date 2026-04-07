// ============================================================
// SevenSeg_Display.v  –  Basys-3 4-Digit 7-Segment Controller
//
// Time-multiplexed display for the RISC-V RV32I Single-Cycle CPU.
// Shows a 32-bit value as 4 hex digits on the Basys-3 display.
//
// Segment encoding (active-low, common-anode):
//   seg = {a, b, c, d, e, f, g}  bit 6=a, bit 0=g
//
//        a(6)
//       -----
//  f(1)|     |b(5)
//       -g(0)-
//  e(2)|     |c(4)
//       -----
//        d(3)
//
// DISPLAY MODES (driven by SW[4:2] via mode[2:0]):
//   000 → ALU result lower 16 bits   (Parts 1-6: register results)
//   001 → ALU result upper 16 bits   (overflow inspection)
//   010 → PC lower 16 bits           (any part: watch instruction fetch)
//   011 → mem_word lower 16 bits     (Parts 7,8: sorted array word)
//   100 → {alu[23:16], alu[7:0]}     (mid-byte debug view)
//   101 → {pc[23:16], alu[7:0]}      (PC + ALU low mix)
//   110 → fibonacci result (x24)     (Part 6: x24 lower 16 bits)
//   111 → Test pattern: 8888         (segment health check)
//
// Decimal point encodes mode number visually:
//   mode 000 → dp off
//   mode 001 → dp on digit 0 (rightmost)
//   mode 010 → dp on digit 1
//   mode 011 → dp on digit 2
//   mode 1xx → dp on all digits
// ============================================================

module SevenSeg_Display #(
    parameter CLK_FREQ  = 100_000_000,  // 100 MHz Basys-3 oscillator
    parameter SCAN_FREQ = 1_000         // 1 kHz scan = 250 Hz per digit
)(
    input  wire        clk,
    input  wire        rst,

    // Data inputs from CPU taps
    input  wire [31:0] alu_result,   // ALU output (tapped from CPU core)
    input  wire [31:0] pc_in,        // Program counter
    input  wire [31:0] mem_word,     // Data memory word (for sort results)

    // 3-bit mode select from switches SW[4:2]
    input  wire [2:0]  mode,

    // Basys-3 7-segment outputs
    output reg  [6:0]  seg,   // {a,b,c,d,e,f,g} active-low
    output reg  [3:0]  an,    // digit anodes     active-low
    output reg         dp     // decimal point    active-low
);

    // ----------------------------------------------------------
    // Scan Clock Divider
    // Tick fires once every (CLK_FREQ / SCAN_FREQ / 4) cycles.
    // Digit counter advances each tick → 4 digits × 250 Hz = 1 kHz scan.
    // ----------------------------------------------------------
    localparam integer SCAN_DIV = CLK_FREQ / (SCAN_FREQ * 4);

    reg [$clog2(SCAN_DIV)-1:0] clk_cnt;
    reg                         tick;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            tick    <= 1'b0;
        end else begin
            tick <= 1'b0;
            if (clk_cnt == SCAN_DIV - 1) begin
                clk_cnt <= 0;
                tick    <= 1'b1;
            end else
                clk_cnt <= clk_cnt + 1;
        end
    end

    // ----------------------------------------------------------
    // Digit Counter
    // ----------------------------------------------------------
    reg [1:0] digit_sel;

    always @(posedge clk or posedge rst) begin
        if (rst)       digit_sel <= 2'd0;
        else if (tick) digit_sel <= digit_sel + 1'd1;
    end

    // ----------------------------------------------------------
    // Mode Multiplexer
    // Selects which 16-bit window of CPU data to display.
    // ----------------------------------------------------------
    reg [15:0] display_val;

    always @(*) begin
        case (mode)
            3'b000: display_val = alu_result[15:0];            // ALU lower
            3'b001: display_val = alu_result[31:16];           // ALU upper
            3'b010: display_val = pc_in[15:0];                 // PC lower
            3'b011: display_val = mem_word[15:0];              // Memory lower
            3'b100: display_val = {alu_result[23:16], alu_result[7:0]};  // mid bytes
            3'b101: display_val = {pc_in[23:16], alu_result[7:0]};       // debug mix
            3'b110: display_val = alu_result[15:0];            // Fibonacci x24 lower
            3'b111: display_val = 16'h8888;                    // test: all 8s
            default: display_val = 16'h0000;
        endcase
    end

    // ----------------------------------------------------------
    // Nibble Selector: routes 4 bits to decoder per scan digit
    // Digit 0 (rightmost) = least significant nibble
    // ----------------------------------------------------------
    reg [3:0] nibble;

    always @(*) begin
        case (digit_sel)
            2'd0: nibble = display_val[3:0];    // digit 0 rightmost
            2'd1: nibble = display_val[7:4];    // digit 1
            2'd2: nibble = display_val[11:8];   // digit 2
            2'd3: nibble = display_val[15:12];  // digit 3 leftmost
            default: nibble = 4'h0;
        endcase
    end

    // ----------------------------------------------------------
    // Anode Driver — active-low one-hot enable
    // One digit illuminated per scan period.
    // ----------------------------------------------------------
    always @(*) begin
        case (digit_sel)
            2'd0: an = 4'b1110;   // digit 0 (U2)
            2'd1: an = 4'b1101;   // digit 1 (U4)
            2'd2: an = 4'b1011;   // digit 2 (V4)
            2'd3: an = 4'b0111;   // digit 3 (W4)
            default: an = 4'b1111;
        endcase
    end

    // ----------------------------------------------------------
    // 7-Segment Hex Decoder (active-low)
    // Covers 0–F so any CPU register value displays correctly.
    // All 8 programs produce hex-interpretable results.
    // ----------------------------------------------------------
    always @(*) begin
        case (nibble)
            4'h0: seg = 7'b1000000;  // 0
            4'h1: seg = 7'b1111001;  // 1
            4'h2: seg = 7'b0100100;  // 2
            4'h3: seg = 7'b0110000;  // 3
            4'h4: seg = 7'b0011001;  // 4
            4'h5: seg = 7'b0010010;  // 5
            4'h6: seg = 7'b0000010;  // 6
            4'h7: seg = 7'b1111000;  // 7
            4'h8: seg = 7'b0000000;  // 8
            4'h9: seg = 7'b0010000;  // 9
            4'hA: seg = 7'b0001000;  // A
            4'hB: seg = 7'b0000011;  // b
            4'hC: seg = 7'b1000110;  // C
            4'hD: seg = 7'b0100001;  // d
            4'hE: seg = 7'b0000110;  // E
            4'hF: seg = 7'b0001110;  // F
            default: seg = 7'b1111111;
        endcase
    end

    // ----------------------------------------------------------
    // Decimal Point — visual mode indicator (active-low)
    // Lets you see which display mode is active at a glance.
    // ----------------------------------------------------------
    always @(*) begin
        case (mode)
            3'b000: dp = 1'b1;                               // off
            3'b001: dp = (digit_sel == 2'd0) ? 1'b0 : 1'b1; // dot on digit 0
            3'b010: dp = (digit_sel == 2'd1) ? 1'b0 : 1'b1; // dot on digit 1
            3'b011: dp = (digit_sel == 2'd2) ? 1'b0 : 1'b1; // dot on digit 2
            default: dp = 1'b0;                              // all dots on (modes 1xx)
        endcase
    end

endmodule
