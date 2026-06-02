// Simple combinational tile address generator (skeleton)
module tile_address_generator (
    // use 32-bit widths to match common usage sites
    input  wire [31:0] img_width,
    input  wire [31:0] img_height,
    input  wire [31:0] out_tile_h,
    input  wire [31:0] out_tile_w,
    input  wire [31:0] k_size,
    input  wire [1:0]  tile_y,
    input  wire [1:0]  tile_x,
    input  wire [3:0]  local_y,
    input  wire [3:0]  local_x,
    input  wire [1:0]  ky,
    input  wire [1:0]  kx,
    output wire [31:0] input_addr,
    output wire [31:0] output_addr
);

    // Compute global output coords
    wire [31:0] global_y = tile_y * out_tile_h + local_y;
    wire [31:0] global_x = tile_x * out_tile_w + local_x;

    // Compute input coords (with kernel offsets)
    wire [31:0] in_y = global_y + ky;
    wire [31:0] in_x = global_x + kx;

    assign input_addr  = in_y * img_width + in_x;
    assign output_addr = global_y * (img_width - (k_size - 1)) + global_x;

endmodule
