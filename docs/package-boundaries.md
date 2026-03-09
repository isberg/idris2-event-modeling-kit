# Package Boundaries

The package split in this repository is intentionally narrow.

`emkit-sourcing` owns the pure event-sourcing algebra:

- `History`
- `Projection`
- `Decider`

It must stay dependency-light and should depend on `base` only unless there is a compelling reason to change that.

`emkit-modeling` owns Event Modeling runtime contracts:

- command/state change helpers,
- state-view helpers,
- automation and translation helpers,
- screen contracts and action contracts,
- traceability links.

It may depend on `emkit-sourcing`, but not on storage or web-adapter packages.

`emkit-runtime` owns application runtime composition helpers:

- load stream history as empty when a stream does not exist,
- execute deciders against store-backed stream histories,
- project views from stored stream histories.

It may depend on `emkit-sourcing`, `emkit-modeling`, and `emkit-store`, but it must remain transport-neutral and framework-neutral.

`emkit-stream` owns transport-neutral live-stream helpers:

- stream version/cursor helpers,
- SSE text framing helpers.

It should remain framework-neutral. It must not encode app-specific route naming, audience filtering, or DTO mapping rules.

`emkit-wire` owns shared transport contracts:

- execute payload contracts,
- stream event envelopes,
- multiplexed stream event envelopes,
- resync payloads.

It should remain contract-focused. Domain route naming, JSON codec policy, and transport-framework integration should not be added until repeated use proves the right public shape.

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

After `examples/counter-web`, two more seams are now concrete but still intentionally local:

- backend SSE subscription/replay glue (`examples/counter-web/backend/src/BackendSSE.idr`)
- frontend EventSource lifecycle glue (`examples/counter-web/frontend/src/FrontendSSE.idr`)

They should become shared packages only after at least one more web example confirms that their current shape is stable.
