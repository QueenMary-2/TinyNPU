module pe(
    input logic clk,
    input logic rst,
    input logic clear,
    input logic en,

    input logic signed [7:0] a_in,//从左往右流动
    input logic signed [7:0] b_in,//从上往下流动

    output logic signed [7:0] a_out,
    output logic signed [7:0] b_out,
    output logic signed [31:0] acc//不流动，留在pe内部不断累加
);
    logic signed [15:0] product;
    assign product =a_in*b_in;
    always_ff @ (posedge clk)begin
        if(rst || clear)begin
            a_out<=0;
            b_out<=0;
            acc<=0;
        end
        else if(en)begin
            a_out<=a_in;
            b_out<=b_in;
            acc<=acc+{{16{product[15]}},product};
        end
    end
endmodule