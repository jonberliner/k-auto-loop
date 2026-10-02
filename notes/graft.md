# Graft: the code map the loops navigate with

- Tool: https://github.com/trailhq/Graft (npm `@nanonets/graft`, MIT, by
  Trail HQ / Nanonets). Site: https://trailhq.com/graft
- Video: AI LABS, "Github Top Trending Tool Just Fixed The AI Agent's
  Biggest Problem" — https://www.youtube.com/watch?v=cyIWQHYoUg8
  (paraphrased below; raw transcript kept locally and git-ignored)

## Why it is in this package

Every round of a loop starts with a fresh builder that has to find the
right code. By default that is grep, read, grep again, and each turn
re-sends the growing conversation. On a large repo that is where the
tokens and the minutes go, and it is why the video's four tests for a
loop include "your usage limit can take it".

Graft replaces the searching with a map. It parses the repo with
tree-sitter into a graph of symbols (nodes) and who-uses-what (edges),
stored as local files under `graft/` (git-ignored, regenerable). No
embeddings, no model, no API key for the structural layer. Queries answer
"what uses this", "what does this call", "what breaks if I change this",
which similarity search cannot. Their own benchmarks: roughly 42% fewer
tokens, 46% fewer tool calls, 60% less time on 162 runs, and 54% to 66%
correctness on 50 SWE-bench Verified instances. Savings grow with repo
size, which is exactly where loops hurt most.

For the loops specifically it gives three things:

1. **Cheaper rounds.** The builder asks the graph instead of grepping,
   through the skill, hooks, and MCP tools `graft init` wires in. The
   loop skills do not prescribe Graft commands; Graft's own skill does.
2. **Scoping without prescribing.** Asking the graph what a task is about,
   what depends on it, and what it depends on yields the task's natural
   neighbourhood. The run spec records it as a soft scope: core files to edit, neighbourhood
   likely to be read or touched, everything else out of scope by default.
   The loop may step outside when it must, and logs the excursion, so the
   outer loop can widen the scope with evidence instead of the human
   guessing it up front.
3. **Dependents as a regression check.** Graft's post-edit hook shows
   what depends on the files a round changed. If that leaves the
   neighbourhood, the builder runs the full suite before keeping, and the
   report lists it. It directly implements the video's learned habit
   "find every place the app already does this job".

## What the video adds

- Agents waste tokens on multi-turn file discovery; each turn re-sends
  the whole context, so cost compounds and quality drops.
- Vector search finds similar code but not connected code; "create
  account" and "delete account" look alike and do opposite things.
- Graft builds nodes and edges, saves them locally, offers a browser
  viewer, and keeps the map current by re-parsing only what changed.
- In Claude Code, `graft init` adds a skill, hooks (session start
  instructions, per-prompt context injection of up to three matching
  locations, post-edit refresh), a statusline, and an MCP server. CLI
  mode is faster; MCP mode lets the agent ask only when it needs to and
  scored a little higher in their tests. You get both.
- Run `graft build` in an existing project before using it. In an empty
  project the skill has the agent build once files exist.
- Their test: a booking app built with Fable 5.1 took 39 min and ~31% of
  context with Graft versus 47 min and ~35% without; the gap widened on
  later changes once the map existed.
- Limitation they call out: Graft maps code only. PRDs, plans, notes,
  learnings files are not in the graph, so the agent falls back to the
  default method for those. That is why `project-context` in this
  package holds the non-code knowledge and points at Graft for the code.

## Quick reference (from the README; confirm with `graft --help`)

```
npm install -g @nanonets/graft        # or: npx -y @nanonets/graft <cmd>
graft init --dry-run --agents claude  # list files it would write
graft init --agents claude            # skill + hooks + statusline + .mcp.json
graft build                           # structural graph, no key needed
graft build --deep                    # optional LLM summaries (needs GRAFT_API_KEY)
graft check                           # exit 1 if graph drifted from code
graft map                             # clusters, hubs, hotspots
graft ask "<task>" --json             # ranked nodes with file:line
graft skeleton <file>                 # signatures only (~10% of the tokens)
graft callers <symbol> [-d N] [--direction out]
graft grep "<regex>" [--in <path>]
graft blast --base <ref> [--format markdown]
graft viz                             # local graph viewer
```

MCP tools registered by `init`: `graft_find_code`, `graft_file_api`,
`graft_trace_calls`, `graft_find_all`, `graft_repo_map`,
`graft_check_freshness`.

Files it writes in a repo: `.claude/skills/graft/SKILL.md` (Graft-owned),
`.mcp.json`, hook and statusline entries merged into
`.claude/settings.json`, and `graft/` (git-ignored). Our installer and
`/kloop-setup` re-assert the k-auto-loop deny rules and guard hook after
Graft's merge, and the two sets of hooks coexist.

Graph layout: `graft/.graph/wiring.json` (per-symbol graph),
`graft/.graph/sources.json` (fingerprints), per-file cards, and with
`--deep` a set of linked Markdown concept nodes in `graft/*.md`.
Supported with full fidelity: TypeScript/JavaScript, Python, Go, Java,
Kotlin, PHP, Swift, R; broader support for Rust, C/C++, C#, Ruby, Scala,
and more; opt-in LSP for compiler-grade edges.
