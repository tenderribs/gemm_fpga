# Non-project Vivado build. Runs one stage per invocation and picks up from the
# previous stage's checkpoint. All output goes to build/.
#
# Normally run through the Makefile, which decides which stages need rerunning.
# To run a stage by hand, from the repo root:
#   source /tools/Xilinx/2026.1/Vivado/settings64.sh
#   mkdir -p build
#   vivado -mode batch -nojournal -log build/synth.log -source scripts/build.tcl -tclargs synth

set repo_root [file normalize [file dirname [info script]]/..]
set srcs_dir  $repo_root/src
set out_dir   $repo_root/build
set top       top
set part      xc7k325tffg900-2

set stage [lindex $argv 0]

# Each stage writes its checkpoint last. Make treats that file as proof the stage
# finished, so a stage that fails partway through runs again next time.
switch $stage {
    synth {
        # Only design sources belong here
        read_verilog -sv [glob $srcs_dir/sources/*.sv]
        read_xdc [glob $srcs_dir/constrs/*.xdc]

        # Synthesis: RTL to a netlist of FPGA primitives. Timing here is only an
        # estimate because nothing has been placed or routed yet.
        synth_design -top $top -part $part
        report_utilization -file $out_dir/post_synth_utilization.rpt
        report_timing_summary -file $out_dir/post_synth_timing.rpt
        write_checkpoint -force $out_dir/post_synth.dcp
    }
    impl {
        # Implementation: fit the netlist onto the physical device. The checkpoint
        # carries the constraints, so the XDC is not read again here.
        open_checkpoint $out_dir/post_synth.dcp
        opt_design
        place_design
        route_design
        report_utilization -file $out_dir/post_route_utilization.rpt
        report_timing_summary -file $out_dir/post_route_timing.rpt
        report_drc -file $out_dir/post_route_drc.rpt

        # route_design succeeds even when timing fails, so check it explicitly.
        set wns [get_property SLACK [get_timing_paths -setup]]
        if {$wns < 0} {
            puts "WARNING: timing not met, WNS = $wns ns. See $out_dir/post_route_timing.rpt"
        } else {
            puts "Timing met, WNS = $wns ns"
        }

        write_checkpoint -force $out_dir/post_route.dcp
    }
    bit {
        open_checkpoint $out_dir/post_route.dcp
        write_bitstream -force $out_dir/$top.bit
    }
    default {
        error "Unknown stage '$stage': use synth, impl or bit"
    }
}
