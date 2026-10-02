---
name: kloop-project
description: Start one loop run in an onboarded repo in one short conversation. Infers the mode and target from the request and the Graft graph, drafts a soft scope, then asks exactly four questions only the human can answer (what should get better and how we will know, where it should work, how much to spend, and optionally what to try or avoid), shows one consolidated review of the run spec, the eval draft, and every default before writing or baselining, then measures the eval, baselines, and kicks off. Use when asked to "start a run", "optimise X with the loop", "build these features with the loop", or run /kloop-project.
argument-hint: <what you want the loop to do>
---

# kloop-project

Requires `.claude/kloop/repo.md`; if missing, run `/kloop-setup`. If
`graft check` fails or `graft/` is missing, `graft build` first.

Request: **$ARGUMENTS**

Same three kinds of knobs as setup: decisions are asked, facts are
inferred or **measured**, defaults are shown. Two decisions are never
defaulted: **the metric** (or the feature rules) and **the scope**.
Nothing is written, run, or baselined before the review is approved.

## 1. Recon (no questions)

- Read `.claude/kloop/repo.md`, `program.md`, `features.md` if present,
  and the newest spec in `.claude/kloop/runs/` for house style.
- With Graft, as its skill directs: what code the request is about, what
  depends on it, what it depends on. For an optimisation request also find
  how the thing is trained or configured, what data it reads, and any
  existing metric code. For a feature request find entry points and the
  nearest existing tests.
- Infer the **mode** (`autoresearch` for a number, `build` for one
  feature, `auto-loop` for several) and the **target** (the smallest file
  or module that owns the behaviour).
- Draft the **scope**, a boundary not a fence: **core** (what the loop
  edits, usually one file), **neighbourhood** (what the graph shows
  depends on or feeds the core and the loop will likely read or may need
  to touch), **out of scope by default** (everything else; under the
  `soft` policy the loop may go there when it must and logs the excursion).
  Flag any neighbourhood file that is protected.
- For a number: prepare two or three **metric candidates**. For each, one
  line: what it measures, where ground truth comes from, expected noise,
  how the loop could game it, cost per run. For a feature: draft the
  **rules** as observable behaviour.

Post a **six-line summary**: inferred mode and target; the drafted scope
(core path, neighbourhood count); the metric candidates or drafted rules;
estimated cost per round; risks (noise, leakage, long eval, protected code
in the neighbourhood); anything that needs a question beyond the four.

## 2. Ask: four questions, one batch

`AskUserQuestion` when available, 2-4 options each, recommended first;
the tool adds "Other" for free text. Without it, a numbered list.

1. **"What should get better, and how will we know?"**
   For a number: the candidates as options, each phrased with its
   direction, e.g. `precision@10 on labelled repeat-purchase windows,
   higher is better`; no recommendation marker, this is the user's call.
   For a feature: the drafted rules in the question text, options
   `these rules (Recommended)` / `I will adjust them`.
2. **"Where should it work?"** The drafted scope in the question text.
   Options: `use it (Recommended)` / `widen` / `core only`. Free text for a
   specific directory.
3. **"How much?"** Options with a plateau stop built in:
   `overnight: 8 hours or 120 rounds, stop after 40 straight discards
   (Recommended)` / `a few hours: 3 hours or 40 rounds, stop after 20` /
   `until I stop it (Karpathy-style, no plateau stop)`.
4. **Optional. "Anything to try first, anything to avoid, anything it must
   never do in this run?"** Options: `nothing, use the defaults
   (Recommended)` / `I will type it`. Fills idea seeds, known dead ends,
   and additions to the forbidden list.

If the summary flagged something the four cannot settle (no metric
candidate is credible, the request spans two targets), add that one
question to the batch. Four questions is the tool's limit.

## 3. Draft (in memory)

- `.claude/kloop/runs/<tag>.md` from `templates/run.md`, including Scope.
- **Autoresearch**: the `program.md` autoresearch block (or
  `program.<tag>.md` when the build-loop `program.md` must stay). If no
  eval exists, scaffold one from `templates/eval_template.py` into a
  protected dir with the chosen metric implemented in `metric_fn`, data
  pinned by manifest hash, correctness asserts, secondary lines
  (`latency_ms`, `params_m`, ...) and any hard cap. Plan the
  `protected.txt` and deny-rule additions for the eval dir.
- **Build / auto-loop**: `features.md` entries with the rules, status
  `todo`.

## 4. Review gate: one table, the spec, the eval

Show, in this order:

1. **The knobs table** for this run:

   | knob | value | set by | lives in |
   |---|---|---|---|
   | goal | ... | decided | runs/<tag>.md |
   | mode / target | autoresearch / recsys/pattern_detector.py | inferred | runs/<tag>.md, program.md |
   | scope | core 1 file, neighbourhood 5, soft | decided | runs/<tag>.md |
   | metric, direction | precision@10, higher | decided | program.md, eval/ |
   | eval | new: pinned slice, asserts, latency cap 20 ms | drafted | eval/pattern_eval.py |
   | eval time per run | measured after approval | measured | runs/<tag>.md |
   | noise floor | baseline x3 after approval | measured | runs/<tag>.md, TSV |
   | budget, stop | 8 h / 120 rounds / 40 straight discards | decided | runs/<tag>.md |
   | ablation cadence | every 20 keeps | default | program.md |
   | forbidden | seeds, eval caching, reading labels, new deps (+ additions) | default (+ decided) | program.md |
   | seeds, dead ends | ... | decided / none | runs/<tag>.md |
   | isolation, tag | worktree ../<repo>-kloop, autoresearch/<tag> | default | runs/<tag>.md |
   | reports, deliverable | interim every 25 rounds; final report; human opens PR | default | runs/<tag>.md |
   | holdout | <path from repo.md or manifest> | inferred | runs/<tag>.md |

2. The full run spec, and for autoresearch the eval's `metric_fn` and
   asserts. The user may ask "show me the neighbourhood"; print what the
   graph showed.
3. One question: `approve (Recommended)` / `edit` (free text). Apply,
   re-show changed rows, ask again. Loop until approved.

## 5. Write, measure, verify

- Write spec, program block, eval, protected additions, deny rule, TSV
  header or `features.md` entries. Create worktree and branch if chosen.
  Commit: `kloop(<tag>): run spec + frozen eval`.
- **Measure**: run the eval once; confirm exactly one `metric:` line and
  sane secondary lines; time it. If it exceeds twice the per-round
  estimate, shrink the slice or budget now and say so.
- **Baseline x3** (autoresearch); record spread as the noise floor in the
  spec and the TSV. If the floor would swallow the gains the user expects,
  say so and offer to enlarge the slice or budget.
- Guard self-test on the eval path (exit 2). `graft check` exits 0.
- Report the measured rows of the table. Ask nothing.

## 6. Go

Print both kick-offs:
- Interactive: `cd <worktree> && claude`, then
  `read program.md and .claude/kloop/runs/<tag>.md and start the <mode> run`.
- Unattended: the headless command from `repo.md`, permissions bypassed,
  output to `reports/<tag>.console.log`; note that deny rules and the
  guard hook stay active in bypass mode.
If the user says go, start now with the matching skill (`/autoresearch
<tag>`, `/build <feature>`, `/auto-loop <features>`) and do not ask again
until a stop rule fires.
