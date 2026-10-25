module systolic_array(
    input logic clk,
    input logic rst,
    input logic en,
    input logic clear,

    input logic[31:0] a_left,
    input logic[31:0] b_top,
    output wire[511:0] c_flat
);
    wire signed[7:0] a_link[0:3][0:4];//四行五列，每个位置都可以传输一个8位数
    wire signed[7:0] b_link[0:4][0:3];
    wire signed[31:0] acc_link[0:3][0:3];

    genvar r,c;//生成硬件结构时使用，不会变成实际的寄存器或导线
    generate
        for (r=0;r<4;r=r+1)begin:A_INPUT
            assign a_link[r][0]=a_left[r*8+: 8];//选位语法，将32位a_left拆成四个8位
        end
        for (c=0;c<4;c=c+1)begin:B_INPUT
            assign b_link[0][c]=b_top[c*8+: 8];//assign：连续赋值语句，表示跟随，与单纯=不同
        end

        for(r=0;r<4;r=r+1)begin:ROW//r=0，c完成从0-3的循环，r++，生成16个pe1
            for (c=0;c<4;c=c+1)begin:COL
                pe pe1(
                    .clk(clk),
                    .rst(rst),
                    .en(en),
                    .clear(clear),

                    .a_in(a_link[r][c]),
                    .b_in(b_link[r][c]),
                    .a_out(a_link[r][c+1]),
                    .b_out(b_link[r+1][c]),
                    .acc(acc_link[r][c])
                );
                assign c_flat[(r*4+c)*32+:32]
                    =acc_link[r][c];
            end
        end
    endgenerate
endmodule