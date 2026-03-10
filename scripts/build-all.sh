#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"

cd "$repo_root/packages/emkit-sourcing"
pack build

cd "$repo_root/packages/emkit-modeling"
pack build

cd "$repo_root/packages/emkit-runtime"
pack build

cd "$repo_root/packages/emkit-stream"
pack build

cd "$repo_root/packages/emkit-store"
pack build

cd "$repo_root/packages/emkit-wire"
pack build

cd "$repo_root/packages/emkit-backend"
pack build

cd "$repo_root/packages/emkit-frontend"
pack build

cd "$repo_root/examples/counter-console"
pack build

cd "$repo_root/examples/counter-web"
./scripts/build.sh

cd "$repo_root/examples/counter-web-multi"
./scripts/build.sh

cd "$repo_root/examples/todo-web"
./scripts/build.sh

cd "$repo_root/examples/counters-web"
./scripts/build.sh
