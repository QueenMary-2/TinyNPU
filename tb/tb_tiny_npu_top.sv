
`timescale 1ns/1ps

module tb_tiny_npu_top;

    logic clk;
    logic rst;
    logic start;

    logic [127:0] a_matrix;
    logic [127:0] b_matrix;

    logic done;
    logic [511:0] c_flat;

    integer A [0:3][0:3];
    integer B [0:3][0:3];
    integer expected [0:3][0:3];

    logic signed [31:0] actual;
    integer errors;

    // 1. 实例化完整 TinyNPU
    tiny_npu_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .done(done),
        .c_flat(c_flat)
    );

    // 2. 产生时钟：周期 10 ns
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin

        $dumpfile("sim/tiny_npu_top.vcd");
        $dumpvars(0, tb_tiny_npu_top);

        rst = 1;
        start = 0;
        a_matrix = 0;
        b_matrix = 0;
        errors = 0;

        // 3. 初始化 A 矩阵
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                A[r][c] = r * 4 + c + 1;
            end
        end

        // 4. 初始化 B 矩阵
        B[0][0]=1; B[0][1]=0; B[0][2]=2; B[0][3]=0;
        B[1][0]=0; B[1][1]=1; B[1][2]=0; B[1][3]=2;
        B[2][0]=1; B[2][1]=0; B[2][2]=1; B[2][3]=0;
        B[3][0]=0; B[3][1]=1; B[3][2]=0; B[3][3]=1;

        // 5. 把矩阵装进 128 位输入
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                a_matrix[(r*4+c)*8 +: 8] = A[r][c];
                b_matrix[(r*4+c)*8 +: 8] = B[r][c];
            end
        end

        // 6. 在 Testbench 中计算参考答案
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin
                expected[r][c] = 0;

                for (int k = 0; k < 4; k++) begin
                    expected[r][c] =
                        expected[r][c] + A[r][k] * B[k][c];
                end
            end
        end

        // 7. 释放复位
        repeat (2) @(negedge clk);
        rst = 0;

        // 8. 发送 start 脉冲
        @(negedge clk);
        start = 1;

        @(negedge clk);
        start = 0;

        // 9. 等待 done，最多等待 20 个时钟周期
        begin : WAIT_DONE
            integer t;
            bit finished;

            finished = 0;

            for (t = 0; t < 20 && !finished; t = t + 1) begin
                @(negedge clk);

                if (done === 1'b1)
                    finished = 1;
            end

            if (!finished)
                $fatal(1, "TIMEOUT: done never became 1");
        end

        // 10. 检查全部 16 个结果
        for (int r = 0; r < 4; r++) begin
            for (int c = 0; c < 4; c++) begin

                actual = $signed(c_flat[(r*4+c)*32 +: 32]);

                if (actual !== expected[r][c]) begin
                    $display(
                        "FAIL C[%0d][%0d]: expected=%0d actual=%0d",
                        r, c, expected[r][c], actual
                    );
                    errors = errors + 1;
                end
                else begin
                    $display(
                        "PASS C[%0d][%0d] = %0d",
                        r, c, actual
                    );
                end

            end
        end

        if (errors == 0)
            $display("ALL TINYNPU TOP TESTS PASSED");
        else
            $fatal(1, "%0d matrix elements failed", errors);
        #10
        $finish;
    end

endmodule
