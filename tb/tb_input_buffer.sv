`timescale 1ns/1ps

module tb_input_buffer;
    logic clk;
    logic rst;
    logic load;

    logic[127:0]a_matrix;
    logic[127:0]b_matrix;
    
    logic[127:0]a_reg;
    logic[127:0]b_reg;

    integer errors;
    input_buffer dut(
        .clk(clk),
        .rst(rst),
        .load(load),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .a_reg(a_reg),
        .b_reg(b_reg)
    );

    initial clk=0;
    always #5 clk=~clk;

    initial begin
        $dumpfile("sim/input_buffer.vcd");
        $dumpvars(0,tb_input_buffer);
        errors=0;
        rst=1;
        load=0;
        a_matrix=0;
        b_matrix=0;

        repeat(2)@(negedge clk);
        rst=0;

        if(a_reg!==0||b_reg!==0)begin
            $display("Fail rst test");
            errors=errors+1;
        end
        else
            $display("Rst test pass");

        a_matrix = 128'h0102030405060708090A0B0C0D0E0F10;
        b_matrix = 128'h1112131415161718191A1B1C1D1E1F20;

        load=1;
        @(negedge clk);
        load=0;
        if(a_reg!==128'h0102030405060708090A0B0C0D0E0F10||b_reg!==128'h1112131415161718191A1B1C1D1E1F20)begin
            $display("Load failed");
            errors=errors+1;
        end
        else
            $display("Load test passed");
        
        a_matrix = 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA;
        b_matrix = 128'hBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB;

        repeat (3) @(negedge clk);

        if (a_reg !== 128'h0102030405060708090A0B0C0D0E0F10 ||b_reg !== 128'h1112131415161718191A1B1C1D1E1F20) begin
            $display("Hold data failed");
            errors = errors + 1;
        end
        else
            $display("Hold data pass");

        load=1;
        @(negedge clk);
        load=0;
        if (a_reg !== 128'hAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA ||
            b_reg !== 128'hBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB) begin

            $display("FAIL: Second load");
            errors = errors + 1;
        end
        else
            $display("PASS: Second load");
        
        if (errors == 0)
            $display("ALL INPUT BUFFER TESTS PASSED");
        else
            $display("INPUT BUFFER TEST FAILED: %0d errors", errors);

        #20;
        $finish;
    end

endmodule


    
