#!/usr/bin/env bash
# Append one round to results.tsv (tab-separated; untracked by git).
#   log-result.sh <round> <feature> <status> <passed> <total> "<failing>" "<description>"
# status: baseline | keep | discard | crash | stuck
set -euo pipefail
if [[ $# -lt 7 ]]; then
  echo 'usage: log-result.sh <round> <feature> <status> <passed> <total> "<failing>" "<description>"' >&2; exit 1
fi
root="$(git rev-parse --show-toplevel)"
cd "$root"
f="results.tsv"
[[ -f "$f" ]] || printf 'round\tfeature\tcommit\tpassed\ttotal\tstatus\tfailing\tdescription\n' > "$f"
commit="$(git rev-parse --short HEAD)"
clean() { printf '%s' "$1" | tr '\t\n' '  '; }
printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
  "$1" "$(clean "$2")" "$commit" "$4" "$5" "$(clean "$3")" "$(clean "$6")" "$(clean "$7")" >> "$f"
tail -1 "$f"
