# emkit-backend

Shared backend adapters for event-oriented web applications.

## Provides

- shared memory/file backend app shell for `ReaderT (StoreAppEnv ev) IO`
- SSE replay plus live subscription helpers for stream-backed applications
- mapped SSE replay plus live subscription helpers for stored-event applications

## Dependency Rule

This package stays transport-framework specific to the backend boundary, but route naming and application policy remain app-local.
