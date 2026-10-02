#!/usr/bin/env python3
"""PreToolUse hook: refuse any tool call that would modify protected paths.

Protected by default: checks/locked/ and the ## Fixed rules section's host
file is protected separately by the auto-loop skill's instructions (a hook
cannot see section-level edits). Extra protected prefixes can be listed one
per line in .claude/kloop/protected.txt (e.g. eval.sh, prepare.py).

Exit 2 = block the tool call; stderr is shown to the agent.
"""
import json
import os
import re
import sys


def load_protected(cwd):
    prefixes = ["checks/locked"]
    extra = os.path.join(cwd, ".claude", "kloop", "protected.txt")
    if os.path.exists(extra):
        with open(extra) as fh:
            for line in fh:
                line = line.strip()
                if line and not line.startswith("#"):
                    prefixes.append(line.rstrip("/"))
    return prefixes


def rel(path, cwd):
    if not path:
        return ""
    if os.path.isabs(path):
        try:
            return os.path.relpath(path, cwd)
        except ValueError:
            return path
    return path.lstrip("./")


def touches(path, prefixes):
    p = path.replace("\\", "/")
    return any(p == pre or p.startswith(pre + "/") for pre in prefixes)


# Commands that may legitimately touch the locked folder.
ALLOWLIST = re.compile(r"(approve-checks\.sh|run-checks\.sh|log-result\.sh)")
# Mutation-shaped bash: anything that writes, moves, deletes, or rewrites.
MUTATION = re.compile(
    r"(\brm\b|\bmv\b|\bcp\b|\bsed\s+-[a-zA-Z]*i|\bperl\s+-[a-zA-Z]*i|\btee\b|"
    r"\btruncate\b|\bchmod\b|\bchown\b|\bln\b|\bunlink\b|\brmdir\b|\bmkdir\b|"
    r"\btouch\b|>{1,2}\s*\S*|\bgit\s+(rm|mv|checkout|restore|clean|stash)\b|"
    r"\bpython[0-9.]*\s+-c\b|\bnode\s+-e\b|\bdd\b|\binstall\b|\bpatch\b)"
)


def main():
    try:
        data = json.load(sys.stdin)
    except Exception:
        return 0
    cwd = data.get("cwd") or os.getcwd()
    tool = data.get("tool_name", "")
    inp = data.get("tool_input", {}) or {}
    prefixes = load_protected(cwd)

    if tool in ("Edit", "Write", "MultiEdit", "NotebookEdit"):
        path = rel(inp.get("file_path") or inp.get("notebook_path") or "", cwd)
        if touches(path, prefixes):
            sys.stderr.write(
                f"k-auto-loop guard: '{path}' is protected (checks/locked or "
                f"protected.txt). Approved checks are read-only. If a check is "
                f"wrong, stop and report it to the human instead of editing it.\n"
            )
            return 2
        return 0

    if tool == "Bash":
        cmd = inp.get("command", "") or ""
        if ALLOWLIST.search(cmd):
            return 0
        mentions = [pre for pre in prefixes if pre in cmd]
        if mentions and MUTATION.search(cmd):
            sys.stderr.write(
                f"k-auto-loop guard: this command looks like it modifies a "
                f"protected path ({', '.join(mentions)}). Reading is fine; "
                f"writing, moving, deleting, or redirecting into it is not.\n"
            )
            return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
