#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

pack build >/dev/null

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

printf '1\nKitchen\n3\n3\n3\nq\n' | ./build/exec/tutorial-counter-stage-04 >"$out"

grep -F 'Slice: 04-automation' "$out" >/dev/null
grep -F 'Translated external signal tap -> Increment.' "$out" >/dev/null
grep -F 'Automation decided: [Reset]' "$out" >/dev/null
grep -F 'Automation accepted at version 5 with events [ResetToZero]' "$out" >/dev/null
grep -F 'Counter: Kitchen = 0 []' "$out" >/dev/null

echo 'SMOKE_OK'
