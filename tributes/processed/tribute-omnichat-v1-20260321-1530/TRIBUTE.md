# Tribute — omnichat-v1 → The Genesis
**Date:** 2026-03-21
**Source project:** omnichat-v1
**Retrospective round:** 2 (deployment round)
**Retrospective artifact:** retrospective-20260321-1530.md

---

## What happened

During the first staging deployment of omnichat-v1, six deployment-time failures were discovered that **no pipeline agent caught through code inspection alone**. All failures were invisible to code-reviewer, security-auditor, and compliance-officer because they only manifest when real cloud infrastructure is provisioned and actual deploy commands are executed.

The full findings are in the retrospective artifact. Three agents were implicated:
- `solution-architect` — Platform Runtime Compatibility Matrix did not check CPU budget or service routing compatibility
- `devops-engineer` — wrangler.toml placeholder hygiene, Workers-specific config issues, and missing cloud resource pre-creation
- `developer` — frontend builds never verified with a clean `npm ci && npm run build`

---

## Proposed changes to The Genesis

Two generic files require updates. The proposed modified versions are in `proposed/`.

### File 1: `agent_docs/generic/agent-roles.md`

| Proposal | Target agent | Change |
|---|---|---|
| PROP-01 | `solution-architect` | Platform Runtime Compatibility Matrix gains **CPU budget** and **platform service routing** columns; CPU budget rule and platform service routing rule added as named requirements |
| PROP-02 | `devops-engineer` | Add Cloudflare Workers **pre-deploy readiness checklist** (placeholders, deprecated keys, cron day-of-week format, export pattern, dry-run) and **cloud resource pre-creation manifest** template |
| PROP-03 | `developer` | Spec Compliance Checklist gains: `npm ci && npm run build` clean-build gate, `vercel.json` framework field verification, `api-spec.yaml` YAML parse validation |
| PROP-04 | `compliance-officer` | New **Architectural Runtime Assumption Verification** bullet: missing CPU budget estimates or routing compatibility notes in the architecture matrix are a blocking FAIL, not a conditional pass |

### File 2: `agent_docs/generic/deployment-vercel-cloudflare.md`

| Proposal | Section | Change |
|---|---|---|
| PROP-01 | Architecture Checklist | Update password hashing item (PBKDF2 over pure-JS argon2id) and database connection item (TCP driver required for Hyperdrive); add CPU budget verified and platform service routing verified checklist items |
| PROP-05 | New section | Add **Cloudflare Workers — First-Deployment Checklist** covering cloud resource pre-creation table, wrangler.toml readiness checklist, and vercel.json readiness checklist |

---

## Included artifacts

| File | Description |
|---|---|
| `TRIBUTE.md` | This cover document |
| `retrospective-20260321-1530.md` | Full retrospective with agent scores, framework gap analysis, and PROP-01–05 |
| `bug-report-20260321-1530.md` | Deployment round bug inventory (DEPLOY-CRIT-01/02, DEPLOY-MAJ-01–04) |
| `self-review-20260321-1530.md` (architecture) | solution-architect self-review |
| `self-review-20260321-1530.md` (devops) | devops-engineer self-review |
| `self-review-20260321-1530.md` (development) | developer self-review |
| `proposed/agent-roles.md` | Proposed new version of `agent_docs/generic/agent-roles.md` |
| `proposed/deployment-vercel-cloudflare.md` | Proposed new version of `agent_docs/generic/deployment-vercel-cloudflare.md` |

---

## Agent scores this round

| Agent | Score | Key finding |
|---|---|---|
| solution-architect | 2/5 | Framework gap — compat matrix had no CPU budget or service routing dimension |
| devops-engineer | 2/5 | Framework gap — no Workers pre-deploy checklist or resource pre-creation step defined |
| developer | 2/5 | Framework gap — no mandatory clean-build gate in Spec Compliance Checklist |

**Overall process health: 2/5** — systemic blind spot: deployment-time failures are invisible to all downstream pipeline agents through static analysis alone.
