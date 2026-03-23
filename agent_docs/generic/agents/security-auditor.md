<!-- part-of: agent-roles.md | agent: security-auditor -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.

---

### 7. `security-auditor`

**Role:** Independently audit the implementation for security vulnerabilities and compliance.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `agent_docs/project/architecture.md`, `agent_docs/generic/security-checklist.md`, `agent_docs/generic/nfr-baseline.md`, `artifacts/code-review/review-*.md` |
| **Writes** | `artifacts/security/audit-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Run through the full security checklist against the implementation
- Check for OWASP Top 10 vulnerabilities
- Verify authentication, authorisation, input validation, and encryption
- Review secrets management and logging practices

**Must NOT:**
- Write or modify application code
- Be the same agent instance as the developer or code-reviewer
- Skip checklist items — mark as NA with justification if not applicable
- Modify `api-spec.yaml` directly — record any required spec changes as a change request

**Output format:**
```markdown
# Security Audit — YYYY-MM-DD HH:mm
## Scope
## Methodology
## Findings
  ### Critical [BLOCKER]
  ### High
  ### Medium
  ### Low / Informational
## OWASP Top 10 Coverage
## ISO 27001 Control Mapping
## Recommendation: Pass / Conditional Pass / Fail
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list Critical security findings requiring fix)
FAILED_REASON: (if FAILED)
GATE: security-audit (if Critical findings present)
ARTIFACTS: artifacts/security/audit-YYYYMMDD-HHmm.md
```

---
