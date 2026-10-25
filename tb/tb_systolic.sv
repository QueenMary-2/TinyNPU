
`timescale 1ns/1ps

module tb_systolic_array;

    logic clk = 0;
    logic rst = 1;
    logic en = 0;
    logic clear = 0;

    logic [31:0] a_left = 0;
    logic [31:0] b_top = 0;

    wire [511:0] c_flat;

    // 测试用的两个4×4矩阵
    logic signed [7:0] A [0:3][0:3];
    logic signed [7:0] B [0:3][0:3];

    integer t, i, j, k;//在变量执行过程中取什么值
    integer expected;
    integer got;

    // 10ns时钟周期
    always #5 clk = ~clk;

    // 实例化整个脉动阵列
    systolic_array dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .clear(clear),
        .a_left(a_left),
        .b_top(b_top),
        .c_flat(c_flat)
    );

    initial begin

        $dumpfile("sim/array.vcd");
        $dumpvars(0, tb_systolic_array);

        // 初始化矩阵A和B
        for (i=0; i<4; i=i+1) begin
            for (j=0; j<4; j=j+1) begin
                A[i][j] = i*4+j+1;
                B[i][j] = 0;
            end
        end

        B[0][0] = 1;
        B[0][2] = 2;
        B[1][1] = 1;
        B[1][3] = 2;
        B[2][0] = 1;
        B[2][2] = 1;
        B[3][1] = 1;
        B[3][3] = 1;

        // 复位
        repeat (2) @(negedge clk);
        rst = 0;
        en = 1;

        // 逐拍向阵列送入错位后的矩阵数据
        for (t=0; t<10; t=t+1) begin

            @(negedge clk);

            a_left = 0;
            b_top = 0;

            // A的第i行延迟i拍输入
            for (i=0; i<4; i=i+1) begin
                if ((t>=i) && (t-i<4))
                    a_left[i*8 +: 8] = A[i][t-i];
            end

            // B的第j列延迟j拍输入
            for (j=0; j<4; j=j+1) begin
                if ((t>=j) && (t-j<4))
                    b_top[j*8 +: 8] = B[t-j][j];
            end

        end

        // 等待最后一次输入被时钟采样
        @(negedge clk);

        // 对比16个计算结果
        for (i=0; i<4; i=i+1) begin
            for (j=0; j<4; j=j+1) begin

                expected = 0;

                for (k=0; k<4; k=k+1)
                    expected = expected
                             + A[i][k]*B[k][j];

                got = $signed(
                    c_flat[(i*4+j)*32 +: 32]
                );

                $display(
                    "C[%0d][%0d]: got=%0d expected=%0d",
                    i, j, got, expected
                );

                if (got !== expected)
                    $fatal(1, "MATRIX TEST FAILED");

            end
        end

        $display("ALL ARRAY TESTS PASSED");
        $finish;

    end

endmodule
