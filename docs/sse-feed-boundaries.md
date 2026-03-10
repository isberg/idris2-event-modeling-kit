# SSE Feed Boundaries

This note records the current design stance for Server-Sent Events (SSE) in this repository after building and validating `counter-web`, `counter-web-multi`, `todo-web`, and `counters-web`.

## Source of Truth

The source of truth is the persisted event streams in the event store.

SSE feeds are transport views over those streams. They are not themselves the source of truth.

That means:

- replay and resync must ultimately be defined in terms of persisted events,
- client state must be recoverable from persisted events,
- SSE may be used as the fast path, but not as the only path.

## Two Feed Shapes

There are two feed shapes we currently consider first-class.

### 1. Per-stream feed

Use one SSE feed for one real event stream when the client needs exact stream semantics.

Typical use:

- aggregate detail screens,
- one-stream replay/resume,
- exact `Last-Event-ID` behavior,
- precise `id = stream version` alignment.

This is the cleanest shape for:

- detail views,
- operator/debug views,
- any client state that must track one stream exactly.

### 2. Category or per-view feed

Use one SSE feed that forwards events from many streams when the screen is fundamentally cross-stream.

Typical use:

- overview screens,
- cross-stream dashboards,
- list pages,
- category projections.

This feed is a transport contract for that view. It is not the same thing as any individual aggregate stream.

## Duplicate Delivery Across Feeds

It is acceptable for the same underlying event to appear on more than one SSE feed.

Examples:

- one per-stream detail feed,
- one overview category feed,
- one future dashboard feed.

That duplication is not a design flaw by itself.

It becomes a problem only if the client treats those feeds as if they were the same cursor or the same projection contract.

## Cursor Semantics

Per-stream feeds may use:

- `SSE id = stream version`

when the feed is truly the stream.

Category or per-view feeds must not pretend to have the same replay semantics as a real aggregate stream unless the server can actually reproduce that feed with a stable cursor model.

Current rule:

- per-stream feed: replay/resume is expected,
- category/per-view feed: live-first is acceptable,
- query/resync remains the recovery path for cross-stream views.

## Client Responsibilities

When a client consumes more than one feed that can affect the same local view, the local view must be version-aware.

This was proven by the `counters-web` bug where:

- the overview view was updated from the category feed,
- the same entity was also updated through detail resync/detail live updates,
- stale or out-of-order updates could corrupt the local overview summary.

Current rule:

- local summaries that can be advanced by live events must carry stream version,
- stale events must be ignored,
- gaps must trigger query/resync rather than blind projection.

## Should The Client Subscribe To All Streams?

Not by default.

Client-side subscribe-all is acceptable only for:

- tiny local demos,
- diagnostics,
- deliberate experiments.

It is not the recommended default for real app architecture because it pushes too much responsibility into every client:

- stream discovery,
- filtering,
- authorization scope,
- transport cost,
- projection policy,
- replay semantics.

The default should be:

- server-provided per-view/category feeds for cross-stream screens,
- per-stream feeds for exact detail screens.

## Current Repository Stance

The current preferred shape is:

- event store streams remain the truth,
- per-stream SSE feeds serve detail screens,
- server-provided category/per-view SSE feeds serve overview screens,
- query/resync remains the safety path,
- each feed is treated as its own contract.

That means a view may legitimately depend on:

- one category feed,
- one detail feed,
- one query/resync path,

as long as the client state model is explicit about versioning and recovery.

## Consequence For Shared Packages

What is justified as shared today:

- per-stream SSE helper,
- category-feed SSE helper,
- execute/resync wire contracts,
- replay/resume support for real streams.

What is not yet justified as shared:

- a universal web-app shell,
- one standard navigation/controller model,
- a one-size-fits-all policy for overview/detail composition.

Those remain app-local until another example proves a stable common shape.
