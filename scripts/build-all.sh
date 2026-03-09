#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

cd "$repo_root/packages/emkit-sourcing"
pack build

cd "$repo_root/packages/emkit-modeling"
pack build

cd "$repo_root/packages/emkit-stream"
pack build

cd "$repo_root/packages/emkit-store"
pack build

cd "$repo_root/packages/emkit-wire"
pack build
