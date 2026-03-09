# emkit-wire

Shared transport contracts for event-oriented applications.

## Provides

- execute payload contracts
- single-stream event contracts
- multiplexed stream event contracts
- resync payload contracts
- JSON and JSON.Simple codec modules for the shared payload records

## Dependency Rule

This package currently exposes transport-neutral contracts only. JSON codecs and framework-specific route helpers are intentionally deferred until the public surface is clearer.
