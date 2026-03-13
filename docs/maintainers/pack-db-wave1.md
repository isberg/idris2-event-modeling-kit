# Pack-DB Wave 1

This document prepares the first realistic `idris2-pack-db` submission wave for `emkit`.

## Wave 1 Package Set

Wave 1 is frozen at the current `0.1.0` versions for:
- `emkit-sourcing`
- `emkit-stream`
- `emkit-modeling`
- `emkit-wire`

These four packages are the smallest stable public kernel of the repository.

## Why These Four First

They provide:
- pure history, projection, and decider algebra
- Event Modeling screen and pattern contracts
- stream version/SSE framing helpers
- transport contracts and JSON codecs

They deliberately avoid the more opinionated layers:
- runtime execution
- event storage adapters
- backend framework glue
- frontend browser glue

## Downstream Proof

The narrow downstream proof for Wave 1 is:
- `tutorials/wave1-kernel`

It depends only on the four Wave 1 packages and proves that they already make sense together without the rest of the stack.

Canonical Wave 1 verification command:

```bash
./scripts/verify-wave1.sh
```

## Dependency Check Against Current pack-db HEAD

Checked against `collections/HEAD.toml` on March 12, 2026.

External dependencies needed by Wave 1:
- `base`
- `json`
- `json-simple`

Confirmed present in current pack-db `HEAD`:
- `json`
- `json-simple`

## Naming Review Against Current pack-db STATUS

Checked against the current `STATUS.md` on March 12, 2026.

Conclusions:
- there are currently no `emkit-*` name collisions in pack-db
- prefixed package families are normal in pack-db
- multiple sibling packages from one repository are also normal

Relevant examples from current `STATUS.md`:
- `async`, `async-dom`, `async-epoll`, `async-js`, `async-posix`, `async-spec`
- `ilex`, `ilex-core`, `ilex-debug`, `ilex-fasta`, `ilex-json`, `ilex-streams`, `ilex-toml`
- `json`, `json-simple`

That means the current `emkit-*` naming is appropriate, and a four-package first wave is not unusually fragmented for pack-db.

## Candidate HEAD.toml Entries

These are the candidate package entries to adapt into a pack-db PR.

```toml
[db.emkit-sourcing]
type   = "github"
url    = "https://github.com/isberg/idris2-event-modeling-kit"
commit = "main"
ipkg   = "packages/emkit-sourcing/emkit-sourcing.ipkg"

[db.emkit-stream]
type   = "github"
url    = "https://github.com/isberg/idris2-event-modeling-kit"
commit = "main"
ipkg   = "packages/emkit-stream/emkit-stream.ipkg"

[db.emkit-modeling]
type   = "github"
url    = "https://github.com/isberg/idris2-event-modeling-kit"
commit = "main"
ipkg   = "packages/emkit-modeling/emkit-modeling.ipkg"

[db.emkit-wire]
type   = "github"
url    = "https://github.com/isberg/idris2-event-modeling-kit"
commit = "main"
ipkg   = "packages/emkit-wire/emkit-wire.ipkg"
```

## Notes

- The candidate entries intentionally omit a `test = ...` field for now.
- The downstream proof currently lives in this repository as `tutorials/wave1-kernel`, but pack-db test wiring should only be added once the multi-package PR strategy is confirmed.
- If the first public release should use tags instead of `commit = "main"`, this document should be updated at the same time as the pack-db PR is prepared.
