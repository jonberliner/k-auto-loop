---
name: build
description: Run the Karpathy-style build loop for one or more features - write checks first, get the human to approve and lock them, then hand each feature to a fresh feature-builder agent that iterates in commit/check/keep-or-reset rounds until every locked check passes. Use when asked to build a feature with the loop, or to "run the build loop".
argument-hint: <feature or request>
---

# build

Single-pass build loop. Rules of the road are in `program.md`; read it first,
all of it, every time. This skill is the driver, the `feature-builder` agent
does the building, `write-checks` writes the checks, and `project-context`
is the memory. For a loop that improves its own instructions between
features, use `auto-loop` instead; it calls this skill.

Request: **$ARGUMENTS**

## 0. Preflight
- Read `program.md`. Load `project-context`. If `.claude/kloop/repo.md` exists,
  read it; if a run spec for this work exists in `.claude/kloop/runs/`, read
  it too. They override defaults here (round cap, delivery, nevers).
- Confirm `.claude/kloop/*.sh` are executable and `checks/locked/` exists.
- Confirm the working tree is clean (`git status --porcelain` empty). If
  not, stop and ask the human to commit or stash. This is the only
  preflight question allowed.
- Confirm `results.tsv` exists with its header; create it from
  `templates/results.header.tsv` semantics if missing (the log script also
  creates it).

## 1. Feature intake
- Map the request onto `features.md`. If the feature is not there, add an
  entry: summary, entry point, **Rules** as observable behaviour, status
  `todo`. Split anything that cannot be verified by a handful of checks into
  smaller features. One feature per loop pass; the app is never "finished"
  in one loop.

## 2. Checks (the human gate)
- Invoke `write-checks <feature>`. It produces `checks/pending/<feature>/`
  and a `CHECKLIST.md`.
- Show the human the checklist in plain words. Iterate until they say go.
  Record changes they asked for in `features.md`.
- On go: run `.claude/kloop/approve-checks.sh <feature>`. It moves the
  checks to `checks/locked/<feature>/` and commits them. Set the feature's
  status to `checks-locked`. From here no agent may touch those files.

## 3. Build rounds (delegated)
- Set status `building`. Note the starting commit.
- Launch the `feature-builder` agent with a **fresh context**. Pass it:
  the feature name, the path to its locked checks, the rules from
  `features.md`, the max rounds from `program.md`, and the instruction to
  read `program.md` and `project-context` itself. Do not paste the whole
  repo into its prompt; it has tools.
- The builder runs the rounds and logs every one with
  `.claude/kloop/log-result.sh`. It returns a structured summary:
  rounds, final status (`done` | `stuck`), what was tried, what failed and
  why, files changed, anything the checks did not cover that it wired
  anyway, and anything it believes is a bug in a check.
- If it returns `stuck`, do not loosen anything. Record it and move on.

## 4. Verify, log, report
- Run `.claude/kloop/run-checks.sh all > checks.log 2>&1` and grep the
  summary. Every locked check in the repo must pass, not just this
  feature's. Then run the project's own test suite.
- Write `reports/<YYYY-MM-DD>-<feature>.md`: rounds table (from
  `results.tsv`), kept vs discarded, where the builder went wrong and how it
  recovered, what the checks missed, diffs of interest, dependencies added,
  open questions for the human. Copy the feature's rows of `results.tsv`
  into `reports/<YYYY-MM-DD>-<feature>.results.tsv`.
- Update `features.md` status to `done` or `stuck`.
- Update the `project-context` skill with new pages, conventions, traps.
- Commit the report, `features.md`, and skill updates:
  `report(<feature>): <status> in N rounds`.
- If more features were requested, go to step 1 for the next one. Do not
  ask whether to continue.

## Hard limits (also in program.md)
- Never edit `checks/locked/`. Never skip, mock away, or special-case a
  check. If a check is wrong, say so in the report and stop that feature.
- Never run the build rounds in this context. Fresh builder per feature.
- Never pipe test output into context; redirect to a log and grep.
