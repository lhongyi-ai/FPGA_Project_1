// Signed INT32 ReLU activation.
module relu #(
    parameter int ACC_W = 32
) (
    input  logic signed [ACC_W-1:0] in_data,
    output logic signed [ACC_W-1:0] out_data
);
    assign out_data = (in_data < 0) ? '0 : in_data;
endmodule
