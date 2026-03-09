# emkit-runtime

Runtime helpers for applications built on `emkit`.

## Canonical Modules

- `EmKit.Runtime.Execute`

## Boundary Rule

`emkit-runtime` owns the small bridge between storage and domain execution:

- load stream history as empty when no stream exists,
- hydrate state from stored events,
- run a decider against the current state,
- append produced events,
- project a view from stored history.

It does not own:

- HTTP routes,
- browser clients,
- SSE subscriber registries,
- domain stream routing,
- persisted event envelopes.

Those concerns belong either in applications or in future backend/frontend packages.
