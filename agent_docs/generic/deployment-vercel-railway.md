<!-- last-reviewed: 2026-03-24 | reviewed-by: The Genesis | next-review: 2026-09-24 -->

# Vercel (Frontend) + Railway (API Backend) Deployment Best Practices (Company Standard)

> Extends `deployment-standards.md`. All platform-agnostic rules still apply.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.
> This architecture is suited for full-stack projects where the frontend is deployed on Vercel
> and the API backend runs on Railway as a standard Node.js (or Python/Go) server process.

## When to Use This Platform (vs Vercel + Cloudflare)

| Consideration | Vercel + Cloudflare Workers | Vercel + Railway |
|---|---|---|
| Backend runtime | V8 isolate (not Node.js) | Full Node.js (or Python/Go/Rust) |
| Native npm packages | Not supported (bcrypt, sharp, etc.) | Fully supported |
| CPU limits | 10ms free / 30ms paid / 30s Unbound | No per-request CPU limit |
| File system access | Not available | Available (ephemeral per deploy) |
| Long-running processes | Not supported (request-response only) | Supported (background jobs, cron, WebSockets) |
| Database connections | Must use HTTP drivers or Hyperdrive proxy | Standard TCP connections (pg, Prisma, etc.) |
| Cold starts | Near-zero (V8 isolates) | Possible (mitigated by Railway's always-on option) |
| Global edge distribution | Yes (Workers run at 300+ PoPs) | Single region (choose closest to DB) |
| Cost at scale | Very low per request | Per-hour compute pricing |

**Choose Railway when:** the project uses native npm packages, needs long-running processes, requires standard Node.js APIs, or when Cloudflare Workers runtime constraints would force too many workarounds.

---

## Railway Runtime — What You Get

- Full **Node.js** runtime (any LTS version) — no V8 isolate restrictions
- Standard `process.env` for environment variables
- Native npm packages work (`bcrypt`, `sharp`, `canvas`, `argon2`, etc.)
- TCP database connections (Prisma, pg, Sequelize — all work natively)
- File system access (ephemeral — use object storage for persistence)
- WebSocket support (native `ws` package or Socket.io)
- Cron jobs via Railway's built-in cron trigger
- Background workers as separate Railway services
- Docker support for custom runtimes

### Architecture Checklist for This Platform

Before signing off on architecture for a Vercel + Railway project, confirm:

- [ ] Backend service region selected (choose closest to database for lowest latency)
- [ ] Database connection method: standard TCP via Prisma/pg/Sequelize (no HTTP driver workarounds needed)
- [ ] Password hashing: any standard algorithm works (`bcrypt`, `argon2`, PBKDF2) — no CPU budget concerns
- [ ] File handling: ephemeral local fs available, but persistent files must use object storage (R2, S3, or Railway Volumes)
- [ ] Environment variables: accessed via standard `process.env`
- [ ] Railway service type: Web (HTTP server) for API, Worker (no port) for background jobs
- [ ] Health check endpoint configured in Railway service settings
- [ ] Sleep/idle behaviour configured: use "Always On" for production, allow sleep for dev to save costs
- [ ] Railway Volumes configured if persistent storage is needed (database backups, file uploads before S3 migration)

---

## Architecture Overview

```
User
  |
  v
Cloudflare (DNS + CDN + WAF + DDoS Protection)  [optional — see Networking section]
  |
  +-- *.yourdomain.com  --> Vercel (Next.js / React frontend)
  |
  +-- api.yourdomain.com --> Railway (Node.js API server)
                               |
                               +-- Neon / Railway Postgres (database)
                               +-- Upstash Redis (cache / sessions)
                               +-- External APIs (Resend, Sentry, etc.)
```

## Recommended Service Stack

| Concern | Service | Notes |
|---|---|---|
| Frontend hosting | Vercel | Next.js or Vite SPA; automatic preview deployments |
| API backend | Railway | Full Node.js server; Express/Fastify/NestJS |
| Background jobs | Railway (Worker service) | Separate service, no HTTP port, triggered by queue or cron |
| Database (SQL) | Neon or Railway Postgres | Neon for serverless; Railway Postgres for co-located, low-latency |
| Cache / sessions | Upstash Redis | Serverless Redis; works from both Vercel and Railway |
| Object storage | Cloudflare R2 or AWS S3 | S3-compatible; no egress fees with R2 |
| Secrets | Railway Variables + Vercel Env Vars | Never commit to code |
| DNS | Cloudflare DNS (recommended) or Vercel DNS | Cloudflare preferred for WAF + DDoS protection |
| CDN / WAF | Cloudflare (recommended) | Optional but recommended for production |
| Email | Resend | DKIM + SPF configured via DNS |
| Queue | Upstash QStash or BullMQ on Railway | QStash for serverless; BullMQ for Railway-native |
| Monitoring | Vercel Analytics + Railway Metrics | Combine for full-stack visibility |
| Error tracking | Sentry | Both Vercel and Railway support Sentry SDK |
| Audit logging | Application-level + Railway logs | Ship to external SIEM for 12-month retention |

## IaC — Terraform + Railway CLI

```
infrastructure/
+-- terraform/
|   +-- cloudflare/           # (if using Cloudflare DNS/WAF)
|   |   +-- dns.tf
|   |   +-- waf.tf
|   +-- environments/
|       +-- dev/
|       +-- staging/
|       +-- production/
+-- railway.toml              # Railway service config
+-- Dockerfile                # API server container (optional — Railway auto-detects Node.js)
+-- vercel.json               # Vercel project config
```

- Railway resources managed via Railway CLI or Terraform `[ISO 27001: 8.32]`
- Separate Railway environments for dev/staging/production `[ISO 27001: 8.31]`
- `railway.toml` must not contain secrets — use Railway Variables or CI/CD env vars `[8.24]`

---

## Railway — First-Deployment Checklist

> Run this checklist before the first deployment for each environment.

### 1. Railway Project Setup

- [ ] Railway project created (via MCP or CLI: `railway project create`)
- [ ] Environments created: dev, staging, production
- [ ] Service created for API (type: Web)
- [ ] Service created for background worker (type: Worker) — if needed
- [ ] Railway Postgres provisioned (or Neon database URL configured)
- [ ] Custom domain configured for production (`api.yourdomain.com`)
- [ ] Health check path set in Railway service settings (e.g. `/health`)
- [ ] Deploy region selected (closest to database)

### 2. Environment Variables

Set in Railway Variables (per environment):

```
DATABASE_URL=postgresql://...
REDIS_URL=redis://...
JWT_SECRET=...
CORS_ALLOWED_ORIGINS=https://yourdomain.com
RESEND_API_KEY=...
SENTRY_DSN=...
NODE_ENV=production|staging|development
PORT=3000
```

### 3. vercel.json Readiness Checklist (Vite SPA)

- [ ] `rewrites` configured: `[{ "source": "/(.*)", "destination": "/index.html" }]` for client-side routing
- [ ] CSP headers configured with correct API domain for `connect-src`
- [ ] Environment variables set per Vercel environment (`VITE_API_BASE_URL`, etc.)
- [ ] Preview deployment protection enabled `[ISO 27001: 8.2]`

### 4. Cross-Service URL Wiring (First Deployment Only)

On first deployment, frontend and API have a mutual URL dependency:

1. **Deploy Railway API first** — capture the Railway-provided URL (e.g. `https://your-api-production.up.railway.app`)
2. **Set the API URL as Vercel env var** — `VITE_API_BASE_URL` or `NEXT_PUBLIC_API_URL` for the target environment
3. **Set the frontend URL in Railway** — update `CORS_ALLOWED_ORIGINS` with the Vercel deployment URL
4. **Redeploy Railway** with updated CORS (Railway auto-redeploys on variable change)
5. **Deploy frontend on Vercel** — it now has the correct API URL
6. **Document final URLs** in `agent_docs/project/deployment.md`

When switching from Railway preview URLs to custom domains, repeat this sequence.

---

## SS5 -- Post-Deploy Smoke Tests (Per Service)

> These tests run in CI after each deployment and are also used by the tester agent.
> A failure at any step halts the pipeline.

### API (Railway) -- run after every API deploy

1. `GET /health` -- expect 200 + JSON with `status: "ok"`, `git_commit`, `git_commit_time`, `deploy_time`
2. Deployment sanity check: `deploy_time > git_commit_time`, `git_commit` matches expected SHA
3. CORS preflight: `OPTIONS /api/v1/...` with `Origin: https://your-frontend.vercel.app` -- expect `Access-Control-Allow-Origin` header
4. Auth rejection: `GET /api/v1/protected-resource` without token -- expect 401
5. DB connectivity: `GET /api/v1/...` (any endpoint that reads from DB) -- expect 200 with data
6. If WebSocket: connect and receive initial handshake

### Frontend (Vercel) -- run after frontend deploys

1. `curl` root URL -- expect 200 + non-empty HTML
2. `curl` a page that fetches live data from the API -- response must contain data markers (not empty shell)
3. Check `VITE_API_BASE_URL` / `NEXT_PUBLIC_API_URL` resolves to the correct Railway URL for this environment
4. If CSP headers configured: verify `connect-src` includes the API domain

### CMS (if present) -- same pattern as Frontend

1. `curl` root URL -- expect 200 + non-empty HTML
2. `curl` a page that fetches CMS-specific API data

---

## Networking & Edge Security
`ISO 27001: 8.20, 8.22`

- **With Cloudflare (recommended for production):**
  - All DNS records proxied through Cloudflare -- never expose Railway origin IPs `[8.20]`
  - SSL mode: **Full (strict)** -- end-to-end TLS `[8.24]`
  - HSTS enabled: `max-age=31536000; includeSubDomains` `[8.20]`
  - HTTP -> HTTPS redirect enforced at Cloudflare level `[8.20]`
  - Minimum TLS version: 1.2 `[8.24]`
  - WAF: enable OWASP Core Ruleset + managed rules in production `[8.20]`
  - Rate limiting rules on all API endpoints (especially auth) `[8.5]`
  - Bot Management or Bot Fight Mode enabled for production `[8.20]`

- **Without Cloudflare (simpler setup):**
  - Railway provides automatic HTTPS with Let's Encrypt
  - Vercel provides automatic HTTPS
  - Rate limiting must be implemented at application level (e.g. `express-rate-limit`)
  - No WAF -- consider adding Cloudflare later for production

- CORS: set `CORS_ALLOWED_ORIGINS` in Railway -- never allow `*` in production `[8.20]`

## Security Hardening
`ISO 27001: 8.2, 8.5, 8.8, 8.9, 8.24`

- **Railway tokens**: use project-scoped tokens where possible; rotate every 90 days `[8.5]`
- **Vercel tokens**: scoped to project; rotate every 90 days `[8.5]`
- **Railway Variables**: all sensitive values set via Railway dashboard or CLI -- never in code or `railway.toml` `[8.24]`
- **Vercel Env Vars**: mark all secrets as "Sensitive" (encrypted at rest, hidden after save) `[8.24]`
- **Dependency scanning**: run Snyk or OWASP DC on API and frontend code in CI `[8.8]`
- **Container scanning**: if using Dockerfile, scan image with Trivy in CI `[8.8]`
- **Railway private networking**: use internal URLs between Railway services (avoids public internet hop) `[8.22]`

---

## CI/CD -- GitHub Actions --> Vercel + Railway

> **Deployment trigger rule -- ALL environments, no exceptions:**
> Every deployment to every environment (dev, UAT, pre-production, staging, production)
> **must** be triggered by a `git push` to the correct branch. GitHub Actions then runs
> the deploy commands inside CI.

### Permitted deployment methods

| Environment | Trigger | Pipeline |
|---|---|---|
| dev | Push to `develop` | GitHub Actions -> Railway deploy (API) + Vercel deploy (frontend) |
| staging | Push to `release/*` | GitHub Actions -> Railway deploy (API) + Vercel deploy (frontend) |
| production | Merge to `main` | GitHub Actions -> Railway deploy (API) + Vercel deploy (frontend) |

### Prohibited deployment methods (ALL environments)

- `railway up` from a local machine or from Claude Code
- `vercel deploy` from a local machine or from Claude Code
- Deploying via Railway MCP, Vercel MCP, or any MCP tool directly
- Clicking "Deploy" in Railway dashboard or Vercel dashboard
- Any other method that bypasses the CI/CD pipeline

**Rationale:** These bypass all CI checks (tests, SAST, secrets scan, smoke tests) and break pipeline integrity regardless of environment `[ISO 27001: 8.32]`.

### Required CI stages (in order)

```
1. Lint + type check (tsc --noEmit)
2. Unit tests
3. Integration tests
4. SAST scan (CodeQL / SonarQube)
5. Dependency vulnerability scan (Snyk / npm audit)
6. Container image scan (Trivy) -- if using Dockerfile
7. Build
8. Deploy API to Railway (railway up --service api --environment $ENV)
9. API smoke test (health check + CORS + auth rejection + DB read)
10. Deploy frontend to Vercel (vercel deploy --prod / vercel deploy)
11. Frontend smoke test (render check + API connectivity)
12. Deployment sanity check (verify /health timestamps and commit SHA)
```

---

## Secrets Management
`ISO 27001: 8.24`

| Secret type | Where to store | Notes |
|---|---|---|
| Database URL | Railway Variables | Per-environment; auto-injected if using Railway Postgres |
| API keys (Resend, Sentry, etc.) | Railway Variables | Set via CLI or dashboard |
| JWT secret | Railway Variables | Generate unique per environment |
| Frontend API URL | Vercel Env Vars | `VITE_API_BASE_URL` / `NEXT_PUBLIC_API_URL` |
| CI/CD deploy tokens | GitHub Actions Secrets | Railway token + Vercel token |

## Environment Separation
`ISO 27001: 8.31`

| Environment | Railway | Vercel | Database | Notes |
|---|---|---|---|---|
| dev | Railway env: dev | Vercel preview | Neon branch or Railway dev DB | May sleep after idle |
| staging | Railway env: staging | Vercel preview (staging branch) | Separate Neon project or Railway staging DB | Always on |
| production | Railway env: production | Vercel production | Separate Neon project or Railway production DB | Always on, custom domain |

## Monitoring & Observability

- **Railway**: built-in metrics (CPU, memory, network), log streaming, deploy logs
- **Vercel**: Analytics, Speed Insights, function logs
- **Sentry**: error tracking for both frontend and API -- configure source maps
- **Uptime monitoring**: use Railway's built-in health checks or external (e.g. UptimeRobot, Better Stack)
- Production alert channels configured (Slack, email, PagerDuty) `[ISO 27001: 8.16]`

## Backup & Recovery

- **Database**: Neon automatic point-in-time recovery (PITR) or Railway Postgres daily backups `[8.13]`
- **Object storage**: R2/S3 versioning enabled for production buckets `[8.13]`
- **Railway**: automatic deploy history -- rollback to any previous deployment via dashboard or CLI
- **Recovery test**: quarterly restore drill documented `[8.14]`

## Rollback

- **Railway**: `railway rollback` or select previous deployment in dashboard -- instant, no rebuild
- **Vercel**: promote previous deployment via dashboard or `vercel rollback` -- instant
- **Database**: Neon branch-based rollback (create branch before migration, drop if migration fails) or Railway Postgres point-in-time restore
- All rollback procedures documented in `agent_docs/project/deployment.md` `[8.14]`

## Cost Controls

- **Railway**: use sleep/idle for dev environments; set spend limits per environment
- **Vercel**: use hobby plan for dev/staging; pro plan for production
- **Neon**: use free tier branching for dev; scale compute for production
- **Upstash**: serverless pricing -- pay per request (cost-effective for low-traffic)
- Monitor Railway usage dashboard weekly; set billing alerts `[5.23]`

---

## Compliance Evidence for ISO 27001 Audits

| Control | Evidence source |
|---|---|
| 8.32 Change management | GitHub Actions deploy logs, Railway deploy history, Vercel deploy logs |
| 8.25 Secure development | CI pipeline config (lint, test, SAST, dep scan stages) |
| 8.31 Separation of environments | Railway environments config, Vercel environment settings, separate DB instances |
| 8.24 Secrets management | Railway Variables (encrypted), Vercel Env Vars (sensitive flag), GitHub Actions Secrets |
| 8.9 Configuration management | `railway.toml`, `vercel.json`, Terraform state, IaC repo |
| 8.15 Audit logging | Railway deploy logs, application audit logs, Cloudflare audit logs (if used) |
| 8.13 Backup | Neon PITR / Railway Postgres backup config, R2/S3 versioning |
| 8.16 Monitoring | Railway metrics, Vercel Analytics, Sentry alerts, uptime monitoring |
