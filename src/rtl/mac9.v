module mac9 (
    input  wire signed [7:0]  in0,
    input  wire signed [7:0]  in1,
    input  wire signed [7:0]  in2,
    input  wire signed [7:0]  in3,
    input  wire signed [7:0]  in4,
    input  wire signed [7:0]  in5,
    input  wire signed [7:0]  in6,
    input  wire signed [7:0]  in7,
    input  wire signed [7:0]  in8,

    input  wire signed [7:0]  w0,
    input  wire signed [7:0]  w1,
    input  wire signed [7:0]  w2,
    input  wire signed [7:0]  w3,
    input  wire signed [7:0]  w4,
    input  wire signed [7:0]  w5,
    input  wire signed [7:0]  w6,
    input  wire signed [7:0]  w7,
    input  wire signed [7:0]  w8,

    output wire signed [31:0] sum
);

    wire signed [15:0] p0 = in0 * w0;
    wire signed [15:0] p1 = in1 * w1;
    wire signed [15:0] p2 = in2 * w2;
    wire signed [15:0] p3 = in3 * w3;
    wire signed [15:0] p4 = in4 * w4;
    wire signed [15:0] p5 = in5 * w5;
    wire signed [15:0] p6 = in6 * w6;
    wire signed [15:0] p7 = in7 * w7;
    wire signed [15:0] p8 = in8 * w8;

    assign sum =
        {{16{p0[15]}}, p0} +
        {{16{p1[15]}}, p1} +
        {{16{p2[15]}}, p2} +
        {{16{p3[15]}}, p3} +
        {{16{p4[15]}}, p4} +
        {{16{p5[15]}}, p5} +
        {{16{p6[15]}}, p6} +
        {{16{p7[15]}}, p7} +
        {{16{p8[15]}}, p8};

endmodule
