# grantsy

Helm chart for [Grantsy](https://github.com/grantsy/grantsy) — a Go entitlements microservice
backed by Casbin, with first-class LemonSqueezy webhook handling.

This chart deploys a single Grantsy process serving both the **API** (`/v1/check`, `/v1/features`,
`/v1/plans`, `/v1/users`) and the **LemonSqueezy webhook** (`/v1/webhook/lemonsqueezy`) on the
same port. Two independent Ingresses route those concerns separately so they can be exposed on
different hostnames with different policies (rate limits on API, IP allowlists on webhook).

## TL;DR

```bash
kubectl create secret generic grantsy-app-secrets \
  --from-literal=API_KEY=replace-me \
  --from-literal=LEMONSQUEEZY_API_KEY=replace-me \
  --from-literal=LEMONSQUEEZY_WEBHOOK_SECRET=replace-me

cat > values.yaml <<'EOF'
ingress:
  webhook:
    host: hooks.example.com
  api:
    enabled: true
    host: api.example.com
envFrom:
  - secretRef:
      name: grantsy-app-secrets
config:
  env: prod
  log: { level: info, format: json }
  metrics: { enable: true, path: /metrics }
  entitlements:
    default_plan: free
    plans:
      - {id: free, name: Free, features: [dashboard]}
    features:
      - {id: dashboard, name: Dashboard, description: Basic}
  auth:
    api_key: ${API_KEY}
  providers:
    lemonsqueezy:
      api_key: ${LEMONSQUEEZY_API_KEY}
      webhook:
        secret: ${LEMONSQUEEZY_WEBHOOK_SECRET}
EOF

helm install grantsy grantsy/grantsy -f values.yaml
```

## How configuration works

Grantsy's binary runs `os.ExpandEnv` on its YAML config file before parsing. That's the
secret-injection mechanism: anywhere in your `config:` value you can write `${ENV_VAR}` and the
running process resolves it from the container's environment at startup.

You wire those env vars through the standard `env` / `envFrom` lists in `values.yaml`, which use
the normal Kubernetes shapes (`valueFrom.secretKeyRef`, `secretRef`, `configMapRef`, etc.). The
chart never touches secret content — operators bring their own Secrets, and any existing Secret in
the cluster works without translation.

The `database:` section is regular operator-supplied config — same as everything else. The chart
reads `config.database.driver` to decide PVC provisioning, single-replica enforcement, and the
HPA-with-sqlite guard, but it never edits the rendered ConfigMap. The Postgres DSN goes through
the same `env:` + `${VAR}` pattern as every other secret.

## Two ingresses, one Service

| Ingress | Default | Path | Purpose |
|---|---|---|---|
| `ingress.webhook` | enabled | `/v1/webhook` | LemonSqueezy webhook receiver. Always-on. Set `host` to a public DNS name. |
| `ingress.api` | disabled | `/v1/` | Customer-facing API. Set `enabled: true` and `host` to enable. |

Both Ingresses point at the same Service — there's only ever one Deployment. The chart **fails
template rendering** if you enable an Ingress without setting a `host`; this is intentional, since
an empty host makes the Ingress a wildcard for that controller and would silently expose the API
to every unmatched request hitting the cluster.

## Database

`config.database.driver` is the single field that toggles backend behavior. Defaults to `sqlite`
when unset.

- **SQLite**: chart provisions a PVC (or uses `persistence.existingClaim`), pins replica count to
  1, and refuses to render an HPA. Switch to Postgres if you need to scale horizontally.
- **PostgreSQL**: set `config.database.driver: postgres` and supply the DSN through `env:` like
  any other secret. PVC creation is automatically skipped.

```yaml
env:
  - name: DATABASE_DSN
    valueFrom:
      secretKeyRef:
        name: grantsy-postgres
        key: dsn
config:
  database:
    driver: postgres
    namespace: grantsy
    dsn: "${DATABASE_DSN}"
```

## Values reference

See [`values.yaml`](values.yaml). Every field is documented inline. The most important ones:

| Key | Default | Notes |
|---|---|---|
| `image.repository` | `ghcr.io/grantsy/grantsy` | |
| `image.tag` | `""` (→ `Chart.AppVersion`) | Keep the `v` prefix when overriding. |
| `replicaCount` | `1` | Forced to 1 when `config.database.driver=sqlite`. |
| `config.database.driver` | `sqlite` (default when unset) | `sqlite` \| `postgres` — single source of truth for backend mode. |
| `persistence.enabled` | `true` | Auto-skipped on Postgres. |
| `persistence.existingClaim` | `""` | If set, chart reuses an existing PVC. |
| `config` | `{}` | Operator must populate. Rendered verbatim into the chart-managed ConfigMap. |
| `env`, `envFrom` | `[]` | Pass-through for app credentials including `DATABASE_DSN`. |
| `ingress.webhook.enabled` | `true` | `host` required when enabled. |
| `ingress.api.enabled` | `false` | `host` required when enabled. |
| `autoscaling.enabled` | `false` | Not allowed with `config.database.driver=sqlite`. |
| `serviceMonitor.enabled` | `false` | Prometheus Operator integration. |
| `terminationGracePeriodSeconds` | `45` | App needs ~23s for graceful shutdown. |

## Validation logic

The chart fails fast (i.e. `helm template`/`install` errors with a clear message) on:

- `ingress.api.enabled=true` with empty `ingress.api.host`
- `ingress.webhook.enabled=true` with empty `ingress.webhook.host`
- `autoscaling.enabled=true` with `config.database.driver=sqlite`

Other misconfigurations (e.g. SQLite with `persistence.enabled=false`, or a missing
`DATABASE_DSN` env entry when `config.database.dsn` references it) surface as `NOTES.txt`
warnings or runtime errors from the Grantsy binary itself.

## Upgrading

Bump `image.tag` (or rely on `Chart.AppVersion` after a chart bump). Config changes trigger a pod
rollout via a `checksum/config` pod annotation. Secret rotations don't trigger rollouts
automatically — restart pods manually after rotating env-backing Secrets.

## License

[Elastic License 2.0](https://github.com/grantsy/grantsy/blob/main/LICENSE), matching the upstream
Grantsy project.
