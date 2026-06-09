// Tracks spatial tile and output-channel coordinates.
module tile_scheduler #(
    parameter int OUT_CH = 4
) (
    input  logic clk,
    input  logic rst_n,
    input  logic reset_sched,
    input  logic advance_tile,
    output logic tile_y,
    output logic tile_x,
    output logic [$clog2(OUT_CH)-1:0] oc,
    output logic next_tile_y,
    output logic next_tile_x,
    output logic [$clog2(OUT_CH)-1:0] next_oc,
    output logic final_tile
);
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tile_y <= 1'b0;
            tile_x <= 1'b0;
            oc     <= '0;
        end else if (reset_sched) begin
            tile_y <= 1'b0;
            tile_x <= 1'b0;
            oc     <= '0;
        end else if (advance_tile) begin
            tile_y <= next_tile_y;
            tile_x <= next_tile_x;
            oc     <= next_oc;
        end
    end

    always_comb begin
        next_tile_y = tile_y;
        next_tile_x = tile_x;
        next_oc     = oc;

        if (tile_x == 1'b0) begin
            next_tile_x = 1'b1;
        end else begin
            next_tile_x = 1'b0;
            if (tile_y == 1'b0) begin
                next_tile_y = 1'b1;
            end else begin
                next_tile_y = 1'b0;
                next_oc     = oc + 1'b1;
            end
        end
    end

    assign final_tile = (oc == OUT_CH-1) && (tile_y == 1'b1) && (tile_x == 1'b1);
endmodule
