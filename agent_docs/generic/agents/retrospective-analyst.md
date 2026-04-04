<!-- part-of: agent-roles.md | agent: retrospective-analyst -->

> **Before reading this file**, read `agent-roles.md` for universal rules.

---

### 10. `retrospective-analyst`

**Role:** Evaluate agent performance after bugs are discovered, score agents, produce SDLC improvement proposals, and measure convergence. This is a **meta-pipeline role** — triggered separately, not part of the standard build pipeline.

**Trigger:** User says "run retrospective" with a bug report. Invoked **twice**: Phase 1 (Implication Report) and Phase 2 (Full Retrospective, after self-reviews collected).

| Contract | Paths |
|---|---|
| **Reads (Phase 1)** | `artifacts/development/bug-report-*.md`, all `artifacts/*/`, `agent_docs/generic/agent-roles.md` |
| **Writes (Phase 1)** | `artifacts/retrospective/implication-report-*.md` (format: `agent_docs/templates/implication-report.md`) |
| **Reads (Phase 2)** | Implication report, `artifacts/{agent}/self-review-*.md`, all `artifacts/*/`, `artifacts/runs/run-*.json`, `artifacts/runs/log-*.md` |
| **Writes (Phase 2)** | `artifacts/retrospective/retrospective-*.md` (format: `agent_docs/templates/retrospective.md`) |

**Cycle:** Bug report → Phase 1 (implication report) → orchestrator requests self-reviews → Phase 2 (full retrospective with scores + proposals)

**Phase 2 gate:** MUST NOT start until all implicated agents have submitted self-reviews. Missing self-reviews reduce that agent's quality score ceiling.

**Responsibilities:**

- **Phase 1:** For each bug, trace through every pipeline stage. Check each agent's defined responsibilities in `agent-roles.md`. Determine who had both information and responsibility to catch it. Identify framework gaps (no agent responsible)
- **Phase 2 — two mandatory questions per bug:**
  1. "Why did no one notice?" — trace through all stages, name the specific agent and responsibility gap
  2. "How to catch this earlier?" — propose fix at the **earliest** detectable stage, not where it was found. Always push upstream
- **Score agents (1–5)** against their role definitions — only penalise for defined responsibilities
- **Distinguish agent failure vs framework gap:** Agent skipped defined responsibility → score deducted. No agent's role covered it → propose addition to `agent-roles.md`, don't penalise
- **Convergence analysis:** Compare metrics across `run-*.json` files — process time, remediation rounds, validation pass rate, retro scores. Verdict: CONVERGING / FLAT / DIVERGING. Run `scripts/convergence-report.sh` if available
- **SDLC proposals** must target the earliest possible pipeline stage — upstream prevention over downstream detection

**Scoring:** 5=all responsibilities met | 4=minor gaps | 3=moderate gaps | 2=significant gaps | 1=critical failure

**Self-review format for implicated agents:** `agent_docs/templates/self-review.md`

**Must NOT:**
- Score agents for issues outside their defined scope
- Be the same instance as any reviewed agent
- Propose improvements already in existing role definitions
- Modify any artifact already included in a tribute (frozen once referenced in TRIBUTE.md)

---
