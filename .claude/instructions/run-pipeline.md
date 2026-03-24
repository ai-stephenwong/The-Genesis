# Trigger: Run Pipeline / Run Agent

Execute this when the user says **"run pipeline"** or **"run agent {name}"**.

---

## Step 1 — Read pipeline configuration

Read `agent_docs/project/pipeline.md` to determine:
- Active agents and their order
- Source paths for each agent
- Pipeline Configuration table (especially `api-spec-required`)

If resuming from a breakpoint, identify the latest artifact from the last completed stage.

---

## Step 1b — Requirements Gate Check (before any pipeline stage)

Before launching **any** agent sub-agent via the `Agent` tool, verify that real requirements files exist in `agent_docs/project/specs/requirements-include-files/`.

1. List all files in `agent_docs/project/specs/requirements-include-files/`.
2. Exclude any file that contains only the default template content (placeholder text such as `<!-- Add your requirements here -->` or an empty body with only headings and no content).
3. If **no non-template files remain** → **STOP** and alert:

```
🚫 Cannot start pipeline — Requirements gate failed.

   The folder agent_docs/project/specs/requirements-include-files/
   contains no requirements files (only default templates found).

   The pipeline cannot proceed without at least one real requirements file.
   Please add your requirements files to this folder before running the pipeline.
```

4. If non-template files exist:

**Autopilot mode:** List the files found in the Decision Log, auto-confirm, and proceed immediately. Do NOT ask.

**Manual mode:** List them and ask the project owner to confirm:

```
📋 Requirements files found:

   1. 01-functional.md          (last modified: YYYY-MM-DD)
   2. 02-non-functional.md      (last modified: YYYY-MM-DD)
   3. 03-integration.md         (last modified: YYYY-MM-DD)

   Are these all the requirements files for this pipeline run? [Y/n]
```

**Do NOT proceed until the owner confirms.** If the owner says no or wants to add more files, wait for them to update the folder and re-run the check.

---

## Step 2 — Architecture Gate Check (before developer agent only)

Read `api-spec-required` from the Pipeline Configuration table in `pipeline.md`.

**If `api-spec-required: true`**, check ALL four mandatory architecture deliverables before launching the developer sub-agent via the `Agent` tool:

| # | File | Check |
|---|---|---|
| 1 | `agent_docs/project/architecture.md` | Exists and contains a Mermaid diagram (not just placeholder) |
| 2 | `agent_docs/project/er-diagram.md` | Exists and contains a Mermaid erDiagram (not just placeholder) |
| 3 | `agent_docs/project/specs/functional-specs.md` | Exists and contains at least one feature spec (not just placeholder) |
| 4 | `agent_docs/project/specs/api-spec.yaml` | Exists and contains at least one real path (not just template placeholder) |

If any file is missing or contains only placeholder content → **STOP** and alert:

```
🚫 Cannot start developer agent — Architecture gate failed.

   The following mandatory deliverables from the solution-architect are missing or incomplete:

     ❌ agent_docs/project/er-diagram.md          — missing
     ❌ agent_docs/project/specs/functional-specs.md — placeholder only
     ✅ agent_docs/project/architecture.md
     ✅ agent_docs/project/specs/api-spec.yaml

   All four deliverables must be complete and approved before development begins.

   Run:  "run agent solution-architect"   to produce the missing deliverables.
```

If all four files exist with real content → proceed and note: `✅ Architecture gate passed (all 4 deliverables present)`

**If `api-spec-required: false`** → skip the gate check entirely and proceed directly.

---

## Step 3 — Launch all agents as sub-agents via the `Agent` tool

**CRITICAL: Every pipeline agent — in both the main pipeline AND remediation loops — MUST run as a sub-agent using the `Agent` tool.** This applies to ALL roles: requirements-analyst, solution-architect, developer, code-reviewer, tester, uiux-reviewer, security-auditor, compliance-officer, devops-engineer, and deploy agents. Do NOT role-play any agent inline in the main conversation. Each sub-agent gets its own context window, which:
- Prevents the orchestrator from running out of context
- Keeps large files (requirements, source code, specs) out of the orchestrator's context
- Allows the orchestrator to run the full pipeline end-to-end without hitting context limits

**How to launch a sub-agent:**

Use the `Agent` tool with:
- `prompt`: Include the agent's role definition (from `agent_docs/generic/agents/{agent-name}.md`), the input file paths, and the output expectations. Be explicit about what files to read and what artifacts to produce.
- The sub-agent reads files, does its work, produces artifacts, and returns a summary.
- The orchestrator receives only the summary — not the full working context.

**Rules:**
- One sub-agent per pipeline stage (never combine stages)
- For independent stages (code-reviewer + tester + uiux-reviewer), launch multiple sub-agents in parallel using parallel `Agent` tool calls
- The orchestrator's job is: gate checks → launch sub-agent via `Agent` tool → receive summary → update pipeline.md → next stage

**Update the Pipeline Status table in `agent_docs/project/pipeline.md` at TWO points for each stage:**
  1. **Before launching** — mark the stage as `🔄 In progress` with the current timestamp. Write the file immediately so other sessions can see it.
  2. **After completion** — mark the stage as `✅ Completed`, `🤖 Auto-approved`, or `❌ Failed` with the completion timestamp. Write the file immediately.

---

## Step 4 — Stage progression (Autopilot vs Manual)

**Check the current session mode** (set during session-start):

**Autopilot mode:**
- After each stage completes with `STATUS: COMPLETE`, **immediately proceed to the next stage** — do NOT ask the user for permission
- Mark intermediate deliverables as `🤖 Auto-approved` in the pipeline status table
- Continue launching the next agent as a sub-agent via the `Agent` tool until all stages are complete
- The pipeline runs end-to-end without human intervention unless a human-decision gate fires

**Autopilot — handling fixable issues (auto-remediate):**

**Core rule: if the agent can fix it, the agent MUST fix it. Never present fixable issues to the user as "conditions" or "things to fix". The user should only see things that genuinely require human input.**

Fixable issues include (not exhaustive):
- Code bugs, missing sanitisation, security vulnerabilities (XSS, CSRF, injection)
- Missing error handling, unhandled edge cases
- Env var naming mismatches, import path errors
- Missing tests or insufficient test coverage
- Missing HTTP headers (CSP, CORS, security headers)
- Missing i18n, hreflang, accessibility fixes
- Placeholder/stub code that should be real implementations
- Any issue that can be resolved by changing code, config, or dependencies

When a review stage (code-reviewer, tester, security-auditor, compliance-officer, uiux-reviewer) identifies fixable issues:
1. Do NOT stop to ask the user
2. Immediately use the `Agent` tool to launch the `developer` as a sub-agent to fix ALL identified issues
3. After fixes are applied, use the `Agent` tool to launch the review stage as a new sub-agent to verify the fixes
4. If the re-run passes → continue to the next stage
5. If new issues are found → fix those too (loop)
6. If the same issue persists after **5 fix attempts** → STOP and escalate to the user with a summary of what was tried

**Reminder:** The sub-agent rule from Step 3 applies to ALL agents in this section — every requirements-analyst, solution-architect, developer, and reviewer in the remediation loop MUST be launched via the `Agent` tool as a sub-agent. Never role-play any agent inline.

The orchestrator must not ask "Want me to fix these?" — it must just fix them. The orchestrator must not present a report with "conditions to fix" — it must fix the conditions first, then present the clean report.

**Remediation Loopback Protocol:**

When a late-stage reviewer finds fixable issues, the fix must go through a proper approval and re-review cycle. The requirements-analyst and solution-architect must assess the fix BEFORE the developer implements it — a security or compliance fix could conflict with requirements or require architectural changes.

**Loopback flow** (every step uses the `Agent` tool to launch a sub-agent):

```
Issue found by reviewer
    ↓
requirements-analyst  (sub-agent) — assess impact on requirements, flag conflicts
    ↓
solution-architect    (sub-agent) — assess architectural impact, produce fix guidance
    ↓
developer             (sub-agent) — implement fix per guidance
    ↓
re-review chain       (sub-agents) — validate fix through intermediate stages
    ↓
original reviewer     (sub-agent) — re-check
```

| Issue found by | Full remediation chain |
|---|---|
| code-reviewer / tester / uiux-reviewer | requirements-analyst → solution-architect → developer fix → re-run same reviewer |
| security-auditor | requirements-analyst → solution-architect → developer fix → code-reviewer + tester (parallel) → re-run security-auditor |
| compliance-officer | requirements-analyst → solution-architect → developer fix → code-reviewer + tester (parallel) → security-auditor → re-run compliance-officer |

Loopback rules:
- **Requirements-analyst** reviews the findings and assesses: does the fix conflict with any requirement? Are there requirements implications? Output: fix-assessment with requirements impact (append to Decision Log).
- **Solution-architect** reviews the findings + requirements-analyst assessment and produces: fix guidance with architectural approach. If the fix requires API spec or architecture changes, update those artifacts.
- **Developer** implements the fix following the solution-architect's guidance.
- Re-review is **SCOPED**: reviewers only check files changed by the remediation fix, not the full codebase. Pass the list of changed files to each re-review sub-agent.
- If a re-review stage finds **NEW issues** in the changed files, those are fixed in the same loopback cycle (not a separate loopback).
- The **5-attempt limit** applies to the entire loopback cycle, not per-stage.
- **uiux-reviewer** is only included in the re-review chain if the fix touched frontend files (components, styles, layouts).
- Log every loopback cycle in the Decision Log: which stage triggered it, the requirements-analyst and solution-architect assessments, what was fixed, which stages re-ran, and the outcome.

**Autopilot — accepted risks:**
If a review stage flags an item as `Accepted Risk` (e.g. "MFA deferred to v1.1"), log it in the Decision Log but do not block the pipeline. Accepted risks are not fixable blockers — they are documented trade-offs.

**Manual mode:**
- After each stage completes, present the output summary and ask:
  ```
  Stage {N} ({agent-name}) complete. Proceed to stage {N+1} ({next-agent})? [Y/n]
  ```
- Wait for user confirmation before launching the next sub-agent via the `Agent` tool

**Gates that always require human approval (even in Autopilot):**
- `staging-sign-off` — staging must pass before production deploy
- `production-deploy` — production deployment must be explicitly approved

---

## Step 5 — Autopilot Decision Log (Autopilot mode only)

The Decision Log is the audit trail of every autonomous decision made during an Autopilot run. It is a persistent file — not just console output.

### Decision Log File

- **Path:** `artifacts/decision-log-YYYYMMDD-HHmm.md`
- **Created:** at pipeline start (Step 1), before any sub-agent is launched
- **Updated:** after every decision point — append, never overwrite earlier entries

**File format:**

```markdown
# Autopilot Decision Log — {Project Name}

Started: {YYYY-MM-DD HH:mm}
Mode: Autopilot

---

## Stage: {stage-name} — {timestamp}

| # | Decision Point | Options Considered | Decision | Rationale |
|---|---|---|---|---|
| 1 | {what was decided} | {alternatives} | {chosen action} | {why} |

**Stage outcome:** {PASS / FAIL / AUTO-REMEDIATED}
**Artifacts produced:** {list of files}
**Git snapshot:** `snapshot/{stage}-{HHmm}`

---
```

### Stage-Level Reporting

After each stage completes in Autopilot mode, **display a brief stage report** to the console so the project owner can monitor progress in real time:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Stage {N} — {agent-name}  ✅ Complete
  Decisions made: {count}
  Key decisions:
    • {one-line summary of each decision}
  Artifacts: {list}
  Next: {next-stage-name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### Overall Report (on demand)

When the project owner asks for a report at any point (e.g. "show report", "what decisions were made", "status"), read the latest `artifacts/decision-log-*.md` and present:

1. **Pipeline progress** — which stages are done, in progress, or pending
2. **Decision summary** — total decisions made, grouped by stage
3. **Auto-remediations** — any fix cycles triggered and their outcomes
4. **Accepted risks** — items flagged as risk but not blocking
5. **Placeholders** — any `PLACEHOLDER_*` tokens still unresolved
6. **Blockers** — anything that stopped the pipeline

This report is always available — the owner should never have to dig through logs to understand what Autopilot did.

### Pipeline Completion Report

When the entire pipeline finishes (or is stopped by a blocker), automatically display the report below.

**Critical rule:** The report must NOT contain fixable code issues. All code bugs, missing sanitisation, missing tests, security vulnerabilities, etc. must have been auto-remediated BEFORE this report is generated. If any fixable issues remain, go back and fix them first — do not present this report until only genuinely human-required items remain.

The report has two sections:
1. **Summary + Auto-fixed** (informational — what the agent did autonomously)
2. **YOUR ACTION REQUIRED** (only items that genuinely need human input: credentials, external service setup, business decisions, DNS configuration, third-party account creation)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  AUTOPILOT COMPLETE — {Project Name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Stages completed : {N} / {total}
  Decisions made   : {count}
  Auto-remediations: {count}
  Accepted risks   : {count}

  Decision Log     : artifacts/decision-log-{timestamp}.md

─── What was auto-fixed (no action needed) ─────

  | # | Issue | Fix Applied | Stage |
  |---|-------|-------------|-------|
  | 1 | {e.g. Missing DOMPurify sanitisation} | {Added sanitisation in ChatMessage.tsx} | code-reviewer |
  | 2 | {e.g. CSRF token missing} | {Added csrf middleware + token generation} | security-auditor |
  | ... | ... | ... | ... |

─── YOUR ACTION REQUIRED ───────────────────────

  The following items require human input and
  cannot be resolved by the agent:

  | # | Item | What You Need To Do |
  |---|------|---------------------|
  | 1 | PLACEHOLDER_STRIPE_KEY | Add your Stripe API key to .env |
  | 2 | DNS configuration | Point your domain to Vercel |
  | ... | ... | ... |

  If this section is empty — you're all set!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```
