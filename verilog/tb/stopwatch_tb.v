`include "../src/counter.v"

module counter_tb;
    reg r_clk = 1'b0;
    reg r_rst = 1'b0;
    wire[1:0] r_cnt_out;
    wire r_cnt_done;

    parameter integer tb_cnt = 6;

    counter #(.MAX_CNT(tb_cnt), .LOOP(1)) UUT
    (
        .i_clk(r_clk),
        .i_rst(r_rst),
        .o_cnt_done(r_cnt_done),
        .o_cnt_val(r_cnt_out)
    );

    always #1 r_clk <= !r_clk;

    // Block for dumping waveform files for GTKWave
    /*
    initial begin
        $dumpfile("counter.vcd");
        $dumpvars();
    end*/

    initial begin
        #62
        $display("Test complete");
        $display("This is r_cnt_out: %d", r_cnt_out);
        $display("This is r_cnt_done: %d", r_cnt_done);
        $finish;
    end
endmodule