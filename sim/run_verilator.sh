#!/usr/bin/env bash
# Build and run the example with Verilator (5.x, needs --timing for the TB's
# delays and @(posedge) waits).
# Usage: sim/run_verilator.sh [N ...]   (default: 2 4 128)
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$REPO/sim/build/verilator"

SOURCES=("$REPO/sim/IBUFDS.v")
while IFS= read -r f; do SOURCES+=("$f"); done \
  < <(find "$REPO/genesys2.srcs/sources" -name '*.sv' | sort)
SOURCES+=("$REPO/genesys2.srcs/sim/tb_top.sv")

if (($#)); then SIZES=("$@"); else SIZES=(2); fi
# if (($#)); then SIZES=("$@"); else SIZES=(2 4 128); fi

for N in "${SIZES[@]}"; do
  echo "=== N=$N ==="
  OUT="$BUILD/N$N"
  rm -rf "$OUT"
  mkdir -p "$OUT"

  verilator --binary --timing -Wall -Wno-fatal -Wno-TIMESCALEMOD \
    --x-assign unique --x-initial unique \
    -Mdir "$OUT" \
    -GN="$N" \
    -GAFile="\"$REPO/sim/A_$N.hex\"" \
    -GBFile="\"$REPO/sim/B_$N.hex\"" \
    -GCFile="\"$REPO/sim/C_$N.hex\"" \
    -GYFile="\"$REPO/sim/Y_$N.hex\"" \
    --top-module tb_top "${SOURCES[@]}"

  out=$("$OUT/Vtb_top" +verilator+seed+$RANDOM +verilator+rand+reset+ 2>&1 || true)
  echo "$out" | grep -E '^(TEST | MISMATCH | FAIL)|%Error' || true
  echo "$out" | grep -q 'TEST PASSED' || status=1
done
