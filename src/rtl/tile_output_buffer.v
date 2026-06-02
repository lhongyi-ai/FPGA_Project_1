// Simple tile output buffer: synchronous write, combinational read
module tile_output_buffer #(
    parameter TILE_H = 13,
    parameter TILE_W = 13
) (
    input  wire        clk,
    input  wire        rst_n,
    // write interface
    input  wire        wr_en,
    input  wire [7:0]  wr_addr,
    input  wire [31:0] wr_data,
    // read interface
    input  wire [7:0]  rd_addr,
    output wire [31:0] rd_data
);

    localparam DEPTH = TILE_H * TILE_W;

    reg [31:0] mem [0:DEPTH-1];

    // synchronous write
    always @(posedge clk) begin
        if (!rst_n) begin
            // no reset init
        end else begin
            if (wr_en) begin
                mem[wr_addr] <= wr_data;
            end
        end
    end

    // combinational read
    assign rd_data = mem[rd_addr];

endmodule
