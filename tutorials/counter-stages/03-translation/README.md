# 03-translation

This slice adds the Translation pattern.

The console now accepts boundary-shaped external signals and translates them into internal commands before execution.

Read order:
1. `src/Domain.idr`
2. `src/Main.idr`
3. `scripts/smoke.sh`

Build and smoke:

```sh
pack build
./scripts/smoke.sh
```
