#!/usr/bin/env bash
# Move approved checks from checks/pending/<feature>/ to checks/locked/<feature>/
# and commit them. This is the human gate: run it only after the human has
# reviewed the plain-English checklist and said go.
set -euo pipefail
feature="${1:-}"
if [[ -z "$feature" ]]; then
  echo "usage: approve-checks.sh <feature>" >&2; exit 1
fi
root="$(git rev-parse --show-toplevel)"
cd "$root"
src="checks/pending/$feature"
dst="checks/locked/$feature"
if [[ ! -d "$src" ]] || [[ -z "$(ls -A "$src")" ]]; then
  echo "no pending checks at $src" >&2; exit 1
fi
if [[ -d "$dst" ]] && [[ -n "$(ls -A "$dst")" ]]; then
  echo "refusing: $dst already has locked checks. Ask the human to remove them manually if re-approval is intended." >&2
  exit 1
fi
mkdir -p "$dst"
mv "$src"/* "$dst"/
rmdir "$src" 2>/dev/null || true
n=$(find "$dst" -type f | wc -l | tr -d ' ')
git add "$dst"
git commit -q -m "checks($feature): approve and lock $n check file(s)" -- "$dst"
echo "locked $n file(s) into $dst at $(git rev-parse --short HEAD)"
find "$dst" -type f | sort
