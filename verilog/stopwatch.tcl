# Create output directory and clear contents
set outputdir ./synthesis
file mkdir $outputdir

# Sets the files variable to get the names of all the files
# present in the output directory
# glob returns all files that match the pattern specified
set files [glob -nocomplain "$outputdir/*"]

# puts will output the a message to the console
if {[llength $files] != 0} {
    puts "Deleting the Contents of $outputdir"
    file delete -force {*}[glob -directory $outputdir *];
} else {
    puts "$outputdir is empty"
}

# Create project
create_project -part xc7a100tcsg324-1 stopwatch $outputdir

# Add testbench source file
add_files -fileset sim_1 ./tb/stopwatch_tb.v
add_files [glob ../../base_components/verilog/src/*.v]
add_files ./src/stopwatch.v
add_files -fileset constrs_1 ../constraint.xdc
set_property -library work [glob ../../base_components/verilog/src/*.v]

# Set top level module and update compile order
set_property top top [current_fileset]
update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

# Launch synthesis
launch_runs synth_1
wait_on_run synth_1
puts "Synthesis Done"

# Run Implementation and generate bitstream
set_property STEPS.PHYS_OPT_DESIGN.IS_ENABLED true [get_runs impl_1]
set_property STEPS.OPT_DESIGN.TCL.PRE [pwd]/pre_opt_design.tcl [get_runs impl_1]
set_property STEPS.OPT_DESIGN.TCL.POST [pwd]/post_opt_design.tcl [get_runs impl_1]
set_property STEPS.PLACE_DESIGN.TCL.POST [pwd]/post_place_design.tcl [get_runs impl_1]
set_property STEPS.PHYS_OPT_DESIGN.TCL.POST [pwd]/post_phys_opt_design.tcl [get_runs impl_1]
set_property STEPS.ROUTE_DESIGN.TCL.POST [pwd]/post_route_design.tcl [get_runs impl_1]
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
puts "Implementation and Bitstream Done"

# "vivado -mode tcl" will open vivado TCL command line (doesn't work on Windows unless you have the path set up, currently broken)
# "source stopwatch.tcl" will run this script