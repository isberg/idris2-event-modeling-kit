# Pattern Map

This document maps the Event Modeling patterns and the main glue layers to concrete files in this repository.

## Command / State Change Pattern

Meaning:
- a command is validated against current aggregate state
- accepted commands emit events
- rejected commands return a rejection

Shared abstraction:
- `packages/emkit-sourcing/src/EmKit/Sourcing/Decider.idr`

Best first example:
- `examples/counter-console/src/Domain.idr`

Richer examples:
- `examples/todo-web/domain/src/Domain.idr`
- `examples/project-tasks-web/domain/src/Domain/Project.idr`
- `examples/project-tasks-web/domain/src/Domain/Task.idr`

## View Pattern

Meaning:
- events are folded into a read model or policy model

Shared abstraction:
- `packages/emkit-sourcing/src/EmKit/Sourcing/Projection.idr`

Best first example:
- `examples/counter-console/src/Domain.idr`

Richer examples:
- `examples/todo-web/domain/src/Domain.idr`
- `examples/counters-web/domain/src/Domain.idr`
- `examples/project-tasks-web/domain/src/Domain/Project.idr`
- `examples/project-tasks-web/domain/src/Domain/Task.idr`

## Automation Pattern

Meaning:
- events update a view
- a policy evaluates the updated view
- the system may issue an automated command

Shared helper:
- `packages/emkit-modeling/src/EmKit/Modeling/Pattern/Automation.idr`

Current example:
- `examples/project-tasks-web/domain/src/Domain/Automation.idr`
- backend execution glue in `examples/project-tasks-web/backend/src/BackendMain.idr`

Note:
- the policy is still app-local
- shared packages do not yet own automation idempotency or policy-loop infrastructure

## Translation Pattern

Meaning:
- external or boundary-shaped signals are translated into internal intents or commands

Shared helper:
- `packages/emkit-modeling/src/EmKit/Modeling/Pattern/Translation.idr`

Current examples:
- pure boundary translation in `examples/project-tasks-web/domain/src/Domain/Translation.idr`
- routing after translation in `examples/project-tasks-web/domain/src/Domain/Routing.idr`
- backend composition in `examples/project-tasks-web/backend/src/BackendMain.idr`

Two routing shapes are now present:
1. context-based routing for task creation
2. direct routing for task actions on an existing task stream

## Screen Glue

Meaning:
- expose data and actions for a screen or page
- connect UI actions to app intents

Shared contracts:
- `packages/emkit-modeling/src/EmKit/Modeling/Screen/Contracts.idr`
- `packages/emkit-modeling/src/EmKit/Modeling/Screen/Actions.idr`

Examples:
- `examples/counter-console/src/Domain.idr`
- `examples/project-tasks-web/domain/src/Domain/Screens.idr`

## Store and Runtime Glue

Meaning:
- load stream histories
- execute deciders against store-backed histories
- query projected summaries

Shared packages:
- `packages/emkit-store/src/EmKit/Store/Core.idr`
- `packages/emkit-runtime/src/EmKit/Runtime/Execute.idr`
- `packages/emkit-runtime/src/EmKit/Runtime/Query.idr`

Examples:
- `examples/todo-web/backend/src/BackendMain.idr`
- `examples/counters-web/backend/src/BackendMain.idr`
- `examples/project-tasks-web/backend/src/BackendMain.idr`

## SSE and Web Glue

Meaning:
- replay and live feed endpoints
- typed execute/resync payloads
- frontend EventSource lifecycle

Shared packages:
- `packages/emkit-wire/src/EmKit/Wire/Contracts.idr`
- `packages/emkit-backend/src/EmKit/Backend/SSE.idr`
- `packages/emkit-backend/src/EmKit/Backend/StoreApp.idr`
- `packages/emkit-frontend/src/EmKit/Frontend/SSE.idr`
- `packages/emkit-frontend/src/EmKit/Frontend/Execute.idr`
- `packages/emkit-frontend/src/EmKit/Frontend/Stream.idr`

Best examples:
- `examples/counter-web`
- `examples/todo-web`
- `examples/project-tasks-web`

## Routing Glue

Meaning:
- choose target stream/category after translation or before execution
- keep routing concerns out of aggregate deciders

Current examples:
- `examples/project-tasks-web/domain/src/Domain/Routing.idr`
- `examples/project-tasks-web/backend/src/BackendMain.idr`

Note:
- routing is still intentionally app-local
- the repo does not yet define a shared routing abstraction
