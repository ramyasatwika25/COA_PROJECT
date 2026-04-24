module main_memory(
    input clk,
    input we,
    input [7:0] addr,
    input [15:0] write_data,
    output [15:0] read_data
);

    reg [15:0] mem [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            mem[i] = i * 3 + 1;
    end

    assign read_data = mem[addr];

    always @(posedge clk) begin
        if (we)
            mem[addr] <= write_data;
    end

endmodule