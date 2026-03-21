# Tribute — omnichat-v4 → The Genesis

**Date:** 2026-03-21
**Source project:** omnichat-v4
**Retrospective round:** 1
**Retrospective artifact:** retrospective-20260321-0000.md

---

## What happened

The first full pipeline run for OmniChat v4 completed successfully through to staging
deployment, but the review stages (code-review, ux-review, security-audit, compliance)
collectively surfaced 5 security blockers, 5 critical code review findings, 4 critical UX
violations, and 5 compliance blocking issues — all requiring three separate bugfix passes
before the compliance gate passed. Root cause analysis identified three systemic framework
gaps: the developer role does not mandate reading `uiux-standards.md`, causing i18n wiring
and accessibility patterns to be skipped at implementation time; no agent's contract requires
cross-verifying deployment manifest binding declarations against application code, which
allowed a silent runtime failure to reach the security audit stage rather than being caught
during development or code review; and the developer role does not mandate reading
`security-checklist.md`, causing rate-limiting gaps and missing server-side sanitisation to
reach the security auditor. A fourth gap — the absence of a self-review gate before the
retrospective-analyst is spawned — was also identified and resolved.

---

## Proposed changes to The Genesis

### File 1: `agent_docs/generic/agent-roles.md`

| Proposal | Target agent | Change |
|---|---|---|
| PROP-01 | `developer` | Add `uiux-standards.md` to Reads (frontend projects); add pre-submission accessibility + i18n responsibility |
| PROP-02 | `developer` | Add infrastructure binding cross-check to Spec Compliance Checklist |
| PROP-03 | `code-reviewer` | Add deployment manifest to Reads; add binding verification responsibility |
| PROP-04 | `developer` | Add `security-checklist.md` to Reads; add security pre-submission responsibility |
| PROP-05 | `retrospective-analyst` | Add orchestrator gate requiring self-reviews before analyst is spawned |

---

## Included artifacts

| File | Description |
|---|---|
| `TRIBUTE.md` | This cover document |
| `retrospective-20260321-0000.md` | Full retrospective — Round 1 |
| `proposed/agent-roles.md` | Proposed updated version of `agent_docs/generic/agent-roles.md` with all 5 proposals applied |

**Note — missing artifacts:** No formal bug-report file was raised prior to this retrospective;
the trigger was the combined findings from the review pipeline artifacts. No agent self-reviews
were collected (PROP-05 addresses this gap going forward). The retrospective was conducted on
independent observations only.

---

## Agent scores this round

| Agent | Score | Key finding |
|---|---|---|
| developer | 2/5 | Systemic field-name mismatches across 6 API calls, KV binding misconfiguration, 15 missing endpoints, missing sanitisation and rate limits |
| code-reviewer | 4/5 | Comprehensive; missed server-side sanitisation gap in `content.ts` |
| tester | 3/5 | Good critical path coverage; all 3 repos below 80%; auth integration test not written |
| ux-reviewer | 5/5 | All critical WCAG violations found; systemic i18n gap correctly abstracted |
| security-auditor | 5/5 | All 5 blockers found including KV binding mismatch before any deployment |
| compliance-officer | 4/5 | Found BLOCK-004 (wrong demo URL) via cross-artifact synthesis |

**Overall process health: 3/5** — Review pipeline caught everything before deployment; developer
defect density was too high and three framework gaps directly explain the highest-severity misses.
