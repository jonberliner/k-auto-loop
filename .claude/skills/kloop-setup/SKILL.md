---
name: kloop-setup
description: Onboard a repository for k-auto-loop in one short conversation. Runs Graft first (install if missing, init, build), infers everything the repo can tell it, asks exactly three questions that only the human can answer (what may change, what must never change, what the code does not say), then shows one consolidated review of every knob with its value and where it lives before writing anything. Use when asked to "set up the loop on this repo", "onboard this repo", or run /kloop-setup. Can be run from the k-auto-loop repo with a path to install first.
argument-hint: [path-to-repo]
---

# kloop-setup

Three kinds of knobs, three rules:

| Kind | Rule |
|---|---|
| **Decisions only the human can make** | Ask. Three questions, one batch. |
| **Facts the repo can tell you** | Never ask. Infer, show in the review, ask only if inference failed. |
| **Preferences with strong defaults** | Never ask. Show each with its value in the review; the human changes it by saying so. |

Nothing is written to the repo until the review is approved. Graft and the
k-auto-loop install are the exceptions, and both are announced first.

Target: `$0` if given (a path; if it has no `.claude/kloop/`, run this
package's `install.sh <path>` first, then `cd` there), otherwise the
current repo.

## 0. Graft first

Graft (https://github.com/trailhq/Graft) builds a local code graph and
wires itself into Claude Code with its own skill, hooks, and MCP tools.
Use it the way Graft intends; do not invent command recipes for it.

1. `graft --version`. If missing, ask the one conditional question:
   install globally (`npm install -g @nanonets/graft`), use
   `npx -y @nanonets/graft` per call, or skip. Installing a global package
   is the user's call. If skipped, continue and mark recon degraded.
2. `graft init --dry-run --agents claude`, show the file list, then
   `graft init --agents claude` (add `--no-statusline` if the repo has a
   statusline to keep). `graft build` if init did not. `graft check` must
   exit 0.
3. Confirm the k-auto-loop guard survived Graft's settings merge: the
   PreToolUse entry for `guard-locked.py` and the `Edit(checks/locked/**)`
   deny rule are still in `.claude/settings.json`. If not, re-run
   `install.sh` on this path.

## 1. Recon (no questions)

Code structure through Graft as its skill directs: what the repo is, which
areas are central, where tests, evaluation, data loading, and configuration
live. Prefer the graph to reading hub files whole.

Everything Graft does not map, from files: `README*`, `CLAUDE.md`,
`AGENTS.md`, docs index, manifests, test config and the exact CI test
command (and its duration if CI says), data and model directories,
migrations, infra, generated code, existing `.claude/` config, hot files
from `git log --since=6.months --name-only --pretty=format: | sort | uniq -c | sort -rn | head -30`,
and compute if ML-shaped (`nvidia-smi`, CUDA availability, CPU count).

Post a **ten-line "what I found"**: stack; graph size and languages; test
command and estimated duration; the areas a loop would most plausibly
work in; the areas that look like they must never change; data and holdout
hints; compute; anything surprising. The only unprompted text before the
questions.

## 2. Ask: three questions, one batch

Use `AskUserQuestion` when available (2-4 options each, recommended first
and marked "(Recommended)"; the tool always adds "Other" for free text).
Without it, ask as a numbered list and wait. Fold free text into the
profile verbatim.

1. **"Which parts of the repo may a loop change?"**
   Options: `<the inferred lab directories> (Recommended)` /
   `anywhere, on a loop branch` / `one file I will name per run`.
   This is the hard outer boundary. Per-run scope inside it is drafted by
   `/kloop-project` from the graph and is soft.
2. **"Which parts must a loop never touch, and is there anything it must
   never do here?"** Put the recon candidates in the question text as a
   list (evals and benchmarks, data and manifests, CI and deploy,
   migrations and schemas, prod code and secrets, the existing suite,
   anything that feeds production). Options: `protect all of these
   (Recommended)` / `all of these plus rules I will type` / `let me edit
   the list`. Rules like "never call the live feature store" belong here.
3. **"What should an agent know about this repo that the code does not
   say?"** Options: `nothing beyond README and CLAUDE.md (Recommended if
   they are current)` / `I will type it`. Feeds `project-context`: intent,
   conventions, process, owners, flaky areas, where the PRD and runbooks
   live. Graft holds the code map; this holds the rest.

That is the whole interview. If an inference failed (no test runner
found, no CI, ambiguous lab area), add one question for it to the same
batch, up to the tool's limit of four.

## 3. Draft (in memory)

- `.claude/kloop/repo.md` from `templates/repo.md`, every line tagged
  `(decided)`, `(inferred)`, or `(default)`.
- `.claude/kloop/protected.txt`; `.claude/kloop/config.sh` (`CHECK_CMD`,
  `SUITE_CMD`).
- `program.md` `## Fixed rules`: lab boundary, protected list, nevers,
  defaults below. Never touch `## How to work`.
- `.claude/skills/project-context/SKILL.md` filled from recon and answer 3.
- `.claude/settings.json`: deny rules for each protected area, e.g.
  `Edit(eval/**)`.
- `.claude/agents/feature-builder.md` only if a default there changes.

## 4. Review gate: one table, then approve or edit

Show, in chat, in this order:

1. **The knobs table.** Every knob, its value, how it was set, and the file
   it lives in. This is the whole configuration in one place:

   | knob | value | set by | lives in |
   |---|---|---|---|
   | lab boundary | recsys/ | decided | program.md Fixed rules, repo.md |
   | protected paths | eval/, data/, ... | decided | protected.txt, settings deny |
   | repo nevers | ... | decided | program.md Fixed rules |
   | non-code context | ... | decided | project-context |
   | check runner / full suite | `uv run pytest {dir} -q -rf` / `uv run pytest -q` (6 min) | inferred | config.sh |
   | suite cadence | at feature end (suite > 2 min) | default | program.md |
   | round cap per feature | 8 | default | program.md |
   | builder turn limit / model | 150 / inherit | default | feature-builder.md |
   | isolation | worktree per run | default | repo.md |
   | delivery | commits stay on the loop branch; human opens PR | default | program.md |
   | scope policy | soft | default | repo.md |
   | Graft | 0.21.1, 4,812 nodes, structural (no --deep) | inferred / default | repo.md |
   | data, holdout hints | data/manifests/..., holdout manifest points outside repo | inferred | repo.md |
   | compute | 1x A10, 32 CPU | inferred | repo.md |

2. The full `repo.md` draft and the `program.md` fixed-rules diff.
3. One question: `approve and write (Recommended)` / `edit` (free text:
   "hard scope", "maxTurns 300", "add infra/ to protected", anything in
   the table). Apply edits, re-show the changed rows, ask again. Loop
   until approved.

## 5. Write and verify

- Write the drafted files. Confirm `.gitignore` covers `results.tsv`,
  `autoresearch.tsv`, `run.log`, `checks.log`, `graft/`.
- Prove the runner executes (empty check dir or collect-only mode).
- Guard self-test: fake `Edit` on a protected path into
  `.claude/kloop/guard-locked.py`; expect exit 2. `graft check` exits 0.
- If isolation is worktree: `git worktree add ../<repo>-kloop -b kloop/<date>`.
- Commit: `kloop: onboard repo (graft wiring, profile, protected paths, context)`.
- End with five lines: what was written, what was verified, and the next
  command, `/kloop-project <what you want the loop to do>`.
