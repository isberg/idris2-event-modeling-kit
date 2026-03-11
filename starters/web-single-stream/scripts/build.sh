#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

(
  cd domain
  pack --no-prompt build web-single-stream-starter-domain.ipkg
)

(
  cd backend
  pack --no-prompt build web-single-stream-starter-backend.ipkg
)

(
  cd frontend
  pack --no-prompt build web-single-stream-starter-frontend.ipkg
)

mkdir -p static
cp frontend/build/exec/starter_web_frontend.js static/frontend.js
