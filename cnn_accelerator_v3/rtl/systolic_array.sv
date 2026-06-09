// Structural 4x4 systolic-style PE fabric.
// The first implementation uses lane [0][0] for the scalar tile schedule, while
// keeping all PE instances visible for future parallel output-channel mapping.
module systolic_array #(
    parameter int DATA_W  = 8,
    parameter int ACC_W   = 32,
    parameter int ARRAY_M = 4,
    parameter int ARRAY_N = 4
) (
    input  logic                                      clk,
    input  logic                                      rst_n,
    input  logic                                      clear,
    input  logic                                      valid_in,
    input  logic signed [DATA_W-1:0]                  act_in,
    input  logic signed [DATA_W-1:0]                  weight_in,
    input  logic signed [ACC_W-1:0]                   psum_seed,
    output logic                                      valid_out,
    output logic signed [ACC_W-1:0]                   psum_out
);
    logic valid_bus [ARRAY_M][ARRAY_N];
    logic signed [DATA_W-1:0] act_bus [ARRAY_M][ARRAY_N];
    logic signed [DATA_W-1:0] weight_bus [ARRAY_M][ARRAY_N];
    logic signed [ACC_W-1:0] psum_bus [ARRAY_M][ARRAY_N];

    genvar r;
    genvar c;
    generate
        for (r = 0; r < ARRAY_M; r++) begin : gen_rows
            for (c = 0; c < ARRAY_N; c++) begin : gen_cols
                logic signed [DATA_W-1:0] pe_act_in;
                logic signed [DATA_W-1:0] pe_weight_in;
                logic signed [ACC_W-1:0]  pe_psum_in;
                logic                     pe_valid_in;

                if (c == 0) begin : gen_left_edge
                    assign pe_act_in = act_in;
                    assign pe_psum_in = (r == 0) ? psum_seed : '0;
                    assign pe_valid_in = (r == 0) ? valid_in : 1'b0;
                end else begin : gen_from_left
                    assign pe_act_in = act_bus[r][c-1];
                    assign pe_psum_in = psum_bus[r][c-1];
                    assign pe_valid_in = valid_bus[r][c-1];
                end

                if (r == 0) begin : gen_top_edge
                    assign pe_weight_in = weight_in;
                end else begin : gen_from_above
                    assign pe_weight_in = weight_bus[r-1][c];
                end

                pe #(
                    .DATA_W(DATA_W),
                    .ACC_W(ACC_W)
                ) u_pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .clear(clear),
                    .valid_in(pe_valid_in),
                    .act_in(pe_act_in),
                    .weight_in(pe_weight_in),
                    .psum_in(pe_psum_in),
                    .valid_out(valid_bus[r][c]),
                    .act_out(act_bus[r][c]),
                    .weight_out(weight_bus[r][c]),
                    .psum_out(psum_bus[r][c])
                );
            end
        end
    endgenerate

    assign valid_out = valid_bus[0][0];
    assign psum_out  = psum_bus[0][0];
endmodule
