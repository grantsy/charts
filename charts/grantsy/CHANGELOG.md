# Changelog

All notable changes to this chart are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the chart
adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
