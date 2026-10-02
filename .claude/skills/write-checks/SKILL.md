---
name: write-checks
description: Write the mechanical checks for a feature BEFORE any feature code exists, into checks/pending/<feature>/, plus a plain-English checklist for the human to approve. Use when the build or auto-loop skill asks for checks, or when a feature in features.md has rules but no checks.
argument-hint: <feature>
---

# write-checks

Write the checks for feature **$0** before anyone writes the feature.
Checks written after the code tend to describe what the code does; checks
written before describe what the feature must do. That is the whole point.

## Inputs
1. Load the `project-context` skill.
2. Read the feature's entry in `features.md`. If the feature is missing or
   has no **Rules**, write the rules first from the human's request, as
   observable behaviour, and show them to the human along with the checks.
3. Look at how this project already tests things (runner, fixtures, where
   tests live). Match it. If there is no runner, pick the lightest one that
   fits the stack and note it in `.claude/kloop/config.sh` as `CHECK_CMD`.

## Rules for good checks
- **One behaviour per check**, named so the name alone says what it protects.
- **Mirror the rules.** Every rule in `features.md` has at least one check.
  Every check traces back to a rule.
- **At least one wiring check**: the feature is reachable from the app (the
  route responds, the page renders the control, the command is registered).
  Checks that pass on code nothing calls let the loop declare victory on an
  unfinished feature.
- **At least one negative case** per input the user controls (missing,
  malformed, unauthorised).
- **At least one regression guard** for existing behaviour the feature is
  likely to touch. Grep for every place the app already does this job.
- **Deterministic and fast.** No network, no clock, no randomness without a
  seed. Prefer the real code path over mocks; mock only true externals.
- **Test behaviour, not implementation.** No asserting on private helpers,
  file names, or internal call order.
- **Must fail now.** Run them. Every new check should fail before the
  feature exists. A check that already passes is not testing the feature.

## Output
1. Check files in `checks/pending/<feature>/` using the project's runner.
2. `checks/pending/<feature>/CHECKLIST.md`: one line per check in plain
   English, numbered, in the form "N. <what a user can observe>". No code.
3. Fill the **Checks** block of the feature in `features.md` with the same
   list. Set its status to `checks-pending`.
4. Run `.claude/kloop/run-checks.sh` against the pending dir (set the dir
   temporarily via `CHECK_CMD` or run the runner directly) and report the
   red count. Then show the human the CHECKLIST and ask them to add,
   remove, or change checks. **Stop there.** Approval and locking happen in
   the `build` skill via `.claude/kloop/approve-checks.sh`.

## Never
- Never write into `checks/locked/`.
- Never write the feature code. Checks only.
