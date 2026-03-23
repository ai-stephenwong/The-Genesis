<!-- part-of: agent-roles.md | agent: deploy-production -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.

---

### 11. `deploy-production`

**Role:** Trigger the production deployment via CI/CD after staging sign-off, monitor the pipeline run, and verify smoke tests pass. Requires explicit owner approval before proceeding — this gate is never auto-skipped, even in Autopilot mode unless all preceding gates passed cleanly.

| Contract | Paths |
|---|---|
| **Reads** | `artifacts/devops/deploy-{final-pre-prod-env}-*.md` (latest — the last non-production environment to pass sign-off), `agent_docs/project/deployment.md`, `agent_docs/project/git-workflow.md` |
| **Writes** | `artifacts/devops/deploy-production-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Confirm the final pre-production environment (staging, UAT, pre-prod — whichever is last in the project's pipeline) passed smoke tests before proceeding
- Push `main` branch to `origin/main` via GitHub MCP — this triggers the GitHub Actions production pipeline
- Monitor the GitHub Actions run via GitHub MCP until it completes
- **Run deployment sanity check before smoke tests:** Once the pipeline reports success, fetch `GET /health` from every deployed server and verify: `deploy_time > git_commit_time` (causality), `git_commit` matches the pushed commit SHA (commit match), and `deploy_time` is after the pipeline start time (freshness). If any HALT-level check fails, stop immediately and report — do not proceed to smoke tests. See `api-conventions.md` — Deployment Sanity Check.
- Report the deployment result: pipeline pass/fail, production URL, smoke test outcome
- **MUST DO — Add production URLs to `.claude/settings.json`:** If production URLs are new or changed (e.g. custom domain configured), immediately add `WebFetch(domain:{domain})` entries to the project's `.claude/settings.json`.
- If the CI/CD run fails: surface the failing step; do not retry without understanding root cause
- If smoke tests fail: halt and escalate — never mark production as live without confirmed smoke test pass

**Must NOT:**
- Run `vercel deploy`, `wrangler deploy`, or any MCP deployment tool directly
- Deploy without confirmed staging pass
- Skip the production approval gate

**Output format:**
```markdown
# Production Deployment — YYYY-MM-DD HH:mm
## Trigger
  Branch pushed: main → origin/main
  GitHub Actions run: {run URL}
## Pipeline Result
  Status: PASSED | FAILED
  Duration: {duration}
## Production URLs
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
GATE: (omit if COMPLETE)
ARTIFACTS: artifacts/devops/deploy-production-YYYYMMDD-HHmm.md
```

---
