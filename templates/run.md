# run spec: <tag>

Written by `/kloop-project`. One file per run. The loop skill reads this
after `program.md`.

- mode: autoresearch | build | auto-loop
- branch / worktree: 
- started: <date>
- requester: 

## Objective (one sentence)


## Scope (from the Graft graph; soft unless repo.md says hard)
- core (edit): 
- neighbourhood (read, may touch; from `graft callers <symbol> -d 2`): 
- out of scope by default: everything else
- policy: soft | hard
- excursions so far (filled by the loop and reviewed by auto-loop): 

## Target
- files the agent may edit (= core): 
- everything else is read-only; protected prefixes added: 

## Eval (autoresearch) or features (build)
- eval command: 
- prints: `metric: <n>` (direction: lower | higher), plus: 
- data slice and how it is pinned: 
- correctness asserts the eval enforces: 
- time budget per run: ; kill at 2x
- baseline x3: , , ; noise floor = 
- features in order (build): 

## Budget and stop rules
- hours / experiments: 
- stop on plateau after N consecutive discards: 
- ablation pass every K keeps: 
- interim report every N rounds: 

## Forbidden
- seed changes, eval caching, reading expected outputs, new deps, and: 

## Idea seeds (try first)
1. 

## Known dead ends (do not retry)
- 

## Holdout (human-run, after the loop)
- path / command: 
- result on kept commits: 

## Delivery
- report path: reports/<date>-<tag>.md
- PR: draft | none ; reviewer: 
