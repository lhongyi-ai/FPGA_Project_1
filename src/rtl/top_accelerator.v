module top_accelerator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  w_write_addr,
    input  wire [7:0]  w_write_data,
    input  wire        w_write_en,
    input  wire [7:0]  a_write_addr,
    input  wire [7:0]  a_write_data,
    input  wire        a_write_en,
    output reg         done,
    output reg  [31:0] result
);

    localparam IMG_WIDTH  = 6;
    localparam IMG_HEIGHT = 6;
    localparam OUT_WIDTH  = IMG_WIDTH - 2;
    localparam OUT_HEIGHT = IMG_HEIGHT - 2;

    wire [7:0] weight_word0;
    wire [7:0] weight_word1;
    wire [7:0] weight_word2;
    wire [7:0] weight_word3;
    wire [7:0] weight_word4;
    wire [7:0] weight_word5;
    wire [7:0] weight_word6;
    wire [7:0] weight_word7;
    wire [7:0] weight_word8;

    wire [7:0] act_word0;
    wire [7:0] act_word1;
    wire [7:0] act_word2;
    wire [7:0] act_word3;
    wire [7:0] act_word4;
    wire [7:0] act_word5;
    wire [7:0] act_word6;
    wire [7:0] act_word7;
    wire [7:0] act_word8;

    wire signed [31:0] mac_sum;
    wire [7:0] base_addr;
    wire [7:0] act_read_addr0;
    wire [7:0] act_read_addr1;
    wire [7:0] act_read_addr2;
    wire [7:0] act_read_addr3;
    wire [7:0] act_read_addr4;
    wire [7:0] act_read_addr5;
    wire [7:0] act_read_addr6;
    wire [7:0] act_read_addr7;
    wire [7:0] act_read_addr8;

    reg [2:0] row;
    reg [2:0] col;

    localparam IDLE = 2'd0,
               RUN  = 2'd1,
               DONE = 2'd2;

    reg [1:0] state;

    assign base_addr      = row * IMG_WIDTH + col;
    assign act_read_addr0 = base_addr + 8'd0;
    assign act_read_addr1 = base_addr + 8'd1;
    assign act_read_addr2 = base_addr + 8'd2;
    assign act_read_addr3 = base_addr + IMG_WIDTH + 8'd0;
    assign act_read_addr4 = base_addr + IMG_WIDTH + 8'd1;
    assign act_read_addr5 = base_addr + IMG_WIDTH + 8'd2;
    assign act_read_addr6 = base_addr + IMG_WIDTH * 2 + 8'd0;
    assign act_read_addr7 = base_addr + IMG_WIDTH * 2 + 8'd1;
    assign act_read_addr8 = base_addr + IMG_WIDTH * 2 + 8'd2;

    cache_buffer u_weight_buf0 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd0),
        .read_data(weight_word0)
    );

    cache_buffer u_weight_buf1 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd1),
        .read_data(weight_word1)
    );

    cache_buffer u_weight_buf2 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd2),
        .read_data(weight_word2)
    );

    cache_buffer u_weight_buf3 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd3),
        .read_data(weight_word3)
    );

    cache_buffer u_weight_buf4 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd4),
        .read_data(weight_word4)
    );

    cache_buffer u_weight_buf5 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd5),
        .read_data(weight_word5)
    );

    cache_buffer u_weight_buf6 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd6),
        .read_data(weight_word6)
    );

    cache_buffer u_weight_buf7 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd7),
        .read_data(weight_word7)
    );

    cache_buffer u_weight_buf8 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(8'd8),
        .read_data(weight_word8)
    );

    cache_buffer u_act_buf0 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr0),
        .read_data(act_word0)
    );

    cache_buffer u_act_buf1 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr1),
        .read_data(act_word1)
    );

    cache_buffer u_act_buf2 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr2),
        .read_data(act_word2)
    );

    cache_buffer u_act_buf3 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr3),
        .read_data(act_word3)
    );

    cache_buffer u_act_buf4 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr4),
        .read_data(act_word4)
    );

    cache_buffer u_act_buf5 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr5),
        .read_data(act_word5)
    );

    cache_buffer u_act_buf6 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr6),
        .read_data(act_word6)
    );

    cache_buffer u_act_buf7 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr7),
        .read_data(act_word7)
    );

    cache_buffer u_act_buf8 (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(act_read_addr8),
        .read_data(act_word8)
    );

    mac9 u_mac9 (
        .in0(act_word0),
        .in1(act_word1),
        .in2(act_word2),
        .in3(act_word3),
        .in4(act_word4),
        .in5(act_word5),
        .in6(act_word6),
        .in7(act_word7),
        .in8(act_word8),
        .w0(weight_word0),
        .w1(weight_word1),
        .w2(weight_word2),
        .w3(weight_word3),
        .w4(weight_word4),
        .w5(weight_word5),
        .w6(weight_word6),
        .w7(weight_word7),
        .w8(weight_word8),
        .sum(mac_sum)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state  <= IDLE;
            done   <= 1'b0;
            result <= 32'd0;
            row    <= 3'd0;
            col    <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    done   <= 1'b0;
                    result <= 32'd0;
                    row    <= 3'd0;
                    col    <= 3'd0;
                    if (start)
                        state <= RUN;
                end

                RUN: begin
                    result <= mac_sum;
                    if (row == OUT_HEIGHT - 1 && col == OUT_WIDTH - 1) begin
                        done  <= 1'b1;
                        state <= DONE;
                    end else begin
                        if (col == OUT_WIDTH - 1) begin
                            col <= 3'd0;
                            row <= row + 3'd1;
                        end else begin
                            col <= col + 3'd1;
                        end
                    end
                end

                DONE: begin
                    done <= 1'b1;
                    if (!start)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
