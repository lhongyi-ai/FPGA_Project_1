`timescale 1ns/1ps

module tb_mac_unit;

    reg        clk;
    reg        rst_n;
    reg [7:0]  a;
    reg [7:0]  b;
    reg        accum_en;
    reg        clear_acc;
    wire [15:0] acc;

    mac_unit dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .accum_en(accum_en),
        .clear_acc(clear_acc),
        .acc(acc)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        a = 8'd0;
        b = 8'd0;
        accum_en = 1'b0;
        clear_acc = 1'b0;

        #10 rst_n = 1;
        clear_acc = 1'b1;
        @(posedge clk);
        clear_acc = 1'b0;
        a = 8'd5;
        b = 8'd1;
        accum_en = 1'b1;
        @(posedge clk);
        a = 8'd6;
        b = 8'd2;
        @(posedge clk);
        accum_en = 1'b0;

        if (acc === 16'd17) begin
            $display("PASS: mac_acc=%0d", acc);
        end else begin
            $display("FAIL: mac_acc=%0d", acc);
        end
        $finish;
    end
endmodule
