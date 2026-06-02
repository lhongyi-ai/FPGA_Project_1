// Simple tile input buffer: synchronous write, combinational read
module tile_input_buffer #(
    parameter TILE_H = 15,
    parameter TILE_W = 15
) (
    input  wire        clk,
    input  wire        rst_n,
    // write interface
    input  wire        wr_en,
    input  wire [7:0]  wr_addr,
    input  wire [7:0]  wr_data,
    // local coordinates within tile for window read
    input  wire [3:0]  local_y,
    input  wire [3:0]  local_x,
    // 3x3 window outputs
    output wire [7:0]  win0,
    output wire [7:0]  win1,
    output wire [7:0]  win2,
    output wire [7:0]  win3,
    output wire [7:0]  win4,
    output wire [7:0]  win5,
    output wire [7:0]  win6,
    output wire [7:0]  win7,
    output wire [7:0]  win8
);

    localparam DEPTH = TILE_H * TILE_W;

    reg [7:0] mem [0:DEPTH-1];

    // synchronous write
    always @(posedge clk) begin
        if (!rst_n) begin
            // no reset initialization required for tile buffer
        end else if (wr_en) begin
            mem[wr_addr] <= wr_data;
        end
    end

    // combinational window read
    assign win0 = mem[(local_y + 0) * TILE_W + (local_x + 0)];
    assign win1 = mem[(local_y + 0) * TILE_W + (local_x + 1)];
    assign win2 = mem[(local_y + 0) * TILE_W + (local_x + 2)];
    assign win3 = mem[(local_y + 1) * TILE_W + (local_x + 0)];
    assign win4 = mem[(local_y + 1) * TILE_W + (local_x + 1)];
    assign win5 = mem[(local_y + 1) * TILE_W + (local_x + 2)];
    assign win6 = mem[(local_y + 2) * TILE_W + (local_x + 0)];
    assign win7 = mem[(local_y + 2) * TILE_W + (local_x + 1)];
    assign win8 = mem[(local_y + 2) * TILE_W + (local_x + 2)];

endmodule
