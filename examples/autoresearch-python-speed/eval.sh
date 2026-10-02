#!/usr/bin/env bash
# FROZEN eval. Prints exactly one line "metric: <seconds>" (lower is better).
# Correctness is checked first; a wrong answer is a crash, not a score.
set -euo pipefail
cd "$(dirname "$0")"
python3 - <<'PY'
import time, importlib
t = importlib.import_module("target")
expected = {1000: 168, 20000: 2262}
best = None
for _ in range(3):
    t0 = time.perf_counter()
    for n, want in expected.items():
        got = t.solve(n)
        if got != want:
            raise SystemExit(f"WRONG ANSWER for n={n}: got {got}, want {want}")
    dt = time.perf_counter() - t0
    best = dt if best is None else min(best, dt)
print(f"metric: {best:.6f}")
PY
