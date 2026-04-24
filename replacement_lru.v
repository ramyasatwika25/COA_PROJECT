module replacement_lru(
    input clk,
    input rst,
    input access_update,
    input [1:0] set_idx,
    input accessed_way,
    output victim_way
);

    reg recent_way [0:3];
    integer i;

    initial begin
        for (i = 0; i < 4; i = i + 1)
            recent_way[i] = 0;
    end

    assign victim_way = ~recent_way[set_idx];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 4; i = i + 1)
                recent_way[i] <= 0;
        end
        else if (access_update) begin
            recent_way[set_idx] <= accessed_way;
        end
    end

endmodule