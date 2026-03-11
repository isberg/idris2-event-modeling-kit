# Copying This Starter

This starter supports two paths:

1. Manual copy and rename
2. Scripted copy for the mechanical rename layer

Use the script if you want a fast runnable copy with the same tiny counter domain. Use the manual path if you want full control from the first edit.

## Manual Path

### 1. Copy the directory

```sh
cp -R starters/web-single-stream /path/to/your-app
```

If you copy outside the shared repo, remove build artifacts from the copy:

```sh
rm -rf /path/to/your-app/domain/build
rm -rf /path/to/your-app/backend/build
rm -rf /path/to/your-app/frontend/build
rm -f /path/to/your-app/static/frontend.js
```

### 2. Rename package files and package names

Current package files:
- `domain/web-single-stream-starter-domain.ipkg`
- `backend/web-single-stream-starter-backend.ipkg`
- `frontend/web-single-stream-starter-frontend.ipkg`

Rename them to your app slug, for example `my-app-domain.ipkg`, and update:
- `pack.toml`
- `scripts/build.sh`
- package names inside the `*.ipkg` files
- any references in docs or scripts

### 3. Rename executable names

Current executable names:
- backend: `starter_web_backend`
- frontend: `starter_web_frontend.js`

Update:
- `backend/*.ipkg`
- `frontend/*.ipkg`
- `scripts/build.sh`
- `scripts/run.sh`
- `scripts/smoke.sh`

### 4. Fix package paths in `pack.toml`

If your copied app lives outside this repo, the local `../../packages/...` paths will be wrong.

Choose one of these:
- point them at the current shared repo using absolute paths
- replace them with your own local checkout paths
- replace them with published package sources later when the packages are in pack-db

### 5. Replace the tiny domain

The starter domain is intentionally tiny. Replace these first:
- `domain/src/Domain.idr`
- any route text in `backend/src/BackendMain.idr`
- frontend labels and button text in `frontend/src/FrontendMain.idr`
- smoke expectations in `scripts/smoke.sh`

Do not change the shared wiring shape until you have a reason.

### 6. Rebuild and validate

```sh
./scripts/build.sh
./scripts/smoke.sh --port 3000
./scripts/smoke.sh --port 3001 --skip-build --file-store "$(mktemp -d)"
```

## Scripted Path

The helper script automates only the safe mechanical layer:
- target directory creation
- package file renames
- package name rewrites
- executable name rewrites
- `pack.toml` shared-package paths pointing at the current shared repo
- starter title text

It does not replace the domain for you.

Usage:

```sh
./scripts/copy-starter.sh /path/to/target my-app --title "My App"
```

Then:
1. build and smoke the generated copy
2. replace the tiny counter domain with your own
3. re-run build and smoke

## What The Script Does Not Do

It does not:
- invent new commands, events, or rejections
- rename `Domain`, `BackendMain`, or `FrontendMain` modules
- rewrite app-specific route semantics
- change the frontend screen shape

That work stays manual so the script remains predictable.
