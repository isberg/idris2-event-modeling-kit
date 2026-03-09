# idris2-event-modeling-kit

Reusable Idris2 packages for building event-modeled, event-sourced, SSE-first applications.

This repository is not an application. It is a package workspace intended to shorten the path from idea to running system by providing stable shared contracts and helpers.

## Current Packages

- `emkit-sourcing`
  Pure history, projection, and decider algebra.
- `emkit-modeling`
  Event Modeling pattern helpers, screen contracts, and traceability helpers.
- `emkit-stream`
  Stream version/cursor helpers and transport-neutral SSE framing helpers.
- `emkit-wire`
  Shared transport contracts for execute, stream, and resync payloads.

## Planned Packages

- `emkit-store`
  Generic event-store interfaces and adapters.

## Quickstart

Build a package from its package directory:

    cd packages/emkit-sourcing
    pack build

    cd ../emkit-modeling
    pack build

    cd ../emkit-stream
    pack build

    cd ../emkit-wire
    pack build

## Repository Rule

Application policy stays out of shared packages. Audience filtering, route naming, DTO mapping, and domain-specific automation remain app-local unless repeated evidence justifies extraction.
