module cache_memory(
    input clk,
    input we,
    input [1:0] set_idx,
    input way_sel,

    input [15:0] write_data,
    input [5:0]  write_tag,
    input write_valid,
    input write_dirty,

    output reg [15:0] read_data0,
    output reg [15:0] read_data1,
    output reg [5:0] read_tag0,
    output reg [5:0] read_tag1,
    output reg read_valid0,
    output reg read_valid1,
    output reg read_dirty0,
    output reg read_dirty1
);

    reg [15:0] data_mem0 [0:3];
    reg [15:0] data_mem1 [0:3];

    reg [5:0] tag_mem0 [0:3];
    reg [5:0] tag_mem1 [0:3];

    reg valid0 [0:3];
    reg valid1 [0:3];

    reg dirty0 [0:3];
    reg dirty1 [0:3];

    integer i;

    initial begin
        for (i = 0; i < 4; i = i + 1) begin
            data_mem0[i] = 0;
            data_mem1[i] = 0;
            tag_mem0[i] = 0;
            tag_mem1[i] = 0;
            valid0[i] = 0;
            valid1[i] = 0;
            dirty0[i] = 0;
            dirty1[i] = 0;
        end
    end

    always @(*) begin
        read_data0 = data_mem0[set_idx];
        read_data1 = data_mem1[set_idx];
        read_tag0 = tag_mem0[set_idx];
        read_tag1 = tag_mem1[set_idx];
        read_valid0 = valid0[set_idx];
        read_valid1 = valid1[set_idx];
        read_dirty0 = dirty0[set_idx];
        read_dirty1 = dirty1[set_idx];
    end

    always @(posedge clk) begin
        if (we) begin
            if (way_sel == 0) begin
                data_mem0[set_idx] <= write_data;
                tag_mem0[set_idx] <= write_tag;
                valid0[set_idx] <= write_valid;
                dirty0[set_idx] <= write_dirty;
            end
            else begin
                data_mem1[set_idx] <= write_data;
                tag_mem1[set_idx] <= write_tag;
                valid1[set_idx] <= write_valid;
                dirty1[set_idx] <= write_dirty;
            end
        end
    end

endmodule