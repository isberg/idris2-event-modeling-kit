#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PORT=3000

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
    *)
      echo "usage: ./scripts/run.sh [--port <port>]"
      exit 1
      ;;
  esac
done

if [[ ! -x "backend/build/exec/counter_web_multi_backend" ]] || [[ ! -f "static/frontend.js" ]]; then
  ./scripts/build.sh
fi

./backend/build/exec/counter_web_multi_backend --port "$PORT"
