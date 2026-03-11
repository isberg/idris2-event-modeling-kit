# project-tasks-web

## What It Teaches

This is the main reference app in the repo.

It teaches:
- multi-category domain split
- aggregate-local events with an app-local stored-event wrapper
- project overview plus project-scoped task feeds
- Automation Pattern
- two Translation Pattern shapes
- local routing after translation

## Read Order

1. `domain/src/Domain/Project.idr`
2. `domain/src/Domain/Task.idr`
3. `domain/src/Domain/Automation.idr`
4. `domain/src/Domain/Translation.idr`
5. `domain/src/Domain/Routing.idr`
6. `domain/src/Domain/Screens.idr`
7. `backend/src/BackendMain.idr`
8. `frontend/src/Frontend/State.idr`
9. `frontend/src/Frontend/Update.idr`
10. `frontend/src/Frontend/View.idr`
11. `scripts/smoke.sh`

## Build And Run

```sh
./scripts/build.sh
./scripts/run.sh --port 3000
./scripts/smoke.sh --port 3016
./scripts/smoke.sh --port 3017 --skip-build --file-store "$(mktemp -d)"
```

Then open `http://127.0.0.1:3000/static/index.html`.

## What Stays Local

- app routing after translation
- automation trigger policy
- stored-event wrapper type
- frontend page-state composition

## Note

This is not the first example to read. Read `counter-console`, then `counter-web`, then `todo-web` first.
