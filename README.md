# Grantsy Helm Charts

Helm charts for [Grantsy](https://github.com/grantsy/grantsy), a Go entitlements microservice
backed by Casbin and LemonSqueezy.

## Usage

```bash
helm repo add grantsy https://grantsy.github.io/charts
helm repo update
helm install my-grantsy grantsy/grantsy -f my-values.yaml
```

## Available charts

| Chart | Description |
|---|---|
| [`grantsy`](charts/grantsy) | Standalone deployment of Grantsy with optional API and webhook ingresses, SQLite (default) or PostgreSQL backend, and Prometheus Operator integration. |

See [`charts/grantsy/README.md`](charts/grantsy/README.md) for the full reference.

## Repository layout

```
charts/grantsy/        # The Grantsy chart
.github/workflows/     # Lint/test on PR, chart-releaser on push to main
ct.yaml                # chart-testing config
cr.yaml                # chart-releaser config
```

## Releasing

Push to `main`. The `release.yml` workflow runs `chart-releaser`, which packages any chart whose
`Chart.yaml` `version:` is newer than the latest matching GitHub release, creates the release, and
updates the `gh-pages` index. Bump `charts/grantsy/Chart.yaml`'s `version:` (SemVer) on every chart
change.

## License

[Elastic License 2.0](LICENSE), matching the upstream Grantsy project.
