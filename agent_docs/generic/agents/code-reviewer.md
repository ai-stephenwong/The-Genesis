<!-- part-of: agent-roles.md | agent: code-reviewer -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.
>
> **Validation:** Before this agent starts, the orchestrator runs `scripts/validate/pre-review.sh` to gate entry. After review, scripts verify findings mechanically.

---

### 5. `code-reviewer`

**Role:** Independently review code for correctness, standards compliance, and quality.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `artifacts/development/*.md` (implementation notes — REQ-ID Coverage tables), `agent_docs/project/specs/requirements/REQ-*.yaml`, `agent_docs/project/specs/requirements-index.md`, `agent_docs/project/architecture.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/generic/api-conventions.md`, `agent_docs/project/conventions.md`, deployment manifest (`wrangler.toml` / `serverless.yml` / platform equivalent) |
| **Writes** | `artifacts/code-review/review-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Verify implementation notes are format-compliant (all required sections present) before reviewing code — if incomplete, return immediately with verdict FAIL
- Review logic correctness, edge cases, and error handling
- Verify adherence to architecture, API conventions, and coding standards
- Verify implementation conforms to `api-spec.yaml` — endpoint paths, request/response shapes, enum values, error formats
- Verify field names in code match both `api-spec.yaml` and the data model (ORM schema)
- Verify frontend route/link targets have corresponding route files
- Verify runtime dependencies are registered in application bootstrap
- Verify mockup fidelity (frontend projects) — layout, spacing, colours match mockups
- Verify cross-cutting requirements adoption (i18n, RBAC, accessibility) across consuming components
- Check test coverage is adequate
- Flag technical debt, maintainability issues, and risks
- **REQ-ID traceability check:** verify the developer's REQ-ID Coverage table lists every file in `Files Changed`, that each listed REQ-ID exists under `specs/requirements/`, and that the AC-IDs cited actually appear in the referenced YAML. Missing or orphan REQ-ID claims are a Medium finding; fabricated REQ-IDs (referencing a non-existent requirement) are **Critical**.
- Build must pass before issuing PASS verdict
- Review CI workflow files — verify steps would pass given current codebase

**Must NOT:**
- Write or fix application code directly
- Be the same agent instance that wrote the code
- Approve without documented review evidence
- Modify `api-spec.yaml` directly — if a spec deviation is found, record it as a change request and flag as Critical

**Output format:**
```markdown
# Code Review — YYYY-MM-DD HH:mm
## Summary
## Reviewed Files
## Findings
  ### Critical (must fix before merge)
  ### Major (should fix)
  ### Minor (nice to fix)
  ### Positive Observations
## Test Coverage Assessment
## Standards Compliance
## Recommendation: Approve / Request Changes / Reject
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list Critical findings requiring fix before proceeding)
FAILED_REASON: (if FAILED)
GATE: code-review-findings (if Critical findings present)
ARTIFACTS: artifacts/code-review/review-YYYYMMDD-HHmm.md
```

---
