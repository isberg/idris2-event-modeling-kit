#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PORT=3000
SKIP_BUILD=0
FILE_STORE=""

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
      FILE_STORE="$1"
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
cleanup() {
  for pid_var in SSE_PID RESUME_PID BACKEND_PID; do
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
  for _ in $(seq 1 100); do
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

if [[ "$SKIP_BUILD" -ne 1 ]]; then
  ./scripts/build.sh >"$TMP_DIR/build.log" 2>&1
fi

if [[ -n "$FILE_STORE" ]]; then
  ./backend/build/exec/starter_web_backend file "$FILE_STORE" --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
else
  ./backend/build/exec/starter_web_backend --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
fi
BACKEND_PID=$!

READY=0
for _ in $(seq 1 100); do
  if curl -fsS "$BASE_URL/health" >/dev/null 2>&1; then
    READY=1
    break
  fi
  sleep 0.1
done
if [[ "$READY" -ne 1 ]]; then
  echo "backend did not become ready"
  cat "$TMP_DIR/backend.log"
  exit 1
fi

view0=$(curl -fsS "$BASE_URL/api/counter/view")
echo "$view0" | ${grep_cmd} '"created":false'

resync0=$(curl -fsS "$BASE_URL/api/counter/resync")
echo "$resync0" | ${grep_cmd} '"version":0'
echo "$resync0" | ${grep_cmd} '"events":\[\]'

SSE_FILE="$TMP_DIR/sse.log"
curl -N -sS "$BASE_URL/api/counter/events/smoke-client" >"$SSE_FILE" 2>"$TMP_DIR/sse.err" &
SSE_PID=$!
wait_for_event "SSE connected" '^: connected' "$SSE_FILE"

create_status=$(curl -sS -o "$TMP_DIR/create.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":{"tag":"Create","contents":"Kitchen"}}')
echo "$create_status" | ${grep_cmd} '^200$'
wait_for_event "Created arrived" '"tag":"Created","contents":"Kitchen"' "$SSE_FILE"
wait_for_event "Created id is 1" '^id: 1$' "$SSE_FILE"

inc_status=$(curl -sS -o "$TMP_DIR/inc.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":1,"command":"Increment"}')
echo "$inc_status" | ${grep_cmd} '^200$'
wait_for_event "Increment arrived" '"event":"Incremented"' "$SSE_FILE"
wait_for_event "Increment id is 2" '^id: 2$' "$SSE_FILE"

RESUME_FILE="$TMP_DIR/resume.log"
curl -N -sS "$BASE_URL/api/counter/events/resume-client" -H 'Last-Event-ID: 1' >"$RESUME_FILE" 2>"$TMP_DIR/resume.err" &
RESUME_PID=$!
wait_for_event "Resume connected" '^: connected' "$RESUME_FILE"
wait_for_event "Resume replay incremented" '"event":"Incremented"' "$RESUME_FILE"
if ${grep_cmd} '"tag":"Created"' "$RESUME_FILE"; then
  echo "resume stream unexpectedly replayed Created"
  cat "$RESUME_FILE"
  exit 1
fi

dec_status=$(curl -sS -o "$TMP_DIR/dec.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":2,"command":"Decrement"}')
echo "$dec_status" | ${grep_cmd} '^200$'
wait_for_event "Decrement arrived" '"event":"Decremented"' "$SSE_FILE"

reject_status=$(curl -sS -o "$TMP_DIR/reject.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":3,"command":"Decrement"}')
echo "$reject_status" | ${grep_cmd} '^400$'
cat "$TMP_DIR/reject.txt" | ${grep_cmd} 'already at minimum'

view1=$(curl -fsS "$BASE_URL/api/counter/view")
echo "$view1" | ${grep_cmd} '"created":true'
echo "$view1" | ${grep_cmd} '"label":"Kitchen"'
echo "$view1" | ${grep_cmd} '"value":0'
echo "$view1" | ${grep_cmd} '"roman":""'

resync1=$(curl -fsS "$BASE_URL/api/counter/resync")
echo "$resync1" | ${grep_cmd} '"version":3'
echo "$resync1" | ${grep_cmd} '"tag":"Created","contents":"Kitchen"'
echo "$resync1" | ${grep_cmd} '"Incremented"'
echo "$resync1" | ${grep_cmd} '"Decremented"'

index_file="$TMP_DIR/index.html"
bundle_file="$TMP_DIR/frontend.js"
curl -fsS "$BASE_URL/static/index.html" -o "$index_file"
curl -fsS "$BASE_URL/static/frontend.js" -o "$bundle_file"
${grep_cmd} 'frontend.js' "$index_file"
${grep_cmd} 'EMKit Web Single-Stream Starter' "$index_file"
${grep_cmd} 'Creating counter' "$bundle_file"

echo 'SMOKE_OK'
