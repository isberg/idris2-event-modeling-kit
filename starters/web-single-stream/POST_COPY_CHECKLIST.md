# Post-Copy Checklist

Use this after the copied starter already builds and passes smoke once unchanged.

The goal is to replace the tiny starter domain without breaking the shared app shape all at once.

## Recommended Order

### 1. Freeze the wiring first

Before changing domain logic, make sure the copied app still works unchanged:

```sh
./scripts/build.sh
./scripts/smoke.sh --port 3000
./scripts/smoke.sh --port 3001 --skip-build --file-store "$(mktemp -d)"
```

If this is not green yet, do not start replacing domain files.

### 2. Replace `domain/src/Domain.idr`

Change these first:
- stream id constant
- command type
- rejection type
- event type
- projection model
- decider legality
- `renderRejection`
- `renderAction`
- screen actions if the visible actions changed

Keep these shapes if possible:
- one fixed stream
- one screen
- one projection model
- one detail/resync payload shape

### 3. Regenerate the domain JSON surface

Update these if type names changed:
- `domain/src/Domain/JSON.idr`
- `domain/src/Domain/JSON/Simple.idr`

The starter assumes these files derive JSON for:
- commands
- events
- model
- detail

### 4. Update backend semantics, not structure

Edit `backend/src/BackendMain.idr` only where the domain changed:
- route text if needed
- user-facing error text if needed
- stream id constant usage
- model/event type names

Avoid changing:
- store wiring
- SSE endpoint shape
- execute/resync endpoint structure
- `StoreAppEnv` setup

### 5. Update frontend labels and command calls

Edit `frontend/src/FrontendMain.idr`:
- visible titles and text
- action labels
- command constructors sent in `post...` helpers
- history rendering text
- route names if backend route text changed

Avoid changing:
- EventSource lifecycle
- resync flow
- optimistic expected-version flow
- general controller shape

### 6. Update smoke expectations

Edit `scripts/smoke.sh` last.

Update only after domain, backend, and frontend compile again.

Typical changes:
- command payload JSON
- expected event names
- rejection messages
- snapshot/view expectations
- page title text

### 7. Rebuild after each layer

Recommended cadence:

```sh
./scripts/build.sh
```

After the domain compiles, check backend. After backend compiles, check frontend. Only then update smoke.

### 8. Re-run full validation

```sh
./scripts/smoke.sh --port 3000
./scripts/smoke.sh --port 3001 --skip-build --file-store "$(mktemp -d)"
```

## Strong Recommendation

Do not redesign the app shell during the first domain replacement.

Keep the starter's:
- one fixed stream
- one screen
- one resync endpoint
- one execute endpoint
- one per-stream SSE feed

If you need more than that, get the copied app green first and evolve it after.
