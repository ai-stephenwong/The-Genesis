<!-- last-reviewed: 2026-03-21 | reviewed-by: retrospective-analyst (omnichat-v1 deployment round) | next-review: 2026-09-21 -->

# Vercel (Frontend) + Cloudflare (API/Edge) Deployment Best Practices (Company Standard)

> Extends `deployment-standards.md`. All platform-agnostic rules still apply.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.
> This architecture is suited for JAMstack / edge-first projects where the frontend is
> deployed on Vercel and APIs run on Cloudflare Workers or Cloudflare Pages Functions.

## Cloudflare Workers Runtime Constraints (Read Before Architecture Sign-off)

> The solution-architect **must** review this section and complete the Platform Runtime Compatibility Matrix in `architecture.md` before development starts.
> Discovering these constraints at deployment time causes source code rewrites. Catch them here.

### What Cloudflare Workers IS

- A **V8 isolate** runtime — not Node.js
- Supports the [WinterCG subset](https://wintercg.org/) of Web APIs
- Has access to Web Crypto API (`crypto.subtle`), Fetch API, URL API, Streams API, TextEncoder/Decoder

### What Cloudflare Workers IS NOT / CANNOT DO

| Constraint | Detail | Alternative |
|---|---|---|
| No native Node.js modules | `fs`, `path`, `child_process`, `os`, `net` etc. are not available | Use Web APIs or Cloudflare-native equivalents |
| No native addons (N-API) | Packages with native bindings **will not work**: `bcrypt`, `sharp`, `canvas`, `argon2` (native) | `bcryptjs` (pure JS), `@noble/hashes`, Web Crypto API |
| No `node:crypto` (full) | Node's `crypto` module is not fully available | Use Web Crypto API (`crypto.subtle`) for hashing, signing, encryption |
| No TCP connections (direct) | Cannot open raw TCP sockets to databases | Use Cloudflare Hyperdrive (PostgreSQL proxy), REST APIs, or Neon/PlanetScale serverless drivers |
| No file system | Cannot read or write local files | Use Cloudflare R2, KV, or external object storage |
| No long-running processes | Default CPU time limit: 10ms (free) / 30ms (paid Bundled) / up to 30s (Unbound) | Design endpoints to be fast; offload heavy work to queues |
| Script size limit | 1MB compressed, 10MB uncompressed per Worker | Code-split workers; avoid bundling large libraries |
| No WebSocket server (basic) | Cannot maintain stateful WebSocket connections in a standard Worker | Use Cloudflare Durable Objects for stateful connections |
| `process.env` not available | Node's `process.env` does not exist | Use `env` parameter passed to Worker handler, or Cloudflare Worker Secrets |
| Some npm packages incompatible | Packages that assume Node.js runtime may fail silently or at build time | Test with `wrangler dev` early; check package's Workers compatibility |

### Vercel Edge Runtime Constraints

If using Vercel Edge Functions (not Node.js runtime):

| Constraint | Detail | Alternative |
|---|---|---|
| Same V8 isolate restrictions | No native modules, no `fs`, etc. | Same as Workers above |
| No `node:` protocol imports | Cannot use `import 'node:crypto'` | Use Web Crypto API |
| Size limit | 1MB per edge function | |

> Vercel **Node.js runtime** (non-edge) does not have these restrictions — but has higher latency and cold starts.

### Architecture Checklist for This Platform

Before signing off on architecture for a Vercel + Cloudflare project, confirm:

- [ ] Password hashing: using Web Crypto API PBKDF2-SHA256 (`crypto.subtle`) — **not** `bcrypt` (native) and **not** pure-JS `argon2id` (pure-JS argon2id with m=65536 requires ~200–400ms CPU — far exceeds the 10–30ms Workers CPU limit)
- [ ] Database connection: using a TCP-based PostgreSQL driver (`pg` / `postgres.js` with `nodejs_compat` flag) for Hyperdrive compatibility — HTTP/WebSocket drivers such as `@neondatabase/serverless` in default mode bypass Hyperdrive's TCP proxy entirely
- [ ] Encryption / crypto: using Web Crypto API (`crypto.subtle`) — not Node's `crypto`
- [ ] File handling: using R2 / external storage — **not** `fs`
- [ ] Environment variables: accessed via Worker `env` object — **not** `process.env`
- [ ] All npm dependencies verified compatible with Workers runtime (tested with `wrangler dev`)
- [ ] No packages with native addons in the dependency tree
- [ ] Script bundle size checked (use `wrangler deploy --dry-run` or `wrangler build`)
- [ ] **CPU budget verified** for every computationally intensive operation — estimate CPU cost and confirm it fits within the target Workers plan limit (10ms free / 30ms Bundled); pure-JS crypto almost always fails this check
- [ ] **Platform service routing verified** for every library connecting to a Cloudflare service — confirm transport strategy (TCP vs HTTP/WebSocket) is compatible (Hyperdrive requires TCP; D1 requires D1 binding; R2 requires R2 binding or S3-compatible API)
- [ ] Platform Runtime Compatibility Matrix completed with **CPU budget** and **platform service routing** columns — signed off in `architecture.md`

---

## Cloudflare Workers — First-Deployment Checklist

> Run this checklist before the first `wrangler deploy` for each environment.
> These errors surface only when cloud credentials are available and an actual deploy is attempted —
> no code reviewer or compliance officer can catch them through static analysis alone.

### 1. Cloud Resource Pre-Creation

The following resource types are **not auto-created** by `wrangler deploy`. They must exist before the Worker that binds them can be deployed:

| Resource type | Create command | Note |
|---|---|---|
| Queue | `wrangler queues create <name>` | Create both primary queue and DLQ |
| KV Namespace | `wrangler kv namespace create <name>` | Copy the returned namespace ID into `wrangler.toml` |
| Hyperdrive Config | `wrangler hyperdrive create <name> --connection-string="..."` | Copy the returned config ID into `wrangler.toml` |
| R2 Bucket | `wrangler r2 bucket create <name>` | |

The devops setup artifact **must** include a pre-creation manifest:

| Resource | Type | Environment | Create command | Created? |
|---|---|---|---|---|
| (fill per project) | | dev | | [ ] |
| (fill per project) | | staging | | [ ] |
| (fill per project) | | production | | [ ] |

### 2. wrangler.toml Readiness Checklist

Before running `wrangler deploy`:

- [ ] All `[PLACEHOLDER: ...]` values replaced with actual provisioned IDs
- [ ] `usage_model = "standard"` removed (deprecated in wrangler 4.x — omit the key entirely)
- [ ] Cron trigger day-of-week uses three-letter abbreviation: `SUN`, `MON`, `TUE`, `WED`, `THU`, `FRI`, `SAT` — **not** numeric (`0`–`6`)
- [ ] Worker handlers exported via `export default { fetch, scheduled, queue }` — named exports (`export const queue = ...`) are **not** recognised by Cloudflare for queue consumers or scheduled handlers
- [ ] `wrangler deploy --dry-run` passes with no errors in all configured environments

### 3. vercel.json Readiness Checklist (Vite SPA)

Before running `vercel deploy`:

- [ ] `"framework"` field matches the build tool in `package.json` — `"vite"` for Vite projects, `"nextjs"` for Next.js; **never copy vercel.json between projects without verifying this field**
- [ ] Rewrite/redirect rules use the correct static asset path for the framework (`/assets/` for Vite, `/_next/` for Next.js)
- [ ] Cache headers target the correct asset directory for the framework
- [ ] SPA fallback rewrite redirects all non-file routes to `/index.html`

### 4. Cross-Service URL Wiring (First Deployment Only)

> On first deployment, the frontend and API have a mutual URL dependency:
> the frontend must know the API URL, and the API must know the frontend URL (for CORS).
> This cannot be done in parallel — follow this order strictly.

**Step 1 — Deploy the API (Workers) first:**
```
wrangler deploy --env staging    # or production
```
Capture the deployed Worker URL from the output (e.g. `https://project-api.workers.dev` or the custom domain once DNS is configured).

**Step 2 — Set the API URL in the frontend environment:**

In Vercel dashboard (or CLI), set the env var for the target environment:
```
VITE_API_BASE_URL=https://project-api.workers.dev   # Vite
NEXT_PUBLIC_API_URL=https://project-api.workers.dev # Next.js
```
Mark as **Plain Text** (not Sensitive) — it is a public URL, not a secret.

**Step 3 — Set the frontend URL in the API's CORS config:**

Before deploying the frontend, update `allowed_origins` in the Worker's CORS config to include the Vercel deployment URL. For first deployment this is the `*.vercel.app` preview URL or the custom domain once confirmed:
```toml
# wrangler.toml — never use "*" in production
[vars]
ALLOWED_ORIGINS = "https://project.vercel.app,https://yourdomain.com"
```
Or set as a Worker secret: `wrangler secret put ALLOWED_ORIGINS --env staging`

**Step 4 — Redeploy the API** with the updated CORS config (if changed in step 3).

**Step 5 — Deploy the frontend:**
```
vercel deploy --prod   # or via CI after env var is set
```

**Step 6 — Verify the wiring end-to-end:**
- [ ] Frontend can reach the API: open the deployed frontend URL, check network tab — no CORS errors, API calls return 200
- [ ] API returns correct `Access-Control-Allow-Origin` header matching the frontend origin
- [ ] If custom domains are used, repeat steps 2–5 with the custom domain URLs (replace the `*.vercel.app` / `*.workers.dev` URLs)

---

## Architecture Overview

```
User
  │
  ▼
Cloudflare (DNS + CDN + WAF + DDoS Protection)
  │
  ├── *.yourdomain.com  → Vercel (Next.js / React frontend)
  │
  └── api.yourdomain.com → Cloudflare Workers (API / edge functions)
                               │
                               └── Origin services (DB, external APIs)
```

## Recommended Service Stack

| Concern             | Service                              | Notes                                                    |
|---------------------|--------------------------------------|----------------------------------------------------------|
| Frontend hosting    | Vercel                               | Next.js preferred; automatic preview deployments         |
| API / edge logic    | Cloudflare Workers                   | V8 isolates; low-latency globally distributed            |
| Edge functions      | Cloudflare Pages Functions           | Colocated with static assets if using Cloudflare Pages   |
| Object Storage      | Cloudflare R2                        | S3-compatible; no egress fees                            |
| Database (SQL)      | PlanetScale / Neon / Supabase        | Serverless-friendly PostgreSQL or MySQL                  |
| Database (NoSQL)    | Cloudflare D1 / Upstash              | D1 for edge-local SQLite; Upstash Redis for cache        |
| Cache / KV          | Cloudflare KV                        | Eventually consistent; good for config and sessions      |
| Durable state       | Cloudflare Durable Objects           | Strongly consistent; for real-time and coordination      |
| Secrets             | Cloudflare Workers Secrets + Vercel Env Vars | Never commit to code                           |
| DNS                 | Cloudflare DNS                       | Proxied for all production records                       |
| CDN / WAF           | Cloudflare                           | Enable WAF rules and Bot Management in production        |
| Email               | Resend / SendGrid                    | DKIM + SPF configured via Cloudflare DNS                 |
| Queue               | Cloudflare Queues                    | For async background tasks from Workers                  |
| Monitoring          | Cloudflare Analytics + Vercel Analytics | Combine for full-stack visibility                     |
| Error tracking      | Sentry (Workers + Next.js)           | Both platforms support Sentry SDK                        |
| Audit Logging       | Cloudflare Audit Logs + Logpush      | Ship to external SIEM for 12-month retention             |

## IaC — Terraform + Wrangler

```
infrastructure/
├── terraform/
│   ├── cloudflare/
│   │   ├── dns.tf            # DNS records, proxied settings
│   │   ├── waf.tf            # WAF rules, rate limiting, bot management
│   │   ├── r2.tf             # R2 buckets
│   │   └── workers-routes.tf # Worker route bindings
│   └── environments/
│       ├── dev/
│       ├── staging/
│       └── production/
├── wrangler.toml             # Cloudflare Workers config (per environment)
└── vercel.json               # Vercel project config
```

- Cloudflare resources managed via `terraform-provider-cloudflare` `[ISO 27001: 8.32]`
- Separate Cloudflare accounts or zones per environment preferred `[ISO 27001: 8.31]`
- `wrangler.toml` must not contain secrets — use `wrangler secret put` or CI/CD env vars `[8.24]`

## Networking & Edge Security
`ISO 27001: 8.20, 8.22`

- All DNS records proxied through Cloudflare — never expose origin IPs `[8.20]`
- SSL mode: **Full (strict)** — end-to-end TLS between Cloudflare and origin `[8.24]`
- HSTS enabled via Cloudflare SSL settings: `max-age=31536000; includeSubDomains` `[8.20]`
- HTTP → HTTPS redirect enforced at Cloudflare level (Page Rule or Redirect Rule) `[8.20]`
- Minimum TLS version: 1.2 (enforce via Cloudflare SSL/TLS settings) `[8.24]`
- Cloudflare WAF: enable OWASP Core Ruleset + managed rules in production `[8.20]`
- Bot Management or Bot Fight Mode enabled for production `[8.20]`
- Rate limiting rules on all API endpoints (especially auth endpoints) `[8.5]`
- Workers: set `allowed_origins` — never allow `*` in production CORS config `[8.20]`

## Security Hardening
`ISO 27001: 8.2, 8.5, 8.8, 8.9, 8.24`

- **Cloudflare API Tokens**: use scoped tokens (not Global API Key); minimum permissions per token `[8.2]`
- **Vercel tokens**: scoped to project; rotate every 90 days `[8.5]`
- **Workers Secrets**: all sensitive values set via `wrangler secret put` or Cloudflare dashboard — never in `wrangler.toml` `[8.24]`
- **Vercel Env Vars**: mark all secrets as "Sensitive" (encrypted at rest, hidden after save) `[8.24]`
- **R2 buckets**: disable public access unless explicitly serving public assets `[8.12]`
- **Cloudflare Zero Trust**: use Access policies to protect staging and preview deployments `[8.2]`
- **Vercel preview deployments**: protect with Vercel Authentication or Cloudflare Access `[8.2]`
- **Dependency scanning**: run Snyk or OWASP DC on Workers and frontend code in CI `[8.8]`
- **Cloudflare Audit Log**: enabled — all account changes logged `[8.15]`

## CI/CD — GitHub Actions → Vercel + Cloudflare Workers

```yaml
# Typical pipeline flow (subsequent deployments — both services already wired)
1. Test (unit + integration)
2. SAST (CodeQL or SonarQube)
3. Dependency scan (Snyk)
4. Secrets scan (GitLeaks)
5a. Deploy frontend → Vercel (via vercel CLI or Vercel GitHub integration)
5b. Deploy Workers → Cloudflare (via wrangler deploy)
   ↑ 5a and 5b can run in parallel on subsequent deploys (URLs already set)
6. Smoke tests / health check (both frontend URL and API endpoint)

# First deployment — must follow cross-service URL wiring order (see checklist §4):
1–4. Same as above
5.   Deploy Workers first → capture API URL
6.   Set API URL in Vercel env vars; set frontend URL in Worker CORS config
7.   Redeploy Workers (CORS update); deploy frontend (with API URL set)
8.   Smoke tests / health check
```

- Use OIDC or scoped API tokens for both Vercel and Cloudflare in CI — no personal tokens `[8.5]`
- Preview deployments on every PR (Vercel) — protect with Cloudflare Access `[8.2]`
- Production deploy only from `main` branch after all checks pass `[8.32]`
- Never use `--force` or skip checks in deploy commands `[8.32]`

## Secrets Management
`ISO 27001: 8.24, 5.17`

- **Cloudflare Workers**: secrets set via `wrangler secret put <NAME>` per environment
- **Vercel**: environment variables set via Vercel dashboard or CLI; use Preview / Production scopes
- Never store secrets in `wrangler.toml`, `vercel.json`, or `.env` files committed to git `[5.17]`
- Separate secret values per environment (dev / staging / production) `[8.31]`
- Rotate all secrets immediately on any suspected exposure `[8.24]`

## Environment Separation
`ISO 27001: 8.31, 8.33`

| Environment | Vercel | Cloudflare Workers |
|---|---|---|
| dev | Local (`vercel dev`) | Local (`wrangler dev`) |
| staging | Vercel Preview or staging branch | Staging Worker environment |
| production | Vercel Production | Production Worker environment |

- Staging Workers use separate KV namespaces, D1 databases, and R2 buckets from production `[8.31]`
- Production data must never be used in dev or staging `[8.33]`

## Monitoring & Observability
`ISO 27001: 8.15, 8.16`

- **Cloudflare Workers**: use `console.log` → Cloudflare Logpush → external log sink (Datadog / Logtail / S3) `[8.15]`
- **Vercel**: Runtime logs available in dashboard; use Vercel Log Drains to ship to external sink `[8.15]`
- Log retention: minimum 12 months total (hot + cold) `[8.15]`
- **Sentry**: install in both Workers (`@sentry/cloudflare`) and Next.js (`@sentry/nextjs`) for error tracking `[8.16]`
- **Cloudflare Analytics**: monitor request volume, error rates, cache hit ratio, WAF events `[8.16]`
- Alerts on: Worker error rate > 1%, p99 latency > 500ms, WAF block spike, DDoS event `[8.16]`

## Backup & Recovery
`ISO 27001: 5.29, 5.30`

- **Cloudflare KV / D1**: export snapshots regularly; no built-in PITR — use external backup strategy
- **R2**: versioning not natively supported — implement object versioning pattern in application code or use lifecycle rules
- **Vercel deployments**: every deployment is immutable and can be instantly promoted — instant rollback available
- **Workers**: `wrangler rollback` available; previous versions retained by Cloudflare for 7 days
- DR runbook must include: rollback steps for both Vercel and Workers, DNS failover procedure `[5.30]`

## Rollback
`ISO 27001: 5.29`

- **Frontend (Vercel)**: instant rollback via Vercel dashboard or `vercel rollback` CLI — previous deployment promoted immediately
- **API (Workers)**: `wrangler rollback` to previous version; or redeploy tagged release from CI
- Target rollback time: < 5 minutes for both layers

## Cost Controls

- Cloudflare Workers: free tier is generous; monitor CPU time and request count per Worker
- Vercel: monitor bandwidth and build minutes; use ISR/SSG to reduce serverless function invocations
- R2: no egress fees — prefer R2 over S3 for assets served via Cloudflare
- Set up Cloudflare billing alerts and Vercel spend notifications

## Autopilot Credential Security
`ISO 27001: 8.24, 5.17, 8.2`

> This section governs how credentials are stored and used when Claude Code runs in Autopilot mode.
> The goal is that the AI never reads a credential value — it only references variable names.

### Threat Model

| Threat | Mitigation |
|---|---|
| Credential committed to git | `.secrets/` is gitignored; only `*.template` files are committed |
| Credential in Claude's context window | Credentials are pre-loaded as shell env vars; Claude references `$VAR_NAME` only |
| Credential in tool call output / logs | Wrapper scripts call CLIs that read env vars internally — no token flags in commands |
| Prompt injection → env var exfiltration | `check-credential-inspection.py` PreToolUse hook blocks inspection commands |
| Leaked token blast radius | All tokens scoped to minimum permissions (see table below) |
| Stale token exposure window | Short-lived tokens where supported (see table below) |

### Required Token Scopes (Layer 3 — Minimal Scope)

| Service | Where to create | Required scopes | Notes |
|---|---|---|---|
| GitHub | github.com/settings/tokens → Fine-grained PAT | `contents: read+write`, `workflows: read+write` on specific repo only | Set expiry: 30 days. Never use classic PAT with repo-wide access |
| Vercel | vercel.com/account/tokens | Project-scoped token | Rotate every 90 days |
| Cloudflare | dash.cloudflare.com/profile/api-tokens | `Workers Scripts: Edit`, `D1: Edit` for specific account. **Never use Global API Key** | Set TTL if available |
| Neon | console.neon.tech | Connection string for one database only — not admin credentials | Use separate strings per environment |
| Resend | resend.com/api-keys | `Sending access` on verified domain only — not full account | |
| Upstash | console.upstash.com | Specific database REST token — not account token | |

### Token Expiry (Layer 4 — Short-Lived Tokens)

| Service | Supports TTL | Recommended setting |
|---|---|---|
| GitHub fine-grained PAT | Yes | 30 days — rotate after each project deploy |
| Cloudflare API token | Yes | Set TTL in token settings |
| Vercel token | No | Rotate manually every 90 days |
| Neon connection string | No | Rotate immediately if any exposure suspected |
| Resend API key | No | Rotate every 90 days |
| Upstash REST token | No | Rotate every 90 days |

### Setup Workflow (one-time per project)

1. Install 1Password CLI: `brew install 1password-cli`
2. Sign in: `op signin`
3. Copy `.secrets/manifest.yaml.template` → `.secrets/manifest.yaml`
4. Fill in `op://VaultName/ItemName/field` paths for each service
5. Copy `.secrets/load-credentials.sh.template` → `.secrets/load-credentials.sh`
6. Update `op://` paths in `load-credentials.sh` to match manifest
7. Before each Claude Code Autopilot session: `source .secrets/load-credentials.sh`
8. Start Claude Code: `claude`

Credentials are loaded into shell memory only. Nothing is written to disk. Claude Code inherits the shell environment and all wrapper scripts consume credentials by env var reference.

### Wrapper Scripts (Layer 2)

Claude calls these scripts instead of CLI tools directly. The AI never references a token value.

| Script | Wraps | Env vars required |
|---|---|---|
| `scripts/deploy-vercel.sh` | `vercel deploy` | `VERCEL_TOKEN`, `VERCEL_ORG_ID` |
| `scripts/deploy-wrangler.sh` | `wrangler deploy` | `CLOUDFLARE_API_TOKEN`, `CLOUDFLARE_ACCOUNT_ID` |
| `scripts/db-migrate.sh` | `npx prisma migrate` | `DATABASE_URL` |
| `scripts/gh-push.sh` | `git push` | `GH_TOKEN` |

### Layer 5 — Separate Execution Context
> **Recommended but not implemented.**
>
> In this design, Claude generates a `deploy-manifest.sh` artifact but does not execute it.
> A separate trusted process (not the AI) reads the manifest and performs the actual deployment with credentials.
> This is the only architecture where the AI provably never interacts with credentials at all.
> Adoption is deferred because it requires a human review step or a trusted execution runner,
> which breaks fully unattended Autopilot operation. Implement when highest-security deployment is required.

---

## Compliance Evidence for ISO 27001 Audits
`ISO 27001: 5.28, 8.15`

| Evidence Required                    | Source                                              |
|--------------------------------------|-----------------------------------------------------|
| All API calls / changes logged       | Cloudflare Audit Logs                               |
| Access to sensitive data audited     | Cloudflare Logpush → SIEM                           |
| Configuration drift detection        | Terraform state diff + Cloudflare Audit Logs        |
| Vulnerability scan results           | Snyk CI reports + Cloudflare WAF event logs         |
| Secret access audit                  | CI/CD logs (secret usage) + Cloudflare Audit Logs   |
| Network / WAF logs                   | Cloudflare Firewall Events + Logpush                |
| Deployment history                   | Vercel deployment log + Wrangler deploy history     |
| Rollback capability evidence         | Vercel instant rollback + `wrangler rollback` log   |
