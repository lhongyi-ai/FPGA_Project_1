module fsm_conv (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        start,
    output reg         done,
    output reg         load_input,
    output reg         load_weight,
    output reg         compute,
    output reg         store_out
);

    reg [1:0] state;
    localparam IDLE = 2'd0,
               LOAD = 2'd1,
               RUN  = 2'd2,
               DONE = 2'd3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
            done <= 1'b0;
            load_input <= 1'b0;
            load_weight <= 1'b0;
            compute <= 1'b0;
            store_out <= 1'b0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0;
                    load_input <= 1'b0;
                    load_weight <= 1'b0;
                    compute <= 1'b0;
                    store_out <= 1'b0;
                    if (start) state <= LOAD;
                end
                LOAD: begin
                    load_input <= 1'b1;
                    load_weight <= 1'b1;
                    state <= RUN;
                end
                RUN: begin
                    compute <= 1'b1;
                    state <= DONE;
                end
                DONE: begin
                    store_out <= 1'b1;
                    done <= 1'b1;
                    if (!start) state <= IDLE;
                end
            endcase
        end
    end
endmodule
