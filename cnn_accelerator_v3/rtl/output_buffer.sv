// Output storage for 26x26x4 signed INT32 results.
module output_buffer #(
    parameter int ACC_W  = 32,
    parameter int OUT_W  = 26,
    parameter int OUT_H  = 26,
    parameter int OUT_CH = 4
) (
    input  logic                     clk,
    input  logic                     rst_n,
    input  logic                     write_en,
    input  logic [$clog2(OUT_W*OUT_H*OUT_CH)-1:0] write_addr,
    input  logic signed [ACC_W-1:0]  write_data,
    input  logic [$clog2(OUT_W*OUT_H*OUT_CH)-1:0] read_addr,
    output logic signed [ACC_W-1:0]  read_data
);
    localparam int DEPTH = OUT_W * OUT_H * OUT_CH;

    logic signed [ACC_W-1:0] mem [0:DEPTH-1];

    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
            end
        end else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end

    always_comb begin
        read_data = mem[read_addr];
    end
endmodule
