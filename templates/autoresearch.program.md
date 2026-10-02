# program.md (autoresearch mode)

Karpathy-style metric loop, generalised. Fill in the four values below, then
tell the agent: "read program.md and start a new autoresearch run".

## Setup

- **Target**: `<path/to/file>` — the ONE file the agent may edit.
- **Eval**: `<command>` — prints a line `metric: <number>` and nothing else
  that matters. Lives in a file the agent never edits (e.g. `eval.sh`).
- **Direction**: `lower` | `higher`.
- **Budget**: each eval run should take about `<N>` minutes. Kill anything
  that runs longer than 2x that.
- **Noise floor**: run the baseline 3 times before experimenting. An
  improvement smaller than the spread of those runs is noise, not a keep.

## Hard limits

- Edit only the target file. The eval command, its inputs, fixtures, and
  data are frozen. Changing them is cheating, not research.
- No new dependencies.
- No random-seed changes, no changing what is measured, no caching eval
  outputs, no reading the eval's expected answers.
- Simplicity criterion: a tiny gain that adds ugly complexity is not worth
  it. Equal metric with less code is a keep.

## The loop

Work on branch `autoresearch/<tag>`. `autoresearch.tsv` is untracked.

LOOP FOREVER:
1. Note the current commit.
2. Change the target with one idea. Commit with a one-line description.
3. Run the eval with all output redirected: `<eval> > run.log 2>&1`.
4. `grep '^metric:' run.log`. Empty means crash: `tail -n 50 run.log`.
5. Append `commit, metric, keep|discard|crash, description` to `autoresearch.tsv`.
6. Better than the current best by more than the noise floor: keep (advance).
   Otherwise: `git reset --hard HEAD~1`.
7. Do not stop. Do not ask. If out of ideas, re-read the target, combine
   near misses, try a structural change, or run an ablation pass over the
   kept commits to remove ones that no longer help.

## Ideas to try first

- (human fills this in; the agent appends ideas it generated but has not tried)
