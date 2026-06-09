// Converts tile/local/kernel coordinates into flat memory addresses.
module address_generator #(
    parameter int IN_W       = 28,
    parameter int OUT_W      = 26,
    parameter int OUT_H      = 26,
    parameter int K          = 3,
    parameter int TILE_OUT_W = 13,
    parameter int TILE_OUT_H = 13,
    parameter int TILE_IN_W  = 15
) (
    input  logic tile_y,
    input  logic tile_x,
    input  logic [1:0] oc,
    input  logic [$clog2(TILE_OUT_H)-1:0] local_y,
    input  logic [$clog2(TILE_OUT_W)-1:0] local_x,
    input  logic [$clog2(K)-1:0] ky,
    input  logic [$clog2(K)-1:0] kx,
    output logic [$clog2(IN_W*IN_W)-1:0] input_addr,
    output logic [$clog2(4*K*K)-1:0] weight_addr,
    output logic [$clog2(OUT_W*OUT_H*4)-1:0] output_addr,
    output logic [$clog2(TILE_IN_W*TILE_IN_W)-1:0] tile_input_addr,
    output logic [$clog2(K*K)-1:0] tile_weight_addr
);
    logic [$clog2(OUT_H)-1:0] global_y;
    logic [$clog2(OUT_W)-1:0] global_x;

    always_comb begin
        global_y = (tile_y ? TILE_OUT_H : 0) + local_y;
        global_x = (tile_x ? TILE_OUT_W : 0) + local_x;

        input_addr      = (global_y + ky) * IN_W + (global_x + kx);
        weight_addr     = oc * (K * K) + ky * K + kx;
        output_addr     = oc * (OUT_W * OUT_H) + global_y * OUT_W + global_x;
        tile_input_addr = (local_y + ky) * TILE_IN_W + (local_x + kx);
        tile_weight_addr = ky * K + kx;
    end
endmodule
