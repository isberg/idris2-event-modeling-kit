#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

(
  cd domain
  pack --no-prompt build counter-web-multi-domain.ipkg
)

(
  cd backend
  pack --no-prompt build counter-web-multi-backend.ipkg
)

(
  cd frontend
  pack --no-prompt build counter-web-multi-frontend.ipkg
)

mkdir -p static
cp frontend/build/exec/counter_web_multi_frontend.js static/frontend.js
