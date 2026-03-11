# Package Readiness Matrix

This matrix tracks whether each `emkit-*` package is ready for the first public release wave.

Status values:
- `ready-soon`: strong candidate after the remaining global blockers are cleared
- `needs-more-hardening`: useful and exercised, but still more opinionated or less externally tested

Global blockers still affecting every package:
- release wave versions and public repo URL metadata should be treated as final enough for first publication

| Package | Current Version | Wave | Status | Evidence | Main Remaining Risk |
|---|---:|---:|---|---|---|
| `emkit-sourcing` | `0.1.0` | 1 | `ready-soon` | tutorials, console example, all web examples | needs final public repo metadata |
| `emkit-stream` | `0.1.0` | 1 | `ready-soon` | all web examples, starter | SSE/version helper surface may still get minor polish |
| `emkit-modeling` | `0.1.0` | 1 | `ready-soon` | tutorials, console example, project/tasks example | translation helper remains intentionally minimal |
| `emkit-wire` | `0.1.0` | 1 | `ready-soon` | multi-stream web examples, starter | route-level helper policy intentionally deferred |
| `emkit-store` | `0.1.0` | 2 | `needs-more-hardening` | memory/file-backed examples and starter | file-store/public API should be validated again after first external use |
| `emkit-runtime` | `0.1.0` | 2 | `needs-more-hardening` | all larger web examples | mapped execution/query helpers are useful but still opinionated |
| `emkit-backend` | `0.1.1` | 3 | `needs-more-hardening` | all web examples and starter | adapter-heavy surface likely to evolve from user feedback |
| `emkit-frontend` | `0.1.0` | 3 | `needs-more-hardening` | all web examples and starter | controller-level ergonomics still intentionally local |

## Interpretation

Wave 1 is close after the remaining global publication blockers are cleared.

Wave 2 and Wave 3 are already useful internally, but they are more exposed to policy and ergonomics feedback. They should be published only after:
- GitHub publication succeeds
- Wave 1 package boundaries survive first external use
- at least one external consumer path has been exercised without hidden local context
