#!/bin/bash
# Smoke test. Copies the repo to a fresh temp folder, swaps the harness in
# as main.lua (the game's own main.lua becomes game_main.lua), and runs it
# with LOVE's console build. Saves go to a separate "tower-defense-smoketest"
# save folder, never the player's.
#
#   tests/smoke/run_smoke.sh              run and print everything
#   LOVEC=/path/to/lovec tests/smoke/run_smoke.sh
#
# Exit code 0 = every check passed, 1 = a check failed, 2 = crash.
set -e
REPO="$(cd "$(dirname "$0")/../.." && pwd)"
LOVEC="${LOVEC:-/c/Program Files/LOVE/lovec.exe}"
D=$(mktemp -d "${TMPDIR:-/tmp}/td-smoke.XXXX")
cd "$REPO"
tar --exclude=.git --exclude='Tower Defense assets' --exclude='art/incoming' -cf - . | tar -xf - -C "$D"
mv "$D/main.lua" "$D/game_main.lua"
cp "$REPO/tests/smoke/main.lua" "$D/main.lua"
echo "copy: $D"
set +e
timeout 900 "$LOVEC" "$D" 2>&1
