module accumulator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        clear,
    input  wire        enable,
    input  wire signed [31:0] data_in,
    output reg  signed [31:0] data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear)
            data_out <= 32'sd0;
        else if (enable)
            data_out <= data_out + data_in;
    end
endmodule
