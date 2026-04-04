# Trigger: Run Pipeline / Run Agent

Execute this when the user says **"run pipeline"** or **"run agent {name}"**.

---

## Step 1 — Read pipeline configuration

Read `agent_docs/project/pipeline.md` to determine active agents, order, source paths, and `api-spec-required`. If resuming, identify the latest artifact from the last completed stage.

---

## Step 1b — Requirements Gate Check

Before launching **any** agent, verify real requirements files exist in `agent_docs/project/specs/requirements-include-files/`. Exclude template-only files.

- **No real files** → STOP: `Cannot start pipeline — no requirements files found.`
- **Files exist (Autopilot):** Log files in Decision Log, auto-confirm, proceed.
- **Files exist (Manual):** List files, ask owner to confirm.

---

## Step 2 — Architecture Gate Check (before developer only)

If `api-spec-required: true` in `pipeline.md`, check ALL four deliverables:

| File | Check |
|---|---|
| `architecture.md` | Has Mermaid diagram |
| `er-diagram.md` | Has Mermaid erDiagram |
| `functional-specs.md` | Has at least one feature spec |
| `api-spec.yaml` | Has at least one real path |

Any missing → STOP. All present → proceed.

---

## Step 2b — Module Decomposition Check (before developer only)

Check if `agent_docs/project/modules/module-*.md` exist.

**If modules exist** — run developer in **module mode**:
- **Phase 0** (shared/common): One developer sub-agent, sequential
- **Phase 1** (independent): One developer sub-agent per module, parallel
- **Phase 2** (integration): After Phase 1, sequential
- After all modules: **integration verification** (full project build)
- Route integration failures to the responsible module's developer

Module-scoped developer prompt must include:
1. Developer role definition
2. Module spec (`modules/module-{name}.md`)
3. "Read other modules only for interface contracts"
4. "Write code only within your module's owned scope"

**If no modules** — single developer stage.

---

## Step 3 — Launch agents as sub-agents

**Every pipeline agent MUST run as a sub-agent via the `Agent` tool.** Never role-play inline. Each sub-agent gets its own context window.

**How to launch:** Include the agent's role definition, input file paths, and output expectations. The sub-agent reads files, does work, produces artifacts, returns a summary.

**Rules:**
- One sub-agent per pipeline stage
- Independent stages (code-reviewer + tester + uiux-reviewer) → launch in parallel
- Orchestrator's job: gate checks → launch sub-agent → receive summary → update pipeline.md → next stage

**Pipeline status updates (hard gate):** Update `pipeline.md` at THREE points:
1. Before launching → set Started, Status = In progress
2. After completion → set Completed, Status, Artifact, Process Time
3. After remediation → add new row (e.g. `4a-R1 | code-review remediation`)

---

## Step 4 — Stage progression

**Autopilot:** After `STATUS: COMPLETE`, immediately proceed. Mark as `Auto-approved`. Auto-remediate fixable issues.

**Manual:** Present output, ask: `Proceed to next stage? [Y/n]`

**Gates requiring human approval (even in Autopilot):**
- `staging-sign-off`
- `production-deploy`

### Auto-remediation (Autopilot)

When reviewers find fixable issues: fix them, don't ask. Fixable = code bugs, missing sanitisation, security issues, missing tests, env var mismatches, placeholder code, translations, etc.

**Remediation protocol:** See `.claude/instructions/remediation.md` for:
- Attempt limits (3/issue, 9/stage)
- Loopback flow (requirements-analyst → solution-architect → developer → re-review)
- Blocker judgement (two-agent rule)
- Anti-circumvention rules

**Secrets:** Use Doppler directly: `doppler secrets get SECRET_NAME --plain --project {project} --config {env}`

**Available services:** Selected by solution-architect during architecture stage. See `architecture.md` for the project's selected services. If developer needs a new tool/service, submit a Tool Selection Change Request.

**MCP-first, CLI fallback:** Try MCP server first. If it fails, fall back to CLI with Doppler credentials. Don't ask — fall back silently, log it.

---

## Step 5 — Decision Log (Autopilot only)

**Path:** `artifacts/decision-log-YYYYMMDD-HHmm.md` — created at pipeline start, appended after every decision.

**Per-stage entry:**

```markdown
## Stage: {stage-name} — {timestamp}
| # | Decision Point | Options | Decision | Rationale |
|---|---|---|---|---|
**Stage outcome:** {PASS / FAIL / AUTO-REMEDIATED}
**Artifacts:** {files}
**Snapshot:** `snapshot/{stage}-{HHmm}`
```

**Stage report (display after each stage):**

```
━━━ Stage {N} — {agent-name}  ✅ Complete
  Decisions: {count}  |  Artifacts: {list}  |  Next: {next-stage}
━━━
```

**Pipeline Completion Report:** Display when pipeline finishes. Must NOT contain fixable issues — fix them first. Two sections:
1. **Auto-fixed** (informational)
2. **YOUR ACTION REQUIRED** (only genuinely human-required items: credentials, DNS, business decisions)

> Format: see `agent_docs/templates/decision-log.md`
