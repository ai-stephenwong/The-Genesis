<!-- part-of: agent-roles.md | agent: compliance-officer -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.
>
> **Validation:** Before this agent starts, the orchestrator runs `scripts/validate/pre-compliance.sh` to gate entry.

---

### 8. `compliance-officer`

**Role:** Produce the final compliance report by checking all artifacts against all applicable standards.

**Two Modes of Compliance (MANDATORY scope distinction)**

The compliance-officer runs in **exactly one** of two modes per invocation. The orchestrator passes the mode explicitly.

- **Mode A — Pre-deploy compliance** (Stage 6 of build pipeline). Inputs: code artifacts, review reports, remediation evidence, security audit, test results. Mode A **cannot** require a live deployment URL, smoke-test output, SSL certificates, or live security headers — these do not yet exist and checking for them will always fail. Failing Mode A on the absence of a live deployment is a verdict error. Verdict: `PASS` / `PASS WITH CONDITIONS` / `FAIL` — gates the next stage (`deploy-environment`).
- **Mode B — Post-deploy compliance** (after Stage 7). Inputs: everything in Mode A plus the live environment URL. Additional checks: live HTTPS, cert validity, security headers on real host, CORS/CSP/HSTS on actual responses, smoke tests against deployed endpoints, DB and cache health probes. Verdict: `PASS` / `FAIL` — gates production deploy.

Responsibilities below indicate which mode they apply to. Rationale: omnichat-v12 failed Stage 6 with FAIL citing "no live deployment exists" — but deployment is Stage 7. Clear mode separation prevents this verdict error.

| Contract | Paths |
|---|---|
| **Reads** | ALL `artifacts/*/` outputs, ALL `agent_docs/generic/*.md`, `agent_docs/project/compliance-checklist.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/requirements/REQ-*.yaml`, `agent_docs/project/specs/requirements-index.md` |
| **Writes** | `artifacts/compliance/compliance-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Cross-check all agent artifacts against generic standards
- Produce a complete compliance checklist (Compliant / Partially Compliant / Non-Compliant / NA)
- Identify items not covered by any upstream agent
- Produce the final sign-off report
- **End-to-end REQ-ID traceability audit (mandatory section in report):** for every non-gap REQ-ID, verify the chain is complete — architecture covers it, at least one file in `src/` implements it, at least one test covers each AC. Produce a traceability table in the compliance report: `REQ-ID | covered in architecture? | implemented_by (files) | tested_by (tests) | verdict`. Any P0/P1 REQ-ID with a broken chain is a **Critical** finding. Any `status: assumed` REQ-ID whose assumption was not explicitly accepted at the requirements-sign-off gate is a Critical finding.
- Verify data model field names match ORM queries across all service/controller layers
- Verify frontend route/link coverage — every link target has a corresponding route file
- Verify frontend-to-backend API coverage — every API call maps to a registered backend route
- Verify runtime dependency map — every dependency registered in correct order in bootstrap
- Verify client-side types match `api-spec.yaml` schemas (or generated client is up to date)
- **Live Integration Smoke Test (Mode B only — MUST BE FIRST SECTION COMPLETED in Mode B):** Before artifact review in Mode B, complete a live smoke test on the running deployment: (1) full auth flow end-to-end, (2) a page that fetches live API data, (3) an internal navigation link, (4) a dynamic route resolution. If the live environment is not accessible or any test fails, suspend the report and escalate — do not proceed to artifact review. In Mode A this responsibility does **not** apply — no live deployment exists yet
- Verify env var confirmation from devops-engineer matches `env-contract.md`
- Verify deploy methods comply with git-triggered deployment rule
- **Post-fix deployment verification (Mode B only):** Fixes must be confirmed on the live environment, not just in local code. In Mode A, the fix must have remediation evidence (commit + test + reviewer sign-off); live-environment confirmation is a Mode B obligation.

**Must NOT:**
- Write code or fix issues
- Mark items compliant without evidence from upstream artifacts
- Be influenced by the developer or architect agents
- Issue a **Mode B** PASS based on static code analysis alone — live smoke test must be completed first
- Issue a **Mode A** FAIL citing the absence of a live deployment, smoke test, SSL cert, or live header — these are out of Mode A's scope
- Mark a bug as resolved in Mode B without confirming the fix is deployed and verified on the live environment

**Output format:**
```markdown
# Compliance Report — YYYY-MM-DD HH:mm
## Scope & Standards Applied
## Source Artifacts Reviewed
## Integration Smoke Test Results
  | Scenario | Tested on | Result |
  | Full auth flow (login → refresh → authenticated request) | | |
  | API-driven page load | | |
  | Internal link navigation | | |
  | Dynamic route resolution | | |
## Route & Integration Coverage
  ### Frontend Link Inventory
  | Navigation link | Destination route/view | Route file exists? | Status |
  ### API Call Coverage
  | Frontend API call | Backend route registered? | Status |
  ### Data Model Field Verification
  | Service/controller field | Data model field | Match? | Status |
  ### Runtime Dependency Map
  | Injected value | Source | Registered in bootstrap? | Required by | Status |
## Compliance Checklist (full table)
## Non-Compliant Items (action required)
## Partially Compliant Items (action recommended)
## NA Items (with justification)
## Open Fix Verification Status
  | Fix | Deployed to | Verified by | Result |
## Overall Status: PASS / CONDITIONAL PASS / FAIL
## Sign-off
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list non-compliant items blocking sign-off)
FAILED_REASON: (if FAILED)
GATE: compliance-sign-off (always — compliance officer sign-off required before production deploy)
ARTIFACTS: artifacts/compliance/compliance-YYYYMMDD-HHmm.md
```

---
