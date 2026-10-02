# program.md

Rules for the build loop in this repository. Two sections, two owners:

- `## Fixed rules` is owned by the human. Agents never edit it.
- `## How to work` is owned by the `auto-loop` skill. It rewrites this section
  after each feature based on what `results.tsv` shows. Humans may edit it too.

Nothing in this file may be used to weaken the checks. The checks in
`checks/locked/` are the ground truth and no agent edits them, ever.

## Fixed rules

**Files and ownership**
- `features.md`: the feature tracker. Each feature has a status, a short
  description, and its rules (the behaviour the checks encode).
- `checks/pending/<feature>/`: draft checks written by `write-checks`. Agents
  may edit these until the human approves them.
- `checks/locked/<feature>/`: approved checks. Read-only for every agent. A
  permission deny rule and a PreToolUse hook enforce this; a commit records
  the approved state. If a check is wrong, stop and tell the human.
- `results.tsv`: one row per round, tab-separated, untracked by git. Never
  commit it; snapshots are copied into `reports/` at the end of a run.
- `reports/<date>-<feature>.md`: the human-readable report for each feature.

**Order of operations for every feature**
1. Checks are written before any feature code (`write-checks`).
2. The human reviews a plain-English list of what each check tests and gives
   the go-ahead. This is the only human gate in the loop.
3. `.claude/kloop/approve-checks.sh <feature>` moves the checks into
   `checks/locked/<feature>/` and commits them.
4. A fresh `feature-builder` agent builds the feature in rounds.
5. Results are logged. A report is written. `project-context` is updated.

**Round mechanics (the Karpathy loop)**
- One round = one commit. Record the starting commit first.
- Make the change, `git add -A`, commit with `feat(<feature>): round N - <what>`.
- Run `.claude/kloop/run-checks.sh <feature> > checks.log 2>&1`. Never pipe
  check output into your context; grep the summary lines out of the log.
- Keep the round if, and only if, the number of passing checks went up and no
  check that passed before now fails. Otherwise `git reset --hard <start>`.
- Log every round with `.claude/kloop/log-result.sh`, kept or not.
- Max rounds per feature: 8. If the cap is hit, log `stuck`, write the report
  with what was tried, and move to the next feature. Do not loosen anything.
- A round that cannot run the checks at all (syntax error, crashed server) is
  `crash`. Fix trivially if obvious, otherwise reset and try another approach.

**Definition of done**
- Every locked check for the feature passes.
- The feature is reachable from the app: a page, route, CLI entry, or call
  site actually uses it. Passing checks on code nothing calls is not done.
- No previously passing check anywhere in `checks/locked/` fails.
- The existing test suite of the project (if any) still passes.

**Hard limits**
- Never edit anything under `checks/locked/`. Never delete, rename, skip,
  mark xfail, mock away, or special-case a check so it passes.
- Never edit `## Fixed rules`.
- Never add dependencies without listing them in the report.
- Never ask the human whether to continue mid-loop. The human may be away.
  The loop ends when the feature list is done or the human interrupts.
- Keep the diff reviewable. Simpler is better. A change that passes one more
  check by adding a tangle is worse than a smaller change that passes the
  same check.

## How to work

<!-- auto-loop: this section is rewritten by the auto-loop skill. Each habit
     lists the evidence (feature and round numbers from results.tsv) that
     justified it. Habits with no evidence are removed. -->

1. Read `features.md` for the feature's rules and `checks/locked/<feature>/`
   before writing code. Enumerate what each check needs; plan the smallest
   change that satisfies all of them.
2. Connect the feature to the app in the same round that makes its checks
   pass. A data layer or helper with no caller is not a finished round.
3. Before changing shared behaviour, grep for every place the app already
   does that job and make each one follow the new rule.
4. Run the existing project test suite once before your first round so you
   know the baseline, and once after the last round.
