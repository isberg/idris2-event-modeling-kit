#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

pack build >/dev/null

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

printf '1\nKitchen\n2\n3\n3\nq\n' | ./build/exec/tutorial-counter-stage-01 >"$out"

grep -F 'Slice: 01-state-change' "$out" >/dev/null
grep -F 'Accepted at version 1 with events [Created(Kitchen)]; state{name=Kitchen, value=0}' "$out" >/dev/null
grep -F 'Accepted at version 2 with events [Incremented]; state{name=Kitchen, value=1}' "$out" >/dev/null
grep -F 'Accepted at version 3 with events [Decremented]; state{name=Kitchen, value=0}' "$out" >/dev/null
grep -F 'Rejected: counter is already at minimum.' "$out" >/dev/null

echo 'SMOKE_OK'
