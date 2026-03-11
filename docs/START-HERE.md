# Start Here

This repository has three different entry paths, depending on what you are trying to do.

## 1. Learn The Core Pattern Stack

Start here if you want to understand the Event Modeling patterns and the shared `emkit-*` packages before copying anything.

Recommended order:

1. `docs/getting-started.md`
2. `tutorials/counter-stages/README.md`
3. `examples/counter-console/README.md`
4. `examples/counter-web/README.md`
5. `examples/project-tasks-web/README.md`

## 2. Build A New App Quickly

Start here if you want a narrow copy target.

1. `starters/web-single-stream/README.md`
2. `starters/web-single-stream/COPYING.md`
3. `starters/web-single-stream/POST_COPY_CHECKLIST.md`

If you want the mechanical rename layer handled for you, use:

```bash
cd starters/web-single-stream
./scripts/copy-starter.sh /tmp/my-app my-app --title "My App"
```

## 3. Evaluate Release Readiness

Start here if you want to understand whether the workspace is ready for public publication or pack-db submission.

1. `docs/publishing.md`
2. `docs/package-readiness.md`
3. `scripts/verify-release.sh`

## Recommended First Technical Read

If you only read one example first, use:
- `examples/counter-console`

If you only read one web example first, use:
- `examples/counter-web`

If you want the full pattern map in one app, use:
- `examples/project-tasks-web`
