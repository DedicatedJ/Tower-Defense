#!/bin/bash
# Test runner. Copies the repo to a fresh temp folder, swaps a harness in
# as main.lua (the game's own main.lua becomes game_main.lua), and runs it
# with LOVE's console build. Each suite uses its own save folder, never the
# player's.
#
#   tests/run.sh            unit, then smoke
#   tests/run.sh unit       fast logic checks with exact expected values
#   tests/run.sh smoke      drives the real game through menus and 10 waves
#   tests/run.sh balance    a simple AI plays every level; prints a difficulty
#                           read-out (not run by default; BALANCE_LEVEL=<id> for one)
#   LOVEC=/path/to/lovec tests/run.sh
#
# Exit code 0 = every check passed, 1 = a check failed, 2 = crash.
REPO="$(cd "$(dirname "$0")/.." && pwd)"
LOVEC="${LOVEC:-/c/Program Files/LOVE/lovec.exe}"

run_suite() {
    local suite="$1" limit="$2"
    local D
    D=$(mktemp -d "${TMPDIR:-/tmp}/td-$suite.XXXX") || return 2
    (cd "$REPO" && tar --exclude=.git --exclude='Tower Defense assets' --exclude='art/incoming' -cf - .) | tar -xf - -C "$D"
    mv "$D/main.lua" "$D/game_main.lua"
    cp "$REPO/tests/$suite/main.lua" "$D/main.lua"
    echo "== $suite (copy: $D)"
    timeout "$limit" "$LOVEC" "$D" 2>&1
}

status=0
for suite in ${1:-unit smoke}; do
    case "$suite" in
        unit)  run_suite unit 120 ;;
        smoke) run_suite smoke 900 ;;
        balance) run_suite balance 3000 ;;
        *) echo "unknown suite: $suite (use unit, smoke or balance)"; exit 2 ;;
    esac
    rc=$?
    echo "== $suite exit=$rc"
    [ "$rc" -gt "$status" ] && status=$rc
done
exit $status
