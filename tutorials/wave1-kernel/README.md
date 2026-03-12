# wave1-kernel

This tutorial is the narrow downstream consumer for the proposed first pack-db release wave.

It depends only on:
- `emkit-sourcing`
- `emkit-stream`
- `emkit-modeling`
- `emkit-wire`

It intentionally avoids:
- `emkit-runtime`
- `emkit-store`
- `emkit-backend`
- `emkit-frontend`

The purpose is to prove that the first public `emkit` kernel already makes sense on its own.

Read order:
1. `src/Domain.idr`
2. `src/Domain/JSON/Simple.idr`
3. `src/Main.idr`
4. `scripts/smoke.sh`

Build and smoke:

```sh
pack build
./scripts/smoke.sh
```
