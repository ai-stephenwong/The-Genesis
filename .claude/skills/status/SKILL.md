# Status Dashboard

Show a complete status dashboard in one shot. Do ALL of the following:

## 1. MCP Servers

Run `claude mcp list` and present results as a compact table showing server name and status (Connected / Failed / Needs auth).

## 2. Active Pipelines

Find the most recent `artifacts/runs/run-*.json` file in the current project (if it exists). Read it and show:
- Run ID, mode, started time
- Per-stage status table: stage name, status, process time, validation pass/fail

If no run file exists, say "No active pipeline run."

## 3. Git Status

Show current branch, uncommitted changes count, and unpushed commits count.

## 4. Child Projects (Genesis only)

If the current project is The Genesis, list folders in `people/` with a one-line summary (last modified date).

## Formatting

- Use compact tables, not verbose explanations
- Show everything in ONE response — no follow-up questions
- Use status icons: check mark for good, X for failed, arrow for in-progress, dash for pending
