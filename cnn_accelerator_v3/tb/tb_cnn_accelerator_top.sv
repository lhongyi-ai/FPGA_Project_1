`timescale 1ns/1ps

module tb_cnn_accelerator_top;
    localparam int OUT_W  = 26;
    localparam int OUT_H  = 26;
    localparam int OUT_CH = 4;
    localparam int OUT_DEPTH = OUT_W * OUT_H * OUT_CH;

    logic clk;
    logic rst_n;
    logic start;
    logic done;

    cnn_accelerator_top dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .done(done)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    integer fd;
    integer i;

    initial begin
        rst_n = 1'b0;
        start = 1'b0;

        repeat (5) @(posedge clk);
        rst_n = 1'b1;

        repeat (3) @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        wait (done);
        repeat (2) @(posedge clk);

        fd = $fopen("mem/rtl_output.mem", "w");
        if (fd == 0) begin
            $fatal(1, "Could not open mem/rtl_output.mem");
        end

        for (i = 0; i < OUT_DEPTH; i++) begin
            $fwrite(fd, "%08h\n", dut.u_output_buffer.mem[i]);
        end
        $fclose(fd);

        $display("CNN accelerator V3 simulation complete.");
        $finish;
    end

    initial begin
        #1000000;
        $fatal(1, "Simulation timeout");
    end
endmodule
