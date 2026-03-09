#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

TMP_DIR="$(mktemp -d)"
cleanup() {
  if [[ -n "${SSE_PID:-}" ]] && kill -0 "$SSE_PID" >/dev/null 2>&1; then
    kill "$SSE_PID" >/dev/null 2>&1 || true
    wait "$SSE_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "${RESUME_PID:-}" ]] && kill -0 "$RESUME_PID" >/dev/null 2>&1; then
    kill "$RESUME_PID" >/dev/null 2>&1 || true
    wait "$RESUME_PID" >/dev/null 2>&1 || true
  fi
  if [[ -n "${BACKEND_PID:-}" ]] && kill -0 "$BACKEND_PID" >/dev/null 2>&1; then
    kill "$BACKEND_PID" >/dev/null 2>&1 || true
    wait "$BACKEND_PID" >/dev/null 2>&1 || true
  fi
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

./scripts/build.sh >"$TMP_DIR/build.log" 2>&1
./backend/build/exec/counter_web_backend >"$TMP_DIR/backend.log" 2>&1 &
BACKEND_PID=$!

READY=0
for _ in $(seq 1 100); do
  if curl -fsS http://127.0.0.1:3000/health >/dev/null 2>&1; then
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

curl -fsS http://127.0.0.1:3000/api/counter | ${grep_cmd} '"created":false'

SSE_FILE="$TMP_DIR/sse.log"
curl -N -sS http://127.0.0.1:3000/api/events/smoke-client >"$SSE_FILE" 2>"$TMP_DIR/sse.err" &
SSE_PID=$!
wait_for_event "SSE connected" '^: connected' "$SSE_FILE"

create_resp=$(curl -fsS -X POST http://127.0.0.1:3000/api/counter/create \
  -H 'Content-Type: application/json' \
  -d '"Kitchen"')
echo "$create_resp" | ${grep_cmd} '"ok":true'
wait_for_event "Created arrived" '"eventType":"Created"' "$SSE_FILE"
wait_for_event "Created id is 1" '^id: 1$' "$SSE_FILE"

inc_resp=$(curl -fsS -X POST http://127.0.0.1:3000/api/counter/increment)
echo "$inc_resp" | ${grep_cmd} '"ok":true'
wait_for_event "Increment arrived" '"eventType":"Incremented"' "$SSE_FILE"
wait_for_event "Increment id is 2" '^id: 2$' "$SSE_FILE"

RESUME_FILE="$TMP_DIR/resume.log"
curl -N -sS http://127.0.0.1:3000/api/events/resume-client -H 'Last-Event-ID: 1' >"$RESUME_FILE" 2>"$TMP_DIR/resume.err" &
RESUME_PID=$!
wait_for_event "Resume connected" '^: connected' "$RESUME_FILE"
wait_for_event "Resume replay incremented" '"eventType":"Incremented"' "$RESUME_FILE"
if ${grep_cmd} '"eventType":"Created"' "$RESUME_FILE"; then
  echo "resume stream unexpectedly replayed Created"
  cat "$RESUME_FILE"
  exit 1
fi

dec_resp=$(curl -fsS -X POST http://127.0.0.1:3000/api/counter/decrement)
echo "$dec_resp" | ${grep_cmd} '"ok":true'
wait_for_event "Decrement arrived" '"eventType":"Decremented"' "$SSE_FILE"

reject_resp=$(curl -fsS -X POST http://127.0.0.1:3000/api/counter/decrement)
echo "$reject_resp" | ${grep_cmd} '"ok":false'
echo "$reject_resp" | ${grep_cmd} 'already at minimum'

snapshot=$(curl -fsS http://127.0.0.1:3000/api/counter)
echo "$snapshot" | ${grep_cmd} '"version":3'
echo "$snapshot" | ${grep_cmd} '"label":"Kitchen"'
echo "$snapshot" | ${grep_cmd} '"roman":""'
echo "$snapshot" | ${grep_cmd} '"eventType":"Created"'
echo "$snapshot" | ${grep_cmd} '"eventType":"Incremented"'
echo "$snapshot" | ${grep_cmd} '"eventType":"Decremented"'

index_file="$TMP_DIR/index.html"
bundle_file="$TMP_DIR/frontend.js"
curl -fsS http://127.0.0.1:3000/static/index.html -o "$index_file"
curl -fsS http://127.0.0.1:3000/static/frontend.js -o "$bundle_file"
${grep_cmd} 'frontend.js' "$index_file"
${grep_cmd} 'Counter Web' "$bundle_file"
${grep_cmd} 'Live feed' "$bundle_file"

echo "SMOKE_OK"
