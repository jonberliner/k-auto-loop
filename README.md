# k-auto-loop

A Claude Code package for running Karpathy-style autonomous loops on your
own projects, plus the one change that makes the loop improve itself.

Two loops, one set of mechanics:

| Loop | What it optimises | Where the idea comes from |
|---|---|---|
| **autoresearch** | one number from a frozen eval (speed, loss, size, score) | Karpathy's [autoresearch](https://github.com/karpathy/autoresearch) |
| **build** + **auto-loop** | features, scored by locked checks written *before* the code; the outer loop rewrites the inner loop's instructions from the results log | AI LABS, ["He Finally 10x Claude Code With This Method"](https://www.youtube.com/watch?v=qLfSDQ5NGh0) |

Both share the mechanics that make the original work: one commit per round,
a scorer the agent cannot touch, keep on improvement, `git reset` on
anything else, an untracked TSV as the lab notebook, and a `program.md`
that is the human's steering wheel. Notes on both sources are in
[`notes/`](notes/).

## What is in the box

```
.claude/
  skills/
    project-context/   memory bank for the app (load first, update last)
    write-checks/      checks before code; produces a plain-English checklist
    build/             the driver: checks -> human approval -> lock -> builder -> report
    auto-loop/         build one feature at a time; rewrite "## How to work" from evidence
    autoresearch/      Karpathy's metric loop, generalised to any eval command
  agents/
    feature-builder.md fresh-context builder that runs the commit/check/keep-or-reset rounds
  kloop/
    approve-checks.sh  move checks/pending/<f> -> checks/locked/<f>, commit
    run-checks.sh      run locked checks, print greppable summary lines
    log-result.sh      append a round to results.tsv
    guard-locked.py    PreToolUse hook: block any edit/rm/mv/redirect into protected paths
    protected.txt      extra protected prefixes (your frozen eval, etc.)
    config.sh          optional CHECK_CMD override
  settings.json        deny rules for checks/locked + the hook
templates/
  program.md           build-loop rules: "## Fixed rules" (human) + "## How to work" (auto-loop)
  autoresearch.program.md
  features.md
  results.header.tsv
examples/
  autoresearch-python-speed/   a toy target + frozen eval to try the metric loop on
  feature-loop-walkthrough/    what one feature looks like going through the build loop
notes/
  video-summary.md             the video's method, paraphrased, section by section
  karpathy-autoresearch.md     design, loop, numbers, and lessons from people who ran it
  sources.md                   every link used
install.sh                     copy all of the above into another repo and merge settings
```

## Install into a project

```bash
git clone https://github.com/jonberliner/k-auto-loop
cd k-auto-loop
./install.sh /path/to/your/project              # build loop (+ auto-loop, + autoresearch)
./install.sh /path/to/your/project --research   # autoresearch-flavoured program.md
```

The installer never overwrites an existing `program.md`, `features.md`,
`config.sh`, or `protected.txt`, and merges (not replaces) your
`.claude/settings.json`. It adds `results.tsv`, `autoresearch.tsv`,
`run.log`, `checks.log` to `.gitignore`; the TSVs must stay untracked so a
`git reset` never deletes the log.

This repo is itself an installed instance, so you can open it in Claude
Code and try the example under `examples/autoresearch-python-speed/`.

## Use it

In Claude Code, inside the target project:

1. `/project-context` and fill in the memory bank. Five minutes here saves
   every builder from re-reading the repo.
2. Read `program.md`. Edit `## Fixed rules` to your taste (round cap,
   definition of done, limits). Leave `## How to work` to the auto-loop.
3. Pick a loop:
   - `/build <one feature>` for a single pass. You will be shown a
     plain-English checklist and asked to approve it. That is the only
     question the loop asks.
   - `/auto-loop <several features>` for multi-feature work. Same gate per
     feature, and after each one the "How to work" section is rewritten
     from `results.tsv` with cited evidence.
   - `/autoresearch` to make a number move. You fill in target, eval,
     direction, budget; it baselines three times, computes a noise floor,
     and loops until you stop it.

### How the build loop keeps itself honest

- **Checks first.** `write-checks` writes them into `checks/pending/`,
  runs them to prove they fail, and gives you a numbered plain-English
  list. You add, cut, or change items.
- **Lock on approval.** `approve-checks.sh` moves them to `checks/locked/`
  and commits. From then on the agent cannot edit them: a permission deny
  rule covers the file tools, and `guard-locked.py` (a PreToolUse hook)
  refuses Bash commands that would write, move, delete, or redirect into
  that folder. The commit is the third layer.
- **Fresh builder per feature.** The `feature-builder` agent starts with
  an empty context, reads `program.md` and the checks, and runs rounds.
  Keep = more checks pass with no regressions. Otherwise reset.
- **Done means wired.** Passing checks on code nothing calls is not done.
  `program.md` requires the feature to be reachable from the app, and
  `write-checks` requires at least one wiring check.
- **Every round is logged**, including discards and crashes. The outer
  loop learns more from those than from the keeps.

### The outer loop

A fresh builder has no memory, so the same mistake repeats across
features. `auto-loop` reads `results.tsv` and the per-feature report after
each feature, finds problems that recur (same check failing twice, a
regression pattern, a gap the checks missed), and rewrites **only** the
`## How to work` section of `program.md` as numbered habits with evidence
like `(evidence: shared-db r1, mentions r1)`. It may not touch the checks
or the fixed rules, so it cannot make rounds stop failing by lowering the
bar. The final report lists which habits paid off and suggests fixed-rule
changes only you can make.

## Running unattended

The loops are designed to run while you are away, so permission prompts
have to be off. Run Claude Code in the target project with permissions
bypassed (for example `claude --dangerously-skip-permissions`, or in
headless mode `claude -p "..." --permission-mode bypassPermissions`; check
`claude --help` for the flags your version supports). The guard hook and
deny rules still apply in bypass mode. Work on a branch. The blast radius
of a bad round is one reverted commit.

Budget: a feature round is typically 3 to 10 minutes; an autoresearch
round is whatever your eval costs. Each round re-reads context, so a
long run on a small plan will hit limits. The video's four tests for
whether a loop is worth it: you repeat the task often, your usage limit
can take it, the result is mechanically checkable, and the agent can run
what it built.

## Adapting

- Different runner: set `CHECK_CMD` in `.claude/kloop/config.sh`
  (`{dir}` expands to the checks directory). Without it, `run-checks.sh`
  autodetects pytest, vitest/jest, or executable `.sh` checks.
- Protect more paths: add prefixes to `.claude/kloop/protected.txt`
  (your frozen `eval.sh`, fixtures, data).
- Tighter builders: edit `maxTurns` in `.claude/agents/feature-builder.md`
  and the round cap in `program.md`.
- Bigger ideas from the writeups worth trying: periodic ablation passes
  over kept commits, a human-maintained idea list in `program.md`, and
  tracking the git history of `program.md` as carefully as the code.

## Credits

- Andrej Karpathy, [autoresearch](https://github.com/karpathy/autoresearch)
  (MIT). The loop semantics and the `program.md` idea are his; nothing from
  that repo is vendored here.
- AI LABS, [the video](https://www.youtube.com/watch?v=qLfSDQ5NGh0): the
  checks-first build loop, the locked folder, the fresh builder per feature,
  and the auto-loop that rewrites "how to work".
- Community generalisations listed in [`notes/sources.md`](notes/sources.md).

MIT. See [LICENSE](LICENSE).
