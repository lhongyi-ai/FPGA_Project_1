module dma_ctrl (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  len,
    output reg  [7:0]  addr,
    output reg         ready,
    output reg         done
);

    reg [7:0] count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr   <= 8'd0;
            count  <= 8'd0;
            ready  <= 1'b1;
            done   <= 1'b0;
        end else if (start && ready) begin
            addr   <= 8'd0;
            count  <= 8'd0;
            ready  <= 1'b0;
            done   <= 1'b0;
        end else if (!ready) begin
            if (count < len) begin
                addr  <= count;
                count <= count + 8'd1;
            end else begin
                ready <= 1'b1;
                done  <= 1'b1;
            end
        end
    end
endmodule
