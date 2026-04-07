//=============================================================
// Data Memory
//   Word region layout (byte address = word_idx * 4):
//     [0..4]   = {-5, 12, -3, 8, -1}     Array with negatives (signed sort)
//     [5..9]   = {10, 25, 7, 40, 15}     Original unsorted positive array
//     [10..17] = {-5,12,-3,8,-1,20,-7,4} 8-element mixed array (count negatives)
//     [20..24] = {10,25,7,40,15}         Copy for array sum
//     [25..31] = {0,...}                 Scratch / output area
//
// Addressing: addr[9:2] → word index (byte address / 4)
// This means addresses 0..1023 are valid (256 words × 4 bytes).
//
// MemRead is combinational (async) for single-cycle correctness.
// MemWrite is synchronous (posedge clk).
//=============================================================
module Data_Memory
#(parameter N = 32, DEPTH = 256)
(
    input  wire        clk,
    input  wire        rst,
    input  wire        MemWrite,
    input  wire        MemRead,
    input  wire [N-1:0] addr,
    input  wire [N-1:0] write_data,
    output reg  [N-1:0] read_data
);
    reg [N-1:0] mem [0:DEPTH-1];
    integer j;

    initial begin
        for (j = 0; j < DEPTH; j = j + 1)
            mem[j] = 32'd0;

        // ---- Array 1: Signed  {-5, 12, -3, 8, -1}  at words 0..4 (byte 0..16) ----
        // Used by: PART 7 Bubble Sort, PART 8 Insertion Sort
        // Sorted ascending: {-5, -3, -1, 8, 12}
        mem[0] = 32'hFFFFFFFB; // -5
        mem[1] = 32'h0000000C; // 12
        mem[2] = 32'hFFFFFFFD; // -3
        mem[3] = 32'h00000008; //  8
        mem[4] = 32'hFFFFFFFF; // -1

        // ---- Array 2: Unsigned  {10, 25, 7, 40, 15}  at words 5..9 (byte 20..36) ----
        // (kept for compatibility with old PART 3 / PART 4 branchless programs)
        mem[5]  = 32'd10;
        mem[6]  = 32'd25;
        mem[7]  = 32'd7;
        mem[8]  = 32'd40;
        mem[9]  = 32'd15;

        // ---- Array 3: Mixed 8-element  at words 10..17 (byte 40..68) ----
        // Used by: PART 3 Count Negatives  → expects 4 negatives
        mem[10] = 32'hFFFFFFFB; // -5
        mem[11] = 32'h0000000C; // 12
        mem[12] = 32'hFFFFFFFD; // -3
        mem[13] = 32'h00000008; //  8
        mem[14] = 32'hFFFFFFFF; // -1
        mem[15] = 32'h00000014; // 20
        mem[16] = 32'hFFFFFFF9; // -7
        mem[17] = 32'h00000004; //  4

        // ---- Array 4: Positive copy for sum  at words 20..24 (byte 80..96) ----
        // Used by: PART 2 Array Sum → expects sum=97
        mem[20] = 32'd10;
        mem[21] = 32'd25;
        mem[22] = 32'd7;
        mem[23] = 32'd40;
        mem[24] = 32'd15;

        // Words 25..255: cleared to zero (scratch / output area)
    end

    // Synchronous write
    always @(posedge clk) begin
        if (MemWrite)
            mem[addr[9:2]] <= write_data;
    end

    // Asynchronous (combinational) read – correct for single-cycle
    always @(*) begin
        if (MemRead)
            read_data = mem[addr[9:2]];
        else
            read_data = 32'b0;
    end

endmodule
