module controller(
    input logic clk,
    input logic rst,
    input logic start,
    
    output logic clear,
    output logic en,
    output logic done,
    output logic [3:0] cycle
);
    typedef enum logic [1:0] {
        IDLE,
        CLEAR,
        RUN,
        DONE
    }state_t;
    state_t state;
    state_t next_state;
    always_comb begin
        next_state=state;
        case(state)
            IDLE:begin
                if(start)
                    next_state=CLEAR;
            end

            CLEAR:begin
                next_state=RUN;
            end

            RUN: begin
            if (cycle == 4'd9)
                next_state = DONE;
            end

            DONE: begin
                next_state = IDLE;
            end

            default: begin
                next_state = IDLE;
            end
        endcase
    end
    always_comb begin
        clear=1'b0;
        en=1'b0;
        done=1'b0;

        case (state)
            CLEAR:clear=1'b1;
            RUN:en=1'b1;
            DONE:done=1'b1;
            default:;
        endcase
    end
    
    always_ff @(posedge clk) begin
        if (rst) begin
            state <= IDLE;
            cycle <= 4'd0;
        end
        else begin
            state <= next_state;

            if (state == CLEAR)
                cycle <= 4'd0;
            else if (state == RUN && cycle < 4'd9)
                cycle <= cycle + 1'b1;
            else if (state == IDLE)
                cycle <= 4'd0;
        end
    end
  
endmodule
