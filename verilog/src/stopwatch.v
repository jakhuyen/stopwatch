module stopwatch (
    input i_clk,
    input i_rst,
    input i_start,
    input i_clear,
    output [7:0] o_an,
    output [6:0] o_seg
);

    // Anode for the display is VCC through a pnp transitor.
    // Thus, a 0 will turn on that particular digit.
    // All digits' segements will default to all off.
    // Nexys 4 DDR doesn't support initial values

    // Stopwatch will have hours:minutes seconds.centiseconds
    // Will need:
    // 8 seg_display modules
    // Button/switch to start and stop timer
    // Reset button/switch
    // Counter module to count time.
    // 362,439,990,000,000 nanoseconds equals 99:99:99.99
    // Hex is 1_49A3_22DB_3980, meaning a 49 bit number

    // Verilog will round up from a REAL to INTEGER conversion
    reg [7:0] r_an = 8'h7F; //{8{1'b0}};
    reg [6:0] r_seg = 7'h7F; //{7{1'b1}};

    wire w_rst = ~i_rst;

    // TODO: Convert active low reset to active high reset

    assign o_an = 8'hFE;

    localparam reg [48:0] MAX_CNT = 49'h1_49A3_22DB_3980;
    localparam SEC_ONE = 1'b1;

    counter #(.MAX_CNT(MAX_CNT), .LOOP(1)) UUT
    (
        .i_clk(i_clk),
        .i_rst(w_rst),
        .o_cnt_done(r_cnt_done),
        .o_cnt_val(r_cnt_out)
    );

    // Output ports like o_seg cannot be connected to regs in Verilog 2005
    // .o_seg(r_seg) will fail
    seg_display seg_disp
    (
        .i_clk(w_clk),
        .i_rst(i_rst),
        .i_digit($rtoi(6/2)),
        .o_seg(o_seg),
        .o_decimal()
    );

    always @ (posedge w_rst, posedge i_clk) begin
        if (w_rst == 1) begin
            r_an <= 8'h7F;
        end

        else if (i_clk == 1) begin
            case (r_an)
                8'h7F   : r_an <= 8'hBF;
                8'hBF   : r_an <= 8'hDF;
                8'hDF   : r_an <= 8'hEF;
                8'hEF   : r_an <= 8'hF7;
                8'hF7   : r_an <= 8'hFB;
                8'hFB   : r_an <= 8'hFD;
                8'hFD   : r_an <= 8'hFE;
                8'hFE   : r_an <= 8'h7F;
                default : r_an <= 8'h7F;
            endcase
        end
    end

endmodule