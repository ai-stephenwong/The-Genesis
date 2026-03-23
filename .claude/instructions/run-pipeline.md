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

Before spawning **any** agent, verify that real requirements files exist in `agent_docs/project/specs/requirements-include-files/`.

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

4. If non-template files exist, list them and ask the project owner to confirm:

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

**If `api-spec-required: true`**, check ALL four mandatory architecture deliverables before spawning the developer:

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

## Step 3 — Spawn agents

- Spawn the required agent(s) with their defined input paths from `pipeline.md`
- For independent stages (code-reviewer + tester + uiux-reviewer), spawn in parallel
- **Update the Pipeline Status table in `agent_docs/project/pipeline.md` at TWO points for each stage:**
  1. **Before spawning** — mark the stage as `🔄 In progress` with the current timestamp. Write the file immediately so other sessions can see it.
  2. **After completion** — mark the stage as `✅ Completed`, `🤖 Auto-approved`, or `❌ Failed` with the completion timestamp. Write the file immediately.

---

## Step 4 — Stage progression (Autopilot vs Manual)

**Check the current session mode** (set during session-start):

**Autopilot mode:**
- After each stage completes with `STATUS: COMPLETE`, **immediately proceed to the next stage** — do NOT ask the user for permission
- Mark intermediate deliverables as `🤖 Auto-approved` in the pipeline status table
- Continue spawning the next agent in sequence until all stages are complete
- The pipeline runs end-to-end without human intervention unless a human-decision gate fires

**Autopilot — handling fixable blockers (auto-remediate):**
When a review stage (code-reviewer, tester, security-auditor, compliance-officer, uiux-reviewer) identifies **fixable code issues** (bugs, security vulnerabilities, missing sanitisation, unhandled errors, missing lockfiles, etc.):
1. Do NOT stop to ask the user
2. Immediately spawn the `developer` agent to fix all identified issues
3. After fixes are applied, re-run the stage that found the issues to verify the fixes
4. If the re-run passes → continue to the next stage
5. If the re-run still fails after **5 fix attempts** → STOP and escalate to the user with a summary of what was tried

This applies to any issue that can be resolved by changing code, config, or dependencies. The orchestrator must not ask "Want me to fix these?" — it must just fix them.

**Autopilot — accepted risks:**
If a review stage flags an item as `Accepted Risk` (e.g. "MFA deferred to v1.1"), log it in the Decision Log but do not block the pipeline. Accepted risks are not fixable blockers — they are documented trade-offs.

**Manual mode:**
- After each stage completes, present the output summary and ask:
  ```
  Stage {N} ({agent-name}) complete. Proceed to stage {N+1} ({next-agent})? [Y/n]
  ```
- Wait for user confirmation before spawning the next agent

**Gates that always require human approval (even in Autopilot):**
- `requirements-sign-off` — requirements must be confirmed before architecture
- `architecture-sign-off` — all 5 deliverables must be approved before development
- `staging-sign-off` — staging must pass before production deploy
- `production-deploy` — production deployment must be explicitly approved
