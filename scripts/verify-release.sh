#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
base_port="${EMKIT_VERIFY_BASE_PORT:-3110}"

cd "$repo_root"

./scripts/build-all.sh

cd "$repo_root/tutorials/counter-stages/04-automation"
./scripts/smoke.sh

cd "$repo_root/examples/counter-console"
./scripts/smoke.sh

cd "$repo_root/examples/counter-web"
./scripts/smoke.sh --port "$base_port" --skip-build

cd "$repo_root/examples/project-tasks-web"
./scripts/smoke.sh --port "$((base_port + 1))" --skip-build

cd "$repo_root/starters/web-single-stream"
./scripts/smoke.sh --port "$((base_port + 2))" --skip-build
