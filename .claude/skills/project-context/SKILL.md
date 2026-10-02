---
name: project-context
description: Memory bank for this app - what it does, pages/routes, data model, conventions, how to run and test it, and things to avoid. Load before planning or building any feature. Update it after every finished feature.
---

# Project context

This skill is the single place an agent goes to learn the app without
re-reading the whole repo. Only this description sits in context all the
time; the body below loads on demand. Keep it accurate, keep it short, and
grow it as the app grows.

**Agents: update this file at the end of every feature** (new pages, new
conventions, new gotchas). The `build` skill does this as its last step.

## Where the code map lives
Graft (`graft/`, built by `graft build`) owns code structure: symbols,
callers, blast radius. Ask it first (`graft_find_code`, `graft_trace_calls`,
`graft_file_api`, or `graft ask` / `graft callers` / `graft skeleton`). This
skill holds what the graph cannot map: intent, conventions, process, and the
non-code files (PRDs, plans, runbooks) listed below.

## What the app does
<!-- one paragraph: who uses it, for what -->

## Stack and layout
<!-- language, framework, package manager, key directories -->

## How to run it
```
# dev server / CLI entry
```

## How to test it
```
# the project's own test command, plus how the locked checks are run:
# .claude/kloop/run-checks.sh <feature>
```

## Pages, routes, or commands
<!-- table: path -> what it does -> file -->

## Data model
<!-- entities and where they live -->

## Conventions
<!-- naming, error handling, state management, styling, where new code goes -->

## Things to avoid
<!-- known traps: files not to touch, patterns that broke before, flaky areas -->

## Glossary
<!-- domain terms the code uses -->
