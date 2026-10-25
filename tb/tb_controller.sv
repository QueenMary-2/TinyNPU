
`timescale 1ns/1ps

module tb_controller;

    // 1. 定义测试信号
    logic clk;
    logic rst;
    logic start;

    logic clear;
    logic en;
    logic done;
    logic[3:0] cycle;

    // 2. 实例化 Controller
    controller dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .clear(clear),
        .en(en),
        .done(done),
        .cycle(cycle)
    );

    // 3. 产生时钟：周期为10ns
    initial clk = 0;
    always #5 clk = ~clk;

    // 4. 测试过程
    initial begin
        $dumpfile("controller.vcd");
        $dumpvars(0, tb_controller);

        rst = 1;
        start = 0;

        // 复位
        repeat(2) @(negedge clk);
        rst = 0;

        // 检查 IDLE
        #1;
        if (clear !== 0 || en !== 0 || done !== 0)
            $fatal(1, "IDLE test failed");

        // 发送 start
        @(negedge clk);
        start = 1;

        // 下一个上升沿进入 CLEAR
        @(posedge clk);
        #1;
        if (clear !== 1 || en !== 0 || done !== 0)
            $fatal(1, "CLEAR test failed");

        // 关闭 start
        @(negedge clk);
        start = 0;

        // 下一个上升沿进入 RUN
        @(posedge clk);
        #1;
        if (clear !== 0 || en !== 1 || done !== 0)
            $fatal(1, "RUN test failed");

        // 等待 RUN 完成
        // 检查 RUN 的 10 个周期
        for (int t = 0; t < 10; t++) begin
            if (t > 0) begin
                @(posedge clk);
                #1;
            end

            if (cycle !== t || en !== 1 || done !== 0)
                $fatal(1, "RUN cycle %0d failed", t);

            $display("RUN cycle %0d passed", t);
        end

        // 第 10 次 RUN 运算对应的上升沿后，进入 DONE
        @(posedge clk);
        #1;

        if (done !== 1 || en !== 0 || clear !== 0)
            $fatal(1, "DONE test failed");

        $display("All controller tests passed!");

        // 检查是否返回 IDLE
        @(posedge clk);
        #1;
        if (clear !== 0 || en !== 0 || done !== 0)
            $fatal(1, "Return to IDLE failed");

        $display("Return to IDLE passed!");

        $finish;
    end

    // 防止仿真无限等待
    initial begin
        #400;
        $fatal(1, "Simulation timeout!");
    end

endmodule
