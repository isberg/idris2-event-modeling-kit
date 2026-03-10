# Package Boundaries

The package split in this repository is intentionally narrow.

`emkit-sourcing` owns the pure event-sourcing algebra:

- `History`
- `Projection`
- `Decider`

It must stay dependency-light and should depend on `base` only unless there is a compelling reason to change that.

`emkit-modeling` owns Event Modeling runtime contracts:

- command/state change helpers,
- automation and translation helpers,
- screen contracts and action contracts,
- traceability links.

It may depend on `emkit-sourcing`, but not on storage or web-adapter packages.

The Event Modeling View pattern is expressed in code via `Projection` from `emkit-sourcing`. `emkit-modeling` does not own a second fold interface for that pattern.

`emkit-runtime` owns application runtime composition helpers:

- load stream history as empty when a stream does not exist,
- execute deciders against store-backed stream histories,
- project models from stored stream histories,
- list projected summaries across stream catalogs for overview queries.

It may depend on `emkit-sourcing`, `emkit-modeling`, and `emkit-store`, but it must remain transport-neutral and framework-neutral.

`emkit-stream` owns transport-neutral live-stream helpers:

- stream version/cursor helpers,
- version-aware projection safety helpers,
- SSE text framing helpers.

It should remain framework-neutral. It must not encode app-specific route naming, audience filtering, or DTO mapping rules.

`emkit-wire` owns shared transport contracts:

- execute payload contracts,
- stream event envelopes,
- multiplexed stream event envelopes,
- resync payloads.

It should remain contract-focused. Domain route naming, JSON codec policy, and transport-framework integration should not be added until repeated use proves the right public shape.


`emkit-backend` owns shared backend web adapters:

- SSE replay plus live subscription helpers,
- live category-feed subscription helpers,
- per-stream subscription cleanup discipline.

It may depend on `emkit-store` and `emkit-stream`, but it must not own route naming, auth, or domain-specific DTO policy.

`emkit-frontend` owns shared frontend web adapters:

- browser EventSource lifecycle helpers,
- client id generation for live subscriptions.
- typed execute and resync request helpers,
- minimal multi-stream subscribe helpers.

It should remain route-neutral. Higher-level stream controllers, page navigation helpers, and domain-specific retry policy should be added only when more than one local example truly needs them.

`emkit-store` owns persistence contracts and basic adapters:

- stream load/append contracts,
- stream listing contract,
- stream/category subscription contracts,
- in-memory store adapter,
- file-backed store adapter.

It must not own domain routing, event envelopes, command execution, or transport DTOs.

The following concerns remain app-local unless extraction evidence becomes strong enough:

- route names,
- auth and audience filtering,
- domain-specific live event DTOs,
- screen catalogs and projection bundles,
- automation policy rules.

After `examples/counter-web-multi`, two seams remain intentionally local:

- command route conventions for app-specific APIs
- higher-level stream endpoint/controller helpers with unsubscribe or stream switching semantics

The low-level SSE seam, typed execute/resync helpers, and minimal subscribe helpers are now shared in `emkit-backend` and `emkit-frontend`. Richer stream lifecycle helpers still remain deferred until another example proves unsubscribe or stream-switching behavior without app-local assumptions.

After `examples/todo-web`, the following additional seams are now clearer but still intentionally local:

- overview-versus-detail subscription policy for multi-screen apps
- dynamic stream id generation and navigation policy
- page/controller composition for screen catalogs that mix category feeds with per-stream detail feeds

`todo-web` proves that the shared backend/frontend layers are sufficient for:

- one category-wide SSE feed,
- one per-stream SSE feed with resume via `Last-Event-ID`,
- typed execute and resync requests,
- memory and file-store execution with restart persistence.

After auditing `counter-web`, `counter-web-multi`, `todo-web`, and `counters-web`, one more repeated backend seam is now shared in `emkit-runtime`:

- stream-catalog backed projected summary listing for overview queries

This keeps route naming and endpoint layout local, but removes the repeated “list streams, load histories, project summaries, keep existing ones” block from multi-stream web backends.

After `examples/counters-web`, one more backend seam is now proven enough to share:

- a live category-feed subscription helper with cleanup registration

That helper now lives in `emkit-backend` alongside the per-stream SSE helper.

Even after `todo-web` plus `counters-web`, a higher-level web app shell is still not justified. The following seams remain too application-shaped:

- route naming and endpoint layout,
- screen-specific controller state,
- navigation policy,
- dynamic stream-id generation policy,
- overview/detail page rendering.

The next extraction should therefore happen only if another example repeats one of those seams with materially similar behavior.

After the `todo-web` and `counters-web` version-drift fix, one more low-level seam is now shared in `emkit-stream`:

- stale/duplicate versus exact-next versus gap handling for versioned projection updates

The package still does not own domain-specific projection rules. It owns only the cursor law that those projections depend on.

After `examples/project-tasks-web`, the current shared stack is now also proven against a small multi-category app:

- one category-wide overview feed for `project-*`,
- one project-scoped category feed over `task-*`,
- one per-stream task detail feed with replay/resume,
- separate aggregate deciders over aggregate-local event types,
- one app-local stored-event wrapper for the single event store.

That run did not justify a new shared extraction on its own. It did confirm three structural choices:

- split the domain by category early when there are multiple aggregates,
- keep aggregate-local `Decider` and `Projection` instances on aggregate-local event types,
- keep backend and frontend consolidated until repeated cross-category ceremony becomes clearer than the domain policy.

The same run also proved one first automation slice without introducing a background worker:

- task events update projected task summaries for a project,
- a pure policy evaluates project detail plus projected task state,
- the backend may issue `CompleteProject` automatically.

That automation policy remains intentionally app-local. The shared packages still do not own cross-category policy loops, command routing policy, or automation idempotency strategy.
