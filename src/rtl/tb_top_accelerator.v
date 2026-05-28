`timescale 1ns/1ps

module tb_top_accelerator;

    reg        clk;
    reg        rst_n;
    reg        start;
    reg [7:0]  dma_len;
    reg [7:0]  w_write_addr;
    reg [7:0]  w_write_data;
    reg        w_write_en;
    reg [7:0]  a_write_addr;
    reg [7:0]  a_write_data;
    reg        a_write_en;
    wire       done;
    wire [15:0] result;

    top_accelerator dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .dma_len(dma_len),
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
        $monitor("t=%0t clk=%b start=%b done=%b state=%0d count=%0d result=%0d", $time, clk, start, done, dut.state, dut.count, result);
    end

    initial begin
        clk = 0;
        rst_n = 0;
        start = 0;
        dma_len = 8'd2;
        w_write_addr = 8'd0;
        w_write_data = 8'd0;
        w_write_en = 1'b0;
        a_write_addr = 8'd0;
        a_write_data = 8'd0;
        a_write_en = 1'b0;

        #10 rst_n = 1;

        // Load weight buffer: [1, 2]
        @(posedge clk);
        w_write_en <= 1'b1;
        w_write_addr <= 8'd0;
        w_write_data <= 8'd1;
        @(posedge clk);
        w_write_addr <= 8'd1;
        w_write_data <= 8'd2;
        @(posedge clk);
        w_write_en <= 1'b0;

        // Load activation buffer: [5, 6]
        @(posedge clk);
        a_write_en <= 1'b1;
        a_write_addr <= 8'd0;
        a_write_data <= 8'd5;
        @(posedge clk);
        a_write_addr <= 8'd1;
        a_write_data <= 8'd6;
        @(posedge clk);
        a_write_en <= 1'b0;

        // Start the accelerator
        @(posedge clk);
        start <= 1'b1;
        @(posedge clk);
        start <= 1'b0;

        wait(done);
        repeat (2) @(posedge clk);

        if (result === 16'd17) begin
            $display("PASS: done=%0d result=%0d", done, result);
        end else begin
            $display("FAIL: done=%0d result=%0d", done, result);
        end
        $finish;
    end
endmodule
