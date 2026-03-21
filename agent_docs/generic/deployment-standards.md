<!-- last-reviewed: 2026-03-17 | reviewed-by: Stephen Wong | next-review: 2026-09-17 -->

# Deployment Standards (Company Standard)

> These rules apply to all projects regardless of cloud provider or stack.
> Do not override without explicit approval.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

## Deployment Trigger Rule — Non-Negotiable
`ISO 27001: 8.32`

> **ALL deployments to ALL environments MUST be triggered exclusively by a commit or merge to the Git repository (GitHub / GitLab). No exceptions.**

Every deployment — whether to dev, staging, or production — must originate from a git event (push, merge, tag). The CI/CD pipeline is the **only** permitted deployment mechanism.

| Permitted | Prohibited |
|---|---|
| Push to `develop` → CI/CD pipeline deploys to dev | `vercel --prod` from a local machine |
| Merge PR to `release/*` → CI/CD pipeline deploys to staging | `wrangler deploy` from a local machine |
| Merge PR to `main` → CI/CD pipeline deploys to production | `kubectl apply` from a local machine |
| Re-deploy a previous git tag via CI/CD (rollback) | `aws ecs update-service` from a local machine |
| | Clicking "Deploy" in any cloud provider console |
| | Any `deploy` CLI command run outside the pipeline |

**Why this rule exists:**
- Every deployment is automatically traceable to a specific commit, PR, and author
- All quality gates (tests, scans, compliance checks) are guaranteed to run before every deploy
- No developer — including tech leads — may bypass the pipeline without explicit documented approval
- Rollbacks must be performed by re-deploying a previous tagged commit through the pipeline, not by issuing direct cloud commands

**Enforcement:** The `devops-engineer` must configure the CI/CD pipeline and access controls so that direct deployment is not possible — service account credentials used for deployment must exist only inside the CI/CD system, never distributed to individual developers.

---

## Environments

| Environment | Purpose                        | Triggered by              | Data Policy                  |
|-------------|--------------------------------|---------------------------|------------------------------|
| dev         | Developer testing              | Push to `develop`         | Synthetic / anonymised only  |
| staging     | QA / UAT / client review       | Push to `release/*`       | Synthetic / anonymised only  |
| production  | Live system                    | Merge to `main` via PR    | Real data — restricted access|

- Production data must **never** be used in dev or staging `[ISO 27001: 8.33]`
- Each environment must be **strictly separated** — no shared credentials or network access between environments `[ISO 27001: 8.31]`

## General Rules
`ISO 27001: 8.9, 8.32`

- Infrastructure must be defined as code (IaC) — **no manual console changes** in staging or production `[8.32]`
- All secrets stored in the cloud provider's secret manager — never in code, env files, or CI/CD logs `[8.24, 5.17]`
- All services must be containerised (Docker), **except** when deploying to serverless/edge platforms (Vercel, Cloudflare Workers) where platform-native deployment applies
- Use container orchestration (Kubernetes or managed equivalent) for staging and production of containerised services
- Health checks required on all deployed services (`GET /health`)
- Zero-downtime deployment required for production (rolling update or blue/green) `[5.29]`
- **All deployments must be triggered by a git commit or merge — no direct deploys from local machines or cloud consoles** (see Deployment Trigger Rule above) `[8.32]`

## Container Security
`ISO 27001: 8.8, 8.9`

- Container images must be scanned for vulnerabilities before deploy (Trivy or equivalent) `[8.8]`
- No critical or high CVEs permitted in production images `[8.8]`
- Images must run as a **non-root user**
- Use minimal base images (Alpine or distroless preferred)
- Pin base image versions — no `:latest` tags in production Dockerfiles
- Store images in a private registry (ECR / Artifact Registry / ACR) — never Docker Hub for production `[8.12]`

## CI/CD Pipeline Requirements
`ISO 27001: 8.25, 8.29, 8.32`

Every deployment pipeline must include these stages in order:

| Stage              | Required | Notes                                               |
|--------------------|----------|-----------------------------------------------------|
| Unit tests         | Yes      | Fail pipeline if any test fails                     |
| Integration tests  | Yes      | Fail pipeline if any test fails                     |
| **API spec lint**  | **Yes**  | **Spectral or Vacuum — validates `api-spec.yaml` conforms to OpenAPI 3.1 and company ruleset; fail pipeline on error** |
| SAST scan          | Yes      | SonarQube / CodeQL `[8.29]`                        |
| Dependency scan    | Yes      | Snyk / OWASP Dependency Check `[8.8]`              |
| Secrets scan       | Yes      | GitLeaks / GitHub secret scanning `[5.17]`         |
| Container scan     | Yes (container deployments) | Trivy `[8.8]` — skip for Vercel/Workers deployments |
| Build & push image | Yes      | Tag with git SHA + semver                           |
| Deploy to env      | Yes      | Environment-gated (staging before production)       |
| Per-service smoke tests | Yes | Run immediately after each service deploys — frontend, CMS, API each tested independently; fail pipeline if any check fails |
| Cross-service smoke tests | Yes | Run after all services in the environment are deployed — full auth flow, CORS, API call round-trip |

- Pipeline configuration files must be version-controlled and reviewed via PR `[8.32]`
- CI/CD service accounts must follow least-privilege — separate credentials per environment `[8.2]`
- **API spec lint**: use [Spectral](https://stoplight.io/open-source/spectral) (`spectral lint api-spec.yaml`) or [Vacuum](https://quobix.com/vacuum/) (`vacuum lint api-spec.yaml`) with a project `.spectral.yaml` ruleset enforcing OpenAPI 3.1 validity and company conventions (enum casing, required descriptions, error schema). Fail the pipeline on any error.

> For Vercel + Cloudflare deployments, replace "Container scan" with a dependency vulnerability scan (Snyk or npm audit) and skip Docker-specific stages. See `deployment-vercel-cloudflare.md` for the platform-specific pipeline.

## Secrets Management
`ISO 27001: 8.24, 5.17`

- All secrets injected at runtime via secret manager — never baked into images
- Secret access logged and auditable `[8.15]`
- Rotate secrets on any suspected exposure immediately `[8.24]`
- Use separate secret namespaces per environment (e.g. `/dev/db-password`, `/prod/db-password`)

### Per Cloud Provider

| Cloud | Secret Manager         | IaC Tool              | Container Platform          |
|-------|------------------------|-----------------------|-----------------------------|
| AWS   | AWS Secrets Manager    | Terraform / AWS CDK   | ECS Fargate / EKS           |
| GCP   | GCP Secret Manager     | Terraform / Pulumi    | Cloud Run / GKE             |
| Azure | Azure Key Vault        | Terraform / Bicep     | Azure Container Apps / AKS  |
| Vercel + Cloudflare | Vercel Env Vars (Sensitive) + CF Workers Secrets | Terraform (CF provider) + Wrangler | Vercel (frontend) + Railway / Fly.io (backend) |

## Rollback Policy
`ISO 27001: 5.29, 5.30`

- Every production deploy must have a documented rollback plan before deploying
- Rollback must be executable within **15 minutes** of detection (RTO target)
- Previous image tag must be retained for minimum 30 days to enable rollback
- Rollback procedure must be tested at least once per quarter

## Change Management
`ISO 27001: 8.32`

- All production changes require a PR reviewed and approved by at least 1 other developer
- Emergency hotfixes must be tracked with a post-change review within 24 hours
- Changes to IaC must be reviewed identically to application code changes
- Deployment windows for production: communicate to team before deploying

## Monitoring & Alerting Post-Deploy
`ISO 27001: 8.16`

- Confirm `/health` endpoint returns `200` within 2 minutes of deploy
- Monitor error rate for 15 minutes post-deploy — roll back if error rate spikes > 5%
- Ensure log ingestion is active in the new deployment before closing the deploy window
- Alerts must be configured for: service down, p99 latency breach, error rate spike

## Audit & Evidence
`ISO 27001: 8.15, 5.28`

- All pipeline runs must be logged and retained for minimum 12 months `[8.15]`
- Deployment events (who deployed, what version, when, to which environment) must be auditable
- Pipeline logs must not contain secrets, passwords, or tokens — redact before logging `[8.11]`

## Environment Variable Validation (Required Before Cutover)

All required environment variables must be **verified as present and non-empty in the target environment** before cutover — not just compared against `.env.example`.

- Maintain a required env var manifest in `agent_docs/project/deployment.md` listing every variable, its purpose, and which service owns it
- Run a startup validation check in the application that fails fast with a clear error if any required env var is missing — do not allow the service to start in a broken state
- The `devops-engineer` must confirm each variable is set in the secret manager / platform env config **before** the deployment pipeline runs
- Cross-service variables (e.g. `FRONTEND_URL` used in API CORS config, `NEXT_PUBLIC_API_URL` used in frontend) must be explicitly called out and double-checked — these are the most common source of first-deployment failures

## Per-Service Post-Deploy Smoke Tests (Required — run immediately after each service deploys)

Every service deployment — frontend, CMS frontend, or API — must pass a fast, minimal smoke test **before** the deployment is considered successful. These run independently per service; they do not wait for other services to be deployed first. The purpose is to catch obvious failures (blank page, 500 on health, broken JS bundle) the moment they happen.

### Frontend (user-facing web app)

| Check | How | Pass condition |
|---|---|---|
| Homepage loads | `curl -s -o /dev/null -w "%{http_code}" {FRONTEND_URL}` | `200` |
| JS bundle served | `curl -s -o /dev/null -w "%{http_code}" {FRONTEND_URL}/assets/index-*.js` | `200` (or equivalent Vite/Next.js asset path) |
| No JS console error on load | Playwright headless: open homepage, check `page.on('pageerror')` | Zero uncaught errors |

### CMS Frontend

| Check | How | Pass condition |
|---|---|---|
| CMS login page loads | `curl -s -o /dev/null -w "%{http_code}" {CMS_URL}/login` (or root) | `200` |
| JS bundle served | Same as frontend above | `200` |

### API

| Check | How | Pass condition |
|---|---|---|
| Health endpoint | `curl -s -o /dev/null -w "%{http_code}" {API_URL}/health` | `200` |
| Health response body | `curl -s {API_URL}/health` | `{ "status": "ok" }` or equivalent — not an error body |
| No 500 on root | `curl -s -o /dev/null -w "%{http_code}" {API_URL}/` | Not `500` |

**Rules:**
- These smoke tests run as the **final step of each service's deploy job** in the CI/CD pipeline — not as a separate job that runs after all services finish
- A smoke test failure must **fail the pipeline and block the deployment** — not just emit a warning
- If the API smoke test fails, do not proceed to deploy the frontend services (they will have no working backend)
- Results must be logged in the deployment artifact

## Cross-Service Smoke Tests (Required)

Smoke tests must go beyond `/health` endpoint checks. After every deployment to staging or production, the following must pass:

- At least one **full cross-service API call**: frontend base URL → API base URL → database response
- CORS preflight check: an OPTIONS request from the deployed frontend origin must return `Access-Control-Allow-Origin` with the correct value
- Auth flow: a test login must succeed end-to-end
- API base URL check: verify the configured base URL resolves to a valid API route (not a 404)

These tests must be automated in the CI/CD pipeline post-deploy stage. Manual spot-checks are not sufficient.

## Pre-Production Deploy Checklist
`ISO 27001: 8.29`

- [ ] **Deployment triggered via git commit/merge through CI/CD pipeline — not by a direct CLI command or cloud console action**
- [ ] All pipeline stages passed (tests, **API spec lint**, SAST, dependency scan, secrets scan, container scan)
- [ ] Container image tagged with correct version
- [ ] Secrets confirmed in secret manager — no env files used
- [ ] **All required env vars verified present in target environment** (not just `.env.example` comparison)
- [ ] **Cross-service env vars double-checked** (CORS origins, API base URLs, frontend URLs)
- [ ] **API base URL verified to include correct path prefix** (e.g. `/api/v1`)
- [ ] Rollback plan documented and communicated to team
- [ ] Monitoring and alerting confirmed active
- [ ] **Per-service smoke tests passed** for each deployed service (homepage 200, JS bundle 200, API /health 200 with ok body)
- [ ] **Cross-service smoke tests passed** (CORS preflight, auth flow, at least one full API call)
- [ ] Deployment event logged (version, deployer, timestamp)
