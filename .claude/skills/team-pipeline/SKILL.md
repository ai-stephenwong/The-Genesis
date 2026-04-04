# Team Pipeline

Run the Converge Pipeline using custom agents and Agent Teams where parallelism benefits from inter-agent communication.

## Before starting

1. Read `.claude/instructions/run-pipeline.md` for the full pipeline flow
2. Read `agent_docs/project/pipeline.md` for active agents and project config
3. Run the Requirements Gate Check (Step 1b in run-pipeline.md)

## Custom agent definitions

All pipeline roles are defined as custom agents in `.claude/agents/`. Use `subagent_type` when spawning:

| Agent | subagent_type | Model | Can write? |
|-------|---------------|-------|------------|
| requirements-analyst | `requirements-analyst` | sonnet | Yes |
| solution-architect | `solution-architect` | opus | Yes |
| developer | `developer` | sonnet | Yes |
| devops-engineer | `devops-engineer` | sonnet | Yes |
| code-reviewer | `code-reviewer` | sonnet | Read-only |
| tester | `tester` | sonnet | Yes |
| uiux-reviewer | `uiux-reviewer` | sonnet | Read-only |
| security-auditor | `security-auditor` | sonnet | Read-only |
| compliance-officer | `compliance-officer` | sonnet | Read-only |
| retrospective-analyst | `retrospective-analyst` | opus | Yes |

## Pipeline execution — when to use what

### Sequential stages → custom agent as sub-agent

These stages depend on the previous output. Launch each as a sub-agent via the Agent tool with the custom agent type. Wait for completion before moving to the next.

```
Stage 1: requirements-analyst
  Agent(subagent_type="requirements-analyst", prompt="Run your pipeline stage for this project")
  Wait → complete → next

Stage 2: solution-architect
  Agent(subagent_type="solution-architect", prompt="Run your pipeline stage for this project")
  Wait → complete → next
```

### Developer stage → Agent Team (if modules exist)

Check if `agent_docs/project/modules/module-*.md` exist.

**If modules exist — use Agent Team:**

1. Create team:
   ```
   TeamCreate(team_name="{project}-dev", description="Developer team — parallel module implementation")
   ```

2. **Phase 0** (shared/common modules): Spawn ONE teammate at a time, wait for completion.
   ```
   Agent(subagent_type="developer", team_name="{project}-dev", name="dev-shared",
         prompt="Build module 'shared'. Read agent_docs/project/modules/module-shared.md for scope.")
   ```

3. **Phase 1** (independent modules): Spawn ALL teammates in parallel.
   ```
   Agent(subagent_type="developer", team_name="{project}-dev", name="dev-frontend", ...)
   Agent(subagent_type="developer", team_name="{project}-dev", name="dev-backend", ...)
   Agent(subagent_type="developer", team_name="{project}-dev", name="dev-cms", ...)
   ```
   Teammates can use SendMessage to ask each other about interfaces.

4. **Phase 2** (integration modules): After Phase 1 completes, spawn integration teammates.

5. **Integration verification**: After all modules complete, run full project build.

6. Shutdown teammates and TeamDelete.

**If no modules — check repo count:**
- Multiple repos (web, api, cms): use Agent Team with one teammate per repo
- Single repo: use single sub-agent (no team needed)

### DevOps → sub-agent (parallel with developer)

Launch alongside the developer stage:
```
Agent(subagent_type="devops-engineer", prompt="Run your pipeline stage for this project")
```

### Review stages → parallel sub-agents (no team)

Reviewers work independently — they don't need to talk to each other. Launch 3 sub-agents in parallel:

```
Agent(subagent_type="code-reviewer", prompt="Review all code in src/")
Agent(subagent_type="tester", prompt="Write and run tests for the project")
Agent(subagent_type="uiux-reviewer", prompt="Review UI/UX against mockups")  # only if frontend
```

All 3 run simultaneously. Collect findings when all complete.

### Sequential late stages → sub-agents

```
Stage: security-auditor
  Agent(subagent_type="security-auditor", prompt="Audit the project")

Stage: compliance-officer
  Agent(subagent_type="compliance-officer", prompt="Final compliance check")

Stage: deploy-environment (human gate)
Stage: deploy-production (human gate)
```

### Post-pipeline → retrospective

```
Agent(subagent_type="retrospective-analyst", prompt="Analyse this pipeline run and produce tribute if warranted")
```

## Remediation

When reviewers find fixable issues:
1. Spawn a single developer sub-agent for the fix (no team needed)
   ```
   Agent(subagent_type="developer", prompt="Fix these issues: {findings}")
   ```
2. Follow the Remediation Loopback Protocol from run-pipeline.md
3. Re-review uses the same parallel sub-agent pattern

## State tracking

- Update `agent_docs/project/pipeline.md` at three points per stage (before, after, after remediation)
- Update `artifacts/runs/run-*.json` if pipeline run state file exists
- Log agent type and team usage in the Decision Log

## Summary — decision tree

```
Is it sequential?
  YES → sub-agent (custom agent type)

Is it parallel + agents need to talk?
  YES → Agent Team (developer modules)

Is it parallel + agents work independently?
  YES → parallel sub-agents (reviewers)
```

## Fallback

If TeamCreate fails or Agent Teams unavailable:
- Fall back to parallel sub-agents for developer stage
- Log: "Agent Teams unavailable — falling back to parallel sub-agents"
