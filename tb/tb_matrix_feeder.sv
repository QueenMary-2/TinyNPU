`timescale 1ns/1ps

module tb_matrix_feeder;

    logic [127:0] a_matrix;
    logic [127:0] b_matrix;
    logic [3:0] cycle;
    logic en;

    logic [31:0] a_left;
    logic [31:0] b_top;

    matrix_feeder dut (
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .cycle(cycle),
        .en(en),
        .a_left(a_left),
        .b_top(b_top)
    );

    initial begin
        $dumpfile("sim/feeder.vcd");
        $dumpvars(0, tb_matrix_feeder);

        a_matrix = '0;
        b_matrix = '0;
        cycle = 0;
        en = 0;

        // 初始化 A 矩阵：1 到 16
        for (int i = 0; i < 16; i++) begin
            a_matrix[i*8 +: 8] = i + 1;
        end

        // 初始化 B 为单位矩阵
        for (int i = 0; i < 4; i++) begin
            b_matrix[(i*4+i)*8 +: 8] = 1;
        end

        #5;
        en = 1;

        for (int t = 0; t < 10; t++) begin
            cycle = t;
            #10;

            $display(
                "cycle=%0d | A=%0d,%0d,%0d,%0d | B=%0d,%0d,%0d,%0d",
                cycle,
                a_left[7:0],
                a_left[15:8],
                a_left[23:16],
                a_left[31:24],
                b_top[7:0],
                b_top[15:8],
                b_top[23:16],
                b_top[31:24]
            );
        end

        en = 0;
        #1;

        if (a_left !== 32'b0 || b_top !== 32'b0)
            $fatal(1, "Feeder did not stop when en=0");

        $display("FEEDER TEST FINISHED");
        $finish;
    end

endmodule