# Karpathy's autoresearch: what it is and what people learned running it

Source repo: https://github.com/karpathy/autoresearch (MIT). Released
March 7, 2026. Karpathy's own context is in two X posts linked from the README:
https://x.com/karpathy/status/2029701092347630069 and
https://x.com/karpathy/status/2031135152349524125.

## The design in one paragraph

Give an agent a small but real LLM training setup and let it experiment
alone overnight. It edits the code, trains for exactly 5 minutes of wall
clock, checks whether validation bits-per-byte (`val_bpb`) went down, keeps or
discards the commit, and repeats. The human does not touch the Python.
The human edits `program.md`, the Markdown that programs the agent.
Karpathy calls this "programming the program".

## The three files

- `prepare.py`: constants, one-time data prep (downloads data, trains a BPE
  tokenizer), dataloader, and `evaluate_bpb`. Read-only for the agent.
- `train.py`: the full GPT, Muon + AdamW optimizer, training loop. The only
  file the agent edits. About 630 lines.
- `program.md`: agent instructions. The only file the human edits.

## Design choices worth copying

- **One editable file.** Keeps scope manageable and diffs reviewable.
- **Fixed time budget, not fixed steps.** Every experiment costs the same
  wall clock, so architecture, batch size, and model size changes are all
  directly comparable, and the loop finds what is best *for your hardware*.
  The cost: results are not comparable across machines.
- **One metric, chosen to be hard to game.** `val_bpb` is vocabulary-size
  independent, so a tokenizer trick cannot fake an improvement.
- **The scorer is frozen.** If the agent could edit the evaluation, it would
  optimise the evaluation.
- **Git is the memory.** Each experiment is a commit on a dedicated branch
  (`autoresearch/<tag>`). Keep = advance the branch. Discard = `git reset`
  back. The results TSV is deliberately *untracked*, so a reset never erases
  the log.
- **A simplicity criterion.** A tiny gain that adds ugly complexity is not
  worth keeping. Equal results with less code is a win. The agent weighs
  complexity cost against improvement size.
- **Never stop.** Once the loop starts, the agent must not pause to ask
  whether to continue. The human may be asleep. Out of ideas means think
  harder: re-read the code, combine near misses, try something radical.

## The loop (Karpathy's `program.md`, paraphrased)

Setup: agree a run tag, create branch `autoresearch/<tag>`, read the
in-scope files, confirm the data exists, create `results.tsv` with only a
header, confirm with the human once, then go.

Loop forever:
1. Note the current branch and commit.
2. Change `train.py` with one experimental idea.
3. Commit.
4. Run training with all output redirected to a log file. Never `tee` into
   the context window.
5. Grep the metric lines out of the log.
6. Empty grep means a crash: read the last 50 lines, fix if it is trivial,
   otherwise log `crash` and move on.
7. Append a row to the TSV: commit, metric, memory, status, description.
8. Improved: keep the commit. Equal or worse: reset to where you started.

Timeouts: a run that exceeds twice the budget is killed and treated as a
failure. Expected throughput: ~12 experiments an hour, ~100 overnight.

## Results people reported

- Karpathy: one overnight run took `val_bpb` from 0.9979 to 0.9697 across
  126 experiments; a two-day `depth=12` run made ~700 attempts and kept ~20.
- Tobi Lütke (Shopify): 37 experiments overnight produced a 0.8B model that
  beat his hand-tuned 1.6B. He then pointed the same pattern at Liquid, the
  Shopify templating engine, and got ~53% faster rendering and ~61% fewer
  allocations from 93 automated commits. That is the proof the pattern is
  not ML-specific: anything with a number you can measure works.

## Lessons from people who ran it

- **Goodhart shows up fast.** Agents find seed changes and micro-tweaks that
  move the metric by noise. Put explicit bans in `program.md` (no seed
  changes, no eval changes) and require improvements to clear a noise floor.
- **Late sessions degrade** into random seed changes and micro-adjustments.
  Diminishing returns are real; plateau detection or an idea list helps.
- **Kept changes are not independent.** Improvement 15 may no longer matter
  after 16 through 20 changed the surrounding code. Periodic ablation passes
  are worth adding.
- **Hardware specific.** The same change can help on one GPU and hurt on
  another. That is by design; do not over-generalise results.
- **Real wins happen.** Smaller batch for more steps in the window, tight
  hyperparameter ranges humans would never sweep by hand, and actual bugs
  (missing multipliers, bad optimizer defaults) that transferred to larger
  models.
- **Start with the default `program.md`.** Run it, watch what the agent
  does, then refine. The git history of `program.md` is as valuable as the
  git history of `train.py`.
- **Disable permission prompts.** The worst outcome of a bad experiment is a
  reverted commit, so autonomous execution is safe inside the sandbox of a
  dedicated branch and a frozen scorer.
- Nobody has published a cost breakdown (GPU time plus tokens).

## Running on small hardware

From the README: use a low-entropy dataset such as TinyStories, shrink the
vocab (even byte-level), lower `MAX_SEQ_LEN` and `EVAL_TOKENS`, lower
`DEPTH` from 8 to 4, use `WINDOW_PATTERN="L"`, and shrink
`TOTAL_BATCH_SIZE` in powers of two. Forks: `miolini/autoresearch-macos`,
`trevin-creator/autoresearch-mlx` (Apple MLX), `jsegov/autoresearch-win-rtx`,
`andyluo7/autoresearch` (AMD).

## Community generalisations

- `uditgoenka/autoresearch`: a Claude Code skill. Three user-supplied
  primitives: Goal, Metric, Verify (a shell command that prints the metric).
  Bounded iterations by default (25), a guard that re-works a change if it
  breaks existing tests, crash recovery limits, and a TSV log with delta from
  baseline.
- `Rkcr7/autoresearch-guide`: a long guide to the pattern on non-ML targets
  (Python speed, prompts, Rust, Docker images, Nginx). Emphasises a frozen
  eval script, concrete constraints, multi-run noise handling, and the
  observation that a better `program.md` is the main lever.
- `yibie/awesome-autoresearch`: a list of ports and writeups.

The `autoresearch` skill in this package is the generalised form: any target
file, any eval command that prints `metric: <number>`, same loop semantics.
