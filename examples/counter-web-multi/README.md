# counter-web-multi

## What It Teaches

This is a transport and multi-stream pressure-test example.

It teaches:
- typed execute/resync payloads
- multiple fixed streams
- shared frontend execute helpers
- shared SSE subscription cleanup

## Read Order

1. `domain/src/Domain.idr`
2. `domain/src/Domain/JSON.idr`
3. `backend/src/BackendMain.idr`
4. `frontend/src/FrontendMain.idr`
5. `scripts/smoke.sh`

## Build And Run

```sh
./scripts/build.sh
./scripts/run.sh --port 3000
./scripts/smoke.sh --port 3011
```

Then open `http://127.0.0.1:3000/static/index.html`.

## What Stays Local

- domain-specific routing
- page-specific view/controller logic

## Note

This is not the recommended first web example.
