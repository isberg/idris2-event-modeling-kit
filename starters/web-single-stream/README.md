# web-single-stream starter

## Purpose

This is the narrowest web starter in the repo.

It is meant to be copied when you want:
- one fixed stream
- one screen
- typed `ExecutePayload`, `StreamEvent`, and `ResyncPayload`
- SSE replay and live updates
- memory mode by default with optional file-store mode

It intentionally uses a tiny counter domain so the domain does not compete with the wiring.
There is no `Create`, no extra read model endpoint shape, and no arbitrary business rule like a maximum value.
The expected workflow is:
1. copy this directory,
2. rename the package names and modules,
3. replace the domain types and routes,
4. keep the shared `emkit` wiring shape unless you have evidence to change it.

## What It Teaches

- smallest current backend/frontend/store shape for a web app
- single-stream event-sourced execution
- fixed-stream SSE feed with `Last-Event-ID` replay
- client-side resync plus live projection updates
- screen/action glue without category or navigation complexity

## Read Order

1. `domain/src/Domain.idr`
2. `backend/src/BackendMain.idr`
3. `frontend/src/FrontendMain.idr`
4. `scripts/smoke.sh`

## Build And Run

```sh
./scripts/build.sh
./scripts/run.sh --port 3000
./scripts/smoke.sh --port 3048
./scripts/smoke.sh --port 3049 --skip-build --file-store "$(mktemp -d)"
```

Then open `http://127.0.0.1:3000/static/index.html`.

## What Is Intentionally Fixed Here

- one stream id: `counter-main`
- one screen
- one per-stream SSE feed
- one resync endpoint
- one execute endpoint
- only two commands: `Increment` and `Decrement`

## Expected First Extensions

1. Replace the counter domain with your own command/event/model types.
2. Add a query endpoint only if the UI needs something beyond resync plus live events.
3. Add translation or automation only after the basic execute/resync/feed loop is stable.
