# Getting Started

For a fast repository overview, start with `docs/START-HERE.md`.


This repository is a package workspace plus a set of examples.

If you are new to `emkit`, do not start by reading every package. Start by reading one small example end to end.

## Recommended Order

### Human path
1. `tutorials/counter-stages/01-state-change`
2. `tutorials/counter-stages/02-view`
3. `tutorials/counter-stages/03-translation`
4. `tutorials/counter-stages/04-automation`
5. `examples/counter-console`
6. `examples/counter-web`
7. `starters/web-single-stream`
8. `examples/todo-web`
9. `examples/project-tasks-web`

### AI path
1. Read `README.md`
2. Read `docs/pattern-map.md`
3. Read the README of the target example
4. Open only the files listed in that example README
5. Use `docs/package-boundaries.md` only when deciding whether code belongs in a shared package or stays app-local

## First Example

Start with `tutorials/counter-stages` if you want the same app to grow pattern by pattern. Start with `examples/counter-console` if you want the smallest existing reference example.

Why:
- smallest full application in the repo
- pure domain plus a thin app shell
- easiest place to understand `Projection`, `Decider`, and screen/action glue

Read in this order:
1. `examples/counter-console/README.md`
2. `examples/counter-console/src/Domain.idr`
3. `examples/counter-console/src/Main.idr`
4. `examples/counter-console/scripts/smoke.sh`

## First Web Example

Then move to `examples/counter-web`.

Why:
- same small domain shape
- adds backend, frontend, and SSE without dynamic stream complexity

Read in this order:
1. `examples/counter-web/README.md`
2. `examples/counter-web/domain/src/Domain.idr`
3. `examples/counter-web/backend/src/BackendMain.idr`
4. `examples/counter-web/frontend/src/FrontendMain.idr`
5. `examples/counter-web/scripts/smoke.sh`

## First Copy Target

After `examples/counter-web`, read `starters/web-single-stream`.

Why:
- same single-stream web shape, but reduced to the stable current defaults
- typed execute, resync, and stream-event payloads
- fixed stream id so the routing surface stays trivial
- intended to be copied and renamed for a first real app
- supports both:
  - manual copy with `COPYING.md`
  - scripted copy with `scripts/copy-starter.sh`
  - controlled domain replacement with `POST_COPY_CHECKLIST.md`

Read in this order:
1. `starters/web-single-stream/README.md`
2. `starters/web-single-stream/COPYING.md`
3. `starters/web-single-stream/POST_COPY_CHECKLIST.md`
4. `starters/web-single-stream/domain/src/Domain.idr`
5. `starters/web-single-stream/backend/src/BackendMain.idr`
6. `starters/web-single-stream/frontend/src/FrontendMain.idr`
7. `starters/web-single-stream/scripts/smoke.sh`

## Web Progression

After `counter-web`, the suggested progression is:

1. `examples/todo-web`
   - multi-screen
   - category overview feed plus per-stream detail feed
   - dynamic stream creation
2. `examples/project-tasks-web`
   - multi-category domain split
   - automation
   - translation plus routing
   - aggregate-local events with app-local stored-event wrapper

## Application Shape

A typical app in this repo is composed from these parts:

1. Domain
   - commands
   - events
   - projections
   - deciders
   - optional screens, automation, translation, routing
2. Backend
   - event store wiring
   - execute/resync/query endpoints
   - SSE feed endpoints
   - app-local routing and status mapping
3. Frontend or console shell
   - render read models
   - map actions/messages to command requests
   - maintain page or screen state
4. Scripts
   - build
   - run
   - smoke

## Packages To Learn First

In order:
1. `emkit-sourcing`
2. `emkit-modeling`
3. `emkit-runtime`
4. `emkit-store`
5. `emkit-wire`
6. `emkit-backend`
7. `emkit-frontend`
8. `emkit-stream`

This is learning order, not dependency order.

## What To Skip At First

Do not start with:
- `docs/package-boundaries.md`
- `examples/counter-web-multi`
- shared extraction questions

Those are useful after you already understand one complete example.
