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
- Update the Pipeline Status table in `agent_docs/project/pipeline.md` after each stage completes

---

## Step 4 — Stage progression (Autopilot vs Manual)

**Check the current session mode** (set during session-start):

**Autopilot mode:**
- After each stage completes with `STATUS: COMPLETE`, **immediately proceed to the next stage** — do NOT ask the user for permission
- Mark intermediate deliverables as `🤖 Auto-approved` in the pipeline status table
- Continue spawning the next agent in sequence until either:
  - A stage returns `STATUS: BLOCKED` or `STATUS: FAILED` with a `GATE:` → **STOP** and present the gate to the user for decision
  - All stages are complete
- The pipeline runs end-to-end without human intervention unless a gate fires

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
- Any `BLOCKED` or `FAILED` status from any agent
