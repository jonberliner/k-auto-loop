# Video notes: "He Finally 10x Claude Code With This Method" (AI LABS)

- URL: https://www.youtube.com/watch?v=qLfSDQ5NGh0
- Channel: AI LABS (https://www.youtube.com/@AILABS-393)
- These are paraphrased notes, not a transcript. The raw transcript is kept
  locally at `notes/transcript.local.txt` and is git-ignored on purpose.

## 1. The Karpathy loop, as the video explains it

Karpathy's `autoresearch` gives an agent three files:

| File | Who edits it | Role |
|---|---|---|
| `train.py` | the agent | the one file the agent may change |
| `prepare.py` | nobody | data prep and the scoring function; locked so the agent cannot make the score easier to beat |
| `program.md` | the human | plain-English rules for how each round works |

Each round: make one change, train for a few minutes, score it. Better score:
keep the commit. Same or worse: revert. The video cites ~700 experiments over
two days with ~20 kept improvements, and Shopify's CEO getting a 19% better
model overnight from 37 experiments.

## 2. When a loop is worth setting up (four tests)

1. You repeat the task often enough to earn back the setup time.
2. Your usage budget can absorb it. Every round re-reads the project and burns
   tokens even when it fails.
3. The work can be checked mechanically by something that produces a clear
   score (for apps: small checks that exercise a feature).
4. The agent can actually run what it built and see what breaks.

Their rule of thumb: never let a loop build a whole app. One feature at a time,
or a thin slice the checks can verify.

## 3. Their Claude Code setup (skills + one agent)

- **`project-context` skill**: memory bank for the app (what it does, pages,
  conventions, things to avoid). Grows with the app. A skill rather than a
  plain file because only the short description sits in context permanently;
  the full body loads on demand.
- **`write-checks` skill**: writes the checks *before* any feature code, so
  the agent verifies against something it did not write after the fact.
- **`build` skill**: the driver. Order of operations:
  1. Write checks (via `write-checks`).
  2. List what every check tests in plain words. The human reviews and
     adjusts (this is the one human gate).
  3. On go-ahead, an `approve-checks` program moves the checks into a locked
     folder. A Claude Code settings rule blocks edits to that folder, so the
     loop cannot make its own checks easier.
  4. Commit the approved checks (second layer of protection).
  5. Run the loop, handing each feature to a fresh `feature-builder` agent
     so each feature gets its own clean context.
  6. Store every round's result in a results file.
  7. Emit a report when all features are done.
- **`program.md`**: all loop rules, in Karpathy's format.
- **`features.md`**: the feature tracker; the rules for each feature live here.

Worked example: a half-built restaurant site. Asked for guest pickup ordering.
Claude added the feature to `features.md`, proposed 10 checks, the human asked
for a guest-email check (11 total), checks were approved and committed, the
builder passed all 11 in one ~6 minute round. The loop also noticed the checks
only covered the ordering rules and not the order form, so it built and wired
the form before calling the feature done.

## 4. The one problem, and the one change

**Problem**: the agent has habits. If a way of working fails inside a round,
it corrects within that loop, but nothing carries to the next run. Every
feature starts with a fresh builder and the same instructions, so the same
mistake recurs.

**Fix**: a second loop that reads how the first loop ran and rewrites how the
first loop works. They call it **`auto-loop`**.

- Reads the results file: for each round, kept/undone, what was tried, which
  checks still failed.
- Looks for problems that keep coming back: the same mistake, or the same gap
  showing up in two features.
- Writes each habit down with the rounds that show it.
- Rewrites only the **"how to work"** section of `program.md`. The fixed rules
  stay human-owned.
- **Cannot edit the checks.** Otherwise it could make rounds stop failing
  without fixing the habit.
- Runs one feature at a time and updates the instructions after each
  feature, so the next feature starts from the method that actually worked.

Worked example: a project-management app, adding collaboration (shared
sessions, shared projects, @mentions).

- Shared database passed all 10 checks but the app never saved to it. New
  habit: *connect each feature to the app in the same round that makes its
  checks pass.*
- Mentions passed, but an older part of the app still parsed `@` the old way.
  New habit: *find every place the app already does a job and make each one
  follow the new rules.*
- Shared projects took three rounds: round 1 broke mentions (undone), round 2
  split shares as 33/33/33 (a check caught the 99% total), round 3 passed.

The final report says where the builder went wrong, how it was fixed, and
what the workflow looked like.

## 5. What this package takes from the video

Everything in section 3 and 4 is implemented here as Claude Code skills, one
subagent, a permission deny rule plus a PreToolUse hook for the locked folder,
and a `program.md` split into a human-owned `## Fixed rules` section and an
auto-loop-owned `## How to work` section. See the top-level README.
