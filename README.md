# GEMM on FPGA

Computes `Y = A @ B + C` on a Digilent Genesys 2 board (Kintex-7 `xc7k325tffg900-2`).
`A`, `B` and `C` are N×N signed 8-bit matrices, and `Y` is N×N signed 32-bit.

## Required software

| Tool                             | Version                          | Used for                             |
| -------------------------------- | -------------------------------- | ------------------------------------ |
| Vivado (Basic license is enough) | 2026.1                           | synthesis, implementation, bitstream |
| Verilator                        | 5.x (tested with 5.052)          | simulation; needs `--timing` support |
| Python                           | 3.x (tested with 3.13) + `numpy` | test vector generation               |
| GNU Make, Bash                   | any recent                       | build and sim scripts                |

Hardware: Digilent Genesys 2 FPGA board.

## Setup

```sh
git clone git@github.com:tenderribs/gemm_fpga.git
cd gemm_fpga
git submodule update --init

python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

## Test vector generation

```sh
python3 sim/gen_stim.py --sizes 2 4     # default sizes: 2 4 128
```

This writes `sim/N<size>/{A,B,C,Y}_<mode>_<size>.hex` for two modes:

- `iden`: `A` is the identity matrix and `C` is zero, so `Y = B`. Use it as a quick sanity check.
- `rand`: `A`, `B` and `C` are all random.

Each line holds one element in two's-complement hex, in row-major order. These are the files the testbench loads with `$readmemh`. The random seed is fixed, so the vectors come out the same on every run.

## Simulation (Verilator)

```sh
sim/run_verilator.sh            # N = 2 4 128
sim/run_verilator.sh 2 4        # chosen sizes only
```

For each size the script:

1. regenerates the test vectors (it runs `gen_stim.py` itself)
2. builds the testbench once per mode, in `sim/build/verilator/N<size>_<mode>/`
3. runs the sim and prints `TEST PASSED` / `MISMATCH` / `FAIL` / `TIMEOUT` lines

## FPGA build (Vivado)

Put Vivado on your `PATH`, then run `make`:

```sh
source /tools/Xilinx/2026.1/Vivado/settings64.sh

make            # synth -> impl -> bitstream (build/top.bit)
make impl       # stop after place and route
make synth      # stop after synthesis
```

Each stage reruns only when its inputs have changed. All output goes to `build/`: checkpoints, logs, and the utilization and timing reports.
