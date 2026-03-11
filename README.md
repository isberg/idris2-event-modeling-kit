# idris2-event-modeling-kit

Reusable Idris2 packages for building event-modeled, event-sourced, SSE-first applications.

This repository is not an application. It is a package workspace intended to shorten the path from idea to running system by providing stable shared contracts and helpers.

## Current Packages

- `emkit-sourcing`
  Pure history, projection, and decider algebra.
- `emkit-modeling`
  Event Modeling pattern helpers, screen contracts, and traceability helpers.
- `emkit-runtime`
  Shared application runtime bridge for store-backed command execution, mapped stored-event execution, model projection, and overview-query summary listing.
- `emkit-stream`
  Stream version/cursor helpers, version-aware projection safety helpers, and transport-neutral SSE framing helpers.
- `emkit-store`
  Persistence contracts plus memory/file adapters for event streams.
- `emkit-wire`
  Shared transport contracts plus JSON codecs for execute, stream, and resync payloads.
- `emkit-backend`
  Shared backend store-app shell plus SSE replay/live adapter helpers, including mapped per-stream replay/live subscriptions and mapped live category-feed subscriptions.
- `emkit-frontend`
  Shared frontend EventSource lifecycle helpers, typed execute/resync helpers, minimal stream subscribe helpers, and small client-id-gated open/close lifecycle helpers.

## Examples

- `examples/counter-console`
  Small console application that proves the current package stack and the first `emkit-runtime` extraction.
- `examples/counter-web`
  Small SSE-first web application with one fixed stream and one screen. It proves shared backend/frontend SSE helpers while keeping its app-specific command API and snapshot logic local.
- `examples/counter-web-multi`
  Multi-stream SSE-first web application with typed execute and resync payloads. It proves the wire codecs, shared frontend execute/subscribe helpers, and the multi-stream cleanup fix in the shared backend SSE adapter.
- `examples/todo-web`
  Multi-screen SSE-first web application with dynamic per-list streams, a category overview feed, per-stream detail feeds, typed execute/resync payloads, and both memory/file store smoke paths. It now uses the shared backend store-app shell. It pressure-tests stream catalog usage, screen switching, and the split between overview and detail subscriptions.
- `examples/counters-web`
  Multi-screen SSE-first web application with dynamic per-counter streams, a category overview feed, per-stream detail feeds, typed execute/resync payloads, and both memory/file store smoke paths. It now uses the shared backend store-app shell and the shared backend category-feed helper.
- `examples/project-tasks-web`
  Multi-category SSE-first web application with `project-*` and `task-*` streams, aggregate-local project/task events, neutral aggregate-local `ProjectModel` and `TaskModel` folds, an app-local stored-event wrapper, a project overview feed, project-scoped task category feeds, per-project and per-task detail feeds, typed execute/resync payloads, and both memory/file store smoke paths. It now uses the shared backend store-app shell and shared mapped stored-event helpers for execute, summary queries, and SSE replay/live subscriptions. It includes a first Automation Pattern slice, where all-done task state triggers `CompleteProject`, and a Translation Pattern slice with an explicit boundary split: pure signal-to-intent translation, separate routing/context resolution, and task-legality kept in the task decider.

## Notes

- `docs/package-boundaries.md`
  Current package ownership and extraction boundaries.
- `docs/sse-feed-boundaries.md`
  Current stance on per-stream feeds, category feeds, replay semantics, and client-side projection safety.

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

    cd ../todo-web
    ./scripts/build.sh
    ./scripts/smoke.sh --port 3012
    ./scripts/smoke.sh --port 3013 --skip-build --file-store "$(mktemp -d)"

    cd ../counters-web
    ./scripts/build.sh
    ./scripts/smoke.sh --port 3014
    ./scripts/smoke.sh --port 3015 --skip-build --file-store "$(mktemp -d)"

    cd ../project-tasks-web
    ./scripts/build.sh
    ./scripts/smoke.sh --port 3016
    ./scripts/smoke.sh --port 3017 --skip-build --file-store "$(mktemp -d)"

## Repository Rule

Application policy stays out of shared packages. Audience filtering, route naming, DTO mapping, and domain-specific automation remain app-local unless repeated evidence justifies extraction.

The current `counter-web` example intentionally keeps its app-specific command API and snapshot DTO mapping local. The current `counter-web-multi` example intentionally keeps its domain routing and page-specific view/controller logic local. The current `todo-web`, `counters-web`, and `project-tasks-web` examples intentionally keep their route naming, overview/detail page composition, dynamic stream naming policy, and app-specific automation or translation policy local. Shared packages should only absorb behavior that is proven by more than one example or that sits below domain policy boundaries.
