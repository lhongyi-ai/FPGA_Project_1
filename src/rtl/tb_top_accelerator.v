`timescale 1ns/1ps

module tb_top_accelerator;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg [7:0]  w_write_addr;
    reg [7:0]  w_write_data;
    reg        w_write_en;
    reg [7:0]  a_write_addr;
    reg [7:0]  a_write_data;
    reg        a_write_en;
    wire       done;
    wire [31:0] result;

    integer i;

    top_accelerator dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .w_write_addr(w_write_addr),
        .w_write_data(w_write_data),
        .w_write_en(w_write_en),
        .a_write_addr(a_write_addr),
        .a_write_data(a_write_data),
        .a_write_en(a_write_en),
        .done(done),
        .result(result)
    );

    always #5 clk = ~clk;

    initial begin
        $monitor("t=%0t clk=%b start=%b done=%b result=%0d", $time, clk, start, done, result);
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        w_write_addr = 8'd0;
        w_write_data = 8'd0;
        w_write_en = 1'b0;
        a_write_addr = 8'd0;
        a_write_data = 8'd0;
        a_write_en = 1'b0;

        #10 rst_n = 1;

        // Load 3x3 weight kernel: [1,2,3; 4,5,6; 7,8,9]
        @(posedge clk);
        w_write_en <= 1'b1;
        for (i = 0; i < 9; i = i + 1) begin
            w_write_addr <= i;
            w_write_data <= i + 1;
            @(posedge clk);
        end
        w_write_en <= 1'b0;

        // Load a 6x6 input image of all ones
        @(posedge clk);
        a_write_en <= 1'b1;
        for (i = 0; i < 36; i = i + 1) begin
            a_write_addr <= i;
            a_write_data <= 8'd1;
            @(posedge clk);
        end
        a_write_en <= 1'b0;

        // Start the 3x3 convolution pipeline
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        wait(done);
        repeat (1) @(posedge clk);

        if (result === 32'd45) begin
            $display("PASS: done=%0d result=%0d", done, result);
        end else begin
            $display("FAIL: done=%0d result=%0d", done, result);
        end
        $finish;
    end
endmodule
