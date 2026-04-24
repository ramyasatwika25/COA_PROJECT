module cache_top(
    input clk,
    input rst,

    input req_valid,
    input read_en,
    input write_en,
    input policy_select,

    input  [7:0]  address,
    input  [15:0] write_data,

    output [15:0] read_data,
    output hit,
    output [31:0] hit_count,
    output [31:0] miss_count
);

    cache_controller u_controller(
        .clk(clk),
        .rst(rst),
        .req_valid(req_valid),
        .read_en(read_en),
        .write_en(write_en),
        .policy_select(policy_select),
        .address(address),
        .write_data(write_data),
        .read_data(read_data),
        .hit(hit),
        .hit_count(hit_count),
        .miss_count(miss_count)
    );

endmodule