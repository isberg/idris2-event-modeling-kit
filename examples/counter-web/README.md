# counter-web

## What It Teaches

This is the first web example.

It teaches:
- one fixed stream
- one small domain
- one backend
- one frontend
- SSE replay plus live updates without dynamic stream routing

## Read Order

1. `domain/src/Domain.idr`
2. `backend/src/BackendMain.idr`
3. `frontend/src/FrontendMain.idr`
4. `scripts/smoke.sh`

## Build And Run

```sh
./scripts/build.sh
./scripts/run.sh --port 3000
./scripts/smoke.sh --port 3010
```

Then open `http://127.0.0.1:3000/static/index.html`.

## What Stays Local

- app-specific command API
- snapshot DTO mapping
- page rendering
