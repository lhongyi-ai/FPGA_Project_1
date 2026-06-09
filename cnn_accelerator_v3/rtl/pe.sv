// Processing element for signed INT8 multiply and INT32 accumulation.
module pe #(
    parameter int DATA_W = 8,
    parameter int ACC_W  = 32
) (
    input  logic                         clk,
    input  logic                         rst_n,
    input  logic                         clear,
    input  logic                         valid_in,
    input  logic signed [DATA_W-1:0]     act_in,
    input  logic signed [DATA_W-1:0]     weight_in,
    input  logic signed [ACC_W-1:0]      psum_in,
    output logic                         valid_out,
    output logic signed [DATA_W-1:0]     act_out,
    output logic signed [DATA_W-1:0]     weight_out,
    output logic signed [ACC_W-1:0]      psum_out
);
    logic signed [DATA_W-1:0] act_reg;
    logic signed [DATA_W-1:0] weight_reg;
    logic signed [ACC_W-1:0]  acc_reg;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            act_reg   <= '0;
            weight_reg <= '0;
            acc_reg   <= '0;
            valid_out <= 1'b0;
        end else begin
            valid_out <= valid_in;
            act_reg   <= act_in;
            weight_reg <= weight_in;

            if (clear) begin
                acc_reg <= psum_in;
            end else if (valid_in) begin
                acc_reg <= acc_reg + (act_in * weight_in);
            end
        end
    end

    assign act_out    = act_reg;
    assign weight_out = weight_reg;
    assign psum_out   = acc_reg;
endmodule
