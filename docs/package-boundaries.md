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


`emkit-backend` owns shared backend web adapters:

- SSE replay plus live subscription helpers,
- per-stream subscription cleanup discipline.

It may depend on `emkit-store` and `emkit-stream`, but it must not own route naming, auth, or domain-specific DTO policy.

`emkit-frontend` owns shared frontend web adapters:

- browser EventSource lifecycle helpers,
- client id generation for live subscriptions.

It should remain route-neutral. Higher-level execute or stream controller helpers should be added only when more than one local example truly needs them.

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

- higher-level execute helpers
- higher-level stream endpoint/controller helpers

The low-level SSE seam is now shared in `emkit-backend` and `emkit-frontend`. The next likely extraction candidates are typed frontend execute helpers and route-neutral stream endpoint helpers, but they remain deferred until another web example or a refactor of `counter-web` confirms the public shape.
