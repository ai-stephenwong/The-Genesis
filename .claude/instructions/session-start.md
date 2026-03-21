# Session Start — Always-On Instructions

Execute this in full at the start of every conversation, before doing anything else.

## Step 0 — Mode Selection

Display the following prompt and wait for the user's choice before doing anything else:

```
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

If the user chooses **1 — Autopilot**, display this prerequisite check before proceeding:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Autopilot mode selected.

  For a truly unattended run, confirm the following
  are already in place:

  [ ] source .secrets/load-credentials.sh has been run
      (only CLOUDFLARE_API_TOKEN + DATABASE_URL needed;
       GitHub/Vercel/Resend/Upstash are handled by MCP)
  [ ] OP_SERVICE_ACCOUNT_TOKEN set in ~/.zshrc if using
      1Password for the above credentials (no Touch ID)
  [ ] All pipeline tool permissions are pre-approved
      in .claude/settings.json (no mid-run prompts)
  [ ] MCP servers are connected (GitHub, Vercel,
      Cloudflare, Neon, Resend, Upstash)

  If any item is not ready, the session will pause
  mid-run waiting for human input.

  Ready to proceed? [Y / n]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Wait for confirmation before continuing.

Store the chosen mode for the rest of this session:

- **1 — Autopilot**: At every pipeline gate, apply The Genesis standards as decision criteria, decide automatically (approve / reject / resolve), create a `snapshot/{stage}-{HHmm}` git tag immediately after deciding, log the decision with rationale. Do not pause for user input at any gate. Every intermediate deliverable that normally requires owner approval (requirements, architecture, API spec, code review, security, compliance, production deploy) is approved automatically on their behalf — each approval is recorded in the Decision Log so the owner can review every gate and roll back any they disagree with on return. For any unknown value (URLs, connection strings, API keys, credentials), use a `PLACEHOLDER_<DESCRIPTION>` token — never block to ask. Track every placeholder used. On completion, deliver the Configuration Handover block (listing all placeholders with file, token, and description) followed by the Decision Log format from `agent_docs/generic/pilot-spec.md`.
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
  4c   ux-reviewer            ⏳ Not started  —               artifacts/ux-review/review-*.md
       ↑ 4a, 4b and 4c run in parallel
  5    security-auditor       ⏳ Not started  —               artifacts/security/audit-*.md
  6    compliance-officer     ⏳ Not started  —               artifacts/compliance/compliance-*.md
       ↑ quality gate — must PASS before any deployment
  7    deploy-staging         ⏳ Not started  —               Staging URL live + smoke tests passed
                                                              artifacts/devops/deploy-staging-*.md
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
- 4c (ux-reviewer) only appears if active in pipeline.md
- If no artifact yet: show `—` for Last Run and expected output folder for Deliverable
- If all stages "Not started": show all as ⏳

## Step 2 — First-Session Detection

If ALL pipeline stages are "Not started", this is the first session. Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  👋 First session — let's set this project up.
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
   ✅ Setup complete. When you're ready to begin development, say:
      "run agent requirements-analyst"   ← start here if you have requirements
      "run pipeline"                     ← run all agents in sequence
   ```

After first-session onboarding: skip Steps 3 and 4 below. Otherwise proceed.

## Step 3 — Requirements Drift Check

1. Read `agent_docs/project/specs/requirements.md` (the registry)
2. For each file registered, read from `agent_docs/project/specs/requirements-include-files/`
3. Extract its `<!-- last-updated: YYYY-MM-DD -->` tag
4. Compare against the `Last Reviewed` date in the registry
5. If any file is newer, alert before doing anything else:

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
2. If pending requests exist, alert before any other work:

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
