<!-- part-of: agent-roles.md | stage: deploy-environment -->

> This file defines a **pipeline stage**, not an agent role.
> It is executed by the `devops-engineer` or `orchestrator` — not by a separate agent.
> **Before reading this file**, read `agent-roles.md` for universal rules and pipeline overview.

---

### 10. `deploy-environment`

**Role:** Trigger a deployment to any non-production environment (dev, UAT, pre-production, staging, or any custom environment defined in the project) via CI/CD, monitor the pipeline run, and verify smoke tests pass. This agent does **not** run `vercel deploy` or `wrangler deploy` directly — it pushes to the target branch and lets GitHub Actions handle the actual deployment.

> Invoke as: `run agent deploy-environment env={environment}` (e.g. `env=uat`, `env=staging`, `env=pre-production`)

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/pipeline.md`, `agent_docs/project/deployment.md`, `agent_docs/project/git-workflow.md` |
| **Writes** | `artifacts/devops/deploy-{environment}-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Confirm all required upstream gates have passed for the target environment before triggering
- Look up the target branch for `{environment}` in `agent_docs/project/deployment.md` (e.g. `develop` for dev/UAT, `release/*` for staging/pre-prod)
- Push the correct branch to its remote counterpart via GitHub MCP — this triggers the GitHub Actions CI/CD pipeline
- Monitor the GitHub Actions run via GitHub MCP until it completes
- **Run deployment sanity check before smoke tests:** Once the pipeline reports success, fetch `GET /health` from every deployed server and verify: `deploy_time > git_commit_time` (causality), `git_commit` matches the pushed commit SHA (commit match), and `deploy_time` is after the pipeline start time (freshness). If any HALT-level check fails, stop immediately and report — do not proceed to smoke tests. See `api-conventions.md` — Deployment Sanity Check.
- Report the deployment result: pipeline pass/fail, environment URL, smoke test outcome
- **MUST DO — Add confirmed URLs to `.claude/settings.json`:** If the deployment produces new or changed URLs, immediately add `WebFetch(domain:{domain})` entries to the project's `.claude/settings.json`. This is especially critical on first deployment when URLs are established for the first time.
- If the CI/CD run fails: surface the failing step and reason; do not retry without understanding the root cause
- If smoke tests fail: halt and report — do not mark the environment as passed

**Must NOT:**
- Run `vercel deploy`, `wrangler deploy`, or any MCP deployment tool directly — all deployment must go through GitHub Actions
- Push directly to `main`
- Mark the environment as passed without confirmed smoke test results
- Deploy to production — that is `deploy-production` (§11) only

**Output format:**
```markdown
# {Environment} Deployment — YYYY-MM-DD HH:mm
## Target Environment
  Environment : {environment}  (dev | uat | pre-production | staging | custom)
  Branch pushed: {branch} → origin/{branch}
  GitHub Actions run: {run URL}
## Pipeline Result
  Status: PASSED | FAILED
  Duration: {duration}
## Environment URLs
  Frontend : {URL}
  API      : {URL}
  CMS      : {URL} (if applicable)
## Smoke Test Results
  API health check       : PASS | FAIL
  API CORS preflight     : PASS | FAIL
  Frontend load          : PASS | FAIL
  Frontend → API data    : PASS | FAIL
## Issues Found
  (list any failures with details)
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED)
FAILED_REASON: (if FAILED)
GATE: {environment}-sign-off (required before production deploy if this is the final pre-production environment)
ARTIFACTS: artifacts/devops/deploy-{environment}-YYYYMMDD-HHmm.md
```

---
