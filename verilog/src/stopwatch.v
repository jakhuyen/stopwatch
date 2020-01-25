module stopwatch (
  input clkIn,
  input rstIn,
  input buttonIn,
  input clearIn,
  output [7:0] anOut,
  output [6:0] segOut
);

  // Period = (2^num_bits + 2)/clk_frequency
  // 10 ms period is when most switches reach stable logic.
  // 20 bit counter is needed
  localparam reg [19:0] DEBOUNCE_CNT = 20'hF_FFFF   // synthesis translate_off
                                     - 20'hF_FFF0   // synthesis translate_on
                                       ;

  // 359,999,990,000,000 nanoseconds equals 99:59:59.99
  // Since the Nexys 4 is on a 100 MHz (10 ns period) clock, the max count should be 35,999,999,000,000.
  // Hex is 20F6_B6AF_85C0, meaning a 46 bit number
  localparam reg [45:0] MAX_CNT = 46'h20BD_E726_FDC0;
  localparam reg [41:0] HR_TENS = 42'h346_30B8_A000;
  localparam reg [38:0] HR_ONES = 39'h53_D1AC_1000;
  localparam reg [35:0] MIN_TENS = 36'hD_F847_5800;
  localparam reg [32:0] MIN_ONES = 33'h1_65A0_BC00;
  localparam reg [29:0] SEC_TENS = 30'h3B9A_CA00;
  localparam reg [26:0] SEC_ONES = 27'h5F5_E100;
  localparam reg [23:0] SEC_TENTHS = 24'h98_9680;
  localparam reg [19:0] SEC_HUNDRETHS = 20'hF_4240;

  localparam integer DIV_NUM = 100000 // synthesis translate_off
                             -  99990 // synthesis translate_on
                               ;

  integer index;

  // Anode for the display is VCC through a pnp transitor.
  // Thus, a 0 will turn on that particular digit.
  // All digits' segements will default to all off.
  // Nexys 4 DDR doesn't support initial values

  // Verilog will round up from a REAL to INTEGER conversion
  reg [7:0] anR = 8'h7F; //{8{1'b0}};
  reg [6:0] segR;
  reg [3:0] segDigitsR [7:0];
  reg prevButtonStateR;
  reg latchButtonStateR;

  wire [6:0] segW [7:0]; //7'h7F; //{7{1'b1}};
  wire rstW = ~rstIn;
  wire clk10MhzW;
  wire startDebW;
  wire clearDebW;
  wire [45:0] cntValW;

  assign anOut  = anR;
  assign segOut = segR;

  // Debounce the start/stop button input
  button_debounce #(.DEBOUNCE_CNT(DEBOUNCE_CNT)) debounce_start
  (
    .clkIn(clkIn),
    .rstIn(rstW),
    .buttonIn(buttonIn),
    .buttonOut(startDebW)
  );

  // Debounce the clear button input
  // The latchButtonStateR going into the reset port prevents clearing the stopwatch time when it is not paused.
  button_debounce #(.DEBOUNCE_CNT(DEBOUNCE_CNT)) debounce_clear
  (
    .clkIn(clkIn),
    .rstIn(rstW | latchButtonStateR),
    .buttonIn(clearIn),
    .buttonOut(clearDebW)
  );

  // The time counter for the stopwatch
  // Can be reset by either the system reset or clear button input
  counter #(.MAX_CNT(MAX_CNT), .LOOP(1)) time_cnt
  (
    .clkIn(clkIn),
    .rstIn(rstW | clearDebW),
    .enIn(latchButtonStateR),
    .cntDoneOut(),
    .cntValOut(cntValW)
  );

  // Divide the 100 MHz clock into a 1 KHz clock for the display
  // Allows for a good refresh rate without sacrificing brightness of the display.
  clk_divider #(.DIV_NUM(DIV_NUM)) clk_div
  (
    .clkIn(clkIn),
    .rstIn(rstW),
    .clkOut(clk10MhzW)
  );

  // Generate the 8 seg_display modules for each digit on the 7-seg display
  genvar i;
  // generate...endgenerate keywords are not needed, but can be included
  for (i = 0; i < 8; i = i + 1) begin
    // Output ports like segOut cannot be connected to regs in Verilog 2005
    // .segOut(segR) will fail
    seg_display seg_disp
    (
      .clkIn(clkIn),
      .rstIn(rstW),
      .digitIn(segDigitsR[i]),
      .segOut(segW[i]),
      .decimalOut()
    );
  end

  // Stores the state of the start/pause button press and whether or not the stopwatch should continue counting.
  always @ (posedge rstW, posedge clkIn) begin
    if (rstW == 1) begin
      prevButtonStateR  <= 1'b0;
      latchButtonStateR <= 1'b0;
    end

    else if (clkIn == 1) begin
      prevButtonStateR <= startDebW;

      if (startDebW == 1'b1 && prevButtonStateR == 1'b0) begin
        if (latchButtonStateR == 1'b0) begin
          latchButtonStateR <= 1'b1;
        end

        else begin
          latchButtonStateR <= 1'b0;
        end
      end
    end
  end

  // Calculates the 8 individual digits of that are supposed to appear on the segment display.
  always @ (posedge rstW, posedge clkIn) begin
    if (rstW == 1) begin
      for (index = 0; index < 8; index = index + 1) begin
        segDigitsR[index] <= 0;
      end
    end

    else if (clkIn == 1) begin
      // segDigitsR highest index will correspond to the leftmost digit of the display.
      segDigitsR[7] <= (cntValW >= HR_TENS)       ?(cntValW / HR_TENS):0;
      segDigitsR[6] <= (cntValW >= HR_ONES)       ?(cntValW % HR_TENS )   / HR_ONES:0;
      segDigitsR[5] <= (cntValW >= MIN_TENS)      ?(cntValW % HR_ONES )   / MIN_TENS:0;
      segDigitsR[4] <= (cntValW >= MIN_ONES)      ?(cntValW % MIN_TENS)   / MIN_ONES:0;
      segDigitsR[3] <= (cntValW >= SEC_TENS)      ?(cntValW % MIN_ONES)   / SEC_TENS:0;
      segDigitsR[2] <= (cntValW >= SEC_ONES)      ?(cntValW % SEC_TENS)   / SEC_ONES:0;
      segDigitsR[1] <= (cntValW >= SEC_TENTHS)    ?(cntValW % SEC_ONES)   / SEC_TENTHS:0;
      segDigitsR[0] <= (cntValW >= SEC_HUNDRETHS) ?(cntValW % SEC_TENTHS) / SEC_HUNDRETHS:0;
    end
  end

  // Cycles through the 8 digits of the display, outputting the correct anode and segments to be lit up.
  always @ (posedge rstW, posedge clk10MhzW) begin
    if (rstW == 1) begin
      anR  <= 8'h7F;
      segR <= 7'h7F;
    end

    else if (clk10MhzW == 1) begin
      // segW highest index will correspond to the leftmost digit of the display.
      // 
      case (anR)
        8'h7F   : begin 
                    anR  <= 8'hBF;
                    segR <= segW[6];
                  end

        8'hBF   : begin
                    anR  <= 8'hDF;
                    segR <= segW[5];
                  end

        8'hDF   : begin
                    anR  <= 8'hEF;
                    segR <= segW[4];
                  end

        8'hEF   : begin
                    anR  <= 8'hF7;
                    segR <= segW[3];
                  end

        8'hF7   : begin
                    anR  <= 8'hFB;
                    segR <= segW[2];
                  end

        8'hFB   : begin
                    anR  <= 8'hFD;
                    segR <= segW[1];
                  end

        8'hFD   : begin
                    anR  <= 8'hFE;
                    segR <= segW[0];
                  end

        8'hFE   : begin
                    anR  <= 8'h7F;
                    segR <= segW[7];
                  end

        default : begin
                    anR  <= 8'h7F;
                    segR <= 7'h40;
                  end
      endcase
    end
  end
endmodule