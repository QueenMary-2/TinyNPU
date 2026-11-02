
`timescale 1ns/1ps

module tb_mnist_tile;

    logic clk = 0;
    logic rst = 1;
    logic start = 0;

    logic [127:0] a_matrix;
    logic [127:0] b_matrix;

    wire done;
    wire [511:0] c_flat;

    reg [127:0] a_mem [0:0];
    reg [127:0] b_mem [0:0];
    reg [31:0] expected [0:15];

    integer i;
    integer errors = 0;
    integer timeout;

    always #5 clk = ~clk;

    tiny_npu_top dut (
        .clk(clk),
        .rst(rst),
        .start(start),
        .a_matrix(a_matrix),
        .b_matrix(b_matrix),
        .done(done),
        .c_flat(c_flat)
    );

    initial begin
        $readmemh("sim/mnist_tile_a.hex", a_mem);
        $readmemh("sim/mnist_tile_b.hex", b_mem);
        $readmemh("sim/mnist_tile_expected.hex", expected);

        a_matrix = a_mem[0];
        b_matrix = b_mem[0];

        repeat (2) @(negedge clk);
        rst = 0;

        @(negedge clk);
        start = 1;
        @(negedge clk);
        start = 0;

        timeout = 0;
        while (done !== 1'b1 && timeout < 30) begin
            @(negedge clk);
            timeout = timeout + 1;
        end

        if (done !== 1'b1) begin
            $display("FAIL: TIMEOUT");
            $finish;
        end

        for (i = 0; i < 16; i = i + 1) begin
            if (c_flat[i*32 +: 32] !== expected[i]) begin
                $display("FAIL C[%0d]: expected=%0d actual=%0d",
                    i, $signed(expected[i]),
                    $signed(c_flat[i*32 +: 32]));
                errors = errors + 1;
            end
        end

        if (errors == 0)
            $display("MNIST TILE PASS: 16/16");
        else
            $display("MNIST TILE FAIL: %0d errors", errors);

        $finish;
    end

endmodule
