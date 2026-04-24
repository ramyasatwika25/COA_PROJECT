`timescale 1ns/1ps

module tb_cache;

    reg clk;
    reg rst;
    reg req_valid;
    reg read_en;
    reg write_en;
    reg policy_select;   // 0 = FIFO, 1 = LRU
    reg [7:0] address;
    reg [15:0] write_data;

    wire [15:0] read_data;
    wire hit;
    wire [31:0] hit_count;
    wire [31:0] miss_count;

    integer total_accesses;
    real hit_rate;
    real miss_rate;
    integer i;

    cache_top dut(
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

    always #5 clk = ~clk;

    task clear_cache_state;
        begin
            for (i = 0; i < 4; i = i + 1) begin
                // Clear cache memory contents
                dut.u_controller.u_cache_memory.data_mem0[i] = 16'd0;
                dut.u_controller.u_cache_memory.data_mem1[i] = 16'd0;
                dut.u_controller.u_cache_memory.tag_mem0[i]  = 6'd0;
                dut.u_controller.u_cache_memory.tag_mem1[i]  = 6'd0;
                dut.u_controller.u_cache_memory.valid0[i]    = 1'b0;
                dut.u_controller.u_cache_memory.valid1[i]    = 1'b0;
                dut.u_controller.u_cache_memory.dirty0[i]    = 1'b0;
                dut.u_controller.u_cache_memory.dirty1[i]    = 1'b0;

                // Clear FIFO and LRU tracking
                dut.u_controller.u_fifo.fifo_ptr[i]   = 1'b0;
                dut.u_controller.u_lru.recent_way[i]  = 1'b0;
            end
        end
    endtask

    task do_read;
        input [7:0] addr;
        begin
            @(negedge clk);
            req_valid  = 1;
            read_en    = 1;
            write_en   = 0;
            address    = addr;
            write_data = 0;

            @(posedge clk);
            #1;
            total_accesses = total_accesses + 1;
            $display("Time=%0t Policy=%s READ  Addr=%0d Hit=%0d Data=%0d Hits=%0d Misses=%0d",
                     $time, policy_select ? "LRU " : "FIFO", addr, hit, read_data, hit_count, miss_count);

            @(negedge clk);
            req_valid = 0;
            read_en   = 0;
            write_en  = 0;
        end
    endtask

    task do_write;
        input [7:0] addr;
        input [15:0] data;
        begin
            @(negedge clk);
            req_valid  = 1;
            read_en    = 0;
            write_en   = 1;
            address    = addr;
            write_data = data;

            @(posedge clk);
            #1;
            total_accesses = total_accesses + 1;
            $display("Time=%0t Policy=%s WRITE Addr=%0d WData=%0d Hit=%0d Hits=%0d Misses=%0d",
                     $time, policy_select ? "LRU " : "FIFO", addr, data, hit, hit_count, miss_count);

            @(negedge clk);
            req_valid = 0;
            read_en   = 0;
            write_en  = 0;
        end
    endtask

    task reset_dut;
        begin
            rst = 1;
            req_valid = 0;
            read_en = 0;
            write_en = 0;
            address = 0;
            write_data = 0;
            total_accesses = 0;

            clear_cache_state();

            #12;
            rst = 0;
        end
    endtask

    task print_summary;
        input [8*40:1] testname;
        begin
            hit_rate  = (total_accesses > 0) ? (hit_count * 100.0) / total_accesses : 0.0;
            miss_rate = (total_accesses > 0) ? (miss_count * 100.0) / total_accesses : 0.0;

            $display("------------------------------------------------------------");
            $display("Test Case : %0s", testname);
            $display("Policy    : %0s", policy_select ? "LRU" : "FIFO");
            $display("Accesses  : %0d", total_accesses);
            $display("Hits      : %0d", hit_count);
            $display("Misses    : %0d", miss_count);
            $display("Hit Rate  : %0.2f %%", hit_rate);
            $display("Miss Rate : %0.2f %%", miss_rate);
            $display("------------------------------------------------------------");
        end
    endtask

    initial begin
        $dumpfile("cache.vcd");
        $dumpvars(0, tb_cache);
    end

    initial begin
        clk = 0;

        // =========================================================
        // TEST CASE 1 : Conflict Pattern
        // Sequence: 0, 4, 0, 8, 0
        // =========================================================
        policy_select = 0;
        reset_dut();
        do_read(8'd0);
        do_read(8'd4);
        do_read(8'd0);
        do_read(8'd8);
        do_read(8'd0);
        print_summary("TC1 Conflict Pattern");

        policy_select = 1;
        reset_dut();
        do_read(8'd0);
        do_read(8'd4);
        do_read(8'd0);
        do_read(8'd8);
        do_read(8'd0);
        print_summary("TC1 Conflict Pattern");

        // =========================================================
        // TEST CASE 2 : High Locality
        // Sequence: 1, 1, 1, 1, 1
        // =========================================================
        policy_select = 0;
        reset_dut();
        do_read(8'd1);
        do_read(8'd1);
        do_read(8'd1);
        do_read(8'd1);
        do_read(8'd1);
        print_summary("TC2 High Locality");

        policy_select = 1;
        reset_dut();
        do_read(8'd1);
        do_read(8'd1);
        do_read(8'd1);
        do_read(8'd1);
        do_read(8'd1);
        print_summary("TC2 High Locality");

        // =========================================================
        // TEST CASE 3 : Streaming Pattern
        // Sequence: 0, 1, 2, 3, 4, 5
        // =========================================================
        policy_select = 0;
        reset_dut();
        do_read(8'd0);
        do_read(8'd1);
        do_read(8'd2);
        do_read(8'd3);
        do_read(8'd4);
        do_read(8'd5);
        print_summary("TC3 Streaming Pattern");

        policy_select = 1;
        reset_dut();
        do_read(8'd0);
        do_read(8'd1);
        do_read(8'd2);
        do_read(8'd3);
        do_read(8'd4);
        do_read(8'd5);
        print_summary("TC3 Streaming Pattern");

        // =========================================================
        // TEST CASE 4 : Mixed Reuse
        // Sequence: 0, 4, 8, 4, 0, 8, 4
        // =========================================================
        policy_select = 0;
        reset_dut();
        do_read(8'd0);
        do_read(8'd4);
        do_read(8'd8);
        do_read(8'd4);
        do_read(8'd0);
        do_read(8'd8);
        do_read(8'd4);
        print_summary("TC4 Mixed Reuse");

        policy_select = 1;
        reset_dut();
        do_read(8'd0);
        do_read(8'd4);
        do_read(8'd8);
        do_read(8'd4);
        do_read(8'd0);
        do_read(8'd8);
        do_read(8'd4);
        print_summary("TC4 Mixed Reuse");

        // =========================================================
        // TEST CASE 5 : Write Test
        // Sequence: write 12, read 12, write 12, read 12
        // =========================================================
        policy_select = 0;
        reset_dut();
        do_write(8'd12, 16'd555);
        do_read(8'd12);
        do_write(8'd12, 16'd777);
        do_read(8'd12);
        print_summary("TC5 Write Test");

        policy_select = 1;
        reset_dut();
        do_write(8'd12, 16'd555);
        do_read(8'd12);
        do_write(8'd12, 16'd777);
        do_read(8'd12);
        print_summary("TC5 Write Test");

        #20;
        $finish;
    end

endmodule