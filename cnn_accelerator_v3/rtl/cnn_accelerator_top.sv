// Version 3 tiled CNN accelerator top level.
module cnn_accelerator_top #(
    parameter int IN_W       = 28,
    parameter int IN_H       = 28,
    parameter int OUT_W      = 26,
    parameter int OUT_H      = 26,
    parameter int OUT_CH     = 4,
    parameter int K          = 3,
    parameter int TILE_OUT_W = 13,
    parameter int TILE_OUT_H = 13,
    parameter int TILE_IN_W  = 15,
    parameter int TILE_IN_H  = 15,
    parameter int DATA_W     = 8,
    parameter int ACC_W      = 32,
    parameter int ARRAY_M    = 4,
    parameter int ARRAY_N    = 4
) (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    output logic done
);
    localparam int IN_DEPTH       = IN_W * IN_H;
    localparam int WEIGHT_DEPTH   = OUT_CH * K * K;
    localparam int OUT_DEPTH      = OUT_W * OUT_H * OUT_CH;
    localparam int TILE_IN_DEPTH  = TILE_IN_W * TILE_IN_H;
    localparam int TILE_WT_DEPTH  = K * K;
    localparam int LOAD_TOTAL     = TILE_IN_DEPTH + TILE_WT_DEPTH;

    logic signed [DATA_W-1:0] input_mem  [0:IN_DEPTH-1];
    logic signed [DATA_W-1:0] weight_mem [0:WEIGHT_DEPTH-1];
    logic signed [ACC_W-1:0]  bias_mem   [0:OUT_CH-1];

    initial begin
        $readmemh("mem/input.mem", input_mem);
        $readmemh("mem/weight.mem", weight_mem);
        $readmemh("mem/bias.mem", bias_mem);
    end

    logic reset_sched;
    logic load_first_active;
    logic compute_active;
    logic preload_active;
    logic write_active;
    logic advance_tile;
    logic load_sel;
    logic compute_sel;
    logic final_tile;

    logic tile_y;
    logic tile_x;
    logic next_tile_y;
    logic next_tile_x;
    logic [1:0] oc;
    logic [1:0] next_oc;

    logic load_done;
    logic preload_done;
    logic compute_done;
    logic write_done;

    tile_scheduler #(
        .OUT_CH(OUT_CH)
    ) u_tile_scheduler (
        .clk(clk),
        .rst_n(rst_n),
        .reset_sched(reset_sched),
        .advance_tile(advance_tile),
        .tile_y(tile_y),
        .tile_x(tile_x),
        .oc(oc),
        .next_tile_y(next_tile_y),
        .next_tile_x(next_tile_x),
        .next_oc(next_oc),
        .final_tile(final_tile)
    );

    conv_controller u_controller (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .load_done(load_done),
        .preload_done(preload_done),
        .compute_done(compute_done),
        .write_done(write_done),
        .final_tile(final_tile),
        .reset_sched(reset_sched),
        .load_first_active(load_first_active),
        .compute_active(compute_active),
        .preload_active(preload_active),
        .write_active(write_active),
        .advance_tile(advance_tile),
        .done(done),
        .load_sel(load_sel),
        .compute_sel(compute_sel)
    );

    logic load_active;
    logic prev_load_active;
    logic prev_load_sel;
    logic start_load_job;
    logic prev_compute_active;
    logic [$clog2(LOAD_TOTAL)-1:0] load_count;

    logic load_tile_y;
    logic load_tile_x;
    logic [1:0] load_oc;
    logic [$clog2(TILE_IN_DEPTH)-1:0] load_input_index;
    logic [$clog2(TILE_WT_DEPTH)-1:0] load_weight_index;
    logic [$clog2(LOAD_TOTAL)-1:0] load_weight_count;
    logic [$clog2(TILE_IN_W)-1:0] load_in_y;
    logic [$clog2(TILE_IN_W)-1:0] load_in_x;
    logic [$clog2(IN_DEPTH)-1:0] load_input_global_addr;
    logic [$clog2(WEIGHT_DEPTH)-1:0] load_weight_global_addr;
    logic signed [DATA_W-1:0] input_load_data;
    logic signed [DATA_W-1:0] weight_load_data;
    logic input_load_en;
    logic weight_load_en;
    logic buffer_mark_valid;
    logic buffer_clear_valid;

    assign load_active = load_first_active || preload_active;
    assign load_tile_y = load_first_active ? tile_y : next_tile_y;
    assign load_tile_x = load_first_active ? tile_x : next_tile_x;
    assign load_oc     = load_first_active ? oc     : next_oc;

    assign load_input_index = load_count[$clog2(TILE_IN_DEPTH)-1:0];
    assign load_weight_count = load_count - TILE_IN_DEPTH;
    assign load_weight_index = load_weight_count[$clog2(TILE_WT_DEPTH)-1:0];
    assign load_in_y = load_input_index / TILE_IN_W;
    assign load_in_x = load_input_index % TILE_IN_W;
    assign load_input_global_addr = ((load_tile_y ? TILE_OUT_H : 0) + load_in_y) * IN_W +
                                    ((load_tile_x ? TILE_OUT_W : 0) + load_in_x);
    assign load_weight_global_addr = load_oc * TILE_WT_DEPTH + load_weight_index;

    assign input_load_data  = input_mem[load_input_global_addr];
    assign weight_load_data = weight_mem[load_weight_global_addr];
    assign input_load_en    = load_active && (load_count < TILE_IN_DEPTH);
    assign weight_load_en   = load_active && (load_count >= TILE_IN_DEPTH) && (load_count < LOAD_TOTAL);
    assign buffer_mark_valid = load_active && (load_count == LOAD_TOTAL-1);
    assign start_load_job = load_active && (!prev_load_active || (load_sel != prev_load_sel));
    assign buffer_clear_valid = start_load_job;
    assign load_done = load_first_active && (load_count == LOAD_TOTAL-1);

    logic preload_complete;
    assign preload_done = final_tile ? 1'b1 : preload_complete;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            load_count          <= '0;
            prev_load_active    <= 1'b0;
            prev_load_sel       <= 1'b0;
            preload_complete    <= 1'b0;
            prev_compute_active <= 1'b0;
        end else begin
            prev_load_active    <= load_active;
            prev_load_sel       <= load_sel;
            prev_compute_active <= compute_active;

            if (start_load_job) begin
                load_count <= '0;
            end else if (load_active && load_count < LOAD_TOTAL-1) begin
                load_count <= load_count + 1'b1;
            end

            if (compute_active && !prev_compute_active) begin
                preload_complete <= final_tile;
            end else if (preload_active && load_count == LOAD_TOTAL-1) begin
                preload_complete <= 1'b1;
            end
        end
    end

    logic signed [DATA_W-1:0] input_buffer_data;
    logic signed [DATA_W-1:0] weight_buffer_data;
    logic [$clog2(TILE_IN_DEPTH)-1:0] input_buffer_read_addr;
    logic [$clog2(TILE_WT_DEPTH)-1:0] weight_buffer_read_addr;
    logic input_valid_a;
    logic input_valid_b;
    logic weight_valid_a;
    logic weight_valid_b;

    input_double_buffer #(
        .DATA_W(DATA_W),
        .TILE_IN_W(TILE_IN_W),
        .TILE_IN_H(TILE_IN_H)
    ) u_input_double_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(input_load_en),
        .load_sel(load_sel),
        .compute_sel(compute_sel),
        .clear_valid(buffer_clear_valid),
        .mark_valid(buffer_mark_valid),
        .load_addr(load_input_index),
        .load_data(input_load_data),
        .read_addr(input_buffer_read_addr),
        .read_data(input_buffer_data),
        .valid_a(input_valid_a),
        .valid_b(input_valid_b)
    );

    weight_double_buffer #(
        .DATA_W(DATA_W),
        .K(K)
    ) u_weight_double_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .load_en(weight_load_en),
        .load_sel(load_sel),
        .compute_sel(compute_sel),
        .clear_valid(buffer_clear_valid),
        .mark_valid(buffer_mark_valid),
        .load_addr(load_weight_index),
        .load_data(weight_load_data),
        .read_addr(weight_buffer_read_addr),
        .read_data(weight_buffer_data),
        .valid_a(weight_valid_a),
        .valid_b(weight_valid_b)
    );

    logic [$clog2(TILE_OUT_H)-1:0] local_y;
    logic [$clog2(TILE_OUT_W)-1:0] local_x;
    logic [$clog2(K)-1:0] ky;
    logic [$clog2(K)-1:0] kx;
    logic [3:0] mac_phase;

    logic signed [DATA_W-1:0] feeder_act;
    logic signed [DATA_W-1:0] feeder_weight;

    data_feeder #(
        .DATA_W(DATA_W),
        .K(K),
        .TILE_IN_W(TILE_IN_W)
    ) u_data_feeder (
        .local_y(local_y),
        .local_x(local_x),
        .ky(ky),
        .kx(kx),
        .input_buffer_data(input_buffer_data),
        .weight_buffer_data(weight_buffer_data),
        .input_buffer_addr(input_buffer_read_addr),
        .weight_buffer_addr(weight_buffer_read_addr),
        .act_out(feeder_act),
        .weight_out(feeder_weight)
    );

    logic systolic_clear;
    logic systolic_valid;
    logic systolic_valid_out;
    logic signed [ACC_W-1:0] systolic_psum;
    logic signed [ACC_W-1:0] relu_out;

    assign systolic_clear = compute_active && (mac_phase == 4'd0);
    assign systolic_valid = compute_active && (mac_phase >= 4'd1) && (mac_phase <= 4'd9);

    systolic_array #(
        .DATA_W(DATA_W),
        .ACC_W(ACC_W),
        .ARRAY_M(ARRAY_M),
        .ARRAY_N(ARRAY_N)
    ) u_systolic_array (
        .clk(clk),
        .rst_n(rst_n),
        .clear(systolic_clear),
        .valid_in(systolic_valid),
        .act_in(feeder_act),
        .weight_in(feeder_weight),
        .psum_seed(bias_mem[oc]),
        .valid_out(systolic_valid_out),
        .psum_out(systolic_psum)
    );

    relu #(
        .ACC_W(ACC_W)
    ) u_relu (
        .in_data(systolic_psum),
        .out_data(relu_out)
    );

    logic [$clog2(IN_DEPTH)-1:0] unused_input_addr;
    logic [$clog2(WEIGHT_DEPTH)-1:0] unused_weight_addr;
    logic [$clog2(OUT_DEPTH)-1:0] output_addr;
    logic [$clog2(TILE_IN_DEPTH)-1:0] unused_tile_input_addr;
    logic [$clog2(TILE_WT_DEPTH)-1:0] unused_tile_weight_addr;
    logic signed [ACC_W-1:0] unused_output_read_data;

    address_generator #(
        .IN_W(IN_W),
        .OUT_W(OUT_W),
        .OUT_H(OUT_H),
        .K(K),
        .TILE_OUT_W(TILE_OUT_W),
        .TILE_OUT_H(TILE_OUT_H),
        .TILE_IN_W(TILE_IN_W)
    ) u_address_generator (
        .tile_y(tile_y),
        .tile_x(tile_x),
        .oc(oc),
        .local_y(local_y),
        .local_x(local_x),
        .ky(ky),
        .kx(kx),
        .input_addr(unused_input_addr),
        .weight_addr(unused_weight_addr),
        .output_addr(output_addr),
        .tile_input_addr(unused_tile_input_addr),
        .tile_weight_addr(unused_tile_weight_addr)
    );

    output_buffer #(
        .ACC_W(ACC_W),
        .OUT_W(OUT_W),
        .OUT_H(OUT_H),
        .OUT_CH(OUT_CH)
    ) u_output_buffer (
        .clk(clk),
        .rst_n(rst_n),
        .write_en(compute_active && (mac_phase == 4'd10)),
        .write_addr(output_addr),
        .write_data(relu_out),
        .read_addr('0),
        .read_data(unused_output_read_data)
    );

    assign compute_done = compute_active &&
                          (mac_phase == 4'd10) &&
                          (local_y == TILE_OUT_H-1) &&
                          (local_x == TILE_OUT_W-1);
    assign write_done = write_active;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            local_y   <= '0;
            local_x   <= '0;
            ky        <= '0;
            kx        <= '0;
            mac_phase <= '0;
        end else if (compute_active && !prev_compute_active) begin
            local_y   <= '0;
            local_x   <= '0;
            ky        <= '0;
            kx        <= '0;
            mac_phase <= '0;
        end else if (compute_active) begin
            if (mac_phase == 4'd0) begin
                ky        <= '0;
                kx        <= '0;
                mac_phase <= 4'd1;
            end else if (mac_phase >= 4'd1 && mac_phase <= 4'd8) begin
                mac_phase <= mac_phase + 1'b1;
                if (kx == K-1) begin
                    kx <= '0;
                    ky <= ky + 1'b1;
                end else begin
                    kx <= kx + 1'b1;
                end
            end else if (mac_phase == 4'd9) begin
                mac_phase <= 4'd10;
            end else begin
                mac_phase <= '0;
                ky        <= '0;
                kx        <= '0;

                if (!(local_y == TILE_OUT_H-1 && local_x == TILE_OUT_W-1)) begin
                    if (local_x == TILE_OUT_W-1) begin
                        local_x <= '0;
                        local_y <= local_y + 1'b1;
                    end else begin
                        local_x <= local_x + 1'b1;
                    end
                end
            end
        end
    end
endmodule
