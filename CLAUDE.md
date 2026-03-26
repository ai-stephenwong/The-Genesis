# The Genesis

## Purpose

**The Genesis** is the master framework from which all projects are born. It is not a working project itself.

It has three defining properties:
- **Generative** — it gives birth to new projects by scaffolding them from its templates
- **Normative** — it governs how all spawned agents and projects operate through its standards, pipeline definitions, and role contracts
- **Adaptive** — it evolves by absorbing lessons learned from spawned projects back into its standards via the `retrospective-analyst` improvement cycle

Use it to scaffold new projects and maintain company-wide standards.

---

## Always-On (every session)

At the start of every conversation, read and follow `.claude/instructions/session-start.md` before doing anything else.

---

## Triggers — read the instruction file before proceeding

| User says | Read this file first |
|---|---|
| "create new project" (or similar intent) | `.claude/instructions/create-project.md` |
| "run pipeline" / "run agent {name}" | `.claude/instructions/run-pipeline.md` |
| "run retrospective" | `.claude/instructions/run-retrospective.md` |
| "generate compliance report" | `.claude/instructions/generate-compliance.md` |
| "process tribute" / "process it" / tribute found in `tributes/inbox/` | `.claude/instructions/run-retrospective.md` — **Tribute Processing** section |

---

## Standards Conflict Resolution

When any conflict between project requirements and company standards is detected, read `.claude/instructions/conflict-resolution.md` before proceeding.

---

## Company Standards (reference only — agents load these explicitly when needed)

Generic standards live in `agent_docs/generic/`. Do not auto-load these at session start.

| File | Purpose |
|---|---|
| `agent_docs/generic/api-conventions.md` | REST conventions, error format, HTTP status codes |
| `agent_docs/generic/nfr-baseline.md` | Performance, availability, and security baselines |
| `agent_docs/generic/security-checklist.md` | Pre-release security checklist |
| `agent_docs/generic/deployment-standards.md` | Deployment pipeline and environment rules |
| `agent_docs/generic/git-workflow.md` | Branching, commit, and PR conventions |
| `agent_docs/generic/agent-roles.md` | Agent pipeline roles, I/O contracts, separation-of-duty rules |
| `agent_docs/generic/uiux-standards.md` | UI/UX design principles, accessibility, responsive design, sensitive data display rules |
| `agent_docs/generic/agents/orchestrator.md` | Orchestrator (nickname: pilot) — mission, operating modes, gate handling, snapshot convention, decision log, approval summary |

Platform-specific deployment standards:

| File | Purpose |
|---|---|
| `agent_docs/generic/deployment-aws.md` | AWS best practices |
| `agent_docs/generic/deployment-gcp.md` | GCP best practices |
| `agent_docs/generic/deployment-alicloud.md` | Alibaba Cloud best practices |
| `agent_docs/generic/deployment-onpremise.md` | On-premise best practices |
| `agent_docs/generic/deployment-vercel-cloudflare.md` | Vercel + Cloudflare best practices |
| `agent_docs/generic/deployment-vercel-railway.md` | Vercel + Railway best practices |
