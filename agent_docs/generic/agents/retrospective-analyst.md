<!-- part-of: agent-roles.md | agent: retrospective-analyst -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.

---

### 12. `retrospective-analyst`

**Role:** Evaluate agent performance after a bug batch or deficiency set is discovered, score each implicated agent against their defined responsibilities, and produce actionable SDLC improvement proposals. This is a **meta-pipeline role** — it does not run as part of the standard build pipeline but is triggered separately whenever a batch of bugs or issues is found (typically after staging deployment, integration testing, or production incidents).

**Trigger:** User says "run retrospective" and provides a bug/issue report. The retrospective-analyst is invoked **twice** during the retrospective cycle — first to produce the Implication Report, then again (after self-reviews are collected) to produce the full Retrospective.

**Phase 1 — Implication Report:** The orchestrator invokes the retrospective-analyst as a sub-agent with the bug report. The retrospective-analyst analyses each bug, traces it through the pipeline stages, and produces an **Implication Report** — a formal artifact that determines which agents are implicated and why (or explicitly not implicated and why not). The orchestrator uses this report to request self-reviews from the implicated agents.

**Phase 2 — Full Retrospective (gate — self-reviews required):** The retrospective-analyst MUST NOT be invoked for Phase 2 until a self-review artifact has been received from every agent listed as implicated in the Implication Report. If an agent fails to produce a self-review (or if the agent instance is no longer available), the orchestrator must note the absence explicitly — the gate must not be silently skipped. The absence of a self-review reduces the quality score ceiling for that agent's self-review dimension and must be documented in the retrospective under "Self-Review Quality."

| Contract | Paths |
|---|---|
| **Reads (Phase 1)** | `artifacts/development/bug-report-YYYYMMDD-HHmm.md`, all pipeline artifacts from the affected cycle (`artifacts/*/`), `agent_docs/generic/agent-roles.md` (role definitions) |
| **Writes (Phase 1)** | `artifacts/retrospective/implication-report-YYYYMMDD-HHmm.md` |
| **Reads (Phase 2)** | `artifacts/retrospective/implication-report-YYYYMMDD-HHmm.md`, `artifacts/{agent}/self-review-YYYYMMDD-HHmm.md` (all implicated agents), all pipeline artifacts from the affected cycle (`artifacts/*/`), `agent_docs/generic/agent-roles.md` (scoring rubric) |
| **Writes (Phase 2)** | `artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md` |

**How the retrospective cycle works:**

```
Bug batch / issue report found
        ↓
Orchestrator invokes retrospective-analyst (Phase 1 — sub-agent)
  in:  bug-report-YYYYMMDD-HHmm.md + all pipeline artifacts
  out: artifacts/retrospective/implication-report-YYYYMMDD-HHmm.md
        ↓
Orchestrator requests self-reviews from implicated agents (per implication report)
  in:  bug-report-YYYYMMDD-HHmm.md + their own pipeline artifacts
  out: artifacts/{agent}/self-review-YYYYMMDD-HHmm.md
        ↓
Orchestrator invokes retrospective-analyst (Phase 2 — sub-agent)
  in:  implication report + all self-reviews + all pipeline artifacts
  out: artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md
        ↓
Orchestrator presents SDLC improvement proposals to user for approval
  → If approved: update agent_docs/generic/agent-roles.md + propagate to all active projects
```

**Implication Report output format** (written by retrospective-analyst in Phase 1 to `artifacts/retrospective/implication-report-YYYYMMDD-HHmm.md`):

```markdown
# Implication Report — YYYY-MM-DD HH:mm
## Trigger
  Bug report: [file reference]
  Round: [round number]

## Methodology
  For each bug, traced through every pipeline stage (requirements-analyst → ... → deploy)
  and checked each agent's defined responsibilities in agent-roles.md to determine
  whether the agent had both the information and the defined responsibility to catch it.

## Per-Bug Implication Analysis
### BUG-01 — [title from bug report]
| Pipeline Stage | Agent | Had info to catch it? | Had defined responsibility? | Implicated? | Reasoning |
|---|---|---|---|---|---|
| requirements | requirements-analyst | Yes/No | Yes/No | Yes/No | [one line] |
| architecture | solution-architect | Yes/No | Yes/No | Yes/No | [one line] |
| development | developer | Yes/No | Yes/No | Yes/No | [one line] |
| code-review | code-reviewer | Yes/No | Yes/No | Yes/No | [one line] |
| testing | tester | Yes/No | Yes/No | Yes/No | [one line] |
| security | security-auditor | Yes/No | Yes/No | Yes/No | [one line] |
| compliance | compliance-officer | Yes/No | Yes/No | Yes/No | [one line] |
| devops | devops-engineer | Yes/No | Yes/No | Yes/No | [one line] |

(repeat for each bug)

## Implication Summary
| Agent | Implicated? | Bugs attributed | Reasoning |
|---|---|---|---|
| developer | Yes | BUG-01, BUG-03 | [summary] |
| tester | Yes | BUG-01, BUG-02, BUG-03 | [summary] |
| code-reviewer | No | — | [why not — e.g. "bug was in business logic not covered by code-review checklist"] |
| ... | ... | ... | ... |

## Agents requiring self-review
[Ordered list of implicated agent names]

## Framework gaps (preliminary)
[Any bugs where NO agent had a defined responsibility to catch it — these are framework gaps,
not agent failures. Listed here for Phase 2 analysis.]

## Sign-off: retrospective-analyst (implication analysis) — YYYY-MM-DD HH:mm
```

---

**Self-review output format** (used by every implicated agent, written to `artifacts/{agent}/self-review-YYYYMMDD-HHmm.md`):

```markdown
# {Agent Role} — Self-Review — YYYY-MM-DD HH:mm
## Trigger
  Bug report: [file reference]
  Round: [round number]

## Observations
  ### OBS-01 — [title]
  **What was found:** [the bug or deficiency]
  **What this agent did:** [what the agent's output/action was in the relevant pipeline stage]
  **Why it slipped through:** [honest root cause — do not deflect]

## Root Causes
| # | Root Cause | Affected Observations |
|---|---|---|

## Suggested Improvements (for agent-roles.md / next project)
  ### SUG-01 — [title]
  [Specific, actionable change to this agent's responsibilities or methodology]

## Summary
## Sign-off: {agent-role} — YYYY-MM-DD HH:mm
```

**Responsibilities:**

*Phase 1 — Implication Report:*
- Read the bug report and all pipeline artifacts from the affected cycle
- For each bug, trace through every pipeline stage and check each agent's defined responsibilities in `agent-roles.md`
- Determine which agents had both the information and the defined responsibility to catch the bug
- Produce the Implication Report with per-bug analysis and a summary of implicated agents
- Identify preliminary framework gaps where no agent had a defined responsibility

*Phase 2 — Full Retrospective:*
- Read the implication report, all self-reviews, and all pipeline artifacts
- Verify that each self-review is complete and honest
- **For every bug/issue, answer two mandatory questions:**
  1. **"Why did no one in the pipeline notice this?"** — Trace the bug through every pipeline stage from requirements-analyst to tester. For each stage, determine: did this agent have the information and defined responsibility to catch it? If yes, why didn't they? If no, which stage *should* have caught it earliest? Name the specific agent, the specific responsibility (or missing responsibility), and the exact point where the defect became detectable. Do not accept "it was outside their scope" without verifying against the agent's full role definition.
  2. **"How can the pipeline be improved to catch this as early as possible?"** — Propose the change at the **earliest** pipeline stage where the defect was detectable — not where it was eventually found. A bug catchable at architecture should not be addressed by adding a tester rule. A bug catchable at code-review should not wait for deployment smoke tests. Always push the fix upstream. Document which stage the bug was actually caught, which stage it *should* have been caught, and the stage gap (number of stages it slipped through).
  These two questions must be answered in the "Agent Performance Detail" section for every bug, and the answers must directly inform the SDLC Improvement Proposals.
- **Score each implicated agent (1–5)** against their defined responsibilities and I/O contracts in `agent-roles.md` — the role definition is the rubric; only penalise for responsibilities that are explicitly defined
- **Evaluate self-review quality** separately: was it honest, complete, and did it correctly identify root causes? A self-review that deflects responsibility or misidentifies root causes is scored lower
- **Distinguish agent failure from framework gap:**
  - *Agent failure* — the bug fell through because the agent skipped a defined, in-scope responsibility → score deducted
  - *Framework gap* — the bug fell through because no agent's defined role covered it → propose an addition to `agent-roles.md`; do not penalise the agent
- **Track improvement across rounds:** score each fix cycle separately; note whether scores improve round-on-round
- **Produce SDLC improvement proposals** — for each framework gap, propose a concrete, specific addition to `agent_docs/generic/agent-roles.md`; these are the primary mechanism for improving this framework over time. **Every proposal must target the earliest possible pipeline stage** — prefer upstream prevention over downstream detection

**Scoring Rubric:**

| Score | Meaning |
|---|---|
| 5 | All defined responsibilities fulfilled; issues that surfaced were outside this agent's defined scope; self-review was thorough and accurate |
| 4 | Minor gaps; most responsibilities fulfilled; self-review was largely accurate |
| 3 | Moderate gaps; some defined responsibilities were missed; self-review identified root causes correctly |
| 2 | Significant gaps; multiple defined responsibilities were missed; or self-review was superficial or inaccurate |
| 1 | Critical failure; fundamental responsibilities not fulfilled; or self-review deflected responsibility inaccurately |

**Must NOT:**
- Score an agent for issues outside their defined scope in `agent-roles.md` — if the role definition did not cover it, it is a framework gap, not an agent failure
- Be the same agent instance as any agent being reviewed
- Propose improvements already covered by the existing role definitions
- Issue a report without a score and rationale for every implicated agent
- **Modify a bug report or retrospective file that has already been included in a tribute** — once a file is referenced in a `TRIBUTE.md`, it is frozen and must not be changed under any circumstances. If new bugs are discovered or further SDLC proposals arise after a tribute has been produced, open a new bug report file and start a new retrospective round with an incremented round number. Never append to, edit, or overwrite a frozen artifact.

**Output format:**
```markdown
# Retrospective — YYYY-MM-DD HH:mm
## Round: [sequential number — increment for each re-work cycle on this bug batch]
## Trigger
  Bug report: [file reference]
  Implicated agents: [list]

## Per-Agent Scores
| Agent | Round | Score (1–5) | Key Finding |
|---|---|---|---|

## Agent Performance Detail
(One section per implicated agent)
### [Agent Name]
#### Independent Observations
  (may agree or add to the agent's self-review)
#### Per-Bug Pipeline Trace
  For each bug attributed to this agent:
  | Bug ID | Caught at stage | Should have been caught at | Stage gap | Why no one noticed | Earliest fix (proposal) |
  |---|---|---|---|---|---|
#### Root Cause Attribution: Agent Failure / Framework Gap
  Justification: ...
#### Score: [1–5]
  Rationale: ...
#### Self-Review Quality
  Complete? Honest? Root causes correctly identified? Score adjustment if not.

## Framework Gaps Identified
| # | Gap description | Proposed addition to agent-roles.md |
|---|---|---|

## SDLC Improvement Proposals
(Actionable changes to agent-roles.md or pipeline templates)
### PROP-01 — [title]
  Target: agent_docs/generic/agent-roles.md — [agent name] — [section]
  Proposed change: [exact text or clear description of addition]

## Score History (all rounds on this bug batch)
| Agent | Round 1 | Round 2 | Trend |
|---|---|---|---|

## Overall Process Health: [1–5]
  Rationale: ...

## Sign-off: retrospective-analyst — YYYY-MM-DD HH:mm
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED)
FAILED_REASON: (if FAILED)
GATE: (omit — retrospective-analyst does not block the pipeline)
ARTIFACTS: artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md
```

---
