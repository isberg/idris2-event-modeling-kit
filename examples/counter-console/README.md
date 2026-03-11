# counter-console

## What It Teaches

This is the smallest complete application in the repo.

It teaches:
- aggregate-local `Projection`
- aggregate-local `Decider`
- screen/action glue in a console app
- thin runtime shell around the pure domain

## Read Order

1. `src/Domain.idr`
2. `src/Main.idr`
3. `scripts/smoke.sh`

## Build And Run

```sh
pack build
node build/exec/counter-console_app/counter-console_app
./scripts/smoke.sh
```

## What Stays Local

- console rendering
- prompt loop
- command parsing
