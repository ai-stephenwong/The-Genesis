# Trigger: Generate Compliance Report

Execute this when the user says **"generate compliance report"** or similar.

---

## Steps

1. Ask for: release version, reviewer name, environment (staging/production)
2. Check that all required pipeline artifacts exist in `artifacts/` — warn if any are missing
3. Spawn a `compliance-officer` agent (per `agent_docs/generic/agent-roles.md`) with the latest artifacts as input
4. Agent writes output to `artifacts/compliance/compliance-YYYYMMDD-HHmm.md`
