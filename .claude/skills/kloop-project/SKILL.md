---
name: kloop-project
description: Start a specific loop run in an onboarded repo through a short conversation. Uses the Graft graph to find the relevant part of the repo and propose a soft scope, proposes metric candidates with trade-offs for YOU to choose, sets budgets, stop rules, branch and isolation, shows the complete run spec and eval for approval before anything is baselined or started, then scaffolds the frozen eval, baselines, and kicks off or prints the unattended command. Use when asked to "start a run", "optimise X with the loop", "build these features with the loop", or run /kloop-project.
argument-hint: <what you want the loop to do>
---

# kloop-project

Requires `.claude/kloop/repo.md`. If missing, run `/kloop-setup` first.
If `graft check` fails or `graft/` is missing, run `graft build` first.

Request: **$ARGUMENTS**

Principle: **graph recon, ask in batches with defaults, draft, review,
write, verify, go.** The run spec is the contract the loop skills read.
Two decisions are always the user's and are never defaulted silently:
**what the metric is** and **what the scope is**. You propose; they pick.

## 1. Recon with the graph

- Read `.claude/kloop/repo.md`, `program.md`, `features.md` if present,
  and the last spec in `.claude/kloop/runs/` for house style.
- Find the relevant part of the repo:
  - `graft ask "<the request>" --json -n 12` for ranked candidates.
  - For the top candidates: `graft skeleton <file>` for the API surface;
    `graft callers <symbol> -d 2` (in) and `--direction out` (out) for the
    neighbourhood and blast radius.
  - `graft grep` for strings the request names (metric names, config
    keys, feature flags).
- Draft a **scope**, not a fence:
  - **core**: the file(s) the loop will edit, usually one;
  - **neighbourhood**: files within two hops that the loop will likely
    read or may need to touch (tests, callers, config);
  - **out of scope by default**: everything else. Under the `soft` policy
    the loop may go there when it must and logs the excursion; under
    `hard` it stops and reports.
  - Flag any neighbourhood file that is protected per `repo.md`.
- For an optimisation request, also find how the thing is trained or
  configured, what data it reads, and any existing metric computation.
  For a feature request, find entry points and the nearest existing tests.
- Post a **six-line summary**: inferred mode, draft scope (core and
  neighbourhood counts with the core path), 2-3 metric candidates with
  one-line trade-offs, estimated cost per round, risks (noise, leakage,
  long eval, blast radius crossing into protected code).

## 2. Interview (max two batches, `AskUserQuestion` when available)

**Batch A**
1. Mode: `autoresearch` (a number) / `build` (one feature) / `auto-loop`
   (several features, learning between them). Recommended from recon.
2. Scope: `use the drafted scope` (recommended; list core and
   neighbourhood) / `widen to <dir>` / `narrow to core only` / other.
   Remind which policy (`soft`/`hard`) is in force from `repo.md`.
3. Autoresearch: **the metric.** Present 2-3 candidates. For each: what
   it measures, where ground truth comes from, expected noise, how it
   could be gamed, cost per run. Ask the user to pick one or write their
   own, plus direction. Build: the feature list in priority order (free
   text; split anything a handful of checks cannot verify).
4. Budget and stop rules: hours or experiments; stop on plateau after N
   consecutive discards (default never, Karpathy-style; for a bounded
   night suggest 40); ablation pass every K keeps (default 20); per-run
   time budget for the eval (propose from recon).

**Batch B (power user; skip what is already answered)**
5. Eval design when none exists: frozen data slice and how it is pinned
   (manifest hash, date range), correctness asserts, secondary lines to
   print (`latency_ms`, `params_m`, `peak_mem_mb`) and which are hard caps.
6. Isolation: new worktree + branch `autoresearch/<tag>` or `kloop/<tag>`
   (recommended) / branch here. Tag default: today, e.g. `oct02`.
7. Forbidden tricks: no seed changes, no eval caching, no reading expected
   outputs, no new deps. Add or relax?
8. Idea seeds: 3 to 10 directions to try first; known dead ends not to
   retry.
9. Reporting and holdout: interim report every N rounds; final report
   plus draft PR or report only; who reviews; path to holdout data the
   loop must never see, evaluated by the human on the kept commits.

## 3. Draft (in memory)

- `.claude/kloop/runs/<tag>.md` from `templates/run.md`, including the
  Scope section (core, neighbourhood, policy, excursion log pointer).
- **Autoresearch**: the `program.md` autoresearch block (or
  `program.<tag>.md` when the build-loop `program.md` must stay): Target,
  Eval, Direction, Budget, Noise floor policy, forbidden list, idea seeds.
  If no eval exists, scaffold one from `templates/eval_template.py` into a
  protected dir (e.g. `eval/`) with the chosen metric implemented in
  `metric_fn`. Plan to add the eval dir and manifest to
  `.claude/kloop/protected.txt` and an `Edit(eval/**)` deny rule.
- **Build / auto-loop**: `features.md` entries with rules as observable
  behaviour, status `todo`.

## 4. Review gate (nothing lands before this)

Print the complete run spec and, for autoresearch, the eval's
`metric_fn` and the asserts, in chat. Ask one question: `approve` /
`edit` (free text). Loop until approved. The user can also say "show me
the neighbourhood" and you print the `graft callers` output that produced
it.

## 5. Write and verify

- Write the spec, program block, eval, protected additions, deny rule,
  `autoresearch.tsv` header or `features.md` entries. Create the worktree
  and branch if chosen. Commit: `kloop(<tag>): run spec + frozen eval`.
- Run the eval once by hand; confirm exactly one `metric:` line and sane
  secondary lines. Time it. If it exceeds the budget, shrink the slice or
  the budget now, not at 3 a.m.
- Baseline x3 for autoresearch; record the spread as the noise floor in
  the spec and the TSV.
- Guard self-test on the eval path (expect exit 2). `graft check` exits 0.
- Tell the user the baseline, the noise floor, and the measured time per
  run. If the noise floor swallows the kind of gains they expect, say so
  now and offer to enlarge the slice or the budget.

## 6. Go

Print the exact kick-off, both forms:
- Interactive: `cd <worktree> && claude` then
  `read program.md and .claude/kloop/runs/<tag>.md and start the <mode> run`.
- Unattended: the headless command from `repo.md` with permissions
  bypassed and output logged to `reports/<tag>.console.log`; remind that
  the guard hook and deny rules stay active in bypass mode.
If the user says go, start the run now with the matching skill
(`/autoresearch <tag>`, `/build <feature>`, or `/auto-loop <features>`)
and do not ask again until a stop rule fires.
