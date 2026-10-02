---
name: kloop-setup
description: Conversational onboarding of a repository for k-auto-loop. Runs Graft first (install if missing, init, build) so the repo is mapped, then does graph-powered recon, asks only what it cannot infer in at most three batched rounds with every power-user knob exposed but defaulted, shows you everything it is about to write for approval, then writes the repo profile, protected paths, check runner, program.md fixed rules, project-context, and settings. Use when asked to "set up the loop on this repo", "onboard this repo", or run /kloop-setup. Can be run from the k-auto-loop repo with a path to install first.
argument-hint: [path-to-repo]
---

# kloop-setup

Goal: a brief but thorough conversation after which this repo is ready for
`/kloop-project`, with nothing the user cares about left to a default they
did not see. **Nothing is written to the repo until the user approves the
review in step 4.** Graft and the k-auto-loop install are the exceptions,
and both are announced first.

Principle: **map first (Graft), recon second, ask third, review fourth,
write fifth, verify sixth.** Every question states the default you
inferred so the user only confirms or overrides. Never ask something the
code or the graph can answer.

Target: `$0` if given (a path; if it has no `.claude/kloop/`, run this
package's `install.sh <path>` first, then `cd` there), otherwise the
current repo.

## 0. Graft first

Graft (https://github.com/trailhq/Graft) builds a local code graph and
wires itself into Claude Code with its own skill, hooks, and MCP tools. It
goes first so recon and every later builder have the map. Use Graft the
way Graft intends; do not invent command recipes for it.

1. `graft --version`. If missing: say so and ask one question: install
   globally (`npm install -g @nanonets/graft`), use `npx -y @nanonets/graft`
   per call, or skip Graft. Installing a global package is the user's call.
   If they skip, continue without it and mark recon as degraded in the
   profile.
2. `graft init --dry-run --agents claude` and show the file list (it writes
   `.claude/skills/graft/SKILL.md`, `.mcp.json`, hook and statusline
   entries merged into `.claude/settings.json`, and `graft/` which it
   git-ignores). Then `graft init --agents claude`. Add `--no-statusline`
   if the repo already has a statusline it wants to keep.
3. `graft build` if init did not already (structural, no API key). Offer
   `graft build --deep` only in the interview; it needs `GRAFT_API_KEY`.
4. `graft check` must exit 0.
5. Confirm the k-auto-loop guard survived Graft's settings merge: the
   PreToolUse entry for `guard-locked.py` and the `Edit(checks/locked/**)`
   deny rule are still in `.claude/settings.json`. If not, re-run
   `install.sh` on this path (it re-asserts them).

## 1. Recon (no questions yet)

Code structure comes from Graft, used as its skill directs: orient on the
repo, find the areas that match what loops will do here, find where tests,
evaluation, data loading, and configuration live. Prefer the graph to
reading hub files whole.
- Non-code (Graft does not map these): `README*`, `CLAUDE.md`, `AGENTS.md`,
  docs index, manifests (`pyproject.toml`, `package.json`, `go.mod`,
  `Cargo.toml`, `Makefile`), test config and the exact CI test command,
  data and model directories, migrations, infra, generated code, and any
  existing `.claude/` config that could conflict.
- `git log --since=6.months --name-only --pretty=format: | sort | uniq -c | sort -rn | head -30`
  for hot files; cross-check against what the graph shows as central.
- Compute if ML-shaped: `nvidia-smi`, `torch.cuda.is_available()`, CPU
  count, container or sandbox.

Then post a **ten-line "what I found"**: stack, graph size and languages,
test command and estimated duration, likely lab areas, likely protected
areas, compute, anything surprising. The only unprompted text before
questions.

## 2. Interview (max three batches)

Use `AskUserQuestion` when available: up to 4 questions per batch, 2-4
options each, recommended option first and marked "(Recommended)",
`multiSelect` where answers are not exclusive. Without the tool, ask as a
numbered list and wait. Fold free-text answers into the profile verbatim.

**Batch A: shape of the work**
1. What will loops do here? `optimise metrics (autoresearch)` /
   `build features (build, auto-loop)` / `both`.
2. Where may agents edit? `a designated lab area: <inferred dirs>`
   (recommended for production repos) / `anywhere on a loop branch` /
   `one named file only`. This is the hard outer boundary; per-run scope
   inside it is decided by `/kloop-project` from the graph and is soft.
3. Protected areas (multiSelect, pre-ticked from recon): evals and
   benchmarks; data, fixtures, manifests; CI and deploy config;
   migrations and schemas; prod configs and secrets; the existing test
   suite; other (name).
4. Isolation and attendance: `git worktree per run, headless overnight` /
   `branch in this checkout, interactive` / `remote sandbox` (if detected).

**Batch B: mechanics and limits**
5. Check runner: confirm the inferred `CHECK_CMD` and the full-suite
   command; must the full suite pass every round or only at feature end
   (default: feature end if it takes more than ~2 min)?
6. Budgets: minutes per eval or round; round cap per feature (default 8);
   builder `maxTurns` (default 150); experiments per night you expect.
7. Scope policy for runs: `soft` (recommended: the run spec names core
   and neighbourhood from the graph; the loop may step outside when it
   must and logs why; auto-loop widens with evidence) / `hard` (outside
   scope means stop and report).
8. Graft depth: structural only (default, free) / `--deep` LLM summaries
   (needs `GRAFT_API_KEY`; better orientation on very large repos).

**Batch C: only if needed**
9. Model for fresh builders: inherit / a specific model. Delivery:
   `commits stay on the loop branch, human opens PR` (recommended) /
   `agent opens a draft PR at the end`. Never auto-merge or push to the
   default branch.
10. Repo-specific "never do this" rules (free text).
11. Anything project-context should say that the code does not (deploy
    process, owners, conventions, flaky areas). Graft holds the code map;
    project-context holds the rest.
12. For ML repos: holdout data the loop must never see, and where it
    lives (outside the worktree is best). Secondary constraints the eval
    must print (latency, params, memory).

Stop asking as soon as the profile has no blanks. Three batches is the cap.

## 3. Draft (in memory, not yet written)

- `.claude/kloop/repo.md` from `templates/repo.md`: every answer and
  inferred fact, tagged "(inferred)" or "(confirmed)", plus the Graft
  section (version, graph stats, deep or not).
- `.claude/kloop/protected.txt`, `.claude/kloop/config.sh` (`CHECK_CMD`,
  `SUITE_CMD`).
- `program.md` `## Fixed rules`: round cap, definition of done, delivery
  rule, repo-specific nevers, lab boundary, scope policy. Never touch
  `## How to work`.
- `.claude/skills/project-context/SKILL.md`: filled from recon plus
  answers. Say explicitly that Graft is wired in and owns code structure,
  and keep this skill for what the graph cannot map: intent, conventions,
  process, non-code files.
- `.claude/agents/feature-builder.md`: `maxTurns`, `model` if chosen.
- `.claude/settings.json`: extra deny rules for named protected areas,
  e.g. `Edit(eval/**)`.

## 4. Review gate (the user inspects before anything lands)

Show, in chat: the full `repo.md` draft (it is short), the `program.md`
fixed-rules diff, the protected list, and the one-line summary of each
other file. Then ask one question: `approve and write` / `edit` (free
text: what to change). Loop until approved. Do not write before this.

## 5. Write and verify

- Write the drafted files. Confirm `.gitignore` ignores `results.tsv`,
  `autoresearch.tsv`, `run.log`, `checks.log`, and `graft/`.
- Run `CHECK_CMD` against an empty or trivial check dir (or the runner's
  collect-only mode) to prove it executes.
- Self-test the guard: pipe a fake `Edit` on a protected path into
  `.claude/kloop/guard-locked.py`; expect exit 2.
- `graft check` exits 0.
- If a worktree was chosen, create it: `git worktree add ../<repo>-kloop -b kloop/<date>`.
- Commit: `kloop: onboard repo (graft wiring, profile, protected paths, context)`.
- End with a five-line summary and the next command, normally
  `/kloop-project <what you want to do>`.
