---
name: kloop-setup
description: Conversational onboarding of a repository for k-auto-loop. Does reconnaissance first (stack, tests, CI, layout, hot files, compute), then asks only what it cannot infer, in at most three batched rounds with every power-user knob exposed but defaulted, and writes the repo profile, protected paths, check runner, program.md fixed rules, project-context, and settings. Use when asked to "set up the loop on this repo", "onboard this repo", or run /kloop-setup. Can be run from the k-auto-loop repo with a path to install first.
argument-hint: [path-to-repo]
---

# kloop-setup

Goal: a brief but thorough conversation after which this repo is ready for
`/kloop-project`, `/build`, `/auto-loop`, or `/autoresearch`, with nothing
the user cares about left to a default they did not see.

Principle: **recon first, ask second, write third, verify fourth.** Every
question states the default you inferred so the user only confirms or
overrides. Never ask something the code can answer.

Target: `$0` if given (a path; if it has no `.claude/kloop/`, run this
package's `install.sh <path>` first, then `cd` there), otherwise the
current repo.

## 1. Recon (no questions yet)

Read, quickly and shallowly, and keep notes in your head, not in chat:
- `README*`, `CLAUDE.md`, `AGENTS.md`, `CONTRIBUTING*`, docs index.
- Manifests: `pyproject.toml` / `requirements*` / `package.json` /
  `go.mod` / `Cargo.toml` / `Makefile` / `justfile` / `Taskfile`.
- Test config and command: `pytest.ini`, `tox.ini`, `jest.config*`,
  `vitest.config*`, `playwright.config*`, CI yaml under `.github/workflows`
  or similar. Note the exact command CI runs, and how long it takes if the
  CI log or config says.
- Layout: top-level tree, depth 2, with sizes. Flag anything that looks
  like data, fixtures, models, migrations, infra, secrets, generated code.
- Hot files: `git log --since=6.months --name-only --pretty=format: | sort | uniq -c | sort -rn | head -30`.
- Existing evals or benchmarks: anything named `eval*`, `bench*`,
  `score*`, `metrics*`, notebooks that compute a metric.
- Compute: `nvidia-smi` / `python -c "import torch;print(torch.cuda.is_available())"` if ML-shaped; CPU count; whether a container or cloud sandbox is in use.
- Existing `.claude/` config: settings, skills, agents, hooks that could
  conflict with ours.

Then post a **ten-line "what I found"** summary: stack, test command,
estimated suite time, likely lab areas, likely protected areas, compute,
anything surprising. This is the only unprompted text before questions.

## 2. Interview (max three batches)

Use the `AskUserQuestion` tool when available: up to 4 questions per
batch, 2-4 options each, recommended option first and marked
"(Recommended)", `multiSelect` where answers are not exclusive. Without the
tool, ask the same as a numbered list and wait. Fold the user's free-text
"Other" answers back into the profile verbatim.

**Batch A: shape of the work**
1. What will loops do here? `optimise metrics (autoresearch)` /
   `build features (build, auto-loop)` / `both`.
2. Where may agents edit? `a designated lab area` (recommended for
   production repos; name the dir(s) you inferred) / `anywhere on a loop
   branch` / `one named file only`.
3. Protected areas (multiSelect, pre-ticked from recon): evals and
   benchmarks; data, fixtures, manifests; CI and deploy config;
   migrations and schemas; prod configs and secrets; the existing test
   suite; other (name).
4. Isolation and attendance: `git worktree per run, headless overnight` /
   `branch in this checkout, interactive` / `remote sandbox` (if detected).

**Batch B: mechanics and limits**
5. Check runner: confirm the inferred `CHECK_CMD` and the full-suite
   command; ask whether the full suite must pass every round or only at
   feature end (default: at feature end if it takes more than ~2 min).
6. Budgets: minutes per eval or round; round cap per feature (default 8);
   builder `maxTurns` (default 150); experiments per night you expect.
7. Model for the fresh builder / researcher: inherit / a specific model.
   Mention cost: a long loop is many full-context reads.
8. Delivery: `commits stay on the loop branch, human opens PR` (recommended)
   / `agent opens a draft PR at the end` / `never leave the worktree`.
   Never: auto-merge, never push to the default branch.

**Batch C: only if needed**
9. Repo-specific "never do this" rules (free text): feature flags, data
   privacy, external calls, costs, files nobody understands.
10. Anything the project-context should say that the code does not
    (deploy process, owners, naming conventions, known flaky areas).
11. For ML repos: is there a holdout set the loop must never see, and
    where does it live (outside the worktree is best)? Secondary
    constraints the eval must print (latency, params, memory)?

Stop asking as soon as the profile has no blanks. Three batches is the cap.

## 3. Write

- `.claude/kloop/repo.md` from `templates/repo.md`: every answer and
  every inferred fact, with "(inferred)" or "(confirmed)" tags.
- `.claude/kloop/protected.txt`: one prefix per protected area.
- `.claude/kloop/config.sh`: `CHECK_CMD` and `SUITE_CMD`.
- `program.md` `## Fixed rules`: edit the round cap, definition of done,
  delivery rule, repo-specific nevers, and lab-area boundary to match.
  Do not touch `## How to work`.
- `.claude/skills/project-context/SKILL.md`: fill every section from
  recon plus answers. This is the file that saves every future builder a
  repo read; spend effort here.
- `.claude/agents/feature-builder.md`: `maxTurns`, `model` if chosen.
- `.claude/settings.json`: confirm deny rules and guard hook are present
  (the installer merged them); add deny rules for other protected areas
  the user named, e.g. `Edit(eval/**)`.
- `.gitignore`: results/logs are ignored (installer did it; confirm).

## 4. Verify, then hand off

- Run `CHECK_CMD` against an empty or trivial check dir to prove the
  runner executes, or `--collect-only` equivalent.
- Self-test the guard: pipe a fake `Edit` on a protected path into
  `.claude/kloop/guard-locked.py` and confirm exit 2.
- If a worktree was chosen, create it: `git worktree add ../<repo>-kloop -b kloop/<date>`.
- Commit: `kloop: onboard repo (profile, protected paths, context)`.
- End with a five-line summary and the next command, normally
  `/kloop-project <what you want to do>`.
