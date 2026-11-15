#!/usr/bin/env bash
# Build and run the example with Verilator (5.x, needs --timing for the TB's
# delays and @(posedge) waits).
# Usage: [VERBOSE=1] sim/run_verilator.sh [N ...]   (default: 2)
# Logs per run: sim/build/verilator/N<N>_<mode>/{build,sim}.log
set -euo pipefail

REPO=$(cd "$(dirname "$0")/.." && pwd)
BUILD="$REPO/sim/build/verilator"

SOURCES=("$REPO/sim/IBUFDS.v")
while IFS= read -r f; do SOURCES+=("$f"); done \
  < <(find "$REPO/src/sources" -name '*.sv' | sort)
SOURCES+=("$REPO/src/sim/tb_systolic_array.sv")

if (($#)); then SIZES=("$@"); else SIZES=(2); fi
MODES=(iden rand)

python3 "$REPO/sim/gen_stim.py" --sizes "${SIZES[@]}"

# Print the first line of every Verilator diagnostic in a log (one line per
# warning/error, with file:line), repo paths shortened. Full context stays in
# the log.
show_diags() {
  grep -E '^%(Warning|Error)' "$1" | sed "s|$REPO/||g" || true
}

status=0
for N in "${SIZES[@]}"; do
  for MODE in "${MODES[@]}"; do
    echo "=== N=$N mode=$MODE ==="
    VEC="$REPO/sim/N$N"
    OUT="$BUILD/N${N}_$MODE"
    rm -rf "$OUT"
    mkdir -p "$OUT"

    verilator --binary --timing -Wno-fatal -Wall -Wno-TIMESCALEMOD \
      --trace-fst -CFLAGS "-I$(brew --prefix)/include" -LDFLAGS "-L$(brew --prefix)/lib" \
      --x-assign unique --x-initial unique \
      -Mdir "$OUT" \
      -GN="$N" \
      -GAFile="\"$VEC/A_${MODE}_$N.hex\"" \
      -GBFile="\"$VEC/B_${MODE}_$N.hex\"" \
      -GCFile="\"$VEC/C_${MODE}_$N.hex\"" \
      -GYFile="\"$VEC/Y_${MODE}_$N.hex\"" \
      -GFstPath="\"$OUT/out.fst\"" \
      --top-module tb_systolic_array "${SOURCES[@]}" > "$OUT/build.log" 2>&1 \
      || {
        show_diags "$OUT/build.log"
        echo "BUILD FAILED (full log: ${OUT#"$REPO"/}/build.log)"
        status=1
        continue
      }
    show_diags "$OUT/build.log"

    # Full sim output (including $display debug prints) goes to sim.log;
    # set VERBOSE=1 to also echo all of it here.
    "$OUT/Vtb_systolic_array" +verilator+seed+$RANDOM +verilator+rand+reset+2 \
      > "$OUT/sim.log" 2>&1 || true
    if [[ ${VERBOSE:-0} == 1 ]]; then
      cat "$OUT/sim.log"
    else
      grep -E '^(TEST|MISMATCH|FAIL|TIMEOUT)|%Error' "$OUT/sim.log" || true
    fi
    grep -q 'TEST PASSED' "$OUT/sim.log" || status=1
  done
done

exit $status
