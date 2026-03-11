#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PORT=3000
SKIP_BUILD=0

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
    *)
      echo "usage: ./scripts/smoke.sh [--port <port>] [--skip-build]"
      exit 1
      ;;
  esac
done

BASE_URL="http://127.0.0.1:${PORT}"
TMP_DIR="$(mktemp -d)"
cleanup() {
  for pid_var in SSE_A_PID SSE_B_PID RESUME_A_PID BACKEND_PID; do
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
    if [[ -f "$file" ]] && ${grep_cmd} "$pattern" "$file"; then
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
./backend/build/exec/counter_web_multi_backend --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
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

SSE_A="$TMP_DIR/sse-a.log"
SSE_B="$TMP_DIR/sse-b.log"
curl -N -sS "$BASE_URL/api/counter/events/counter-a/smoke-client" >"$SSE_A" 2>"$TMP_DIR/sse-a.err" &
SSE_A_PID=$!
curl -N -sS "$BASE_URL/api/counter/events/counter-b/smoke-client" >"$SSE_B" 2>"$TMP_DIR/sse-b.err" &
SSE_B_PID=$!
wait_for_event "SSE A connected" '^: connected' "$SSE_A"
wait_for_event "SSE B connected" '^: connected' "$SSE_B"

resp_a=$(curl -sS -o "$TMP_DIR/resp-a.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute/counter-a" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":"Increment"}')
echo "$resp_a" | ${grep_cmd} '^200$'
wait_for_event "counter-a incremented" '"version":1' "$SSE_A"
wait_for_event "counter-a event payload" '"event":"Incremented"' "$SSE_A"
wait_for_event "counter-a id is 1" '^id: 1$' "$SSE_A"

resp_b=$(curl -sS -o "$TMP_DIR/resp-b.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute/counter-b" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":"Increment"}')
echo "$resp_b" | ${grep_cmd} '^200$'
wait_for_event "counter-b incremented" '"version":1' "$SSE_B"
wait_for_event "counter-b event payload" '"event":"Incremented"' "$SSE_B"

conflict=$(curl -sS -o "$TMP_DIR/conflict.txt" -w '%{http_code}' -X POST "$BASE_URL/api/counter/execute/counter-a" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":"Increment"}')
echo "$conflict" | ${grep_cmd} '^409$'
cat "$TMP_DIR/conflict.txt" | ${grep_cmd} 'concurrency conflict'

resync_a=$(curl -fsS "$BASE_URL/api/counter/resync/counter-a")
echo "$resync_a" | ${grep_cmd} '"version":1'
echo "$resync_a" | ${grep_cmd} '"events":\["Incremented"\]'

resync_b=$(curl -fsS "$BASE_URL/api/counter/resync/counter-b")
echo "$resync_b" | ${grep_cmd} '"version":1'
echo "$resync_b" | ${grep_cmd} '"events":\["Incremented"\]'

RESUME_A="$TMP_DIR/resume-a.log"
curl -N -sS "$BASE_URL/api/counter/events/counter-a/resume-client" -H 'Last-Event-ID: 1' >"$RESUME_A" 2>"$TMP_DIR/resume-a.err" &
RESUME_A_PID=$!
wait_for_event "Resume A connected" '^: connected' "$RESUME_A"
if ${grep_cmd} '"event":"Incremented"' "$RESUME_A"; then
  echo 'resume unexpectedly replayed old event'
  cat "$RESUME_A"
  exit 1
fi

index_file="$TMP_DIR/index.html"
bundle_file="$TMP_DIR/frontend.js"
curl -fsS "$BASE_URL/static/index.html" -o "$index_file"
curl -fsS "$BASE_URL/static/frontend.js" -o "$bundle_file"
${grep_cmd} 'frontend.js' "$index_file"
${grep_cmd} 'Multi-Stream Counter Web' "$bundle_file"
${grep_cmd} 'Increment' "$bundle_file"

echo 'SMOKE_OK'
