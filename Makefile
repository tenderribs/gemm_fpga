# Vivado build. Each target runs only the stages whose inputs have changed.
#   make        build through to the bitstream
#   make impl   stop after place and route
#   make synth  stop after synthesis
# Source /tools/Xilinx/2026.1/Vivado/settings64.sh first so vivado is on PATH.

VIVADO ?= vivado

SRCS := $(wildcard src/sources/*.sv)
XDC  := $(wildcard src/constrs/*.xdc)

run = $(VIVADO) -mode batch -nojournal -log build/$(1).log -source scripts/build.tcl -tclargs $(1)

.PHONY: bit impl synth
bit:   build/top.bit
impl:  build/post_route.dcp
synth: build/post_synth.dcp

build/post_synth.dcp: $(SRCS) $(XDC) scripts/build.tcl
	mkdir -p build
	$(call run,synth)

build/post_route.dcp: build/post_synth.dcp
	$(call run,impl)

build/top.bit: build/post_route.dcp
	$(call run,bit)
