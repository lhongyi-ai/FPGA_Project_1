// Presents one activation/weight pair from the active tile buffers.
module data_feeder #(
    parameter int DATA_W    = 8,
    parameter int K         = 3,
    parameter int TILE_IN_W = 15
) (
    input  logic [$clog2(13)-1:0] local_y,
    input  logic [$clog2(13)-1:0] local_x,
    input  logic [$clog2(K)-1:0]  ky,
    input  logic [$clog2(K)-1:0]  kx,
    input  logic signed [DATA_W-1:0] input_buffer_data,
    input  logic signed [DATA_W-1:0] weight_buffer_data,
    output logic [$clog2(TILE_IN_W*TILE_IN_W)-1:0] input_buffer_addr,
    output logic [$clog2(K*K)-1:0] weight_buffer_addr,
    output logic signed [DATA_W-1:0] act_out,
    output logic signed [DATA_W-1:0] weight_out
);
    always_comb begin
        input_buffer_addr  = (local_y + ky) * TILE_IN_W + (local_x + kx);
        weight_buffer_addr = ky * K + kx;
        act_out            = input_buffer_data;
        weight_out         = weight_buffer_data;
    end
endmodule
