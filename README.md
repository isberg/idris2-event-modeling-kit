# idris2-event-modeling-kit

Reusable Idris2 packages for building event-modeled, event-sourced, SSE-first applications.

This repository is not an application. It is a package workspace intended to shorten the path from idea to running system by providing stable shared contracts and helpers.

## Current Packages

- `emkit-sourcing`
  Pure history, projection, and decider algebra.
- `emkit-modeling`
  Event Modeling pattern helpers, screen contracts, and traceability helpers.
- `emkit-runtime`
  Shared application runtime bridge for store-backed command execution and view projection.
- `emkit-stream`
  Stream version/cursor helpers and transport-neutral SSE framing helpers.
- `emkit-store`
  Persistence contracts plus memory/file adapters for event streams.
- `emkit-wire`
  Shared transport contracts plus JSON codecs for execute, stream, and resync payloads.
- `emkit-backend`
  Shared backend SSE replay/live adapter helpers.
- `emkit-frontend`
  Shared frontend EventSource lifecycle helpers, typed execute/resync helpers, and minimal multi-stream subscribe helpers.

## Examples

- `examples/counter-console`
  Small console application that proves the current package stack and the first `emkit-runtime` extraction.
- `examples/counter-web`
  Small SSE-first web application with one fixed stream and one screen. It proves shared backend/frontend SSE helpers while keeping its app-specific command API and snapshot logic local.
- `examples/counter-web-multi`
  Multi-stream SSE-first web application with typed execute and resync payloads. It proves the wire codecs, shared frontend execute/subscribe helpers, and the multi-stream cleanup fix in the shared backend SSE adapter.

## Quickstart

Build a package from its package directory:

    cd packages/emkit-sourcing
    pack build

    cd ../emkit-modeling
    pack build

    cd ../emkit-runtime
    pack build

    cd ../emkit-stream
    pack build

    cd ../emkit-store
    pack build

    cd ../emkit-wire
    pack build

    cd ../emkit-backend
    pack build

    cd ../emkit-frontend
    pack build

Build and smoke the first example:

    cd examples/counter-console
    pack build
    ./scripts/smoke.sh

Build and smoke the web examples:

    cd examples/counter-web
    ./scripts/build.sh
    ./scripts/smoke.sh --port 3010

    cd ../counter-web-multi
    ./scripts/build.sh
    ./scripts/smoke.sh --port 3011

## Repository Rule

Application policy stays out of shared packages. Audience filtering, route naming, DTO mapping, and domain-specific automation remain app-local unless repeated evidence justifies extraction.

The current `counter-web` example intentionally keeps its app-specific command API and snapshot DTO mapping local. The current `counter-web-multi` example intentionally keeps its domain routing and page-specific view/controller logic local. Shared packages should only absorb behavior that is proven by more than one example or that sits below domain policy boundaries.
