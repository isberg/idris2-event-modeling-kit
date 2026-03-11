# Slice Contracts

This document explains how to build an `emkit` application pattern by pattern, and what must be agreed early if two people or two agents work on adjacent slices in parallel.

## Why This Exists

The repository already proves that small event-sourced applications can grow from a simple first slice into a richer multi-screen or multi-category application.

What is still easy to get wrong is not the code itself, but the boundaries between slices. If those boundaries move too late, parallel work creates churn in the domain, backend, and frontend at the same time.

This document describes the minimum contracts that should be frozen before the next slice starts.

## Suggested Slice Order

The current repository supports this progression well:

1. Command / State Change
2. View
3. Translation
4. Automation

That order matches the current example path:

1. `examples/counter-console`
2. `examples/counter-web`
3. `examples/todo-web`
4. `examples/project-tasks-web`

## Slice 1: Command / State Change

Goal:
- define commands
- define events
- define the aggregate-local fold
- define the decider
- run a minimal shell

Files typically touched:
- `domain/src/Domain.idr` in a small app
- or split domain files such as `Domain/Project.idr` and `Domain/Task.idr` in a larger app
- a thin shell such as `src/Main.idr` or `backend/src/BackendMain.idr`

Contract that should be frozen before Slice 2:
- command names
- event names
- aggregate stream naming rule
- event payload shape
- rejection names and meanings

Important note:
- in this repository, `Decider` depends on `Projection`
- that means Slice 1 already includes one aggregate-local projection
- this is not a separate View pattern slice yet; it is the internal fold required by the decider

## Slice 2: View

Goal:
- define the visible read model
- expose it through console rendering, query endpoints, or frontend state
- make the read side observable in the running app

Files typically touched:
- aggregate or overview projection code in `domain/src`
- shell files such as `src/Main.idr`, `backend/src/BackendMain.idr`, or `frontend/src/FrontendMain.idr`

Contract that should be frozen before parallel work:
- which events feed the view
- whether the view is single-stream or category-based
- summary/detail model names
- route or screen names that expose the view

Important note:
- aggregate-local state and visible read model can be the same model or different models
- use one neutral `Model` type when they evolve the same way
- split into separate `State` and `View` only when they materially diverge

## Slice 3: Translation

Goal:
- accept a boundary-shaped signal
- translate it into internal intent
- route that intent to a stream
- let the decider handle legality

Files typically touched:
- `domain/src/Domain/Translation.idr`
- optional app-local routing module such as `domain/src/Domain/Routing.idr`
- backend boundary endpoints

Contract that should be frozen before parallel work:
- boundary payload shape
- which translation failures are boundary errors
- which routing data is direct and which requires view lookup
- which legality checks stay in the decider

Important note:
- pure translation is not the same thing as routing
- keep `signal -> intent` pure where possible
- keep stream choice outside the decider

## Slice 4: Automation

Goal:
- update a policy view from events
- evaluate that policy
- issue automated commands when appropriate

Files typically touched:
- `domain/src/Domain/Automation.idr`
- backend execution loop or trigger points

Contract that should be frozen before parallel work:
- which events trigger policy evaluation
- which view feeds the policy
- which command may be emitted
- how duplicate issuance is prevented or tolerated

Important note:
- the current repo keeps automation policy app-local
- shared packages do not yet own policy-loop or idempotency strategy

## Parallel Work: First Two Slices

Two developers or two agents can work on the first two slices in parallel, but only if the contract is frozen first.

Recommended split:

- Developer A
  - commands
  - events
  - aggregate-local projection
  - decider

- Developer B
  - visible read model
  - query or screen shape
  - console or frontend rendering
  - backend read endpoints if needed

This works best when both sides agree on:
- event names
- event payloads
- stream naming
- summary/detail model names
- screen or route names

Main friction points:

1. Event shape churn
- if emitted events change, both the decider side and the view side need updates

2. Naming drift
- stream names, route names, and screen names leak into backend, frontend, and smoke scripts

3. Read model drift
- if the UI needs fields that events do not expose clearly, the domain side and view side have to renegotiate event shape or projection policy

## Parallel Work: Later Slices

Translation and automation can also be built in parallel with the earlier slices, but only after the domain contract is stable.

Recommended split:

- one developer owns the pure translation or policy module
- one developer owns backend composition, route wiring, and feed or trigger integration

This is more fragile than the first two slices, because:
- routing rules are still app-local
- backend status mapping is still app-local
- translation and automation touch both domain meaning and transport shape

## What To Freeze Early

Before parallel work, freeze these items in writing:

1. command names
2. event names
3. event payload fields
4. stream naming rules
5. category naming rules
6. visible summary/detail model names
7. route names and screen names
8. which errors are boundary errors versus decider rejections

If those eight items are still moving, parallel work will be expensive.

## What The Repo Is Good At Right Now

The current repo is good at:
- starting with a small working slice
- growing from state change to visible view
- adding translation after the core is stable
- adding automation once projections exist

The current repo is weaker at:
- teaching View in isolation before State Change
- giving a ready-made starter template
- enforcing parallel contracts automatically

## Current Recommendation

For a new app:

1. start with a tiny state-change slice
2. add one visible view
3. freeze contracts
4. then split work in parallel if needed

This is the path with the least churn in the current repository.
