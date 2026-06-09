// Ping-pong storage for one 3x3 signed INT8 kernel.
module weight_double_buffer #(
    parameter int DATA_W = 8,
    parameter int K      = 3
) (
    input  logic                 clk,
    input  logic                 rst_n,
    input  logic                 load_en,
    input  logic                 load_sel,
    input  logic                 compute_sel,
    input  logic                 clear_valid,
    input  logic                 mark_valid,
    input  logic [$clog2(K*K)-1:0] load_addr,
    input  logic signed [DATA_W-1:0] load_data,
    input  logic [$clog2(K*K)-1:0] read_addr,
    output logic signed [DATA_W-1:0] read_data,
    output logic                 valid_a,
    output logic                 valid_b
);
    localparam int DEPTH = K * K;

    logic signed [DATA_W-1:0] buf_a [0:DEPTH-1];
    logic signed [DATA_W-1:0] buf_b [0:DEPTH-1];

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            valid_a <= 1'b0;
            valid_b <= 1'b0;
        end else begin
            if (load_en) begin
                if (load_sel) begin
                    buf_b[load_addr] <= load_data;
                end else begin
                    buf_a[load_addr] <= load_data;
                end
            end

            if (clear_valid) begin
                if (load_sel) valid_b <= 1'b0;
                else          valid_a <= 1'b0;
            end

            if (mark_valid) begin
                if (load_sel) valid_b <= 1'b1;
                else          valid_a <= 1'b1;
            end
        end
    end

    always_comb begin
        read_data = compute_sel ? buf_b[read_addr] : buf_a[read_addr];
    end
endmodule
