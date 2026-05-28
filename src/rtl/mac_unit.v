module mac_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  a,
    input  wire [7:0]  b,
    input  wire        accum_en,
    input  wire        clear_acc,
    output reg  [15:0] acc
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || clear_acc)
            acc <= 16'd0;
        else if (accum_en)
            acc <= acc + (a * b);
    end
endmodule
