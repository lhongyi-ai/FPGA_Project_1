`timescale 1ns/1ps

module tb_conv_basic;
    reg clk;
    reg rst_n;
    reg start;

    wire done;

    fsm_conv fsm (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done),
        .load_input(),
        .load_weight(),
        .compute(),
        .store_out()
    );

    always #5 clk = ~clk;

    initial begin
        $monitor("t=%0t clk=%b rst_n=%b start=%b done=%b state=%0d", $time, clk, rst_n, start, done, fsm.state);
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        #10 rst_n = 1;
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;
        wait(done);
        #5;
        if (done)
            $display("PASS: FSM done asserted");
        else
            $display("FAIL: FSM not done");
        $finish;
    end
endmodule
