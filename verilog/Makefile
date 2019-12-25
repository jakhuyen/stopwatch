SRC = clk_divider.v
# TESTBENCH =
TBOUTPUT = waves.lxt

COMPILER = iverilog
SIMULATOR = vvp
VIEWER = gtkwave

COFLAGS = -v -o
SFLAGS = -v
SOUTPUT = -lxt

COUTPUT = compiler.out

check : $(SRC) 
	$(COMPILER) -v $(SRC)

simulate : $(COUTPUT)
	$(SIMULATOR) $(SFLAGS) $(COUTPUT) $(SOUTPUT)

display : $(TBOUTPUT)
	$(VIEWER) $(TBOUTPUT) &
