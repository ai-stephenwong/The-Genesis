# The Genesis — Pipeline Flow Reference

## 1. Pipeline Overview

```
                            PRE-FLIGHT GATES
                    ┌─────────────────────────┐
                    │  Requirements Gate       │  At least one real requirements
                    │  (before any stage)      │  file in requirements-include-files/
                    └────────────┬─────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
           Stage 1  │  requirements-analyst    │
                    └────────────┬─────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
           Stage 2  │  solution-architect      │  GATE: architecture-sign-off
                    │                         │  (all 8 deliverables approved)
                    └────────────┬─────────────┘
                                 │
                    ┌────────────┴────────────┐
                    │     PARALLEL GROUP 1     │
                    │                         │
           Stage 3a │  developer              │  Stage 3b │  devops-engineer
                    │                         │           │
                    └────────────┬─────────────┘
                                 │  (sync barrier — both must complete)
                    ┌────────────┴─────────────────────────┐
                    │          PARALLEL GROUP 2             │
                    │                                      │
           Stage 4a │  code-reviewer   Stage 4b │  tester  │  Stage 4c │  uiux-reviewer
                    │                                      │
                    └────────────┬─────────────────────────┘
                                 │  (sync barrier — code-reviewer + tester must complete)
                                 ▼
                    ┌─────────────────────────┐
           Stage 5  │  security-auditor        │
                    └────────────┬─────────────┘
                                 │
                                 ▼
                    ┌─────────────────────────┐
           Stage 6  │  compliance-officer      │  QUALITY GATE: must PASS
                    └────────────┬─────────────┘         before any deployment
                                 │
                                 ▼
                    ┌─────────────────────────┐
           Stage 7  │  deploy-environment      │  e.g. staging, UAT
                    │  (non-production)        │  GATE: staging-sign-off
                    └────────────┬─────────────┘  (human approval even in Autopilot)
                                 │
                                 ▼
                    ┌─────────────────────────┐
           Stage 8  │  deploy-production       │  GATE: production-deploy
                    │                         │  (human approval always required)
                    └─────────────────────────┘


          ═══════════════════════════════════════════════════
                        META-PIPELINE (out-of-band)
          ═══════════════════════════════════════════════════

              Bug batch found (post-staging, post-prod, etc.)
                                 │
                                 ▼
              ┌──────────────────────────────────┐
              │  retrospective-analyst (Phase 1)  │  Implication Report
              └──────────────┬───────────────────┘
                             │
                             ▼
              ┌──────────────────────────────────┐
              │  Implicated agents: self-review   │  Parallel per agent
              └──────────────┬───────────────────┘
                             │
                             ▼
              ┌──────────────────────────────────┐
              │  retrospective-analyst (Phase 2)  │  Full Retrospective + Proposals
              └──────────────┬───────────────────┘
                             │
                             ▼
              ┌──────────────────────────────────┐
              │  Orchestrator presents proposals  │  → Approved: update agent-roles.md
              │  to project owner                 │  → Rejected: note in artifact
              └──────────────────────────────────┘
```

---

## 2. Per-Stage Detail

### Stage 1: requirements-analyst

| Field | Value |
|---|---|
| **Role** | Analyse raw requirements; produce structured, unambiguous requirements summary |
| **Inputs** | `agent_docs/project/specs/requirements-include-files/*` (`.md`, `.html`, `.png`, `.pdf`, etc.) |
| **Outputs** | `artifacts/requirements/analysis-YYYYMMDD-HHmm.md` |
| **Guard** | Requirements Gate: at least one non-template file exists in `requirements-include-files/` |
| **Validation** | None |
| **Gate** | `requirements-sign-off` (if BLOCKED on ambiguities) |

### Stage 2: solution-architect

| Field | Value |
|---|---|
| **Role** | Design technical architecture; produce all 8 mandatory deliverables |
| **Inputs** | `artifacts/requirements/analysis-*.md` (latest), `artifacts/uiux-review/review-*.md` (if exists), `agent_docs/project/specs/requirements-include-files/*`, `agent_docs/generic/nfr-baseline.md`, `agent_docs/generic/api-conventions.md`, `agent_docs/generic/deployment-{platform}.md` |
| **Outputs** | `agent_docs/project/architecture.md`, `agent_docs/project/er-diagram.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/functional-specs.md`, `agent_docs/project/specs/api-spec.yaml`, `artifacts/architecture/design-YYYYMMDD-HHmm.md`, `.nvmrc` / `.java-version` / `.python-version` / `.tool-versions` |
| **Guard** | `requirements-analyst` = `complete` |
| **Validation** | `post-architect` → `runtime-version`, `env-vars` |
| **Gate** | `architecture-sign-off` (all 8 deliverables must be approved before dev starts) |

### Stage 3a: developer (parallel with 3b)

| Field | Value |
|---|---|
| **Role** | Implement features per architecture, requirements, and api-spec.yaml |
| **Inputs** | `agent_docs/project/architecture.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/project/specs/requirements-include-files/*.md`, `agent_docs/project/stack.md`, `agent_docs/project/conventions.md`, `agent_docs/generic/api-conventions.md`, `agent_docs/generic/uiux-standards.md`, `agent_docs/generic/security-checklist.md` |
| **Outputs** | `src/` (application code), `artifacts/development/feature-{name}-YYYYMMDD-HHmm.md` |
| **Guard** | `solution-architect` = `complete` + validation passed. Architecture Gate: all 4 mandatory files exist with real content |
| **Validation** | `post-developer` → `runtime-version`, `env-vars`, `no-stubs`, `routes`, `impl-notes-format` |
| **Gate** | None (unless BLOCKED on pending change requests) |

### Stage 3b: devops-engineer (parallel with 3a)

| Field | Value |
|---|---|
| **Role** | CI/CD pipelines, IaC, deployment configuration |
| **Inputs** | `agent_docs/project/architecture.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/stack.md`, `agent_docs/project/deployment.md`, `agent_docs/generic/deployment-standards.md`, `agent_docs/generic/deployment-{platform}.md`, `agent_docs/project/commands.md` |
| **Outputs** | `.github/workflows/`, `infrastructure/`, `Dockerfile`, `docker-compose.yml`, `agent_docs/project/deployment.md`, `artifacts/devops/setup-YYYYMMDD-HHmm.md` |
| **Guard** | `solution-architect` = `complete` + validation passed |
| **Validation** | `post-devops` → `deploy-method`, `env-vars` |
| **Gate** | None |

### Stage 4a: code-reviewer (parallel with 4b, 4c)

| Field | Value |
|---|---|
| **Role** | Independent code review for correctness, standards compliance, quality |
| **Inputs** | `src/`, `artifacts/development/*.md`, `agent_docs/project/architecture.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/generic/api-conventions.md`, `agent_docs/project/conventions.md`, deployment manifest |
| **Outputs** | `artifacts/code-review/review-YYYYMMDD-HHmm.md` |
| **Guard** | `developer` = `complete` AND `devops-engineer` = `complete` + validation passed |
| **Validation** | `pre-review` (entry gate) → `env-vars`, `no-stubs`, `deploy-method`, `impl-notes-format` |
| **Gate** | `code-review-findings` (if Critical findings present) |

### Stage 4b: tester (parallel with 4a, 4c)

| Field | Value |
|---|---|
| **Role** | Verify implementation meets requirements; own the bug report |
| **Inputs** | `src/`, `agent_docs/project/specs/requirements-include-files/*.md`, `artifacts/requirements/analysis-*.md`, `agent_docs/project/commands.md` |
| **Outputs** | `tests/`, `artifacts/test/results-YYYYMMDD-HHmm.md`, `artifacts/development/bug-report-YYYYMMDD-HHmm.md` |
| **Guard** | `developer` = `complete` |
| **Validation** | None |
| **Gate** | None (unless BLOCKED on test failures) |

### Stage 4c: uiux-reviewer (parallel with 4a, 4b)

| Field | Value |
|---|---|
| **Role** | Review implementation against mockups for design fidelity, accessibility, responsive design |
| **Inputs** | `agent_docs/project/specs/requirements-include-files/*` (mockups), `artifacts/requirements/analysis-*.md` (latest), `agent_docs/generic/uiux-standards.md` |
| **Outputs** | `artifacts/uiux-review/review-YYYYMMDD-HHmm.md` |
| **Guard** | `developer` = `complete` |
| **Validation** | None |
| **Gate** | `design-review` (if BLOCKED on design gaps) |

### Stage 5: security-auditor

| Field | Value |
|---|---|
| **Role** | Independent security audit against OWASP Top 10 and security checklist |
| **Inputs** | `src/`, `agent_docs/project/architecture.md`, `agent_docs/generic/security-checklist.md`, `agent_docs/generic/nfr-baseline.md`, `artifacts/code-review/review-*.md` (latest) |
| **Outputs** | `artifacts/security/audit-YYYYMMDD-HHmm.md` |
| **Guard** | `code-reviewer` = `complete` AND `tester` = `complete` |
| **Validation** | None |
| **Gate** | `security-audit` (if Critical findings present) |

### Stage 6: compliance-officer

| Field | Value |
|---|---|
| **Role** | Final compliance report; cross-check all artifacts against all standards |
| **Inputs** | ALL `artifacts/*/` outputs, ALL `agent_docs/generic/*.md`, `agent_docs/project/compliance-checklist.md`, `agent_docs/project/env-contract.md` |
| **Outputs** | `artifacts/compliance/compliance-YYYYMMDD-HHmm.md` |
| **Guard** | `security-auditor` = `complete` |
| **Validation** | `pre-compliance` (entry gate) → `env-vars`, `no-stubs`, `deploy-method`, `runtime-version` |
| **Gate** | `compliance-sign-off` (always — must PASS before any deployment) |

### Stage 7: deploy-environment

| Field | Value |
|---|---|
| **Role** | Trigger non-production deployment via CI/CD, monitor, verify smoke tests |
| **Inputs** | `agent_docs/project/pipeline.md`, `agent_docs/project/deployment.md`, `agent_docs/project/git-workflow.md` |
| **Outputs** | `artifacts/devops/deploy-{environment}-YYYYMMDD-HHmm.md` |
| **Guard** | `compliance-officer` = `complete` |
| **Validation** | None |
| **Gate** | `staging-sign-off` (human approval required even in Autopilot) |

### Stage 8: deploy-production

| Field | Value |
|---|---|
| **Role** | Trigger production deployment via CI/CD, monitor, verify smoke tests |
| **Inputs** | `artifacts/devops/deploy-{final-pre-prod-env}-*.md` (latest), `agent_docs/project/deployment.md`, `agent_docs/project/git-workflow.md` |
| **Outputs** | `artifacts/devops/deploy-production-YYYYMMDD-HHmm.md` |
| **Guard** | `deploy-environment` = `complete` |
| **Validation** | None |
| **Gate** | `production-deploy` (human approval always required) |

---

## 3. Transition Mechanics

Every transition between stages follows a deterministic sequence managed by `pipeline-runner.sh`:

### 3.1 Guard Check

Before a stage can start, `check_guards()` verifies:

1. **Dependency status** — every stage in `depends_on` must have `status = "complete"` in `pipeline-run.json`
2. **Validation clean** — each completed dependency must have `validation.checks_failed = 0`

**Dependency graph:**

| Stage | Depends on (must be `complete`) |
|---|---|
| `requirements-analyst` | (none) |
| `solution-architect` | `requirements-analyst` |
| `developer` | `solution-architect` |
| `devops-engineer` | `solution-architect` |
| `code-reviewer` | `developer`, `devops-engineer` |
| `tester` | `developer` |
| `uiux-reviewer` | `developer` |
| `security-auditor` | `code-reviewer`, `tester` |
| `compliance-officer` | `security-auditor` |
| `deploy-environment` | `compliance-officer` |
| `deploy-production` | `deploy-environment` |

### 3.2 Validation Scripts

| Validation ID | When it runs | Checks |
|---|---|---|
| `post-architect` | After `solution-architect` completes | `runtime-version`, `env-vars` |
| `post-developer` | After `developer` completes | `runtime-version`, `env-vars`, `no-stubs`, `routes`, `impl-notes-format` |
| `post-devops` | After `devops-engineer` completes | `deploy-method`, `env-vars` |
| `pre-review` | Before `code-reviewer` starts | `env-vars`, `no-stubs`, `deploy-method`, `impl-notes-format` |
| `pre-compliance` | Before `compliance-officer` starts | `env-vars`, `no-stubs`, `deploy-method`, `runtime-version` |

Each check outputs `PASS`, `SKIP`, or `FAIL`. Overall validation passes only if all checks pass (exit code 0).

### 3.3 State Update (`pipeline-run.json`)

Updated at three points per stage:

| Point | Fields set |
|---|---|
| **Stage start** | `status = "running"`, `started = "YYYY-MM-DD HH:mm"` |
| **Stage end (success)** | `status = "complete"`, `completed`, `process_time_seconds`, validation counts |
| **Stage end (failure)** | `status = "failed"`, same timing/validation fields |

After every stage, `update_totals()` recalculates all aggregate fields.

### 3.4 Log Entry (`pipeline-log.md`)

Append-only entries at each event:

```
### [HH:mm] STAGE-START — {stage}
### [HH:mm] VALIDATION — {stage}     (Passed X/Y or FAILED X/Y)
### [HH:mm] STAGE-COMPLETE — {stage}  (or STAGE-FAILED)
### [HH:mm] GATE-DECISION — {stage}   (approved/rejected + rationale)
### [HH:mm] REMEDIATION — {stage}     (fix routed, round number)
### [HH:mm] SNAPSHOT — {stage}        (git tag created)
### [HH:mm] ESCALATION — {stage}      (blocker, remediation limit hit)
### [HH:mm] NOTE — {stage}            (process observation)
```

---

## 4. Remediation Flow

### 4.1 When it triggers

Any reviewing agent (code-reviewer, tester, uiux-reviewer, security-auditor, compliance-officer) identifies fixable issues. In Autopilot mode, the orchestrator fixes immediately without asking.

### 4.2 Remediation Loopback Chain

The fix routes through upstream validation before returning to the original reviewer:

| Issue found by | Remediation chain |
|---|---|
| code-reviewer / tester / uiux-reviewer | requirements-analyst → solution-architect → developer fix → re-run same reviewer |
| security-auditor | requirements-analyst → solution-architect → developer fix → code-reviewer + tester (parallel) → re-run security-auditor |
| compliance-officer | requirements-analyst → solution-architect → developer fix → code-reviewer + tester (parallel) → security-auditor → re-run compliance-officer |

```
Issue found by reviewer
    ↓
requirements-analyst   — assess impact on requirements, flag conflicts
    ↓
solution-architect     — assess architectural impact, produce fix guidance
    ↓
developer              — implement fix per guidance
    ↓
re-review chain        — validate fix through intermediate stages (scoped to changed files only)
    ↓
original reviewer      — re-check
```

### 4.3 Remediation Limits

| Limit | Value | Scope |
|---|---|---|
| **Per-issue** | **3 attempts** | Same issue may be attempted at most 3 times |
| **Per-stage total** | **9 attempts** | Total fix attempts across all issues within one stage |

Whichever limit is hit first stops remediation and triggers **Blocker Judgement**.

### 4.4 Blocker Judgement (Two-Agent Rule)

When a limit is hit, the orchestrator invokes two sub-agents **in parallel**:

1. **The reviewing agent** that found the issue (has technical context)
2. **The solution-architect** (understands system design)

Each returns: **BLOCKER** or **NON-BLOCKER** + rationale.

**Decision rule:** If EITHER says BLOCKER → it IS a blocker (conservative).

| Verdict | Autopilot | Manual |
|---|---|---|
| **Blocker** | STOP pipeline. Log everything. Display error. | STOP. Present to user. |
| **Non-blocker** (both agree) | Log as deferred. Add to "YOUR ACTION REQUIRED". Continue. | Ask user: "Continue? [Y/n]" |

---

## 5. Parallel Execution

| Group | Stages | Starts when | Sync barrier |
|---|---|---|---|
| **Group 1** | `developer`, `devops-engineer` | `solution-architect` = `complete` + validation passed | Both must complete before code-reviewer can start |
| **Group 2** | `code-reviewer`, `tester`, `uiux-reviewer` | Per individual dependencies (see §3.1) | `code-reviewer` + `tester` must complete before security-auditor |

**Conflict of interest:** developer ↔ code-reviewer, developer ↔ tester, developer ↔ uiux-reviewer, developer ↔ security-auditor, code-reviewer ↔ compliance-officer, retrospective-analyst ↔ any reviewed agent — all must be **different agent instances**.

---

## 6. The Closed Loop

```
Pipeline Run
    │
    ├─► pipeline-run.json records per-stage metrics
    │     (time, remediations, validation pass/fail)
    │
    ├─► Bug report produced (by tester or post-deploy)
    │
    ▼
Retrospective ("run retrospective")
    │
    ├─► Phase 1: Implication Report
    │     Per-bug trace through every pipeline stage
    │     Determines which agents are implicated
    │
    ├─► Implicated agents: self-reviews (parallel)
    │
    ├─► Phase 2: Full Retrospective
    │     Agent scores (1-5), framework gaps identified
    │     SDLC Improvement Proposals (target earliest stage)
    │     Convergence Analysis across all prior runs
    │
    ▼
Tribute → The Genesis
    │
    ├─► Proposals reviewed and absorbed into agent_docs/generic/
    ├─► Changes propagated to all child projects
    │
    ▼
Re-Run — next pipeline benefits from updated standards
```

### Convergence Measurement

`scripts/convergence-report.sh` compares all `artifacts/runs/run-*.json` files:

| Metric | What it measures |
|---|---|
| Process time | Are runs getting faster? |
| Remediation rounds | Are fewer fix cycles needed? |
| Validation failures | Are fewer checks failing? (key metric) |
| Retrospective score | Are agent scores improving? |

**Verdict:** CONVERGING (failures trending down) / FLAT (no trend) / DIVERGING (failures trending up)

---

## 7. Human Approval Gates

Even in Autopilot mode, two gates always require explicit human approval:

| Gate | Stage | Why |
|---|---|---|
| `staging-sign-off` | deploy-environment | Staging must pass before production |
| `production-deploy` | deploy-production | Production deployment is irreversible |

All other gates are auto-approved in Autopilot (marked `Auto-approved` in pipeline status).

---

## 8. Validation Check Scripts

| Check | File | What it verifies |
|---|---|---|
| `runtime-version` | `checks/runtime-version.sh` | Pinning file exists and matches `stack.md` |
| `env-vars` | `checks/env-vars.sh` | Code env var usage matches `env-contract.md` |
| `no-stubs` | `checks/no-stubs.sh` | No TODO/HACK/FIXME/Placeholder stubs in source |
| `routes` | `checks/routes.sh` | Frontend link targets have corresponding route files |
| `impl-notes-format` | `checks/impl-notes-format.sh` | Implementation notes have all required sections |
| `deploy-method` | `checks/deploy-method.sh` | No prohibited deploy commands in CI workflows |
