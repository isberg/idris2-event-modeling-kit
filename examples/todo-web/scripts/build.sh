#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

(
  cd domain
  pack --no-prompt build todo-web-domain.ipkg
)

(
  cd backend
  pack --no-prompt build todo-web-backend.ipkg
)

(
  cd frontend
  pack --no-prompt build todo-web-frontend.ipkg
)

mkdir -p static
cp frontend/build/exec/todo_web_frontend.js static/frontend.js
