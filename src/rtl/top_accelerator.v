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

    localparam IMG_WIDTH   = 6;
    localparam IMG_HEIGHT  = 6;
    localparam OUT_WIDTH   = IMG_WIDTH - 2;
    localparam OUT_HEIGHT  = IMG_HEIGHT - 2;
    localparam TILE_OUT_W  = 4;
    localparam TILE_OUT_H  = 4;
    localparam TILE_IN_W   = TILE_OUT_W + 2;
    localparam TILE_IN_H   = TILE_OUT_H + 2;
    localparam TILE_IN_SIZE  = TILE_IN_W * TILE_IN_H;
    localparam TILE_OUT_SIZE = TILE_OUT_W * TILE_OUT_H;

    wire [7:0] weight_word0;
    wire [7:0] weight_word1;
    wire [7:0] weight_word2;
    wire [7:0] weight_word3;
    wire [7:0] weight_word4;
    wire [7:0] weight_word5;
    wire [7:0] weight_word6;
    wire [7:0] weight_word7;
    wire [7:0] weight_word8;

    wire [7:0] tile_win0;
    wire [7:0] tile_win1;
    wire [7:0] tile_win2;
    wire [7:0] tile_win3;
    wire [7:0] tile_win4;
    wire [7:0] tile_win5;
    wire [7:0] tile_win6;
    wire [7:0] tile_win7;
    wire [7:0] tile_win8;

    wire [7:0] full_input_read_data;
    wire signed [31:0] mac_sum;
    wire [31:0] tile_input_addr;
    wire [31:0] tile_output_addr;
    wire [31:0] output_read_data;

    reg [7:0] full_input_read_addr;
    reg [3:0] load_x;
    reg [3:0] load_y;
    reg [3:0] comp_x;
    reg [3:0] comp_y;
    reg [3:0] write_x;
    reg [3:0] write_y;

    wire [7:0] tile_in_wr_addr;
    wire [7:0] tile_out_wr_addr;
    wire [7:0] tile_out_rd_addr;

    // Expanded FSM for tiled operation
    localparam S_IDLE        = 3'd0,
               S_LOAD_TILE   = 3'd1,
               S_COMPUTE     = 3'd2,
               S_WRITE_TILE  = 3'd3,
               S_DONE        = 3'd4;

    reg [2:0] state;

    // Tile counters (skeleton, not fully used for current small example)
    reg [1:0] oc;        // output channel index (0..3 for larger designs)
    reg [1:0] tile_y;    // tile row index
    reg [1:0] tile_x;    // tile col index

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

    cache_buffer u_full_input_buf (
        .clk(clk),
        .rst_n(rst_n),
        .write_addr(a_write_addr),
        .write_data(a_write_data),
        .write_en(a_write_en),
        .read_addr(full_input_read_addr),
        .read_data(full_input_read_data)
    );

    mac9 u_mac9 (
        .in0(tile_win0),
        .in1(tile_win1),
        .in2(tile_win2),
        .in3(tile_win3),
        .in4(tile_win4),
        .in5(tile_win5),
        .in6(tile_win6),
        .in7(tile_win7),
        .in8(tile_win8),
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
    // Instantiate tile/address/buffer modules
    wire [31:0] tile_in_h32  = TILE_IN_H;
    wire [31:0] tile_in_w32  = TILE_IN_W;
    wire [31:0] tile_out_h32 = TILE_OUT_H;
    wire [31:0] tile_out_w32 = TILE_OUT_W;

    assign tile_in_wr_addr  = load_y * TILE_IN_W + load_x;
    assign tile_out_wr_addr = comp_y * TILE_OUT_W + comp_x;
    assign tile_out_rd_addr = write_y * TILE_OUT_W + write_x;

    tile_address_generator u_tile_addr_gen_in (
        .img_width(IMG_WIDTH),
        .img_height(IMG_HEIGHT),
        .out_tile_h(tile_in_h32),
        .out_tile_w(tile_in_w32),
        .k_size(32'd1),
        .tile_y(tile_y),
        .tile_x(tile_x),
        .local_y(load_y),
        .local_x(load_x),
        .ky(2'd0),
        .kx(2'd0),
        .input_addr(tile_input_addr),
        .output_addr()
    );

    tile_address_generator u_tile_addr_gen_out (
        .img_width(IMG_WIDTH),
        .img_height(IMG_HEIGHT),
        .out_tile_h(tile_out_h32),
        .out_tile_w(tile_out_w32),
        .k_size(32'd3),
        .tile_y(tile_y),
        .tile_x(tile_x),
        .local_y(write_y),
        .local_x(write_x),
        .ky(2'd0),
        .kx(2'd0),
        .input_addr(),
        .output_addr(tile_output_addr)
    );

    tile_input_buffer #(
        .TILE_H(TILE_IN_H),
        .TILE_W(TILE_IN_W)
    ) u_tile_in_buf (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(state == S_LOAD_TILE),
        .wr_addr(tile_in_wr_addr),
        .wr_data(full_input_read_data),
        .local_y(comp_y),
        .local_x(comp_x),
        .win0(tile_win0),
        .win1(tile_win1),
        .win2(tile_win2),
        .win3(tile_win3),
        .win4(tile_win4),
        .win5(tile_win5),
        .win6(tile_win6),
        .win7(tile_win7),
        .win8(tile_win8)
    );

    tile_output_buffer #(
        .TILE_H(TILE_OUT_H),
        .TILE_W(TILE_OUT_W)
    ) u_tile_out_buf (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(state == S_COMPUTE),
        .wr_addr(tile_out_wr_addr),
        .wr_data(mac_sum),
        .rd_addr(tile_out_rd_addr),
        .rd_data(output_read_data)
    );

    // Tiled FSM with actual load/compute/write tile flow
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state                <= S_IDLE;
            done                 <= 1'b0;
            result               <= 32'd0;
            oc                   <= 2'd0;
            tile_y               <= 2'd0;
            tile_x               <= 2'd0;
            load_x               <= 4'd0;
            load_y               <= 4'd0;
            comp_x               <= 2'd0;
            comp_y               <= 2'd0;
            write_x              <= 2'd0;
            write_y              <= 2'd0;
            full_input_read_addr <= 8'd0;
        end else begin
            case (state)
                S_IDLE: begin
                    done   <= 1'b0;
                    result <= 32'd0;
                    load_x <= 4'd0;
                    load_y <= 4'd0;
                    comp_x <= 2'd0;
                    comp_y <= 2'd0;
                    write_x<= 2'd0;
                    write_y<= 2'd0;
                    if (start) begin
                        full_input_read_addr <= tile_input_addr[7:0];
                        state <= S_LOAD_TILE;
                    end
                end

                S_LOAD_TILE: begin
                    full_input_read_addr <= tile_input_addr[7:0];
                    if (load_x == TILE_IN_W - 1 && load_y == TILE_IN_H - 1) begin
                        load_x <= 4'd0;
                        load_y <= 4'd0;
                        comp_x <= 2'd0;
                        comp_y <= 2'd0;
                        state  <= S_COMPUTE;
                    end else begin
                        if (load_x == TILE_IN_W - 1) begin
                            load_x <= 4'd0;
                            load_y <= load_y + 4'd1;
                        end else begin
                            load_x <= load_x + 4'd1;
                        end
                    end
                end

                S_COMPUTE: begin
                    result <= mac_sum;
                    if (comp_x == TILE_OUT_W - 1 && comp_y == TILE_OUT_H - 1) begin
                        write_x <= 2'd0;
                        write_y <= 2'd0;
                        state   <= S_WRITE_TILE;
                    end else begin
                        if (comp_x == TILE_OUT_W - 1) begin
                            comp_x <= 2'd0;
                            comp_y <= comp_y + 2'd1;
                        end else begin
                            comp_x <= comp_x + 2'd1;
                        end
                    end
                end

                S_WRITE_TILE: begin
                    result <= output_read_data;
                    if (write_x == TILE_OUT_W - 1 && write_y == TILE_OUT_H - 1) begin
                        state <= S_DONE;
                    end else begin
                        if (write_x == TILE_OUT_W - 1) begin
                            write_x <= 2'd0;
                            write_y <= write_y + 2'd1;
                        end else begin
                            write_x <= write_x + 2'd1;
                        end
                    end
                end

                S_DONE: begin
                    done <= 1'b1;
                    if (!start) begin
                        state <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end
endmodule
