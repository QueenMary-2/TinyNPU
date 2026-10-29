`timescale 1ns/1ps

module tb_tiny_npu_extended;

    logic clk;
    logic rst;
    logic start;

    logic [127:0] a_matrix;
    logic [127:0] b_matrix;

    wire done;
    wire [511:0] c_flat;

    integer errors;
    integer tests_passed;
    integer test_id;

    integer i, j, k;
    integer expected;
    logic signed [31:0] actual;

    // DUT
    tiny_npu_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .done(done),
        .c_flat(c_flat)
    );

    // 10 ns clock period
    initial clk = 0;
    always #5 clk = ~clk;

    // 将矩阵元素写入对应位置
    task automatic set_a(
        input integer row,
        input integer col,
        input integer value
    );
        a_matrix[(row*4+col)*8 +: 8] = value[7:0];
    endtask

    task automatic set_b(
        input integer row,
        input integer col,
        input integer value
    );
        b_matrix[(row*4+col)*8 +: 8] = value[7:0];
    endtask

    // 从矩阵中读取有符号元素
    function automatic integer get_a(
        input integer row,
        input integer col
    );
        get_a = $signed(
            a_matrix[(row*4+col)*8 +: 8]
        );
    endfunction

    function automatic integer get_b(
        input integer row,
        input integer col
    );
        get_b = $signed(
            b_matrix[(row*4+col)*8 +: 8]
        );
    endfunction

    // 执行一次矩阵乘法并检查结果
    task automatic run_test(
        input integer id
    );

        integer r, c, n;
        integer sum;
        integer timeout;
        integer test_errors;

        begin
            test_errors = 0;

            // 等待控制器回到 IDLE
            @(negedge clk);

            start = 1;

            @(negedge clk);
            start = 0;

            // 等待计算完成，最多等待 20 个周期
            timeout = 0;

            while (done !== 1'b1 && timeout < 20) begin
                @(negedge clk);
                timeout = timeout + 1;
            end

            if (done !== 1'b1) begin
                $display("FAIL TEST %0d: TIMEOUT", id);
                errors = errors + 1;
            end
            else begin

                // 检查 16 个输出
                for (r = 0; r < 4; r = r + 1) begin
                    for (c = 0; c < 4; c = c + 1) begin

                        sum = 0;

                        for (n = 0; n < 4; n = n + 1) begin
                            sum = sum
                                + get_a(r,n) * get_b(n,c);
                        end

                        actual = $signed(
                            c_flat[(r*4+c)*32 +: 32]
                        );

                        if (actual !== sum) begin
                            $display(
                                "FAIL TEST %0d C[%0d][%0d]: expected=%0d actual=%0d",
                                id, r, c, sum, actual
                            );

                            errors = errors + 1;
                            test_errors = test_errors + 1;
                        end

                    end
                end

                if (test_errors == 0) begin
                    $display("PASS TEST %0d", id);
                    tests_passed = tests_passed + 1;
                end

            end

            // 等待 DONE 结束，回到 IDLE
            repeat (2) @(negedge clk);

        end

    endtask

    initial begin

        $dumpfile("sim/tiny_npu_extended.vcd");
        $dumpvars(0, tb_tiny_npu_extended);

        errors = 0;
        tests_passed = 0;

        rst = 1;
        start = 0;

        a_matrix = 0;
        b_matrix = 0;

        repeat (2) @(negedge clk);
        rst = 0;

        // TEST 1: 全零矩阵
        a_matrix = 0;
        b_matrix = 0;
        run_test(1);

        // TEST 2: 单位矩阵
        a_matrix = 0;
        b_matrix = 0;

        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                set_a(i,j,i*4+j+1);

                if (i == j)
                    set_b(i,j,1);
                else
                    set_b(i,j,0);
            end
        end

        run_test(2);

        // TEST 3: 负数矩阵
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                set_a(i,j,-(i*4+j+1));
                set_b(i,j,j-i);
            end
        end

        run_test(3);

        // TEST 4: INT8 边界值
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin

                if ((i+j)%2 == 0) begin
                    set_a(i,j,127);
                    set_b(i,j,-128);
                end
                else begin
                    set_a(i,j,-128);
                    set_b(i,j,127);
                end

            end
        end

        run_test(4);

        // TEST 5-24: 随机矩阵
        for (test_id = 5; test_id <= 24; test_id = test_id + 1) begin

            for (i = 0; i < 4; i = i + 1) begin
                for (j = 0; j < 4; j = j + 1) begin

                    set_a(i,j,$urandom_range(0,255)-128);
                    set_b(i,j,$urandom_range(0,255)-128);

                end
            end

            run_test(test_id);

        end

        $display("------------------------------");
        $display("Tests passed: %0d / 24", tests_passed);
        $display("Total errors: %0d", errors);

        if (errors == 0 && tests_passed == 24)
            $display("ALL EXTENDED TESTS PASSED");
        else
            $display("EXTENDED TESTS FAILED");

        #20;
        $finish;

    end

endmodule