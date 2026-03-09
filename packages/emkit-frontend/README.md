# emkit-frontend

Shared frontend adapters for event-oriented web applications.

## Provides

- browser EventSource lifecycle helpers
- client id generation helper for SSE subscriptions

## Dependency Rule

This package stays browser-facing and route-neutral. Higher-level execute and stream helpers remain deferred until more local examples need them.
