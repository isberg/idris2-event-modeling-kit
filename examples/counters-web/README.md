# counters-web

## What It Teaches

This is a richer multi-screen web example than `counter-web`.

It teaches:
- dynamic counter streams
- category overview feed plus detail feed
- version-safe multi-stream overview updates
- stronger screen and read-model pressure than the plain counter examples

## Read Order

1. `domain/src/Domain.idr`
2. `backend/src/BackendMain.idr`
3. `frontend/src/FrontendMain.idr`
4. `scripts/smoke.sh`

## Build And Run

```sh
./scripts/build.sh
./scripts/run.sh --port 3000
./scripts/smoke.sh --port 3014
./scripts/smoke.sh --port 3015 --skip-build --file-store "$(mktemp -d)"
```

Then open `http://127.0.0.1:3000/static/index.html`.

## What Stays Local

- route naming
- stream-id generation policy
- page rendering and interaction choices
