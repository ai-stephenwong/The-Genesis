# Agent Pipeline — [Project Name]

> Project-specific pipeline configuration.
> Generic agent role definitions and I/O contracts are in `agent_docs/generic/agent-roles.md`.
> Do not redefine roles here — only configure which agents are active and their project-specific paths.

---

## Pipeline Configuration

| Setting | Value | Notes |
|---|---|---|
| `api-spec-required` | `true` | Set to `false` only for projects with no REST API (CLI tools, frontend-only, batch jobs) |

---

## Active Agents

| Agent | Active? | Notes |
|---|---|---|
| `requirements-analyst` | ✅ | |
| `solution-architect` | ✅ | Must produce all 4 mandatory deliverables before developer starts |
| `developer` | ✅ | |
| `devops-engineer` | ✅ | Runs in parallel with developer |
| `code-reviewer` | ✅ | Must be different instance from developer |
| `tester` | ✅ | Must be different instance from developer |
| `uiuiux-reviewer` | ✅ | Remove row if project has no frontend |
| `security-auditor` | ✅ | |
| `compliance-officer` | ✅ | Quality gate — must PASS before any deployment |
| `retrospective-analyst` | ✅ | Meta-pipeline — triggered by bug batches, not part of standard build flow |

---

## Project Paths

| Path | Purpose |
|---|---|
| `agent_docs/project/specs/requirements-include-files/` | Raw requirements files (input to requirements-analyst) |
| `agent_docs/project/specs/api-spec.yaml` | **OpenAPI 3.1 API spec — produced by solution-architect; MUST NOT be pre-created or copied from a template. File absence = spec not yet written. Developer is blocked until this file exists and is approved.** |
| `agent_docs/project/architecture.md` | Architecture diagram + platform constraints (output of solution-architect) |
| `agent_docs/project/er-diagram.md` | **ER diagram — mandatory deliverable of solution-architect; absence = not yet produced** |
| `agent_docs/project/specs/functional-specs.md` | **Functional specifications — mandatory deliverable of solution-architect; absence = not yet produced** |
| `agent_docs/project/stack.md` | Tech stack and versions |
| `agent_docs/project/conventions.md` | Project-specific coding conventions |
| `agent_docs/generic/` | Company standards (read by all agents) |
| `src/` | All application source repositories (one sub-folder per repo) |
| `src/{repo-name}/` | Individual source repo — e.g. `src/my-project-api/`, `src/my-project-web/` |
| `artifacts/requirements/` | requirements-analyst outputs |
| `artifacts/architecture/` | solution-architect design snapshots |
| `artifacts/development/` | developer implementation notes + bug reports + API spec change requests |
| `artifacts/code-review/` | code-reviewer reports + self-reviews |
| `artifacts/uiux-review/` | uiuiux-reviewer reports + self-reviews |
| `artifacts/test/` | tester results + self-reviews |
| `artifacts/security/` | security-auditor reports + self-reviews |
| `artifacts/devops/` | devops-engineer setup notes + deploy records |
| `artifacts/compliance/` | compliance-officer reports + self-reviews |
| `artifacts/retrospective/` | retrospective-analyst scored reports (one per bug-batch round) |

---

## Pipeline Stages & Dependencies

```
[requirements-analyst]
  in:  agent_docs/project/specs/requirements-include-files/*.md
  out: artifacts/requirements/analysis-YYYYMMDD-HHmm.md
        ↓
[solution-architect]                   ← GATE: api-spec.yaml must be approved before developer starts
  in:  artifacts/requirements/analysis-*.md (latest)
       agent_docs/generic/nfr-baseline.md
       agent_docs/generic/api-conventions.md
       agent_docs/generic/deployment-[platform].md
  out: agent_docs/project/architecture.md
       agent_docs/project/specs/api-spec.yaml   ← MANDATORY deliverable
       artifacts/architecture/design-YYYYMMDD-HHmm.md
        ↓
[developer] ─────────────────────────── [devops-engineer]  ← parallel
  in:  agent_docs/project/architecture.md         in:  agent_docs/project/architecture.md
       agent_docs/project/specs/api-spec.yaml          agent_docs/project/stack.md
       agent_docs/project/specs/                        agent_docs/project/deployment.md
         requirements-include-files/*.md                agent_docs/generic/deployment-standards.md
       agent_docs/project/stack.md                      agent_docs/generic/deployment-[platform].md
       agent_docs/project/conventions.md           out: .github/workflows/ or .gitlab-ci.yml
       agent_docs/generic/api-conventions.md            infrastructure/
  out: src/                                             Dockerfile
       artifacts/development/                           agent_docs/project/deployment.md (updated)
         feature-{name}-YYYYMMDD-HHmm.md               artifacts/devops/setup-YYYYMMDD-HHmm.md
        ↓
[code-reviewer] ─── [tester] ─── [uiuiux-reviewer]   ← all parallel
  in:  src/              in:  src/                  in:  src/ (frontend)
       artifacts/              requirements/              agent_docs/generic/uiux-standards.md
         development/*.md      analysis-*.md              agent_docs/project/specs/design.md
       architecture.md         commands.md                artifacts/development/*.md
       api-spec.yaml      out: tests/               out: artifacts/uiux-review/
       api-conventions.md      artifacts/test/              review-YYYYMMDD-HHmm.md
  out: artifacts/                results-YYYYMMDD-HHmm.md
         code-review/
         review-YYYYMMDD-HHmm.md
        ↓
[security-auditor]
  in:  src/
       agent_docs/project/architecture.md
       agent_docs/generic/security-checklist.md
       agent_docs/generic/nfr-baseline.md
       artifacts/code-review/review-*.md (latest)
  out: artifacts/security/audit-YYYYMMDD-HHmm.md
        ↓
[compliance-officer]                           ← quality gate — must pass before any deployment
  in:  artifacts/requirements/analysis-*.md (latest)
       artifacts/architecture/design-*.md (latest)
       artifacts/development/*.md (all)
       artifacts/code-review/review-*.md (latest)
       artifacts/uiux-review/review-*.md (latest)
       artifacts/test/results-*.md (latest)
       artifacts/security/audit-*.md (latest)
       artifacts/devops/setup-*.md (latest)
       agent_docs/generic/*.md (all)
       agent_docs/project/compliance-checklist.md
  out: artifacts/compliance/compliance-YYYYMMDD-HHmm.md
        ↓
[deploy-staging]                               ← only after compliance report is PASSED
  in:  artifacts/compliance/compliance-*.md (latest — must be PASSED)
       agent_docs/project/deployment.md
  out: Staging URL live + smoke tests passed
       artifacts/devops/deploy-staging-YYYYMMDD-HHmm.md
        ↓
[deploy-production]                            ← only after staging smoke tests pass
  in:  artifacts/devops/deploy-staging-*.md (latest)
       agent_docs/project/deployment.md
  out: Production URL live + smoke tests passed
       artifacts/devops/deploy-production-YYYYMMDD-HHmm.md
```

---

## Meta-Pipeline: Retrospective

The retrospective cycle runs **outside the standard build pipeline**. It is triggered whenever a batch of bugs or deficiencies is found — typically after staging deployment, integration testing, or a production incident.

```
[Bug batch / issue report found]
  in:  artifacts/development/bug-report-YYYYMMDD-HHmm.md
        ↓
[Each implicated agent — self-review]    ← run in parallel; separate instance per agent
  in:  bug-report-YYYYMMDD-HHmm.md
       their own pipeline artifacts from the affected cycle
  out: artifacts/{agent}/self-review-YYYYMMDD-HHmm.md
        ↓
[retrospective-analyst]                  ← MUST be different instance from all reviewed agents
  in:  artifacts/development/bug-report-YYYYMMDD-HHmm.md
       artifacts/{agent}/self-review-YYYYMMDD-HHmm.md (all implicated)
       artifacts/*/ (all pipeline artifacts from affected cycle)
       agent_docs/generic/agent-roles.md (scoring rubric)
  out: artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md
        ↓
[Orchestrator presents SDLC improvement proposals to user]
  → Approved: update agent_docs/generic/agent-roles.md + propagate to all active project copies
  → Rejected: note in retrospective artifact
```

If the same bug batch triggers multiple fix cycles, repeat the above with an incremented round number. The retrospective-analyst tracks scores across rounds and notes whether they improve.

**Self-review file locations by agent:**

| Agent | Self-review path |
|---|---|
| `developer` | `artifacts/development/self-review-YYYYMMDD-HHmm.md` |
| `code-reviewer` | `artifacts/code-review/self-review-YYYYMMDD-HHmm.md` |
| `tester` | `artifacts/test/self-review-YYYYMMDD-HHmm.md` |
| `uiuiux-reviewer` | `artifacts/uiux-review/self-review-YYYYMMDD-HHmm.md` |
| `security-auditor` | `artifacts/security/self-review-YYYYMMDD-HHmm.md` |
| `compliance-officer` | `artifacts/compliance/self-review-YYYYMMDD-HHmm.md` |
| `devops-engineer` | `artifacts/devops/self-review-YYYYMMDD-HHmm.md` |
| `solution-architect` | `artifacts/architecture/self-review-YYYYMMDD-HHmm.md` |

---

## Resume from Breakpoint

To restart the pipeline from a specific stage, provide the orchestrator with:

1. The stage name to resume from
2. The path to the latest artifact from the preceding completed stage

The orchestrator will skip all completed upstream stages and spawn only the required agent(s).

**Example — resume from security-auditor:**
```
Resume from: security-auditor
Latest code-review artifact: artifacts/code-review/review-20260316-1430.md
```

---

## Parallel Execution Rules

| Stage | Can run in parallel with |
|---|---|
| `code-reviewer` | `tester` |
| `tester` | `code-reviewer` |
| Multiple `developer` instances | Each other (different features/modules) |

All other stages are sequential.

---

## Conflict of Interest Rules

| Pair | Rule |
|---|---|
| developer ↔ code-reviewer | Must be **different** agent instances — never the same |
| developer ↔ tester | Must be **different** agent instances |
| developer ↔ uiuiux-reviewer | Must be **different** agent instances |
| developer ↔ security-auditor | Must be **different** agent instances |
| code-reviewer ↔ compliance-officer | Must be **different** agent instances |
| retrospective-analyst ↔ any reviewed agent | Must be **different** agent instances — retrospective-analyst cannot review itself |

---

## Pipeline Status

| # | Stage | Last Run | Artifact | Status |
|---|---|---|---|---|
| 1 | requirements-analyst | — | — | Not started |
| 2 | solution-architect | — | — | Not started |
| 3a | developer | — | — | Not started |
| 3b | devops-engineer | — | — | Not started |
| 4a | code-reviewer | — | — | Not started |
| 4b | tester | — | — | Not started |
| 4c | uiuiux-reviewer | — | — | Not started |
| 5 | security-auditor | — | — | Not started |
| 6 | compliance-officer | — | — | Not started |
| 7 | deploy-staging | — | — | Not started |
| 8 | deploy-production | — | — | Not started |

## Retrospective History

| Round | Date | Bug Report | Overall Score | Artifact |
|---|---|---|---|---|
| — | — | — | — | — |

## Agent Scores by Round

| Agent | Round 1 | Round 2 | Round 3 | Trend |
|---|---|---|---|---|
| *(populated by retrospective-analyst after each run)* | — | — | — | — |
