#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PORT=3000
STORE_MODE=memory
STORE_PATH=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --port)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --port"
        exit 1
      fi
      PORT="$1"
      shift
      ;;
    --file-store)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --file-store"
        exit 1
      fi
      STORE_MODE=file
      STORE_PATH="$1"
      shift
      ;;
    *)
      echo "usage: ./scripts/run.sh [--port <port>] [--file-store <dir>]"
      exit 1
      ;;
  esac
done

if [[ ! -x "backend/build/exec/starter_web_backend" ]] || [[ ! -f "static/frontend.js" ]]; then
  ./scripts/build.sh
fi

if [[ "$STORE_MODE" == "file" ]]; then
  ./backend/build/exec/starter_web_backend file "$STORE_PATH" --port "$PORT"
else
  ./backend/build/exec/starter_web_backend --port "$PORT"
fi
