---
name: kloop-project
description: Start a specific loop run in an onboarded repo through a short conversation - picks the mode (autoresearch, build, auto-loop), pins the target and the frozen eval or the feature list, sets budgets, stop rules, branch tag and isolation, writes the run spec, scaffolds a frozen eval if none exists, baselines, and either kicks off or prints the exact unattended command. Use when asked to "start a run", "optimise X with the loop", "build these features with the loop", or run /kloop-project.
argument-hint: <what you want the loop to do>
---

# kloop-project

Requires `.claude/kloop/repo.md`. If missing, run `/kloop-setup` first.

Request: **$ARGUMENTS**

Principle: same as setup. **Recon, ask in batches with defaults, write,
verify, go.** A run spec is the contract; the loop skills read it.

## 1. Recon
- Read `.claude/kloop/repo.md`, `program.md`, `features.md` if present,
  and the last run spec in `.claude/kloop/runs/` for style.
- Locate the code the request names. For an optimisation request, find
  the smallest file or module that owns the behaviour, how it is trained
  or configured, what data it reads, and any existing metric computation.
  For a feature request, find the entry points and the nearest existing
  tests.
- Post a **five-line** summary: mode you infer, candidate target(s),
  candidate metric and where its ground truth comes from, estimated cost
  per round, risks (noise, leakage, long eval).

## 2. Interview (max two batches, `AskUserQuestion` when available)

**Batch A**
1. Mode: `autoresearch` (a number) / `build` (one feature) / `auto-loop`
   (several features, learning between them). Recommended from recon.
2. Autoresearch: the target. `one file: <inferred>` (recommended) / `a
   small module: <dirs>` / other. Build: the feature list in priority
   order (free text; split anything a handful of checks cannot verify).
3. Autoresearch: the metric and its direction, and whether an eval
   already exists. If none: what frozen data slice, what correctness
   asserts, what secondary constraints to print (`latency_ms`,
   `params_m`, `peak_mem_mb`), and the per-run time budget. Propose
   concrete values from recon.
4. Budget and stop rules: hours or experiments; stop on plateau after N
   consecutive discards (default: never, Karpathy-style, but for a
   bounded night default 40); ablation pass every K keeps (default 20).

**Batch B (power user; skip items already answered)**
5. Isolation: new worktree + branch `autoresearch/<tag>` or
   `kloop/<tag>` (recommended) / branch here. Tag default: today, e.g.
   `oct02`.
6. Seeds and forbidden tricks: no seed changes, no eval caching, no
   reading expected outputs, no new deps. Anything to add or relax?
7. Idea seeds: 3 to 10 directions to try first (free text); also what
   NOT to try (known dead ends).
8. Reporting: interim report every N rounds; final report plus draft PR,
   or report only. Who reviews.
9. Holdout: path to data the loop must never see, evaluated by the human
   (or by a separate command outside the worktree) on the kept commits
   at the end. Strongly recommended for anything that ships.

## 3. Write
- `.claude/kloop/runs/<tag>.md` from `templates/run.md`: every answer.
- **Autoresearch**: fill `program.md`'s autoresearch block (or write
  `program.<tag>.md` when the build-loop `program.md` must stay) with
  Target, Eval, Direction, Budget, Noise floor policy, forbidden list,
  idea seeds. If no eval exists, scaffold one from
  `templates/eval_template.py` into a protected dir (e.g. `eval/`): fixed
  data slice pinned by a manifest hash, fixed time budget, correctness
  asserts, prints `metric:` plus secondary lines. Add the eval dir and
  data manifest to `.claude/kloop/protected.txt` and a matching
  `Edit(eval/**)` deny rule. Create `autoresearch.tsv` with its header.
- **Build / auto-loop**: add each feature to `features.md` with rules as
  observable behaviour, status `todo`.
- Create the worktree and branch if chosen. Commit the spec and eval:
  `kloop(<tag>): run spec + frozen eval`.

## 4. Verify
- Run the eval once by hand; confirm one `metric:` line and sane
  secondary lines. Time it. If it exceeds the budget, shrink the slice or
  budget now, not at 3 a.m.
- Baseline x3 for autoresearch; record the spread as the noise floor in
  the run spec and the TSV.
- Guard self-test on the eval path.

## 5. Go
Print the exact kick-off, both forms:
- Interactive: `cd <worktree> && claude` then
  `read program.md and .claude/kloop/runs/<tag>.md and start the <mode> run`.
- Unattended: the headless command from `repo.md` with permissions bypassed
  and output logged to `reports/<tag>.console.log`; remind that the guard
  hook and deny rules stay active in bypass mode.
If the user said go, start the run now with the matching skill
(`/autoresearch <tag>`, `/build <feature>`, or `/auto-loop <features>`) and
do not ask again until the stop rule fires.
