#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

pack build >/dev/null

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

printf '1\nKitchen\n3\n4\n5\n6\nq\n' | ./build/exec/tutorial-counter-stage-03 >"$out"

grep -F 'Slice: 03-translation' "$out" >/dev/null
grep -F 'Translated external signal tap -> Increment.' "$out" >/dev/null
grep -F 'Translated external signal lower -> Decrement.' "$out" >/dev/null
grep -F 'Translation rejected: unknown external signal: dance' "$out" >/dev/null
grep -F 'Accepted at version 2 with events [Incremented]' "$out" >/dev/null
grep -F 'Accepted at version 3 with events [Decremented]' "$out" >/dev/null

echo 'SMOKE_OK'
