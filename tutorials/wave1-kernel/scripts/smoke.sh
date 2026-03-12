#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
cd "$repo_root"

pack build >/dev/null

out="$(mktemp)"
trap 'rm -f "$out"' EXIT

./build/exec/tutorial-wave1-kernel >"$out"

grep -F 'Tutorial: wave1-kernel' "$out" >/dev/null
grep -F 'Model: door{open=true}' "$out" >/dev/null
grep -F 'Visible: True' "$out" >/dev/null
grep -F 'Actions: [CloseDoor]' "$out" >/dev/null
grep -F 'Decision: accepted -> model=door{open=false}; events=[DoorClosed]' "$out" >/dev/null
grep -F 'Execute JSON: {"expectedVersion":1,"command":"Close"}' "$out" >/dev/null
grep -F 'Stream JSON: {"version":2,"event":"DoorClosed"}' "$out" >/dev/null
grep -F 'id: 2' "$out" >/dev/null
grep -F 'event: door-event' "$out" >/dev/null
grep -F 'data: {"version":2,"event":"DoorClosed"}' "$out" >/dev/null

echo 'SMOKE_OK'
