module top_accelerator (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    input  wire [7:0]  dma_len,
    input  wire [7:0]  w_write_addr,
    input  wire [7:0]  w_write_data,
    input  wire        w_write_en,
    input  wire [7:0]  a_write_addr,
    input  wire [7:0]  a_write_data,
    input  wire        a_write_en,
    output reg         done,
    output reg  [15:0] result
);

    wire [7:0] dma_addr;
    wire       dma_ready;
    wire       dma_done;
    wire [7:0] weight_word;
    wire [7:0] act_word;
    wire [15:0] mac_acc;

    reg [7:0] count;
    reg       run;
    reg       clear_acc;
    reg       accum_en;

    localparam IDLE = 2'd0,
               RUN  = 2'd1,
               FIN  = 2'd2;

    reg [1:0] state;

    dma_ctrl u_dma (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .len(dma_len),
        .addr(dma_addr),
        .ready(dma_ready),
        .done(dma_done)
    );

    cache_buffer u_weight_buf (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(w_write_addr),
        .write_data(w_write_data),
        .write_en(w_write_en),
        .read_addr(dma_addr),
        .read_data(weight_word)
    );

    cache_buffer u_act_buf (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(dma_addr),
        .read_data(act_word)
    );

    mac_unit u_mac (
        .clk(clk),
        .rst_n(rst_n),
        .a(act_word),
        .b(weight_word),
        .accum_en(accum_en),
        .clear_acc(clear_acc),
        .acc(mac_acc)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= IDLE;
            count      <= 8'd0;
            done       <= 1'b0;
            clear_acc  <= 1'b1;
            accum_en   <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done      <= 1'b0;
                    result    <= 16'd0;
                    clear_acc <= 1'b1;
                    accum_en  <= 1'b0;
                    if (start) begin
                        count <= 8'd0;
                        state <= RUN;
                    end
                end

                RUN: begin
                    clear_acc <= 1'b0;
                    if (count < dma_len) begin
                        accum_en <= 1'b1;
                        count    <= count + 8'd1;
                    end else begin
                        accum_en <= 1'b0;
                        done     <= 1'b1;
                        result   <= mac_acc;
                        state    <= FIN;
                    end
                end

                FIN: begin
                    done <= 1'b1;
                    result <= mac_acc;
                    if (!start)
                        state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end
endmodule
