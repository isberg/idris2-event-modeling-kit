#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PORT=3000
SKIP_BUILD=0
STORE_DIR=""

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
    --skip-build)
      SKIP_BUILD=1
      shift
      ;;
    --file-store)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --file-store"
        exit 1
      fi
      STORE_DIR="$1"
      shift
      ;;
    *)
      echo "usage: ./scripts/smoke.sh [--port <port>] [--skip-build] [--file-store <dir>]"
      exit 1
      ;;
  esac
done

BASE_URL="http://127.0.0.1:${PORT}"
TMP_DIR="$(mktemp -d)"
BACKEND_PID=""
cleanup() {
  for pid_var in OVERVIEW_PID DETAIL_PID RESUME_PID BACKEND_PID; do
    pid="${!pid_var:-}"
    if [[ -n "$pid" ]] && kill -0 "$pid" >/dev/null 2>&1; then
      kill "$pid" >/dev/null 2>&1 || true
      wait "$pid" >/dev/null 2>&1 || true
    fi
  done
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

grep_cmd="rg -q"
if ! command -v rg >/dev/null 2>&1; then
  grep_cmd="grep -q"
fi

wait_for_event() {
  local label="$1"
  local pattern="$2"
  local file="$3"
  for _ in $(seq 1 120); do
    if ${grep_cmd} "$pattern" "$file"; then
      echo "$label"
      return 0
    fi
    sleep 0.1
  done
  echo "Expected pattern not found: $pattern"
  cat "$file"
  return 1
}

wait_for_ready() {
  for _ in $(seq 1 120); do
    if curl -fsS "$BASE_URL/health" >/dev/null 2>&1; then
      return 0
    fi
    sleep 0.1
  done
  echo "backend did not become ready"
  [[ -f "$TMP_DIR/backend.log" ]] && cat "$TMP_DIR/backend.log"
  return 1
}

start_backend() {
  if [[ -n "$STORE_DIR" ]]; then
    mkdir -p "$STORE_DIR"
    ./backend/build/exec/todo_web_backend file "$STORE_DIR" --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
  else
    ./backend/build/exec/todo_web_backend --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
  fi
  BACKEND_PID=$!
  wait_for_ready
}

stop_backend() {
  if [[ -n "$BACKEND_PID" ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
  BACKEND_PID=""
}

if [[ "$SKIP_BUILD" -ne 1 ]]; then
  ./scripts/build.sh >"$TMP_DIR/build.log" 2>&1
fi

start_backend

curl -fsS "$BASE_URL/api/todo/lists" | ${grep_cmd} '^\[\]$'

OVERVIEW_FILE="$TMP_DIR/overview.log"
curl -N -sS "$BASE_URL/api/todo/overview-events/smoke-overview" >"$OVERVIEW_FILE" 2>"$TMP_DIR/overview.err" &
OVERVIEW_PID=$!
wait_for_event "Overview connected" '^: connected' "$OVERVIEW_FILE"

create_code=$(curl -sS -o "$TMP_DIR/create.txt" -w '%{http_code}' -X POST "$BASE_URL/api/todo/execute/todo-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":{"tag":"CreateList","contents":"Errands"}}')
echo "$create_code" | ${grep_cmd} '^200$'
wait_for_event "Overview created event" '"streamId":"todo-1"' "$OVERVIEW_FILE"
wait_for_event "Overview list created tag" '"tag":"ListCreated"' "$OVERVIEW_FILE"

curl -fsS "$BASE_URL/api/todo/lists" | ${grep_cmd} '"listId":"todo-1"'
curl -fsS "$BASE_URL/api/todo/lists" | ${grep_cmd} '"title":"Errands"'

DETAIL_FILE="$TMP_DIR/detail.log"
curl -N -sS "$BASE_URL/api/todo/events/todo-1/smoke-detail" >"$DETAIL_FILE" 2>"$TMP_DIR/detail.err" &
DETAIL_PID=$!
wait_for_event "Detail connected" '^: connected' "$DETAIL_FILE"

resync_one=$(curl -fsS "$BASE_URL/api/todo/resync/todo-1")
echo "$resync_one" | ${grep_cmd} '"version":1'
echo "$resync_one" | ${grep_cmd} '"tag":"ListCreated"'

add_code=$(curl -sS -o "$TMP_DIR/add.txt" -w '%{http_code}' -X POST "$BASE_URL/api/todo/execute/todo-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":1,"command":{"tag":"AddItem","contents":["item-1","Buy milk"]}}')
echo "$add_code" | ${grep_cmd} '^200$'
wait_for_event "Detail item added" '"version":2' "$DETAIL_FILE"
wait_for_event "Detail item added tag" '"tag":"ItemAdded"' "$DETAIL_FILE"
wait_for_event "Overview item added" '"streamVersion":2' "$OVERVIEW_FILE"

curl -fsS "$BASE_URL/api/todo/lists" | ${grep_cmd} '"openCount":1'

toggle_code=$(curl -sS -o "$TMP_DIR/toggle.txt" -w '%{http_code}' -X POST "$BASE_URL/api/todo/execute/todo-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":2,"command":{"tag":"ToggleItem","contents":"item-1"}}')
echo "$toggle_code" | ${grep_cmd} '^200$'
wait_for_event "Detail item completed" '"version":3' "$DETAIL_FILE"
wait_for_event "Detail item completed tag" '"tag":"ItemCompleted"' "$DETAIL_FILE"
wait_for_event "Overview item completed" '"streamVersion":3' "$OVERVIEW_FILE"

resync_two=$(curl -fsS "$BASE_URL/api/todo/resync/todo-1")
echo "$resync_two" | ${grep_cmd} '"version":3'
echo "$resync_two" | ${grep_cmd} '"tag":"ItemCompleted"'

RESUME_FILE="$TMP_DIR/resume.log"
curl -N -sS "$BASE_URL/api/todo/events/todo-1/resume-detail" -H 'Last-Event-ID: 1' >"$RESUME_FILE" 2>"$TMP_DIR/resume.err" &
RESUME_PID=$!
wait_for_event "Resume connected" '^: connected' "$RESUME_FILE"
wait_for_event "Resume replayed add" '"version":2' "$RESUME_FILE"
wait_for_event "Resume replayed toggle" '"version":3' "$RESUME_FILE"
if ${grep_cmd} '"version":1' "$RESUME_FILE"; then
  echo 'resume unexpectedly replayed version 1'
  cat "$RESUME_FILE"
  exit 1
fi

index_file="$TMP_DIR/index.html"
bundle_file="$TMP_DIR/frontend.js"
curl -fsS "$BASE_URL/static/index.html" -o "$index_file"
curl -fsS "$BASE_URL/static/frontend.js" -o "$bundle_file"
${grep_cmd} 'frontend.js' "$index_file"
${grep_cmd} 'Todo Lists' "$bundle_file"
${grep_cmd} 'Overview feed' "$bundle_file"

if [[ -n "$STORE_DIR" ]]; then
  stop_backend
  start_backend
  curl -fsS "$BASE_URL/api/todo/lists" | ${grep_cmd} '"listId":"todo-1"'
  curl -fsS "$BASE_URL/api/todo/lists" | ${grep_cmd} '"doneCount":1'
  persisted_resync=$(curl -fsS "$BASE_URL/api/todo/resync/todo-1")
  echo "$persisted_resync" | ${grep_cmd} '"version":3'
  echo "$persisted_resync" | ${grep_cmd} '"tag":"ItemCompleted"'
fi

echo 'SMOKE_OK'
