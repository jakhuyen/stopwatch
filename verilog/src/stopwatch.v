module stopwatch (
    input i_clk,
    input i_rst,
    output [7:0] o_an,
    output [6:0] o_seg
);

    // Anode for the display is VCC through a pnp transitor.
    // Thus, a 0 will turn on that particular digit.
    // All digits' segements will default to all off.
    reg r_an = {7{1'b1}};
    reg r_seg = {8{1'b1}};

    assign o_an = r_an;
    assign o_seg = r_seg;

    //always @ (posedge i_clk, posedge i_rst) begin
        
    //end

endmodule