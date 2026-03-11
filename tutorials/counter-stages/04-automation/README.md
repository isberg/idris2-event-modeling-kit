# 04-automation

This slice adds the Automation pattern.

When the counter reaches 3, an automation policy issues a `Reset` command and the counter returns to zero.

Read order:
1. `src/Domain.idr`
2. `src/Main.idr`
3. `scripts/smoke.sh`

Build and smoke:

```sh
pack build
./scripts/smoke.sh
```
