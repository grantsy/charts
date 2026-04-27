# Changelog

All notable changes to this chart are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the chart
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] — 2026-04-27

### Changed
- Database configuration moved into the operator-supplied `config:`. A single source of truth
  — `config.database.driver` — drives PVC provisioning, single-replica enforcement, and the
  HPA-with-sqlite guard. `DATABASE_DSN` is now wired through the regular `env:` mechanism, the
  same path used for every other app secret (API_KEY, LEMONSQUEEZY_API_KEY, webhook secrets).
- The chart no longer merges a `database:` block into the rendered ConfigMap; `config:` is
  rendered verbatim.

### Removed
- Top-level `database` block (`driver`, `namespace`, `sqlite.path`, `postgres.dsnSecret`).
- `existingConfigMap` value. Operators who managed config externally should template their
  `config:` value through their GitOps tooling (sealed-secrets, kustomize, ArgoCD, etc.) instead.

### Migration
- Move `database.namespace` / `database.sqlite.path` / `database.postgres.*` settings into
  `config.database` (e.g. `config.database.driver`, `config.database.namespace`,
  `config.database.dsn`).
- For postgres deployments, add a `DATABASE_DSN` entry to `env:` referencing your existing DSN
  Secret, and set `config.database.dsn: "${DATABASE_DSN}"`.
- If you used `existingConfigMap`, inline its contents into `config:` via your GitOps tool of
  choice.

## [0.1.0] — 2026-04-26

### Added
- Initial release of the `grantsy` chart.
- Single Deployment serving API and LemonSqueezy webhook on port 8080.
- Two Ingresses (`ingress.api`, `ingress.webhook`) routing the same Service so
  API and webhook traffic can be exposed on different hosts with different
  edge policies. Webhook ingress enabled by default; API ingress opt-in.
- SQLite (default) and PostgreSQL backends with mutually exclusive plumbing —
  PVC and single-replica enforcement on SQLite; HPA and DSN-from-Secret on
  PostgreSQL.
- Operator-friendly config plumbing: inline `config:` rendered into a
  chart-managed ConfigMap (with chart-owned `database:` block) or
  `existingConfigMap` for fully external config.
- Pass-through `env` / `envFrom` for app credentials; chart never creates
  Secret resources. `${VAR}` placeholders inside the config file resolve via
  the binary's `os.ExpandEnv` at startup.
- Optional `ServiceMonitor`, `PodDisruptionBudget`, and `HorizontalPodAutoscaler`.
- Fail-fast template validation for required Ingress hosts, Postgres DSN
  Secret, and HPA-with-SQLite incompatibility.
- `helm test` smoke check against `/healthz`.
