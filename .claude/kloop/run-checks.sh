#!/usr/bin/env bash
# Run the locked checks for one feature (or all) and print a greppable summary.
#
#   .claude/kloop/run-checks.sh <feature|all> > checks.log 2>&1
#   grep -E '^(checks_total|checks_passed|checks_failed|failing|status):' checks.log
#
# Runner selection, in order:
#   1. CHECK_CMD in .claude/kloop/config.sh (e.g. 'pytest {dir} -q -rf')
#   2. *.py       -> python -m pytest {dir} -q -rf
#   3. *.test.*   -> npx vitest run {dir} (or jest if vitest missing)
#   4. *.sh       -> run each executable, exit 0 == pass
# {dir} is replaced by the checks directory.
set -uo pipefail
root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$root"
feature="${1:-all}"
dir="checks/locked"
[[ "$feature" != "all" ]] && dir="checks/locked/$feature"
if [[ ! -d "$dir" ]]; then
  echo "checks_total: 0"; echo "checks_passed: 0"; echo "checks_failed: 0"
  echo "failing: (no locked checks at $dir)"; echo "status: fail"; exit 1
fi
[[ -f .claude/kloop/config.sh ]] && source .claude/kloop/config.sh
CHECK_CMD="${CHECK_CMD:-}"

total=0; passed=0; failed=0; failing=""
if [[ -z "$CHECK_CMD" ]]; then
  if ls "$dir"/*.py "$dir"/**/*.py >/dev/null 2>&1 || find "$dir" -name 'test_*.py' -o -name '*_test.py' | grep -q .; then
    CHECK_CMD="python -m pytest {dir} -q -rf -p no:cacheprovider"
  elif find "$dir" -name '*.test.*' -o -name '*.spec.*' | grep -q .; then
    if npx --no-install vitest --version >/dev/null 2>&1; then CHECK_CMD="npx vitest run {dir} --reporter=verbose"
    else CHECK_CMD="npx jest {dir} --verbose"; fi
  fi
fi

if [[ -n "$CHECK_CMD" ]]; then
  cmd="${CHECK_CMD//\{dir\}/$dir}"
  echo "+ $cmd"
  out="$(bash -c "$cmd" 2>&1)"; rc=$?
  printf '%s\n' "$out"
  # pytest summary: "3 passed, 1 failed" / vitest+jest: "Tests  3 passed | 1 failed (4)" or "Tests: 1 failed, 3 passed, 4 total"
  p=$(printf '%s\n' "$out" | grep -oE '[0-9]+ passed' | tail -1 | grep -oE '[0-9]+' || true)
  f=$(printf '%s\n' "$out" | grep -oE '[0-9]+ failed' | tail -1 | grep -oE '[0-9]+' || true)
  e=$(printf '%s\n' "$out" | grep -oE '[0-9]+ error' | tail -1 | grep -oE '[0-9]+' || true)
  passed=${p:-0}; failed=$(( ${f:-0} + ${e:-0} )); total=$(( passed + failed ))
  if [[ $total -eq 0 ]]; then total=1; if [[ $rc -eq 0 ]]; then passed=1; else failed=1; fi; fi
  # best-effort names of failing checks
  failing=$(printf '%s\n' "$out" | grep -E '^(FAILED|ERROR) |^ *(✗|×|✕|FAIL) ' | sed -E 's/^(FAILED|ERROR) //; s/ - .*$//' | head -20 | paste -sd ',' - | sed 's/,/, /g')
else
  for f in "$dir"/*.sh "$dir"/**/*.sh; do
    [[ -f "$f" ]] || continue
    total=$((total+1))
    if bash "$f" >/dev/null 2>&1; then passed=$((passed+1)); else failed=$((failed+1)); failing="${failing:+$failing, }$(basename "$f")"; fi
  done
  if [[ $total -eq 0 ]]; then echo "no runnable checks found in $dir and no CHECK_CMD set" ; total=1; failed=1; failing="(no runner)"; fi
fi

echo "---"
echo "checks_total: $total"
echo "checks_passed: $passed"
echo "checks_failed: $failed"
echo "failing: ${failing:-none}"
if [[ $failed -eq 0 && $passed -gt 0 ]]; then echo "status: pass"; exit 0; else echo "status: fail"; exit 1; fi
