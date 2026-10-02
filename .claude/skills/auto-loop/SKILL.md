---
name: auto-loop
description: The loop that improves the loop. Runs the build skill one feature at a time and, after each feature, reads results.tsv and the report for recurring mistakes, writes them down as habits with evidence, and rewrites ONLY the "How to work" section of program.md so the next feature starts from what actually worked. Never touches checks or Fixed rules. Use for multi-feature work or whenever the same mistake keeps recurring across features.
argument-hint: <features or request>
---

# auto-loop

The problem this solves: a fresh builder per feature means no memory. A
mistake made on feature 1 is made again on feature 4, because every builder
starts from the same `program.md`. So after each feature this skill reads
how the inner loop ran and edits how the inner loop works.

Request: **$ARGUMENTS**

## Loop

Read `program.md` in full, then `.claude/kloop/repo.md` and the run spec
in `.claude/kloop/runs/` if present. Then for each feature, in order:

1. **Build** the feature with the `build` skill (which includes the human
   check-approval gate). One feature at a time, never several in parallel
   under this skill, because the point is to learn between them.
2. **Review the run.** Read this feature's rows in `results.tsv` and its
   `reports/<date>-<feature>.md`. Also re-read the rows and reports of
   previous features in this run. Look for:
   - the same check, or same kind of check, failing in two or more rounds;
   - a round discarded for breaking an existing check (a regression habit);
   - a gap the checks did not catch but the builder or human did (e.g. the
     feature passed but was not wired into the app);
   - repeated crashes of the same shape (missing import, wrong runner, env);
   - wasted rounds: the builder re-tried an approach already discarded;
   - anything the human corrected during check review that a rule could
     have pre-empted;
   - excursions outside the run spec's scope: the same path or area needed
     by two features means the scope was drawn too tight; a blast radius
     (from the report) that repeatedly reaches code no check covers means a
     check is missing.
3. **Write habits.** For each recurring problem, write one habit: a short
   imperative sentence a builder can follow before it starts, plus the
   evidence in the form `(evidence: <feature> r<N>, <feature> r<M>)`. One
   data point is an anecdote; two is a habit. Prefer rewording an existing
   habit over adding a near-duplicate. Remove habits whose evidence has not
   recurred in the last three features and that the human did not write.
4. **Rewrite `## How to work`** in `program.md`. Replace the section body
   with the current habit list, numbered, most impactful first, keeping the
   HTML comment at the top. Do not touch a single character above that
   heading. Keep it under ~15 habits; if it grows past that, merge.
5. **Scope**: if two features needed the same excursion, widen the Scope
   section of the run spec in `.claude/kloop/runs/` with the evidence; if
   part of the neighbourhood was never touched across three features,
   narrow it. Scope is soft and yours to tune; protected paths and
   `## Fixed rules` are not.
6. **Commit** `program.md` alone: `program(<feature>): <n> habits updated -
   <one line>`. Append a "Habits learned" section to the feature's report
   and commit that too.
7. Next feature. Do not ask whether to continue.

## Final report
When the feature list is done, write `reports/<date>-auto-loop.md`: every
feature with rounds and status, the habit list before and after, which
habits paid off (a later feature that would have hit the problem and did
not), and recommendations for `## Fixed rules` that only the human may
apply.

## Hard limits
- Never edit anything under `checks/locked/`, `checks/pending/` of a
  feature already approved, or any check file. If a habit would amount to
  "make the check easier", it is not a habit, it is cheating; report it.
- Never edit `## Fixed rules` or anything above `## How to work`. If a
  fixed rule seems wrong, say so in the report.
- Never invent evidence. Every habit cites rounds that exist in
  `results.tsv`.
