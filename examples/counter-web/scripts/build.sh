#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

(
  cd domain
  pack --no-prompt build counter-web-domain.ipkg
)

(
  cd backend
  pack --no-prompt build counter-web-backend.ipkg
)

(
  cd frontend
  pack --no-prompt build counter-web-frontend.ipkg
)

mkdir -p static
cp frontend/build/exec/counter_web_frontend.js static/frontend.js
