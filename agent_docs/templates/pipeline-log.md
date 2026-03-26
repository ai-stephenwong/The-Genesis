# Pipeline Execution Log

> Append-only trace of every pipeline event. The orchestrator appends to this file
> at every stage transition, validation run, remediation round, and gate decision.
> Never edit or delete existing entries — only append new ones.
>
> This file serves as the human-readable flight recorder for the pipeline run.
> For machine-readable metrics, see `artifacts/runs/run-*.json`.

---

## Run: {run-id}
**Started:** {YYYY-MM-DD HH:mm}
**Mode:** {autopilot | co-pilot | manual}
**Genesis version:** {commit hash}

---

<!-- Orchestrator: append entries below using this format:

### [{HH:mm}] {event-type} — {stage/agent}
- **Action:** {what happened}
- **Result:** {outcome}
- **Duration:** {Xm Ys}
- **Validation:** {N passed, N failed} (if applicable)
- **Notes:** {any observations, decisions, or issues}

Event types:
  STAGE-START     — agent invoked
  STAGE-COMPLETE  — agent finished successfully
  STAGE-FAILED    — agent finished with failure
  VALIDATION      — run-stage-checks.sh executed
  REMEDIATION     — fix routed back to agent (include round number)
  GATE-DECISION   — orchestrator approved/rejected at a gate
  GATE-BLOCKED    — gate blocked, awaiting resolution
  SNAPSHOT        — git tag created
  ESCALATION      — issue escalated (remediation limit hit, blocker, etc.)
  RESUME          — pipeline resumed from breakpoint
  NOTE            — orchestrator observation (process friction, improvement idea)

-->
