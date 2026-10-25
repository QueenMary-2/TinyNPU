`timescale 1ns/1ps

module tb_pe;
    logic clk=0;
    logic rst=1;
    logic clear=0;
    logic en=0;
    logic signed  [7:0] a_in=0;
    logic signed  [7:0] b_in=0;
    wire signed  [7:0] a_out;
    wire signed  [7:0] b_out;
    wire signed    [31:0] acc;
    always #5 clk=~clk;
    pe dut(.*);
    initial begin
        $dumpfile("sim/pe.vcd");//指定波形文件，保存到sim文件夹并且命名为pe.vcd
        $dumpvars(0,tb_pe);//start recording at the module tb_pe,level=0
        //rst
        repeat(2)@(negedge clk);
        rst=0;
        en=1;
        //计算第一次2*3
        a_in=2;
        b_in=3;
        @(negedge clk);
        $display("result=%0d a_out=%0d b_out=%0d",acc,a_out,b_out);
        if(acc!==6||a_out!==2||b_out!==3)
            $fatal(1,"first test failed");
        //计算第二次4*5，acc相加
        a_in=4;
        b_in=5;
        @(negedge clk);
        $display("second result=%0d a_out=%0d b_out=%0d",acc,a_out,b_out);
        if(acc!==26||a_out!==4||b_out!==5)
            $fatal(1,"second test failed");
        //禁用测试，若已经禁用，则输出、acc保持为上两次计算得出的最后结果
        en=0;
        a_in=10;
        b_in=10;
        @(negedge clk);
        if(acc!==26||a_out!==4||b_out!==5)
            $fatal(1,"enable test failed");
        //clear 测试
        clear=1;
        @(negedge clk);
        if(acc!==0||a_out!==0||b_out!==0)
            $fatal(1,"test clear failed");
        
        $display("ALL PE TESTS PASSED");
        $finish;
    end
endmodule
