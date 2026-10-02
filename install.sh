#!/usr/bin/env bash
# Install k-auto-loop into a target repository.
#
#   ./install.sh /path/to/your/project            # build loop + auto-loop + autoresearch
#   ./install.sh /path/to/your/project --research # autoresearch-flavoured program.md instead
#
# Copies: .claude/skills/*, .claude/agents/feature-builder.md, .claude/kloop/*,
#         program.md, features.md (never overwrites existing ones),
#         checks/{pending,locked}/.gitkeep, reports/.gitkeep
# Merges: permissions.deny + PreToolUse hook into .claude/settings.json
# Appends: results.tsv / autoresearch.tsv / run.log / checks.log to .gitignore
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
target="${1:-}"
mode="build"
[[ "${2:-}" == "--research" ]] && mode="research"
if [[ -z "$target" || ! -d "$target" ]]; then
  echo "usage: install.sh /path/to/project [--research]" >&2; exit 1
fi
target="$(cd "$target" && pwd)"
echo "installing k-auto-loop into $target (mode: $mode)"

copy_if_missing() { # src dst
  if [[ -e "$2" ]]; then echo "  keep   $2 (exists)"; else mkdir -p "$(dirname "$2")"; cp "$1" "$2"; echo "  add    $2"; fi
}

mkdir -p "$target/.claude/skills" "$target/.claude/agents" "$target/.claude/kloop" "$target/.claude/kloop/runs" \
         "$target/checks/pending" "$target/checks/locked" "$target/reports"
for s in project-context write-checks build auto-loop autoresearch kloop-setup kloop-project; do
  mkdir -p "$target/.claude/skills/$s"
  cp "$here/.claude/skills/$s/SKILL.md" "$target/.claude/skills/$s/SKILL.md"
  echo "  skill  $s"
done
cp "$here/.claude/agents/feature-builder.md" "$target/.claude/agents/feature-builder.md"; echo "  agent  feature-builder"
for f in approve-checks.sh run-checks.sh log-result.sh guard-locked.py; do
  cp "$here/.claude/kloop/$f" "$target/.claude/kloop/$f"; chmod +x "$target/.claude/kloop/$f"
done
copy_if_missing "$here/.claude/kloop/config.sh" "$target/.claude/kloop/config.sh"
copy_if_missing "$here/.claude/kloop/protected.txt" "$target/.claude/kloop/protected.txt"
echo "  kloop  scripts + guard hook"

if [[ "$mode" == "research" ]]; then
  copy_if_missing "$here/templates/autoresearch.program.md" "$target/program.md"
else
  copy_if_missing "$here/templates/program.md" "$target/program.md"
  copy_if_missing "$here/templates/features.md" "$target/features.md"
fi
mkdir -p "$target/templates"
cp "$here/templates/autoresearch.program.md" "$target/templates/autoresearch.program.md"
cp "$here/templates/results.header.tsv" "$target/templates/results.header.tsv"
for t in repo.md run.md eval_template.py autoresearch.header.tsv; do cp "$here/templates/$t" "$target/templates/$t"; done
touch "$target/.claude/kloop/runs/.gitkeep"
touch "$target/checks/pending/.gitkeep" "$target/checks/locked/.gitkeep" "$target/reports/.gitkeep"

# .gitignore additions
gi="$target/.gitignore"; touch "$gi"
for line in results.tsv autoresearch.tsv run.log checks.log; do
  grep -qxF "$line" "$gi" || echo "$line" >> "$gi"
done
echo "  gitignore results.tsv autoresearch.tsv run.log checks.log"

# settings.json merge (python3 for safety)
settings="$target/.claude/settings.json"
python3 - "$settings" <<'PY'
import json, os, sys
p = sys.argv[1]
s = {}
if os.path.exists(p):
    with open(p) as fh:
        try: s = json.load(fh)
        except Exception: 
            print(f"  WARN  {p} is not valid JSON; writing settings.kloop.json instead for manual merge")
            p = p.replace("settings.json", "settings.kloop.json"); s = {}
perm = s.setdefault("permissions", {})
deny = perm.setdefault("deny", [])
for rule in ["Edit(checks/locked/**)", "Edit(./checks/locked/**)"]:
    if rule not in deny: deny.append(rule)
hooks = s.setdefault("hooks", {})
pre = hooks.setdefault("PreToolUse", [])
cmd = 'python3 "$CLAUDE_PROJECT_DIR"/.claude/kloop/guard-locked.py'
if not any(h.get("command") == cmd for e in pre for h in e.get("hooks", [])):
    pre.append({"matcher": "Edit|Write|MultiEdit|NotebookEdit|Bash",
                "hooks": [{"type": "command", "command": cmd, "timeout": 10}]})
with open(p, "w") as fh:
    json.dump(s, fh, indent=2); fh.write("\n")
print(f"  merge  {p} (deny rules + PreToolUse guard)")
PY

cat <<MSG

done. next steps in $target:
  1. open it in Claude Code and run:  /kloop-setup
     (recon + a short interview; writes repo profile, protected paths, context)
  2. start a run:                     /kloop-project <what you want the loop to do>
     (picks mode, pins target + frozen eval or feature list, baselines, kicks off)
  manual route: /project-context, edit program.md '## Fixed rules', then
     /build <feature> | /auto-loop <features> | /autoresearch
  unattended overnight runs: see README "Running unattended".
MSG
