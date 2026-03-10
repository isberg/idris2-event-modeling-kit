# emkit-frontend

Shared frontend adapters for event-oriented web applications.

## Provides

- browser EventSource lifecycle helpers
- client id generation helper for SSE subscriptions
- typed execute and resync request helpers
- minimal stream subscribe/close helpers
- small stream lifecycle helpers for "close current if open" and "open when a client id is available"

## Dependency Rule

This package stays browser-facing and route-neutral. It may own the small lifecycle control flow that repeats across examples, but richer page controllers, route naming, and app-specific retry policy remain local.
