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
