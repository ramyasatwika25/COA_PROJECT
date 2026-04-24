module replacement_fifo(
    input clk,
    input rst,
    input update,
    input [1:0] set_idx,
    output victim_way
);

    reg fifo_ptr [0:3];
    integer i;

    initial begin
        for (i = 0; i < 4; i = i + 1)
            fifo_ptr[i] = 0;
    end

    assign victim_way = fifo_ptr[set_idx];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1)
                fifo_ptr[i] <= 0;
        end
        else if (update) begin
            fifo_ptr[set_idx] <= ~fifo_ptr[set_idx];
        end
    end

endmodule