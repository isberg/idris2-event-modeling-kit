# todo-web

## What It Teaches

This is the first multi-screen web example.

It teaches:
- dynamic per-list streams
- category overview feed plus per-stream detail feed
- overview/detail UI split
- memory and file-store modes

## Read Order

1. `domain/src/Domain.idr`
2. `backend/src/BackendMain.idr`
3. `frontend/src/FrontendMain.idr`
4. `scripts/smoke.sh`

## Build And Run

```sh
./scripts/build.sh
./scripts/run.sh --port 3000
./scripts/smoke.sh --port 3012
./scripts/smoke.sh --port 3013 --skip-build --file-store "$(mktemp -d)"
```

Then open `http://127.0.0.1:3000/static/index.html`.

## What Stays Local

- route naming
- dynamic list and item id policy
- page/controller composition
