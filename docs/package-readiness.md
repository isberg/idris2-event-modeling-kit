# Package Readiness Matrix

This matrix tracks whether each `emkit-*` package is ready for the first public release wave.

Status values:
- `ready-for-pr-review`: strong candidate for a first pack-db PR review
- `needs-more-hardening`: useful and exercised, but still more opinionated or less externally tested

Global review note:
- Wave 1 is frozen at `0.1.0`
- public repo metadata is already wired
- remaining Wave 1 questions are now about pack-db PR strategy, not basic package hygiene

| Package | Current Version | Wave | Status | Evidence | Main Remaining Risk |
|---|---:|---:|---|---|---|
| `emkit-sourcing` | `0.1.0` | 1 | `ready-for-pr-review` | tutorials, console example, all web examples | lowest-level public kernel; minimal remaining risk |
| `emkit-stream` | `0.1.0` | 1 | `ready-for-pr-review` | all web examples, starter | SSE/version helper surface may still get minor polish |
| `emkit-modeling` | `0.1.0` | 1 | `ready-for-pr-review` | tutorials, console example, project/tasks example | translation helper remains intentionally minimal |
| `emkit-wire` | `0.1.0` | 1 | `ready-for-pr-review` | multi-stream web examples, starter, `wave1-kernel` | transport contracts are intentionally minimal, but the boundary now looks coherent |
| `emkit-store` | `0.1.0` | 2 | `needs-more-hardening` | memory/file-backed examples and starter | file-store/public API should be validated again after first external use |
| `emkit-runtime` | `0.1.0` | 2 | `needs-more-hardening` | all larger web examples | mapped execution/query helpers are useful but still opinionated |
| `emkit-backend` | `0.1.1` | 3 | `needs-more-hardening` | all web examples and starter | adapter-heavy surface likely to evolve from user feedback |
| `emkit-frontend` | `0.1.0` | 3 | `needs-more-hardening` | all web examples and starter | controller-level ergonomics still intentionally local |

## Interpretation

Wave 1 is ready for pack-db PR review.

Wave 2 and Wave 3 are already useful internally, but they are more exposed to policy and ergonomics feedback. They should be published only after:
- GitHub publication succeeds
- Wave 1 package boundaries survive first external use
- at least one external consumer path has been exercised without hidden local context
