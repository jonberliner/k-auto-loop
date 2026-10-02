# repo.md - k-auto-loop profile for this repository

Written by `/kloop-setup`. Read by every loop skill before it starts.
Tag each fact `(inferred)` or `(confirmed)`.

## Identity
- repo: 
- purpose of loops here: optimise | build | both
- owner / reviewer for loop output: 

## Stack
- language, framework, package manager: 
- how to run the app or pipeline: 
- test runner and full-suite command: 
- full-suite duration: 
- CI command: 

## Lab boundary (where agents may edit)
- allowed: 
- one-file targets commonly used: 

## Protected (agents never edit; mirrored in .claude/kloop/protected.txt and settings deny rules)
- 

## Isolation and attendance
- worktree per run | branch in checkout | remote sandbox
- unattended command: `cd <worktree> && claude -p "read program.md and .claude/kloop/runs/<tag>.md and start the run" --permission-mode bypassPermissions > reports/<tag>.console.log 2>&1`
  (confirm flags with `claude --help` on this machine)

## Budgets and limits
- minutes per eval or round: 
- round cap per feature: 8
- builder maxTurns: 150
- model for fresh builders: inherit
- expected experiments per night: 

## Delivery
- commits stay on the loop branch; human opens PR | agent opens draft PR
- never: push to default branch, auto-merge, touch prod config

## Compute and data
- GPU / CPU: 
- data locations and how to pin a slice (manifest, hash, date range): 
- holdout the loop must never see (path outside worktree): 

## Repo-specific nevers
- 

## Notes for project-context
- 
