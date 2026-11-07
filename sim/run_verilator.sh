#!/usr/bin/env bash
# Build and run the example with Verilator (5.x, needs --timing for the TB's
# delays and @(posedge) waits). Usage: sim/run_verilator.sh
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$REPO/sim/build/verilator"

SOURCES=("$REPO/sim/IBUFDS.v")
while IFS= read -r f; do SOURCES+=("$f"); done \
  < <(find "$REPO/genesys2.srcs/sources" -name '*.sv' | sort)
SOURCES+=("$REPO/genesys2.srcs/sim/tb_top.sv")

rm -rf $BUILD
mkdir -p $BUILD

verilator --binary --timing -Wall -Wno-fatal -Wno-TIMESCALEMOD \
  --x-assign unique --x-initial unique \
  -Mdir "$BUILD" \
  -GBitWidth="2" \
  -GAVecFile="\"$REPO/sim/A_2.hex\"" \
  -GBVecFile="\"$REPO/sim/B_2.hex\"" \
  -GCVecFile="\"$REPO/sim/C_2.hex\"" \
  --top-module tb_top "${SOURCES[@]}"

"$BUILD/Vtb_top" +verilator+seed+$RANDOM +verilator+rand+reset+2