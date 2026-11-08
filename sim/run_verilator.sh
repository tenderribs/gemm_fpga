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

if (($#)); then SIZES=("$@"); else SIZES=(2 4 128); fi
MODES=(iden rand)

python3 "$REPO/sim/gen_stim.py" --sizes "${SIZES[@]}"

status=0
for N in "${SIZES[@]}"; do
  for MODE in "${MODES[@]}"; do
    echo "=== N=$N mode=$MODE ==="
    VEC="$REPO/sim/N$N"
    OUT="$BUILD/N${N}_$MODE"
    rm -rf "$OUT"
    mkdir -p "$OUT"

    verilator --binary --timing -Wall -Wno-fatal -Wno-TIMESCALEMOD \
      --x-assign unique --x-initial unique \
      -Mdir "$OUT" \
      -GN="$N" \
      -GAFile="\"$VEC/A_${MODE}_$N.hex\"" \
      -GBFile="\"$VEC/B_${MODE}_$N.hex\"" \
      -GCFile="\"$VEC/C_${MODE}_$N.hex\"" \
      -GYFile="\"$VEC/Y_${MODE}_$N.hex\"" \
      --top-module tb_top "${SOURCES[@]}" > "$OUT/build.log" 2>&1 \
      || { echo "BUILD FAILED (see $OUT/build.log)"; grep '%Error' "$OUT/build.log"; status=1; continue; }

    out=$("$OUT/Vtb_top" +verilator+seed+$RANDOM +verilator+rand+reset+2 2>&1 || true)
    echo "$out" | grep -E '^(TEST|MISMATCH|FAIL|TIMEOUT)|%Error' || true
    echo "$out" | grep -q 'TEST PASSED' || status=1
  done
done

exit $status
