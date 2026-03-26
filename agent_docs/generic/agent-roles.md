<!-- last-reviewed: 2026-03-24 | reviewed-by: The Genesis | next-review: 2026-09-24 -->

# Agent Roles & Pipeline Contracts (Company Standard)

> Defines the standard agents used across all projects, their responsibilities,
> input/output contracts, and separation-of-duty boundaries.
>
> Each agent must be an **independent Claude sub-agent** invoked by the orchestrator.
> An agent must never perform work outside its defined role — this prevents conflict
> of interest and ensures rigorous, unbiased outputs.
>
> ISO 27001:2022: Segregation of duties `[5.3]`, Change management `[8.32]`,
> Secure development `[8.25]`, Security testing `[8.29]`.
>
> **Universal Rule — Git-only deployment `[8.32]`:** No agent may trigger a deployment by any method other than `git push` / `git merge` → CI/CD pipeline. Direct deploy commands (`vercel deploy`, `wrangler deploy`), MCP deploy tools, and cloud console deploys are **prohibited** in all environments. See `deployment-standards.md`.
>
> **Universal Rule — API contract change control `[8.32]`:** The `api-spec.yaml` is owned exclusively by the `solution-architect`. **No agent may modify it directly** — not the developer, not the code-reviewer, not even the solution-architect outside of a formal change request flow. The only permitted change path is:
> 1. Any agent (or the project owner) identifies a needed API change → raises a **change request** in `artifacts/development/api-spec-change-requests-YYYYMMDD.md`
> 2. The `solution-architect` reviews and approves or rejects the change request
> 3. If approved, the `solution-architect` updates `api-spec.yaml` with the change and **increments the spec version number** (`info.version`, semver: patch for fixes, minor for new endpoints, major for breaking changes)
> 4. The `developer` implements the approved change in code
> 5. The change request document is updated with: approval date, new spec version, and implementation status
>
> Any direct edit to `api-spec.yaml` that bypasses this flow is a **Critical** violation. The spec is a controlled document, not a working file.
>
> **Universal Rule — Environment Variable change control `[8.32]`:** The **Environment Variable Contract** (`agent_docs/project/env-contract.md`) is owned exclusively by the `solution-architect`. **No agent may add, rename, or remove env vars without approval.** The only permitted change path is:
> 1. Any agent identifies a new or changed env var need → raises a **change request** in `artifacts/development/env-var-change-requests-YYYYMMDD.md`
> 2. The `solution-architect` reviews: approves, rejects, or renames (the architect may choose a different key name that better fits the naming conventions)
> 3. If approved, the `solution-architect` updates the Environment Variable Contract in `architecture.md`
> 4. The `developer` uses the approved key name in code; the `devops-engineer` uses the approved key name in CI/CD and platform configuration
> 5. The change request document is updated with: approval date and implementation status
>
> Any env var in code or CI/CD configuration whose key name does not appear in the contract is a **Critical** violation. The contract is the single source of truth — no guessing, no improvising.
>
> **Universal Rule — Internal consistency `[8.25]`:** All deliverables produced by an agent — and all deliverables across agents — must be consistent with each other. If you update one document, update every other document that references or depends on the same information. If you discover that an upstream deliverable contradicts your own, halt and escalate — do not silently proceed with one version and ignore the other. Reviewing agents (code-reviewer, security-auditor, compliance-officer) must treat any inconsistency between upstream deliverables as a **Critical** finding. Consistency is not optional — a set of deliverables that contradict each other is worse than incomplete deliverables, because contradictions cause downstream agents to build on the wrong assumptions silently.

---

## Pipeline Overview

```
requirements-analyst
        |
uiux-reviewer         <- reviews mockups/design files (skip if no mockups exist)
        |
solution-architect
        |
developer(s)          <- parallel per feature/module
        |
code-reviewer         <- MUST be different agent from developer
        |
tester                <- MUST be different agent from developer
        |
security-auditor      <- MUST be different agent from developer and code-reviewer
        |
compliance-officer    <- reads ALL previous artifacts, produces final report
```

Each stage produces a **timestamped artifact** in `artifacts/{stage}/`.
Any stage can be re-run independently by providing its input paths.
Downstream stages can start as soon as their input artifacts exist.

---

## Orchestration Rules

### PASS WITH CONDITIONS — Critical finding enforcement

When any reviewing agent (uiux-reviewer, code-reviewer, security-auditor, compliance-officer) issues a verdict of **PASS WITH CONDITIONS** that includes one or more **Critical-severity** findings, the orchestrator must:

1. Create a blocking gate artifact (`artifacts/{stage}/open-criticals-YYYYMMDD-HHmm.md`) listing each Critical finding, its required remediation, and verification criteria
2. Treat the pipeline stage as **BLOCKED** until all items in the gate artifact are confirmed resolved
3. Require the compliance-officer to verify closure of each item before issuing a deployment PASS

A PASS WITH CONDITIONS verdict with unresolved Critical findings **must not** allow downstream pipeline stages to proceed. The gate artifact is the auditable record that enforcement occurred.

4. When auto-remediation is triggered (Autopilot mode), follow the **Remediation Loopback Protocol** in `run-pipeline.md` Step 4 to ensure fixes are validated by all intermediate review stages before returning to the stage that found the issue.

---

## Universal Retrospective Obligation

> **Every agent defined below is subject to the self-review requirement when implicated in a retrospective.**

When the orchestrator triggers a retrospective (`run retrospective`), it first invokes the `retrospective-analyst` as a sub-agent to produce an **Implication Report** — a formal artifact that analyses the bug report and determines which agents are implicated and why. The orchestrator then uses this report to request self-reviews from the implicated agents. Every implicated agent **must** produce a self-review report before the `retrospective-analyst` is invoked again for the full retrospective.

**Self-review is mandatory — not optional.** An agent that fails to produce a self-review, produces an incomplete one, or deflects responsibility inaccurately will have its self-review quality scored separately by the `retrospective-analyst` and a lower score recorded for that round.

| Input | `artifacts/{agent}/self-review-YYYYMMDD-HHmm.md` |
|---|---|
| **Reads** | The bug report + the agent's own pipeline artifacts from the affected cycle |
| **Writes** | `artifacts/{agent-name}/self-review-YYYYMMDD-HHmm.md` |

Self-review format and scoring rubric are defined in `agents/retrospective-analyst.md`.

---

## Agent Definitions

Each agent's full role definition, responsibilities, I/O contracts, and output format are in individual files under `agents/`:

| # | Agent | File |
|---|---|---|
| 0 | `orchestrator` (nickname: pilot) | `agents/orchestrator.md` |
| 1 | `requirements-analyst` | `agents/requirements-analyst.md` |
| 2 | `uiux-reviewer` | `agents/uiux-reviewer.md` |
| 3 | `solution-architect` | `agents/solution-architect.md` |
| 4 | `developer` | `agents/developer.md` |
| 5 | `code-reviewer` | `agents/code-reviewer.md` |
| 6 | `tester` | `agents/tester.md` |
| 7 | `security-auditor` | `agents/security-auditor.md` |
| 8 | `compliance-officer` | `agents/compliance-officer.md` |
| 9 | `devops-engineer` | `agents/devops-engineer.md` |
| 10 | `deploy-environment` | `agents/deploy-environment.md` |
| 11 | `deploy-production` | `agents/deploy-production.md` |
| 12 | `retrospective-analyst` | `agents/retrospective-analyst.md` |

When invoking an agent as a sub-agent, the orchestrator must provide:
1. This file (`agent-roles.md`) — for universal rules and pipeline context
2. The agent's individual file (`agents/{role}.md`) — for specific responsibilities
3. The required input artifacts listed in the agent's I/O contract

---

## Pipeline Orchestration Rules

1. **Never reuse the same agent instance** across roles that have a conflict of interest
2. **Always pass explicit file paths** — agents must not rely on memory of previous conversations
3. **Always use the latest timestamped artifact** from the previous stage as input
4. **If an artifact already exists and is recent**, the orchestrator may skip re-running that stage and proceed from the existing output — this is the **resume from breakpoint** pattern
5. **Parallel execution** is allowed between stages with no dependency:
   - `developer` and `devops-engineer` can run in parallel after `solution-architect`
   - `code-reviewer`, `tester`, and `uiux-reviewer` can all run in parallel after `developer`
   - `security-auditor` can start after `code-reviewer` completes
   - `compliance-officer` starts only after ALL other agents complete
6. **A stage must not start** if its required input artifact is missing or flagged as incomplete
7. **`retrospective-analyst` is a meta-pipeline agent** — it never runs as part of the standard build pipeline; it is only triggered by "run retrospective" with a bug/issue report as input
8. **Never modify The Genesis directly** — child project agents must NEVER write to, edit, or delete any file inside The Genesis project folder (`-The Genesis/`). The Genesis is the governing framework; child projects are subject to it, not equal to it. The only permitted mechanism for proposing changes to The Genesis is a **tribute** (see `run-retrospective.md` Step 6). This rule applies at the operations level: no agent running inside a child project may issue any file-write command targeting The Genesis directory, regardless of how good the intention is. Only agents running inside The Genesis project itself may modify its files.
9. **Service preferences — cost-aware defaults.** When multiple services can fulfil the same role, prefer the one with lower operational cost. Key preference: **Neon over Railway for PostgreSQL** — Neon has a generous free tier with auto-suspend and DB branching; Railway Postgres consumes paid compute hours continuously. The `solution-architect` must select Neon for all PostgreSQL needs unless a specific technical requirement (e.g. same-network latency with a Railway-hosted API) justifies Railway Postgres. If a child project is already using Railway Postgres, flag it as a cost optimisation opportunity.
10. **Minimum Viable Deploy — get online first, perfect later.** Non-critical configuration (custom domains, verified sending domains, production-tier plans, DNS records) must never block the pipeline. If a production-ready setup requires human action but a test/sandbox/trial mode exists that is sufficient to deploy and verify, **use the test mode and keep moving**. Log the production upgrade as a to-do in the Decision Log — a to-do is not a blocker. Every agent must apply this principle: do not flag test-mode limitations as pipeline failures, do not wait for production-grade configuration when a working default exists. The pipeline's job is to produce a running, verified application — production hardening is a follow-up. See `agents/orchestrator.md` — Minimum Viable Deploy for the full rule and common test/sandbox modes.

---

## Resume from Breakpoint

To resume the pipeline from a specific stage:

1. Identify the latest artifact from the last completed stage in `artifacts/{stage}/`
2. Provide that artifact path as the input to the next agent
3. The orchestrator does not need to re-run earlier stages

Example: If `code-reviewer` artifact exists but `security-auditor` has not run:
```
-> invoke security-auditor (sub-agent)
  input: artifacts/code-review/review-20260316-1430.md
         src/
         agent_docs/generic/security-checklist.md
  output: artifacts/security/audit-YYYYMMDD-HHmm.md
```
