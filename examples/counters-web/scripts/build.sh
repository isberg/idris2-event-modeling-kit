#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

(
  cd domain
  pack --no-prompt build counters-web-domain.ipkg
)

(
  cd backend
  pack --no-prompt build counters-web-backend.ipkg
)

(
  cd frontend
  pack --no-prompt build counters-web-frontend.ipkg
)

mkdir -p static
cp frontend/build/exec/counters_web_frontend.js static/frontend.js
