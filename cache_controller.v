module cache_controller(
    input clk,
    input rst,

    input req_valid,
    input read_en,
    input write_en,
    input policy_select,   // 0 = FIFO, 1 = LRU

    input  [7:0]  address,
    input  [15:0] write_data,

    output reg [15:0] read_data,
    output reg hit,
    output reg [31:0] hit_count,
    output reg [31:0] miss_count
);

    wire [5:0] tag;
    wire [1:0] index;

    wire [15:0] cdata0, cdata1;
    wire [5:0] ctag0, ctag1;
    wire cvalid0, cvalid1;
    wire cdirty0, cdirty1;

    reg cache_we;
    reg cache_way_sel;
    reg [15:0] cache_write_data;
    reg [5:0] cache_write_tag;
    reg cache_write_valid;
    reg cache_write_dirty;

    reg mem_we;
    wire [15:0] mem_read_data;

    reg fifo_update;
    reg lru_update;
    reg lru_accessed_way;

    wire fifo_victim;
    wire lru_victim;

    wire way0_hit;
    wire way1_hit;

    address_decoder u_decoder(
        .address(address),
        .tag(tag),
        .index(index)
    );

    cache_memory u_cache_memory(
        .clk(clk),
        .we(cache_we),
        .set_idx(index),
        .way_sel(cache_way_sel),
        .write_data(cache_write_data),
        .write_tag(cache_write_tag),
        .write_valid(cache_write_valid),
        .write_dirty(cache_write_dirty),
        .read_data0(cdata0),
        .read_data1(cdata1),
        .read_tag0(ctag0),
        .read_tag1(ctag1),
        .read_valid0(cvalid0),
        .read_valid1(cvalid1),
        .read_dirty0(cdirty0),
        .read_dirty1(cdirty1)
    );

    main_memory u_main_memory(
        .clk(clk),
        .we(mem_we),
        .addr(address),
        .write_data(write_data),
        .read_data(mem_read_data)
    );

    replacement_fifo u_fifo(
        .clk(clk),
        .rst(rst),
        .update(fifo_update),
        .set_idx(index),
        .victim_way(fifo_victim)
    );

    replacement_lru u_lru(
        .clk(clk),
        .rst(rst),
        .access_update(lru_update),
        .set_idx(index),
        .accessed_way(lru_accessed_way),
        .victim_way(lru_victim)
    );

    assign way0_hit = cvalid0 && (ctag0 == tag);
    assign way1_hit = cvalid1 && (ctag1 == tag);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            read_data         <= 0;
            hit               <= 0;
            hit_count         <= 0;
            miss_count        <= 0;

            cache_we <= 0;
            cache_way_sel <= 0;
            cache_write_data <= 0;
            cache_write_tag <= 0;
            cache_write_valid <= 0;
            cache_write_dirty <= 0;

            mem_we <= 0;
            fifo_update <= 0;
            lru_update <= 0;
            lru_accessed_way <= 0;
        end
        else begin
            cache_we <= 0;
            mem_we <= 0;
            fifo_update <= 0;
            lru_update <= 0;
            hit <= 0;

            if (req_valid && (read_en || write_en)) begin

                if (way0_hit || way1_hit) begin
                    hit <= 1;
                    hit_count <= hit_count + 1;

                    if (read_en) begin
                        if (way0_hit)
                            read_data <= cdata0;
                        else
                            read_data <= cdata1;
                    end

                    if (write_en) begin
                        cache_we <= 1;
                        cache_way_sel <= way0_hit ? 0 : 1;
                        cache_write_data <= write_data;
                        cache_write_tag <= tag;
                        cache_write_valid <= 1;
                        cache_write_dirty <= 0;

                        mem_we <= 1;   // write-through
                    end

                    lru_update       <= 1;
                    lru_accessed_way <= way0_hit ? 0 : 1;
                end

                else begin
                    hit <= 0;
                    miss_count <= miss_count + 1;

                    cache_we <= 1;
                    cache_write_tag <= tag;
                    cache_write_valid <= 1;
                    cache_write_dirty <= 0;

                    if (!cvalid0)
                        cache_way_sel <= 0;
                    else if (!cvalid1)
                        cache_way_sel <= 1;
                    else
                        cache_way_sel <= (policy_select) ? lru_victim : fifo_victim;

                    if (read_en) begin
                        cache_write_data <= mem_read_data;
                        read_data <= mem_read_data;
                    end

                    if (write_en) begin
                        cache_write_data <= write_data;
                        mem_we <= 1;
                    end

                    if (cvalid0 && cvalid1)
                        fifo_update <= 1;

                    lru_update <= 1;

                    if (!cvalid0)
                        lru_accessed_way <= 0;
                    else if (!cvalid1)
                        lru_accessed_way <= 1;
                    else
                        lru_accessed_way <= (policy_select) ? lru_victim : fifo_victim;
                end
            end
        end
    end

endmodule