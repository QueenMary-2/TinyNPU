module matrix_feeder(
    input logic[127:0]a_matrix,
    input logic[127:0]b_matrix,
    input logic[3:0]cycle,
    input logic en,

    output logic[31:0]a_left,
    output logic[31:0]b_top
);
integer k;

always_comb begin
    a_left = 32'd0;
    b_top  = 32'd0;

    k = 0;

    if (en) begin
        for (int i = 0; i < 4; i++) begin
            k = int'(cycle) - i;

            if (k >= 0 && k < 4)
                a_left[i*8 +: 8] =
                    a_matrix[(i*4+k)*8 +: 8];
        end

        for (int j = 0; j < 4; j++) begin
            k = int'(cycle) - j;

            if (k >= 0 && k < 4)
                b_top[j*8 +: 8] =
                    b_matrix[(k*4+j)*8 +: 8];
        end
    end
end

endmodule