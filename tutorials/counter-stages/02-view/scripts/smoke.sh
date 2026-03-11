#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

pack build >/dev/null

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

printf '1\nKitchen\n1\n2\n2\nq\n' | ./build/exec/tutorial-counter-stage-02 >"$out"

grep -F 'Slice: 02-view' "$out" >/dev/null
grep -F 'Counter: Kitchen = 0 []' "$out" >/dev/null
grep -F 'Counter: Kitchen = 1 [I]' "$out" >/dev/null
grep -F 'Rejected: counter is already at minimum.' "$out" >/dev/null

echo 'SMOKE_OK'
