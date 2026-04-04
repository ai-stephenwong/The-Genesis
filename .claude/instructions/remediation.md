# Remediation Protocol

Referenced by `orchestrator.md` and `run-pipeline.md`. This is the single source of truth for remediation rules.

---

## Attempt Limits (hard caps — no exceptions)

Two independent limits — whichever is hit first stops remediation:

| Limit | Value | Scope |
|---|---|---|
| **Per-issue** | **3 attempts** | Same issue (or same root cause rephrased) — max 3 tries |
| **Per-stage total** | **9 attempts** | All issues combined within one pipeline stage |

**Same issue = same root cause.** A reviewer rephrasing the same problem doesn't reset the counter. A fix introducing a NEW unrelated problem gets its own counter but shares the stage total.

## Attempt Tracking

The orchestrator maintains a tracker in the Decision Log:

```markdown
## Remediation Tracker — {stage-name}
| # | Issue | Attempt | Action Taken | Outcome | Per-Issue | Stage Total |
|---|---|---|---|---|---|---|
| 1 | Missing input sanitisation | 1 | Added DOMPurify | Resolved | 1/3 | 1/9 |
```

Every fix attempt — successful or not — must appear in the tracker.

## Loopback Flow

When a late-stage reviewer finds fixable issues, the fix goes through a proper chain (every step uses the Agent tool):

```
Issue found → requirements-analyst (assess impact) → solution-architect (fix guidance) → developer (implement) → re-review chain → original reviewer
```

| Issue found by | Re-review chain |
|---|---|
| code-reviewer / tester / uiux-reviewer | developer fix → re-run same reviewer |
| security-auditor | developer fix → code-reviewer + tester → re-run security-auditor |
| compliance-officer | developer fix → code-reviewer + tester → security-auditor → re-run compliance-officer |

Rules:
- Re-review is **scoped** — reviewers only check files changed by the fix
- New issues in changed files are fixed in the same cycle (own per-issue counter, shared stage total)
- uiux-reviewer only re-reviews if the fix touched frontend files

## Blocker Judgement (when limits are hit)

The orchestrator invokes **two sub-agents in parallel**:
1. The reviewing agent that found the issue
2. The solution-architect

Each responds: **BLOCKER** or **NON-BLOCKER** with rationale.

**Decision: if EITHER says BLOCKER, it is a blocker.** Both must agree non-blocking to continue.

**Autopilot:**
- **Blocker:** STOP pipeline. Display blocker message. Manual intervention needed.
- **Non-blocker (both agree):** Log as deferred item. Add to Pipeline Completion Report. Continue pipeline.

**Manual:**
- **Blocker:** STOP. Present to user.
- **Non-blocker:** Present to user and ask: `Continue without fixing? [Y/n]`

## Anti-Circumvention

- No reframing failed fixes as "different approaches" to reset counters
- No splitting one issue into sub-issues for more attempts
- No skipping log entries to hide failures
- If the orchestrator suspects counter manipulation, trigger blocker judgement immediately
- These rules apply in ALL modes — no exceptions
