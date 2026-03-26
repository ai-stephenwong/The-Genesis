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

**Update the Pipeline Status table in `agent_docs/project/pipeline.md` — this is a hard gate, not optional:**

The orchestrator **must not proceed to the next stage** until `pipeline.md` is updated. A pipeline with out-of-date status tracking is untraceable — other sessions, the user, and the retrospective-analyst all depend on this file being accurate.

Update at **THREE** points for each stage:
  1. **Before launching** — set `Started` to current timestamp, `Status` to `In progress`. Write immediately.
  2. **After completion** — set `Completed` to current timestamp, `Status` to `Completed` / `Auto-approved` / `Failed`, `Artifact` to the output path, `Process Time` to actual working time (wall-clock minus any interruptions — permission prompts, token limit pauses, user wait time). Write immediately.
  3. **After remediation rounds** — add a new row (e.g. `4a-R1 | code-review remediation`) with its own start/end/process time. Do not overwrite the original stage row.

Update the `TOTAL` row after every stage completion. If resuming from a previous session, read the existing process times and add to them — do not reset.

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
- **Translations**: if the project requires multi-language support, the agent MUST produce the translation files itself — never ask the project owner to provide translations or run translation scripts. The agent translates all strings, writes the locale files, and adds a todo entry for the project owner to review and amend where necessary. Translation is agent work, not human work.
- Placeholder/stub code that should be real implementations
- Any issue that can be resolved by changing code, config, or dependencies

**Secrets and environment variables — use Doppler directly:**
Assume Doppler is already authenticated in the shell. When any agent needs secrets or environment variables (for testing, migrations, deployment, smoke tests, etc.), use the Doppler CLI directly:
```bash
doppler secrets get SECRET_NAME --plain --project {project} --config {env}
```
Do NOT ask the project owner to provide secrets, load credentials, or run scripts. Just use Doppler. If Doppler fails (not authenticated, secret not found, project not configured), report the error and continue — do not block the pipeline waiting for human input on something that might be fixable.

**Available services:**

There are two categories of services: **infrastructure** and **approved tools**. Both are selected by the **solution-architect** during the architecture stage based on project requirements and the project owner's preferences in `stack.md` and `deployment.md`. The solution-architect documents all selections in `architecture.md`. If the developer later needs to change or add any service from either category, they MUST submit a Tool Selection Change Request to the solution-architect — never change infrastructure or add tools independently.

**Infrastructure** — the solution-architect selects from these based on `stack.md` and `deployment.md`:

| Category | Service | MCP server (try first) | CLI fallback | Doppler key |
|---|---|---|---|---|
| Source control | GitHub | `mcp__github__*` | `gh` | `GITHUB_API_KEY` |
| Database (PostgreSQL) | Neon | `mcp__neon__*` | `neonctl`, `prisma` | `NEON_API_KEY`, `DATABASE_URL` |
| Frontend hosting | Vercel | `mcp__vercel__*` | `vercel` | `VERCEL_API_KEY` |
| Backend hosting | Railway | `mcp__railway__*` | `railway` | `RAILWAY_API_TOKEN` |
| Edge / Workers / CDN | Cloudflare | `mcp__cloudflare-api__*` | `wrangler` | `CLOUDFLARE_API_TOKEN` |
| Secrets management | Doppler | (no MCP) | `doppler` | (already authenticated) |

**Approved tools** — selected by the **solution-architect** during the architecture stage. The solution-architect reviews the requirements and decides which of these tools the project needs, documents the selection in `architecture.md`. If the developer later discovers a need for a tool not selected, they MUST submit a Tool Selection Change Request to the solution-architect for approval — never add a tool independently. Do not suggest alternatives outside this list (e.g. SendGrid instead of Resend, Segment instead of GTM, Redis Cloud instead of Upstash):

| Category | Service | MCP server | Doppler key |
|---|---|---|---|
| Transactional email | **Resend** | `mcp__resend__*` | `RESEND_API_KEY` |
| Redis / caching / rate limiting | **Upstash** | `mcp__upstash__*` | `UPSTASH_API_KEY` |
| Error tracking | **Sentry** | `mcp__sentry__*` | `SENTRY_AUTH_TOKEN` |
| CRM | **HubSpot** | `mcp__hubspot__*` | (OAuth — no key) |
| Tag management | **Google Tag Manager** | `mcp__google-tag-manager__*` | (OAuth — no key) |

**If no service in either list is suitable** for a required capability (e.g. the project needs SMS, payment processing, file storage, or a service not listed here), the agent must **proceed with development** using a clean interface/abstraction, then add an entry to the Pipeline Completion Report under **YOUR ACTION REQUIRED** suggesting which service to add and how to integrate it before deployment.

**MCP-first, CLI fallback:**
For all external service operations, **try the MCP server first**. If the MCP call fails (server not connected, auth expired, operation not supported), fall back to the service's CLI tool with credentials from Doppler:
```bash
export TOKEN=$(doppler secrets get SECRET_NAME --plain --project {project} --config {env})
# then use the CLI tool
```
Do not ask the project owner — just fall back silently and log it in the Decision Log.

When a review stage (code-reviewer, tester, security-auditor, compliance-officer, uiux-reviewer) identifies fixable issues:
1. Do NOT stop to ask the user
2. Immediately use the `Agent` tool to launch the `developer` as a sub-agent to fix ALL identified issues
3. After fixes are applied, use the `Agent` tool to launch the review stage as a new sub-agent to verify the fixes
4. If the re-run passes → continue to the next stage
5. If new issues are found → fix those too, subject to the hard limits below

### Remediation Attempt Limits (MANDATORY — no exceptions)

> **These limits are hard caps. They cannot be overridden, bypassed, or extended by any agent, any mode, or any reasoning. An agent that exceeds these limits is in violation of pipeline rules.**

**Two independent limits apply — whichever is hit first stops the remediation:**

| Limit | Value | Scope | What it means |
|---|---|---|---|
| **Per-issue limit** | **3 attempts** | Per distinct issue | The same issue (or substantially the same issue rephrased) may be attempted at most 3 times. On the 3rd failure, the issue is marked **unresolved** and must not be retried. |
| **Per-stage total limit** | **9 attempts** | Per pipeline stage | The total number of fix attempts across ALL issues within a single pipeline stage (e.g. all code-reviewer findings combined) may not exceed 9. This prevents an endless stream of "new" issues from keeping the stage in a loop. |

**Attempt tracking (mandatory):**

The orchestrator MUST maintain an attempt counter in the Decision Log for every remediation cycle. Each fix attempt must be logged with:
- Attempt number (per-issue and per-stage running total)
- Issue description
- What was tried
- Outcome (resolved / still failing / new issue introduced)

**Format in Decision Log:**
```markdown
## Remediation Tracker — {stage-name}
| # | Issue | Attempt | Action Taken | Outcome | Per-Issue Count | Stage Total |
|---|---|---|---|---|---|---|
| 1 | Missing input sanitisation | 1 | Added DOMPurify to ChatMessage.tsx | Resolved | 1/3 | 1/9 |
| 2 | CSRF token missing | 1 | Added csrf middleware | Still failing — token not sent to client | 1/3 | 2/9 |
| 3 | CSRF token missing | 2 | Added token injection in response header | Resolved | 2/3 | 3/9 |
```

**What counts as "the same issue":**
- The same finding re-reported after a fix attempt → same issue
- A finding with the same root cause but different symptoms → same issue
- A fix that introduces a NEW, unrelated problem → new issue (gets its own 3-attempt counter)
- A reviewer rephrasing or re-categorising the same underlying problem → same issue (the orchestrator must recognise this and not reset the counter)

**When either limit is hit — Blocker Judgement (two-agent rule):**

The orchestrator invokes **two sub-agents in parallel** to independently classify each unresolved issue:
1. **The reviewing agent that found the issue** — it has the technical context
2. **The solution-architect** — it understands the system design and architectural impact

Each agent receives:
- The unresolved issue description
- All attempted fixes and why each failed (from the Remediation Tracker)
- The current pipeline state

Each agent responds with a verdict: **BLOCKER** or **NON-BLOCKER**, with a one-line rationale.

**Decision rule: if EITHER agent classifies the issue as a BLOCKER, it IS a blocker.** Both must agree it is non-blocking for the pipeline to continue. This is a conservative rule — when in doubt, stop.

**Blocker** — the issue prevents the pipeline from continuing (e.g. build fails, tests cannot run, deployment crashes on startup, a Critical-severity security finding). Blockers cannot be skipped.

**Non-blocker** — the issue is a deficiency but the pipeline can continue without it (e.g. a Medium-severity warning, a non-critical feature gap, a cosmetic issue, a test coverage shortfall). Non-blockers can be deferred.

**After judgement:**

**Autopilot mode:**
- **Blocker:** STOP the pipeline immediately. Log the unresolved issue in the Decision Log with all attempted fixes, their failure reasons, and both agents' verdicts. Display:
  ```
  🚫 PIPELINE BLOCKED — Unresolved blocker after {N} fix attempts
     Issue: {description}
     Reviewer verdict: BLOCKER — {rationale}
     Architect verdict: BLOCKER / NON-BLOCKER — {rationale}
     Attempts: {N} — see Decision Log for details
     Action required: Manual intervention needed before pipeline can continue.
  ```
- **Non-blocker (both agents agree):** Log the unresolved issue in the Decision Log as a **deferred item** with both agents' verdicts. Add it to the Pipeline Completion Report under "YOUR ACTION REQUIRED". **Continue the pipeline to the next stage.**
  ```
  ⚠️  Deferred after {N} fix attempts (non-blocking):
     Issue: {description}
     Reviewer verdict: NON-BLOCKER — {rationale}
     Architect verdict: NON-BLOCKER — {rationale}
     Added to Pipeline Completion Report for manual resolution.
     Continuing pipeline...
  ```

**Manual mode:**
- **Blocker:** STOP the pipeline. Present the issue to the user with all attempted fixes, both agents' verdicts, and: `This is a blocker — manual fix required before continuing.`
- **Non-blocker:** STOP the pipeline. Present the issue with all attempted fixes, both agents' verdicts, and ask: `Continue without fixing this? [Y/n]`

**Anti-circumvention rules:**
- An agent MUST NOT reframe a failed fix as a "different approach" to reset the per-issue counter. If the underlying issue is the same, the counter continues.
- An agent MUST NOT split one issue into multiple sub-issues to get more attempts. The per-stage total limit (9) catches this.
- An agent MUST NOT skip logging an attempt to hide a failure. Every fix attempt — successful or not — must appear in the Remediation Tracker.
- If the orchestrator suspects counter manipulation (e.g. an issue keeps reappearing under different names), it must immediately trigger the blocker judgement.
- These rules apply in ALL modes — Autopilot, Manual, and any future mode. No mode is exempt.

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
- If a re-review stage finds **NEW issues** in the changed files, those are fixed in the same loopback cycle (not a separate loopback). New issues get their own per-issue counter but share the per-stage total counter.
- The **Remediation Attempt Limits** (3 per issue, 9 per stage) apply to the entire loopback cycle. When either limit is hit, trigger the blocker judgement per the rules above. No exceptions.
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
