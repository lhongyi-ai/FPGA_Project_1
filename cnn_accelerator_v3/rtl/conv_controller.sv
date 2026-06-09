// Top-level control FSM for loading, overlapped compute/load, write, and buffer swaps.
module conv_controller (
    input  logic clk,
    input  logic rst_n,
    input  logic start,
    input  logic load_done,
    input  logic preload_done,
    input  logic compute_done,
    input  logic write_done,
    input  logic final_tile,
    output logic reset_sched,
    output logic load_first_active,
    output logic compute_active,
    output logic preload_active,
    output logic write_active,
    output logic advance_tile,
    output logic done,
    output logic load_sel,
    output logic compute_sel
);
    typedef enum logic [2:0] {
        S_IDLE,
        S_LOAD_FIRST_TILE,
        S_COMPUTE_BUF_A_LOAD_BUF_B,
        S_COMPUTE_BUF_B_LOAD_BUF_A,
        S_WRITE_OUTPUT_TILE,
        S_NEXT_TILE,
        S_DONE
    } state_t;

    state_t state;
    state_t next_state;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= S_IDLE;
            compute_sel <= 1'b0;
        end else begin
            state <= next_state;

            if (state == S_IDLE && start) begin
                compute_sel <= 1'b0;
            end else if (state == S_NEXT_TILE && !final_tile) begin
                compute_sel <= ~compute_sel;
            end
        end
    end

    always_comb begin
        next_state = state;

        case (state)
            S_IDLE: begin
                if (start) next_state = S_LOAD_FIRST_TILE;
            end
            S_LOAD_FIRST_TILE: begin
                if (load_done) next_state = S_COMPUTE_BUF_A_LOAD_BUF_B;
            end
            S_COMPUTE_BUF_A_LOAD_BUF_B: begin
                if (compute_done && preload_done) next_state = S_WRITE_OUTPUT_TILE;
            end
            S_COMPUTE_BUF_B_LOAD_BUF_A: begin
                if (compute_done && preload_done) next_state = S_WRITE_OUTPUT_TILE;
            end
            S_WRITE_OUTPUT_TILE: begin
                if (write_done) begin
                    if (final_tile) next_state = S_DONE;
                    else            next_state = S_NEXT_TILE;
                end
            end
            S_NEXT_TILE: begin
                if (compute_sel) next_state = S_COMPUTE_BUF_A_LOAD_BUF_B;
                else             next_state = S_COMPUTE_BUF_B_LOAD_BUF_A;
            end
            S_DONE: begin
                if (!start) next_state = S_IDLE;
            end
            default: next_state = S_IDLE;
        endcase
    end

    always_comb begin
        reset_sched       = 1'b0;
        load_first_active = 1'b0;
        compute_active    = 1'b0;
        preload_active    = 1'b0;
        write_active      = 1'b0;
        advance_tile      = 1'b0;
        done              = 1'b0;
        load_sel          = ~compute_sel;

        case (state)
            S_IDLE: begin
                reset_sched = 1'b1;
                load_sel    = 1'b0;
            end
            S_LOAD_FIRST_TILE: begin
                load_first_active = 1'b1;
                load_sel          = 1'b0;
            end
            S_COMPUTE_BUF_A_LOAD_BUF_B,
            S_COMPUTE_BUF_B_LOAD_BUF_A: begin
                compute_active = 1'b1;
                preload_active = !final_tile;
                load_sel       = ~compute_sel;
            end
            S_WRITE_OUTPUT_TILE: begin
                write_active = 1'b1;
            end
            S_NEXT_TILE: begin
                advance_tile = 1'b1;
            end
            S_DONE: begin
                done = 1'b1;
            end
            default: begin
            end
        endcase
    end
endmodule
