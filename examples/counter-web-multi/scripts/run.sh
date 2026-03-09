#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -x "backend/build/exec/counter_web_multi_backend" ]] || [[ ! -f "static/frontend.js" ]]; then
  ./scripts/build.sh
fi

./backend/build/exec/counter_web_multi_backend
