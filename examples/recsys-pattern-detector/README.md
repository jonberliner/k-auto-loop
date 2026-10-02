# Example layout: autoresearch on a production recommender

How a large product-recommendation repo gets a loop pointed at its pattern
detector without the loop ever touching production. Nothing here runs; it
is the shape `/kloop-setup` + `/kloop-project` produce.

## The lab inside the repo

```
recsys/
  pattern_detector.py        <- TARGET: the one file the loop edits
  features.py                 read-only (feature pipeline; protected)
  serving/...                 read-only (prod; protected)
eval/
  pattern_eval.py            <- FROZEN eval, from templates/eval_template.py
  data_manifest.json         <- pins train/val parquet paths + sha256
.claude/kloop/
  repo.md                    <- profile from /kloop-setup
  runs/oct02.md              <- run spec from /kloop-project
  protected.txt              <- eval/, recsys/features.py, recsys/serving/, data/, migrations/
program.md                   <- autoresearch block filled in
autoresearch.tsv             <- untracked lab notebook
```

Outside the worktree, known only to you:

```
~/data/recsys-holdout-2026q3.parquet   # KLOOP_HOLDOUT_PATH; the loop never sees it
```

## What the eval enforces

- Loads `train` and `val` only through the manifest; a hash mismatch is a
  crash. The loop cannot "improve" by changing the slice.
- Calls `build_detector(train, budget_s=180)` from the target and kills
  anything over 1.25x the budget, so every experiment costs the same and
  model-size changes compare fairly (Karpathy's fixed-time rule).
- Asserts prediction shape and finiteness. A cheat is a crash, not a score.
- Prints `metric:` (e.g. precision@10 on labelled patterns, or NDCG@10),
  plus `latency_ms`, `fit_seconds`, `params_m`. `program.md` says the
  latency line is a hard cap; a keep that breaches it is a discard.

## What program.md's autoresearch block says

- Target `recsys/pattern_detector.py`; eval `python eval/pattern_eval.py`;
  direction higher; budget 3 min fit + ~30 s eval; kill at 7 min.
- Baseline x3 first; the spread is the noise floor; improvements inside it
  are discards.
- Forbidden: seeds, caching, reading labels, new deps, touching
  `features.py` even "just to add a column". New features are a separate,
  human-reviewed run with its own target.
- Idea seeds you wrote: windowed co-occurrence counts, decay on session
  recency, min-support pruning, hashing trick for sparse ids, a simple
  two-tower baseline for comparison, pruning the current rule list.
- Stop: 40 consecutive discards, or 8 hours. Ablation pass every 20 keeps.

## The night

```
cd ../recsys-kloop            # worktree on branch autoresearch/oct02
claude -p "read program.md and .claude/kloop/runs/oct02.md and start the autoresearch run" \
  --permission-mode bypassPermissions > reports/oct02.console.log 2>&1
```

About 15 experiments an hour at this budget, so roughly 100 overnight.

## The morning

1. `git log --oneline autoresearch/oct02` and `autoresearch.tsv`: what was
   kept, what was tried.
2. `KLOOP_HOLDOUT_PATH=~/data/recsys-holdout-2026q3.parquet python eval/pattern_eval.py --holdout`
   on the final commit, and on the baseline commit. If val improved and
   holdout did not, the loop overfit the slice: tighten the eval, do not
   ship.
3. Read `reports/2026-10-03-autoresearch-oct02.md`: kept commits, notable
   discards, ablation results, three untried ideas.
4. Open the PR yourself from the branch. The loop never pushes to main.
