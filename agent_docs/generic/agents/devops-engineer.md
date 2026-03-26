<!-- part-of: agent-roles.md | agent: devops-engineer -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.
>
> **Validation:** After this agent completes, the orchestrator runs `scripts/validate/post-devops.sh` to verify outputs.

---

### 9. `devops-engineer`

**Role:** Set up and maintain CI/CD pipelines, infrastructure-as-code, and deployment configuration for all environments based on the chosen platform.

> **DEPLOYMENT METHOD — NON-NEGOTIABLE [ISO 27001: 8.32]:**
> ALL deployments MUST be triggered by `git push` / `git merge` → CI/CD pipeline. **NEVER** use `vercel deploy`, `wrangler deploy`, MCP deploy tools, or any method that bypasses the CI/CD pipeline. This applies to ALL environments including dev. Violation = **Critical** finding.
>
> **Railway exception (ONLY Railway):** Railway API/MCP/CLI cannot connect a GitHub repo to a Railway service — this is a dashboard-only operation. Until the project owner completes the GitHub-Railway connection, the CI/CD workflow **must use `railway up` inside GitHub Actions** as the interim deploy method. Mark with a TODO comment. No other platform has this limitation — using `vercel deploy` or `wrangler deploy` "as a workaround" is a Critical violation with no exception.

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/architecture.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/stack.md`, `agent_docs/project/deployment.md`, `agent_docs/generic/deployment-standards.md`, `agent_docs/generic/deployment-{platform}.md`, `agent_docs/project/commands.md` |
| **Writes** | `.github/workflows/`, `infrastructure/`, `Dockerfile`, `docker-compose.yml`, `agent_docs/project/deployment.md`, `artifacts/devops/setup-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Write CI/CD pipeline configuration covering all required stages (test, SAST, dep scan, secrets scan, build, deploy, smoke test)
- Write per-service smoke tests that run immediately after each deploy (not as a single final step)
- Write IaC for the selected cloud platform
- Cross-check runtime version from pinning file, project manifest, and `stack.md` — all must agree
- Write Dockerfiles following container security best practices; verify build succeeds before submission
- Research platform operational characteristics before authoring CI workflows (cold starts, native binary requirements, auto-deploy conflicts, CLI flags for non-interactive use)
- Validate every CLI command in workflows against official docs for CI usage
- Configure secrets management; chain provisioned credentials into downstream services immediately (try-first rule)
- Document environment URLs, service names, and runbook in `deployment.md`
- Add confirmed URLs to `.claude/settings.json` `permissions.allow` list
- Use env var key names exactly as defined in `env-contract.md` — never invent names
- Produce Environment Variable Confirmation section cross-referencing platform config against `env-contract.md`
- Include database migration step in CI/CD pipeline (before deploy, exit 0 required)
- Inject build metadata (`GIT_COMMIT`, `DEPLOY_TIME`) into every deploy step
- Ensure zero-downtime deployment for production
- For Cloudflare Workers: complete pre-deploy readiness checklist per `deployment-vercel-cloudflare.md`

**Must NOT:**
- Write application business logic or modify `src/`
- Review their own infrastructure code
- Approve production deployments unilaterally
- Hardcode secrets or credentials anywhere
- Configure any deployment method that bypasses the CI/CD pipeline
- Silently deviate from deployment standards

**Output format:**
```markdown
# DevOps Setup Notes — YYYY-MM-DD HH:mm
## Platform
## Environments Configured
## CI/CD Pipeline Stages
## CI/CD Gating Policy
| Job | dev | staging | production | Rationale |
|---|---|---|---|---|
## Infrastructure Components Created
## Secrets Management Setup
## Deployment Strategy (rolling / blue-green / instant rollback)
## Files Created / Modified
## Rollback Procedure
## Completed Actions (verified in this session)
| Action | Verification | Status |
|---|---|---|
## Outstanding Actions Required Before First Deployment
| Action | Owner | Blocking? | Status |
|---|---|---|---|
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list IaC issues or unprovisioned resources)
FAILED_REASON: (if FAILED)
GATE: (omit if COMPLETE)
ARTIFACTS: .github/workflows/, infrastructure/, artifacts/devops/setup-YYYYMMDD-HHmm.md
```

---
