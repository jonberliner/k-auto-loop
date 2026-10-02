---
name: autoresearch
description: Karpathy's autoresearch loop, generalised to anything with a number - one editable target file, one frozen eval command that prints "metric: <n>", a dedicated git branch, and an endless commit/eval/keep-or-reset loop with a TSV log. Use for optimisation tasks (speed, size, loss, score, cost) rather than feature building.
argument-hint: [tag]
---

# autoresearch

The original loop, as described in Karpathy's `program.md`, with the ML
specifics replaced by four values the human fills in. Feature work belongs
in `build` / `auto-loop`; this is for making a number go the right way.

## Setup (work with the human once, then never again this run)

1. Read `program.md`, then `.claude/kloop/repo.md` and
   `.claude/kloop/runs/<tag>.md` if they exist; a run spec written by
   `/kloop-project` already answers most of this section, so skip what it
   covers. If `program.md` is the build-loop version, the human wants the
   autoresearch variant: copy `templates/autoresearch.program.md` over it
   (or to `program.autoresearch.md` if both loops share the repo) and fill
   in, with the human:
   - **Target**: the one file you may edit.
   - **Eval**: a command in a file you may NOT edit that prints exactly one
     line `metric: <number>`. Add that file to `.claude/kloop/protected.txt`
     so the guard hook blocks edits to it.
   - **Direction**: lower or higher is better.
   - **Budget**: approximate minutes per eval run; kill at 2x.
2. Agree a run tag (today's date works: `oct02`). Branch
   `autoresearch/<tag>` must not already exist. `git checkout -b` it.
3. Create `autoresearch.tsv` with the header
   `commit	metric	status	description` (tabs). It is untracked and must
   stay untracked, so a reset never erases it.
4. **Baseline x3**: run the eval three times unchanged. Log each as
   `baseline`. The spread is your noise floor. Write it in the TSV
   description of the third baseline row: `noise_floor=<spread>`.
5. Confirm with the human once. Then go, and do not ask again.

## LOOP FOREVER

1. `git rev-parse --short HEAD` → remember the start.
2. Edit the target with **one** idea. Commit: `research: <one line>`.
3. Run the eval: `<eval> > run.log 2>&1`. Never `tee`. Never read the whole
   log into context.
4. `grep '^metric:' run.log`. If empty: `tail -n 50 run.log`. Trivial
   fix (typo, import)? Fix, amend, re-run. Fundamentally broken? Log
   `crash`, `git reset --hard <start>`, next idea.
5. Append a TSV row: `<commit>	<metric>	keep|discard|crash	<description>`.
6. **Keep** only if the metric beats the current best by more than the
   noise floor. Then the branch advances. Otherwise `git reset --hard
   <start>`.
7. Simplicity criterion: ~equal metric with less code is a **keep**. A
   tiny gain that adds a tangle is a **discard**.
8. Every ~20 kept commits, run an **ablation pass**: revert each kept
   change one at a time and re-measure; drop the ones that no longer help.
   Earlier wins are not independent of later ones.
9. Out of ideas? Re-read the target top to bottom, list what each part
   costs, combine two near-misses, try something structural, read the
   docs of the libraries in use. Do not degrade into seed flips and
   micro-nudges. Do not stop.

## Forbidden
- Editing the eval, its inputs, fixtures, data, or expected outputs.
- Changing random seeds, caching eval results, reading the answers.
- New dependencies.
- Pausing to ask the human whether to continue.
- Any file other than the target (and the untracked TSV / run.log).

## When interrupted
Write `reports/<date>-autoresearch-<tag>.md`: best metric vs baseline,
kept commits with one line each, notable discards, the ablation results,
and three ideas you did not get to. Copy `autoresearch.tsv` next to it.
