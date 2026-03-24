# Session Start — Always-On Instructions

Execute this in full at the start of every conversation, before doing anything else.

## Step -1 — Detect Context (The Genesis vs Child Project)

> **Steps 0–4 (mode selection, session summary, drift checks) apply to child projects ONLY.**
> The Genesis is the governing framework — it does not run a pipeline and has no mode to select.

Read `CLAUDE.md` and check the project name (first `#` heading).

- If the project is **The Genesis**: **STOP here. Do not proceed to Step 0.** Instead, display a brief session summary showing recent git commits and any pending work (tributes in `tributes/inbox/`, any uncommitted changes), then wait for the user's instruction.
- If the project is **any other project (child project)**: continue to Step 0 below.

---

## Step 0 — Prerequisites Reminder and Mode Selection

Before asking the user to choose a mode, display the prerequisites checklist so they know what should be in place:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Before we begin, please confirm these are ready:

  [ ] Requirements files added to
      agent_docs/project/specs/requirements-include-files/
      (at least one real file — not just the default template)
  [ ] Doppler project created with DATABASE_URL configured
      (DOPPLER_TOKEN set in ~/.zshrc for unattended access)
  [ ] MCP servers connected (GitHub, Cloudflare,
      Resend, Upstash — these use tokens and always work)
      Vercel and Neon use OAuth and only connect in one
      project at a time. If they show "not connected":
        - They work in The Genesis session (OAuth host)
        - In child projects, use CLI fallback instead:
            vercel login   (one-time, persistent)
            neonctl auth   (one-time, persistent)
          After login, all vercel/neonctl CLI commands work
          without tokens or env vars.
      If any MCP server shows "Needs authentication",
      clear the auth cache first:
        echo '{}' > ~/.claude/mcp-needs-auth-cache.json
      Then restart Claude Code.
  [ ] Tool permissions pre-approved in .claude/settings.json
      (no mid-run prompts)

  If any item is not ready, you can still proceed in
  Manual mode but the pipeline will pause at the first
  missing prerequisite.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Choose operating mode for this session:

  1) Autopilot  — Claude runs everything unattended.
                  You receive a decision log + git snapshots
                  at every gate when done.

  2) Manual     — You approve every gate yourself.
                  (Standard behaviour)

  Choose [1 / 2]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

If the user chooses **1 — Autopilot**, confirm readiness:

```
  Autopilot mode selected.
  All prerequisites confirmed? [Y / n]:
```

Wait for confirmation before continuing.

Store the chosen mode for the rest of this session:

- **1 — Autopilot**: The agent runs the entire pipeline unattended. **Core principle: if the agent already has a recommendation or sufficient information to decide, execute the recommendation immediately — never pause to ask.**

  **Decision-making:** At every pipeline gate, apply The Genesis standards as decision criteria, decide automatically (approve / reject / resolve), create a `snapshot/{stage}-{HHmm}` git tag immediately after deciding. Do not pause for user input at any gate. Every intermediate deliverable that normally requires owner approval (requirements, architecture, API spec, code review, security, compliance) is approved automatically on their behalf.

  **Decision Log:** All decisions are recorded in a persistent file: `artifacts/decision-log-YYYYMMDD-HHmm.md` (created at pipeline start, appended after every decision). See `run-pipeline.md` Step 5 for the full format.

  **Stage reporting:** After each stage completes, display a brief stage report (decisions made, key decisions, artifacts, next stage). The project owner can request an overall report at any time ("show report", "status").

  **Placeholders:** For any unknown value (URLs, connection strings, API keys, credentials), use a `PLACEHOLDER_<DESCRIPTION>` token — never block to ask. Track every placeholder used.

  **On completion:** Automatically display the Pipeline Completion Report: stages completed, total decisions, auto-remediations, accepted risks, unresolved placeholders (Configuration Handover), and the path to the Decision Log file.
- **2 — Manual**: Standard behaviour — pause and wait for user approval at every gate.

Then continue to Step 1.

---

## Step 1 — Display Session Summary

1. Read `CLAUDE.md` → extract project name, client, phase, and description
2. Read `agent_docs/project/pipeline.md` → read the Pipeline Status table and Retrospective History tables
3. Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project : {Project Name}
  Client  : {Client Name}
  Phase   : {Phase}
  About   : {One-line description}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Pipeline Status

  #    Stage                  Status          Last Run        Deliverable
  ──── ─────────────────────  ──────────────  ──────────────  ──────────────────────────────────────
  1    requirements-analyst   ✅ Completed    2026-03-15      artifacts/requirements/analysis-*.md
  2    solution-architect     ✅ Completed    2026-03-16      artifacts/architecture/design-*.md
                                                              agent_docs/project/architecture.md
                                                              agent_docs/project/er-diagram.md
                                                              agent_docs/project/specs/functional-specs.md
                                                              agent_docs/project/specs/api-spec.yaml
  3a   developer              🔄 In progress  2026-03-18      src/ (all repos)
                                                              artifacts/development/feature-*.md
  3b   devops-engineer        ✅ Completed    2026-03-17      .github/workflows/
                                                              artifacts/devops/setup-*.md
       ↑ 3a and 3b run in parallel
  4a   code-reviewer          ⏳ Not started  —               artifacts/code-review/review-*.md
  4b   tester                 ⏳ Not started  —               artifacts/test/results-*.md
  4c   uiuiux-reviewer          ⏳ Not started  —               artifacts/uiux-review/review-*.md
       ↑ 4a, 4b and 4c run in parallel
  5    security-auditor       ⏳ Not started  —               artifacts/security/audit-*.md
  6    compliance-officer     ⏳ Not started  —               artifacts/compliance/compliance-*.md
       ↑ quality gate — must PASS before any deployment
  7    deploy-environment     ⏳ Not started  —               {env} URL live + smoke tests passed
                                                              artifacts/devops/deploy-{env}-*.md
       ↑ run per environment: dev, UAT, pre-production, staging, etc.
  8    deploy-production      ⏳ Not started  —               Production URL live + smoke tests passed
                                                              artifacts/devops/deploy-production-*.md

  ✅ Completed  🤖 Auto-approved  ❌ Failed  🔄 In progress  ⏳ Not started

  🤖 Auto-approved = stage was completed and approved automatically by Autopilot on the owner's behalf — review the Decision Log

Retrospective History   (from pipeline.md)

  Round  Date        Overall  Artifact
  ─────  ──────────  ───────  ──────────────────────────────────────────────────────
  (rows from pipeline.md Retrospective History table)

  Agent Scores
  Agent                R1   R2   Trend
  ───────────────────  ───  ───  ─────
  (rows from pipeline.md Agent Scores by Round table)

  (show "No retrospectives run yet." if Retrospective History table has no entries)

Commands
  Run full pipeline   : "run pipeline"
  Run a single agent  : "run agent {stage-name}"   e.g. "run agent solution-architect"
  Re-run a stage      : "run agent {stage-name}"   (picks up latest upstream artifact)
  Generate compliance : "generate compliance report"
  Run retrospective   : "run retrospective"         (after a bug batch is found)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Populate the table from `agent_docs/project/pipeline.md`:**
- Use Last Run date and artifact path from the pipeline status table
- 3b (devops-engineer) only appears if active in pipeline.md
- 4c (uiux-reviewer) only appears if active in pipeline.md
- If no artifact yet: show `—` for Last Run and expected output folder for Deliverable
- If all stages "Not started": show all as ⏳

**IMPORTANT — Live pipeline status:**
When the user asks about pipeline status at ANY point during a session (not just at startup), **always re-read `agent_docs/project/pipeline.md` fresh from disk**. Do NOT rely on the version read at session start — another session may be running the pipeline and updating the file in real time.

## Step 2 — First-Session Detection

If ALL pipeline stages are "Not started", this is the first session.

### Autopilot mode — first session

If Autopilot is active, **do not ask setup questions**. Auto-resolve everything:

1. **Stack details** — read `agent_docs/project/stack.md`. If placeholders remain, choose the most common/sensible defaults based on the project's tech stack, fill them in, and log each decision.
2. **GitHub repos** — read `agent_docs/project/git-workflow.md`. If repo URLs are already filled in, proceed. If not, use `PLACEHOLDER_REPO_URL` tokens.
3. **Requirements files** — check `agent_docs/project/specs/requirements-include-files/`. If real files exist, register any unregistered ones automatically. If no real files exist, log it as a blocker and stop.
4. **Git init** — if the project folder is not yet a git repo, initialise it automatically: `git init && git add . && git commit -m "chore: initialise project scaffold"`.
5. **Immediately execute `run pipeline`** — do not display the "Ready to start" prompt, do not wait for the user to say "run pipeline". Autopilot must start the pipeline automatically as soon as setup is complete. Read and follow `.claude/instructions/run-pipeline.md` directly from here.

### Manual mode — first session

Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  First session — let's set this project up.
  I'll ask you a few questions and fill everything in.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Then guide the user through setup **one question at a time** (never ask multiple questions at once):

1. **Stack details** — ask about any unfilled placeholders in `agent_docs/project/stack.md` (ORM, cache, component library, database hosting). Fill in each answer immediately before asking the next.

2. **GitHub repo URLs** — ask: "What are the GitHub repo URLs? (or 'not yet created')" → update `agent_docs/project/git-workflow.md` and `CLAUDE.md`.

3. **Requirements files** — ask:
   > Do you have existing requirements files to import?
   > **A)** I'll copy them myself
   > **B)** Give me a source folder to browse
   > **C)** Skip for now

   - **If A:** Show clickable destination folder link. Say: "Copy your files there and let me know when done." When confirmed, register all new files in `agent_docs/project/specs/requirements.md`.
   - **If B:** Ask for the source folder path → list all files as a checkbox list → copy selected files → register in requirements.md.
   - **If C:** Skip.

4. **Git init reminder** — display:
   ```
   When ready, initialise git (run in the project folder):
     git init && git add . && git commit -m "chore: initialise project scaffold"
   ```

5. **Ready to start** — display:
   ```
   Setup complete. When you're ready to begin development, say:
      "run agent requirements-analyst"   ← start here if you have requirements
      "run pipeline"                     ← run all agents in sequence
   ```

After first-session onboarding: skip Steps 3 and 4 below. Otherwise proceed.

## Step 3 — Requirements Drift Check

1. Read `agent_docs/project/specs/requirements.md` (the registry)
2. For each file registered, read from `agent_docs/project/specs/requirements-include-files/`
3. Extract its `<!-- last-updated: YYYY-MM-DD -->` tag
4. Compare against the `Last Reviewed` date in the registry
5. If any file is newer:

**Autopilot mode:** Log the drift in the Decision Log, treat the updated files as the current requirements (auto-acknowledge), update `Last Reviewed` to today, and proceed. Do NOT ask.

**Manual mode:** Alert before doing anything else:

```
⚠️ Requirements have been updated since they were last reviewed:

  • 01-functional.md    updated: 2026-04-01   last reviewed: 2026-03-16

Would you like to review the changes before we continue? [Y/n]
```

6. If yes — summarise changes and ask if they affect work in progress
7. If no — continue, repeat alert next session
8. Only update `Last Reviewed` when the user explicitly confirms they have reviewed the file

## Step 4 — API Spec Change Request Review

1. Check if `artifacts/development/api-spec-change-requests-*.md` exists and contains items with `Status: PENDING APPROVAL`
2. If pending requests exist:

**Autopilot mode:** Evaluate each change request against the requirements and architecture. If the change is consistent with requirements and the developer's rationale is sound, **auto-approve** — update `api-spec.yaml`, set `Status: APPROVED`, and log the decision. If the change contradicts requirements or introduces risk, **auto-reject** with reason and log the decision. Do NOT ask.

**Manual mode:** Alert before any other work:

```
⚠️ API spec change requests are pending your approval:

  From: developer — 2026-03-17 14:30
  Endpoint: POST /auth/register — role field
  Current spec: enum [candidate, employer]
  Proposed: enum [candidate, employer, recruiter]
  Reason: New recruiter role required per updated requirements
  Impact: Frontend enum, backend validator, RBAC rules

Would you like to review and approve/reject these changes? [Y/n]
```

3. If **approved**: update `api-spec.yaml`, regenerate frontend types and backend DTOs, update `Status: APPROVED`, then continue
4. If **rejected**: update `Status: REJECTED — [reason]`, notify developer agent to implement within existing spec constraints
5. A change request must never be self-approved by the agent that raised it
