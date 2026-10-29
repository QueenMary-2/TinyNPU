module tiny_npu_top(
    input logic clk,
    input logic rst,
    input logic start,
    input logic[127:0] a_matrix,
    input logic[127:0] b_matrix,

    output logic done,
    output logic [511:0] c_flat
);
    logic[3:0]cycle;
    logic en;
    logic clear;
    logic load;

    logic[127:0]a_buffered;
    logic[127:0]b_buffered;

    logic[31:0]a_left;
    logic[31:0]b_top;

    controller u_controller(
        .clk(clk),
        .rst(rst),
        .start(start),
        .clear(clear),
        .en(en),
        .done(done),
        .load(load),
        .cycle(cycle)
    );

    input_buffer u_buffer(
        .clk(clk),
        .rst(rst),
        .load(load),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .a_reg(a_buffered),
        .b_reg(b_buffered)
    );

    matrix_feeder u_feeder(
        .a_matrix(a_buffered),
        .b_matrix(b_buffered),
        .a_left(a_left),
        .b_top(b_top),
        .en(en),
        .cycle(cycle)
    );

    systolic_array u_arrat(
        .clk(clk),
        .rst(rst),
        .clear(clear),
        .en(en),
        .a_left(a_left),
        .b_top(b_top),
        .c_flat(c_flat)
    );
endmodule