# Publishing emkit

This document tracks the minimum release hygiene expected before:

1. making `idris2-event-modeling-kit` public on GitHub
2. submitting `emkit-*` packages to `idris2-pack-db`

## Current Status

The workspace is close on architecture and examples, but not fully publication-ready yet.

License choice completed:
- top-level `LICENSE` added as `MIT`

Current non-legal hardening completed in this slice:
- package metadata strengthened in `.ipkg` files
- public orientation docs strengthened
- package readiness matrix added
- reproducible verification script added
- GitHub Actions CI deferred for now; local release verification remains the canonical check

## Verification Command

From a clean clone, the canonical verification command is:

```bash
./scripts/verify-release.sh
```

This runs:
- workspace builds
- representative smoke checks
- starter validation

## GitHub Publication Gates

Before making the repository public, complete these gates:

1. Legal metadata
- top-level `LICENSE` is present as `MIT`
- reflect that license in package metadata where appropriate if a stable package-level field is adopted later

2. Public verification
- ensure `./scripts/verify-release.sh` passes from a clean clone
- reintroduce CI later if automated hosted verification becomes necessary

3. Public-facing docs
- keep `README.md`, `docs/START-HERE.md`, and `docs/getting-started.md` coherent
- ensure starter copy flow still works

4. Maintainer metadata
- confirm package author/maintainer identity in `.ipkg` files is the intended public identity

5. Repository metadata
- public GitHub repository URL is wired into package metadata

## Pack-DB Submission Gates

Each package should only be submitted when all of the following are true:

1. The package builds against the current `HEAD` collection.
2. The package boundary is documented and understandable to an external consumer.
3. The package has already been pressure-tested by at least one example or starter in this repository.
4. The package name and first public version are considered stable enough for external use.
5. The package no longer depends on unpublished local packages outside its intended release wave.

Current pack-db references:
- `README.md`
- `STATUS.md`
- `collections/HEAD.toml`

At the time of writing, that means pack-db submission still requires:
- updating `collections/HEAD.toml`
- adding package entries in the repo metadata expected by pack-db
- ensuring package build workflows pass in the target pack-db branch

## Recommended Release Waves

### Wave 1
- `emkit-sourcing`
- `emkit-stream`
- `emkit-modeling`
- `emkit-wire`

These are the most stable and least framework-heavy.

### Wave 2
- `emkit-store`
- `emkit-runtime`

These are already useful, but more opinionated.

### Wave 3
- `emkit-backend`
- `emkit-frontend`

These are the most adapter-heavy and benefit most from external feedback.

## Notes On What Is Deliberately Not Frozen Yet

These remain intentionally local to applications and should not be mistaken for stable shared-public APIs:
- route naming
- application-specific DTO mapping
- domain stream naming policy
- page-controller policy
- app-specific automation and translation policy
