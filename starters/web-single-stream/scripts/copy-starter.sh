#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "usage: ./scripts/copy-starter.sh <target-dir> <app-slug> [--title <display title>]"
}

if [[ $# -lt 2 ]]; then
  usage
  exit 1
fi

TARGET_DIR="$1"
APP_SLUG="$2"
shift 2
DISPLAY_TITLE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title)
      shift
      if [[ $# -eq 0 ]]; then
        echo "missing value for --title"
        exit 1
      fi
      DISPLAY_TITLE="$1"
      shift
      ;;
    *)
      usage
      exit 1
      ;;
  esac
done

if [[ ! "$APP_SLUG" =~ ^[a-z0-9]+(-[a-z0-9]+)*$ ]]; then
  echo "app slug must match: ^[a-z0-9]+(-[a-z0-9]+)*$"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STARTER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SHARED_REPO_ROOT="$(cd "$STARTER_DIR/../.." && pwd)"
TARGET_DIR="$(python3 - <<'PY' "$TARGET_DIR"
import os,sys
print(os.path.abspath(sys.argv[1]))
PY
)"

if [[ -e "$TARGET_DIR" ]]; then
  echo "target already exists: $TARGET_DIR"
  exit 1
fi

if [[ -z "$DISPLAY_TITLE" ]]; then
  DISPLAY_TITLE="$APP_SLUG"
fi

APP_SLUG_UNDERSCORE="${APP_SLUG//-/_}"
DOMAIN_PKG="$APP_SLUG-domain"
BACKEND_PKG="$APP_SLUG-backend"
FRONTEND_PKG="$APP_SLUG-frontend"
BACKEND_EXE="${APP_SLUG_UNDERSCORE}_backend"
FRONTEND_EXE="${APP_SLUG_UNDERSCORE}_frontend.js"

mkdir -p "$(dirname "$TARGET_DIR")"
cp -R "$STARTER_DIR" "$TARGET_DIR"

rm -rf "$TARGET_DIR/domain/build" "$TARGET_DIR/backend/build" "$TARGET_DIR/frontend/build"
rm -f "$TARGET_DIR/static/frontend.js"

mv "$TARGET_DIR/domain/web-single-stream-starter-domain.ipkg" "$TARGET_DIR/domain/${DOMAIN_PKG}.ipkg"
mv "$TARGET_DIR/backend/web-single-stream-starter-backend.ipkg" "$TARGET_DIR/backend/${BACKEND_PKG}.ipkg"
mv "$TARGET_DIR/frontend/web-single-stream-starter-frontend.ipkg" "$TARGET_DIR/frontend/${FRONTEND_PKG}.ipkg"

export TARGET_DIR SHARED_REPO_ROOT APP_SLUG DISPLAY_TITLE DOMAIN_PKG BACKEND_PKG FRONTEND_PKG BACKEND_EXE FRONTEND_EXE
python3 - <<'PY'
import os
from pathlib import Path

root = Path(os.environ["TARGET_DIR"])
repo_root = os.environ["SHARED_REPO_ROOT"]
app_slug = os.environ["APP_SLUG"]
display_title = os.environ["DISPLAY_TITLE"]
domain_pkg = os.environ["DOMAIN_PKG"]
backend_pkg = os.environ["BACKEND_PKG"]
frontend_pkg = os.environ["FRONTEND_PKG"]
backend_exe = os.environ["BACKEND_EXE"]
frontend_exe = os.environ["FRONTEND_EXE"]

replacements = [
    ("web-single-stream-starter-domain", domain_pkg),
    ("web-single-stream-starter-backend", backend_pkg),
    ("web-single-stream-starter-frontend", frontend_pkg),
    ("starter_web_backend", backend_exe),
    ("starter_web_frontend.js", frontend_exe),
    ("# web-single-stream starter", f"# {app_slug}"),
    ("EMKit Web Single-Stream Starter", display_title),
    ("web-single-stream starter", app_slug),
    ("./scripts/copy-starter.sh /path/to/target my-app --title \"My App\"", f"./scripts/copy-starter.sh /path/to/target {app_slug} --title \"{display_title}\""),
]

for path in root.rglob("*"):
    if not path.is_file():
        continue
    if path.name == "frontend.js":
        continue
    if path.suffix not in {".md", ".toml", ".ipkg", ".sh", ".idr", ".html"}:
        continue
    text = path.read_text()
    for old, new in replacements:
        text = text.replace(old, new)
    if path.name == "pack.toml":
        text = text.replace('path = "../../packages/emkit-sourcing"', f'path = "{repo_root}/packages/emkit-sourcing"')
        text = text.replace('path = "../../packages/emkit-modeling"', f'path = "{repo_root}/packages/emkit-modeling"')
        text = text.replace('path = "../../packages/emkit-runtime"', f'path = "{repo_root}/packages/emkit-runtime"')
        text = text.replace('path = "../../packages/emkit-stream"', f'path = "{repo_root}/packages/emkit-stream"')
        text = text.replace('path = "../../packages/emkit-store"', f'path = "{repo_root}/packages/emkit-store"')
        text = text.replace('path = "../../packages/emkit-wire"', f'path = "{repo_root}/packages/emkit-wire"')
        text = text.replace('path = "../../packages/emkit-backend"', f'path = "{repo_root}/packages/emkit-backend"')
        text = text.replace('path = "../../packages/emkit-frontend"', f'path = "{repo_root}/packages/emkit-frontend"')
    path.write_text(text)
PY

chmod +x "$TARGET_DIR/scripts/build.sh" "$TARGET_DIR/scripts/run.sh" "$TARGET_DIR/scripts/smoke.sh"
if [[ -f "$TARGET_DIR/scripts/copy-starter.sh" ]]; then
  chmod +x "$TARGET_DIR/scripts/copy-starter.sh"
fi

echo "Created starter copy at: $TARGET_DIR"
echo "Next steps:"
echo "  1. cd $TARGET_DIR"
echo "  2. ./scripts/build.sh"
echo "  3. ./scripts/smoke.sh --port 3000"
echo "  4. Replace domain/src/Domain.idr and app-specific text"
