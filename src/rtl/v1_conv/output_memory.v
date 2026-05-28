module output_memory (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  write_addr,
    input  wire signed [31:0] write_data,
    input  wire        write_en,
    output reg  signed [31:0] read_data
);

    reg signed [31:0] mem [0:255];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 256; i = i + 1)
                mem[i] <= 32'sd0;
        end else if (write_en) begin
            mem[write_addr] <= write_data;
        end
    end

    always @(*) begin
        read_data = mem[write_addr];
    end
endmodule
