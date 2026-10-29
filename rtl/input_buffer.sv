module input_buffer(//定义256个D触发器，在一个时钟上升沿将AB一次送进去
    input logic clk,
    input logic load,
    input logic rst,
    input logic[127:0] a_matrix,
    input logic[127:0] b_matrix,

    output logic[127:0] a_reg,
    output logic[127:0] b_reg
);
    always_ff @(posedge clk)begin
        if(rst)begin
            a_reg<=128'b0;
            b_reg<=128'b0;
        end
        else if(load) begin
            a_reg<=a_matrix;
            b_reg<=b_matrix;
        end
    end
endmodule
