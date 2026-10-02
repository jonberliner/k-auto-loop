#!/usr/bin/env python3
"""FROZEN EVAL TEMPLATE for autoresearch runs. Copy to a protected dir
(e.g. eval/<name>.py), fill the three TODOs, add the dir to
.claude/kloop/protected.txt, and never let the loop edit it.

Contract: prints exactly one `metric: <number>` line (plus optional
secondary lines) to stdout. Wrong answers raise, so a cheat is a crash,
not a score. Data is pinned by a manifest hash so the loop cannot drift
the slice. Training/fitting is time-boxed so experiments are comparable.

    python eval/<name>.py            # one run
    python eval/<name>.py --holdout  # human only, after the loop

Keep the holdout path outside the worktree (env var or absolute path) so
the loop cannot read it even by accident.
"""
import argparse
import hashlib
import importlib
import json
import os
import sys
import time

# --- TODO 1: what the loop edits, imported here --------------------------
TARGET_MODULE = "recsys.pattern_detector"   # the ONE module the agent may edit
TARGET_ENTRY = "build_detector"              # callable(train_data, budget_s) -> model with .predict(x)

# --- TODO 2: pinned data -----------------------------------------------------
DATA_MANIFEST = "eval/data_manifest.json"    # {"train": path, "val": path, "sha256": {...}}
HOLDOUT_ENV = "KLOOP_HOLDOUT_PATH"           # set only in the human's shell

# --- TODO 3: budget and metric ------------------------------------------------
TRAIN_BUDGET_S = 180                          # wall clock for fitting, fixed
LATENCY_BUDGET_MS = 20.0                      # hard cap, printed; program.md enforces


def sha256(path, chunk=1 << 20):
    h = hashlib.sha256()
    with open(path, "rb") as fh:
        for b in iter(lambda: fh.read(chunk), b""):
            h.update(b)
    return h.hexdigest()


def load_split(name, manifest):
    path = manifest[name]
    want = manifest["sha256"][name]
    got = sha256(path)
    if got != want:
        raise SystemExit(f"DATA DRIFT: {name} sha256 {got[:12]} != manifest {want[:12]}")
    # TODO: load into whatever structure your detector expects
    import pandas as pd  # noqa: WPS433 (example)
    return pd.read_parquet(path)


def metric_fn(model, df):
    """TODO: your offline metric. Example: precision@k over labelled patterns.
    Must be deterministic given model + df. Return a float."""
    preds = model.predict(df.drop(columns=["label"]))
    k = 10
    top = preds.argsort()[::-1][:k]
    return float(df["label"].values[top].mean())


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--holdout", action="store_true", help="human only")
    args = ap.parse_args()

    with open(DATA_MANIFEST) as fh:
        manifest = json.load(fh)
    train = load_split("train", manifest)
    if args.holdout:
        hp = os.environ.get(HOLDOUT_ENV)
        if not hp:
            raise SystemExit(f"set {HOLDOUT_ENV} to the holdout parquet path (outside the worktree)")
        import pandas as pd
        evalset = pd.read_parquet(hp)
    else:
        evalset = load_split("val", manifest)

    mod = importlib.import_module(TARGET_MODULE)
    build = getattr(mod, TARGET_ENTRY)

    t0 = time.perf_counter()
    model = build(train, budget_s=TRAIN_BUDGET_S)
    fit_s = time.perf_counter() - t0
    if fit_s > TRAIN_BUDGET_S * 1.25:
        raise SystemExit(f"BUDGET EXCEEDED: fit took {fit_s:.1f}s > {TRAIN_BUDGET_S}s")

    # correctness asserts: shape, finiteness, no NaN cheating
    sample = evalset.drop(columns=["label"]).head(256)
    t1 = time.perf_counter()
    p = model.predict(sample)
    latency_ms = (time.perf_counter() - t1) / max(len(sample), 1) * 1000
    if len(p) != len(sample):
        raise SystemExit("WRONG SHAPE from predict")
    import math
    if any(not math.isfinite(float(x)) for x in p):
        raise SystemExit("NON-FINITE predictions")

    m = metric_fn(model, evalset)
    n_params = getattr(model, "n_params", lambda: float("nan"))()
    print(f"metric: {m:.6f}")
    print(f"latency_ms: {latency_ms:.3f}")
    print(f"fit_seconds: {fit_s:.1f}")
    print(f"params_m: {n_params / 1e6 if n_params == n_params else float('nan'):.3f}")
    if latency_ms > LATENCY_BUDGET_MS:
        print("constraint: latency_over_budget")


if __name__ == "__main__":
    sys.exit(main())
