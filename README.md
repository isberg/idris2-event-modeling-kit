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
  Shared transport contracts for execute, stream, and resync payloads.

## Planned Packages

- web-focused backend/frontend helper packages once the current runtime layer has been proven by more than one example.

## Examples

- `examples/counter-console`
  Small console application that proves the current package stack and the first `emkit-runtime` extraction.
- `examples/counter-web`
  Small SSE-first web application with one fixed stream and one screen. It proves the current backend/frontend seams before extracting shared web helper packages.

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

Build and smoke the first example:

    cd examples/counter-console
    pack build
    ./scripts/smoke.sh

Build and smoke the first web example:

    cd examples/counter-web
    ./scripts/build.sh
    ./scripts/smoke.sh

## Repository Rule

Application policy stays out of shared packages. Audience filtering, route naming, DTO mapping, and domain-specific automation remain app-local unless repeated evidence justifies extraction.

The current `counter-web` example intentionally keeps `BackendSSE` and `FrontendSSE` local. They are the first concrete candidates for future `emkit-backend` and `emkit-frontend` extraction, but they are not shared yet because this repo currently has only one proved web consumer.
