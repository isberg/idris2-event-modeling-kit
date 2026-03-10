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
  for pid_var in OVERVIEW_PID PROJECT_DETAIL_PID PROJECT_TASKS_PID TASK_PID RESUME_PID BACKEND_PID; do
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
    ./backend/build/exec/project_tasks_web_backend file "$STORE_DIR" --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
  else
    ./backend/build/exec/project_tasks_web_backend --port "$PORT" >"$TMP_DIR/backend.log" 2>&1 &
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

curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '^\[\]$'

OVERVIEW_FILE="$TMP_DIR/overview.log"
curl -N -sS "$BASE_URL/api/projects/overview-events/smoke-overview" >"$OVERVIEW_FILE" 2>"$TMP_DIR/overview.err" &
OVERVIEW_PID=$!
wait_for_event "Overview connected" '^: connected' "$OVERVIEW_FILE"

create_project_code=$(curl -sS -o "$TMP_DIR/create-project.txt" -w '%{http_code}' -X POST "$BASE_URL/api/projects/execute/project-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":{"tag":"CreateProject","contents":"Alpha"}}')
echo "$create_project_code" | ${grep_cmd} '^200$'
wait_for_event "Project created event" '"streamId":"project-1"' "$OVERVIEW_FILE"
wait_for_event "Project created tag" '"tag":"ProjectCreated"' "$OVERVIEW_FILE"
wait_for_event "Project created contents" '"contents":"Alpha"' "$OVERVIEW_FILE"

curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"projectId":"project-1"'
curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"title":"Alpha"'
curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"completed":false'

project_resync_one=$(curl -fsS "$BASE_URL/api/projects/resync/project-1")
echo "$project_resync_one" | ${grep_cmd} '"version":1'
echo "$project_resync_one" | ${grep_cmd} '"tag":"ProjectCreated"'
echo "$project_resync_one" | ${grep_cmd} '"contents":"Alpha"'

PROJECT_DETAIL_FILE="$TMP_DIR/project-detail.log"
curl -N -sS "$BASE_URL/api/projects/events/project-1/smoke-project-detail" >"$PROJECT_DETAIL_FILE" 2>"$TMP_DIR/project-detail.err" &
PROJECT_DETAIL_PID=$!
wait_for_event "Project detail connected" '^: connected' "$PROJECT_DETAIL_FILE"
wait_for_event "Project detail replayed create" '"version":1' "$PROJECT_DETAIL_FILE"
wait_for_event "Project detail replayed create tag" '"tag":"ProjectCreated"' "$PROJECT_DETAIL_FILE"

curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '^\[\]$'

PROJECT_TASKS_FILE="$TMP_DIR/project-tasks.log"
curl -N -sS "$BASE_URL/api/projects/tasks-events/project-1/smoke-project" >"$PROJECT_TASKS_FILE" 2>"$TMP_DIR/project-tasks.err" &
PROJECT_TASKS_PID=$!
wait_for_event "Project tasks connected" '^: connected' "$PROJECT_TASKS_FILE"

create_task_code=$(curl -sS -o "$TMP_DIR/create-task.txt" -w '%{http_code}' -X POST "$BASE_URL/api/tasks/execute/task-project-1-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":0,"command":{"tag":"CreateTask","contents":["project-1","First task"]}}')
echo "$create_task_code" | ${grep_cmd} '^200$'
wait_for_event "Task created in project feed" '"streamId":"task-project-1-1"' "$PROJECT_TASKS_FILE"
wait_for_event "Task created tag" '"tag":"TaskCreated"' "$PROJECT_TASKS_FILE"

curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '"taskId":"task-project-1-1"'
curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '"projectId":"project-1"'
curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '"title":"First task"'
curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '"status":"TaskTodo"'

TASK_FILE="$TMP_DIR/task.log"
curl -N -sS "$BASE_URL/api/tasks/events/task-project-1-1/smoke-task" >"$TASK_FILE" 2>"$TMP_DIR/task.err" &
TASK_PID=$!
wait_for_event "Task connected" '^: connected' "$TASK_FILE"

task_resync_one=$(curl -fsS "$BASE_URL/api/tasks/resync/task-project-1-1")
echo "$task_resync_one" | ${grep_cmd} '"version":1'
echo "$task_resync_one" | ${grep_cmd} '"tag":"TaskCreated"'

start_task_code=$(curl -sS -o "$TMP_DIR/start-task.txt" -w '%{http_code}' -X POST "$BASE_URL/api/tasks/execute/task-project-1-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":1,"command":"StartTask"}')
echo "$start_task_code" | ${grep_cmd} '^200$'
wait_for_event "Task started detail" '"version":2' "$TASK_FILE"
wait_for_event "Task started tag" '"StartTask"|"TaskStarted"' "$TASK_FILE"
wait_for_event "Task started project feed" '"streamVersion":2' "$PROJECT_TASKS_FILE"

complete_task_code=$(curl -sS -o "$TMP_DIR/complete-task.txt" -w '%{http_code}' -X POST "$BASE_URL/api/tasks/execute/task-project-1-1" \
  -H 'Content-Type: application/json' \
  -d '{"expectedVersion":2,"command":"CompleteTask"}')
echo "$complete_task_code" | ${grep_cmd} '^200$'
wait_for_event "Task completed detail" '"version":3' "$TASK_FILE"
wait_for_event "Task completed tag" '"CompleteTask"|"TaskCompleted"' "$TASK_FILE"
wait_for_event "Task completed project feed" '"streamVersion":3' "$PROJECT_TASKS_FILE"

wait_for_event "Project automation detail" '"version":2' "$PROJECT_DETAIL_FILE"
wait_for_event "Project automation tag" '"ProjectCompleted"' "$PROJECT_DETAIL_FILE"
wait_for_event "Project automation overview" '"streamVersion":2' "$OVERVIEW_FILE"
wait_for_event "Project automation overview tag" '"ProjectCompleted"' "$OVERVIEW_FILE"

TASK_LIST_AFTER_COMPLETE="$TMP_DIR/project-tasks-after-complete.json"
curl -fsS "$BASE_URL/api/projects/tasks/project-1" -o "$TASK_LIST_AFTER_COMPLETE"
${grep_cmd} '"status":"TaskDone"' "$TASK_LIST_AFTER_COMPLETE"

project_resync_two=$(curl -fsS "$BASE_URL/api/projects/resync/project-1")
echo "$project_resync_two" | ${grep_cmd} '"version":2'
echo "$project_resync_two" | ${grep_cmd} '"ProjectCompleted"'

curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"projectId":"project-1"'
curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"completed":true'

task_resync_two=$(curl -fsS "$BASE_URL/api/tasks/resync/task-project-1-1")
echo "$task_resync_two" | ${grep_cmd} '"version":3'
echo "$task_resync_two" | ${grep_cmd} 'TaskCompleted'

RESUME_FILE="$TMP_DIR/resume.log"
curl -N -sS "$BASE_URL/api/tasks/events/task-project-1-1/resume-task" -H 'Last-Event-ID: 1' >"$RESUME_FILE" 2>"$TMP_DIR/resume.err" &
RESUME_PID=$!
wait_for_event "Resume connected" '^: connected' "$RESUME_FILE"
wait_for_event "Resume replayed start" '"version":2' "$RESUME_FILE"
wait_for_event "Resume replayed complete" '"version":3' "$RESUME_FILE"
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
${grep_cmd} 'Project Tasks Web' "$index_file"
${grep_cmd} 'Project Tracker' "$bundle_file"
${grep_cmd} 'Project/Task Example' "$bundle_file"

if [[ -n "$STORE_DIR" ]]; then
  stop_backend
  start_backend
  curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"projectId":"project-1"'
  curl -fsS "$BASE_URL/api/projects" | ${grep_cmd} '"completed":true'
  curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '"taskId":"task-project-1-1"'
  curl -fsS "$BASE_URL/api/projects/tasks/project-1" | ${grep_cmd} '"status":"TaskDone"'
  persisted_project_resync=$(curl -fsS "$BASE_URL/api/projects/resync/project-1")
  echo "$persisted_project_resync" | ${grep_cmd} '"version":2'
  echo "$persisted_project_resync" | ${grep_cmd} 'ProjectCompleted'
  persisted_task_resync=$(curl -fsS "$BASE_URL/api/tasks/resync/task-project-1-1")
  echo "$persisted_task_resync" | ${grep_cmd} '"version":3'
  echo "$persisted_task_resync" | ${grep_cmd} 'TaskCompleted'
fi

echo 'SMOKE_OK'
