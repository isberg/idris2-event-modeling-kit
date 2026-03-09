# emkit-store

Persistence contracts and basic adapters for event streams.

## Canonical Modules

- `EmKit.Store.Core`
- `EmKit.Store.Memory`
- `EmKit.Store.File`

## Boundary Rule

`emkit-store` is infrastructure-only. It owns load/append/list/subscribe behavior for persisted streams and categories.

It does not own:

- domain routing,
- event envelopes,
- command execution,
- screen definitions,
- transport DTOs.

Those belong in application code or other packages such as `emkit-modeling`, `emkit-stream`, and `emkit-wire`.
