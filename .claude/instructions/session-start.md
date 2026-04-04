# Session Start — Always-On Instructions

Execute at the start of every conversation, before doing anything else.

## Step -1 — Detect Context

Read `CLAUDE.md`. Check the project name (first `#` heading).

- **The Genesis:** STOP. Show recent git commits + pending work (tributes in `tributes/inbox/`, uncommitted changes). Wait for user instruction.
- **Child project:** Continue to Step -0.

---

## Step -0 — Path Sanitisation

Scan for hardcoded absolute paths in: `.claude/settings.json`, `.claude/settings.local.json`, `.claude/instructions/*.md`, `agent_docs/project/*.md`, `scripts/*.sh`, `CLAUDE.md`.

Replace any hardcoded paths with correct paths for this machine. Log each fix. For Genesis tribute path in `settings.json`, if Genesis not found, comment out the permission and warn.

Runs silently in Autopilot. In Manual, display fixes and continue.

---

## Step 0 — Mode Selection

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Prerequisites:
  [ ] Requirements files in agent_docs/project/specs/requirements-include-files/
  [ ] Doppler project + DATABASE_URL configured
  [ ] MCP servers connected (Vercel/Neon: use CLI fallback in child projects)
  [ ] Tool permissions in .claude/settings.json

  Choose mode:
  1) Autopilot  — Unattended. Decision log + snapshots.
  2) Manual     — You approve every gate.
  [1 / 2]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Autopilot:** Confirm readiness → run pipeline unattended. Auto-approve all gates per Genesis standards. Use `PLACEHOLDER_<DESC>` for unknown values. Log all decisions. Snapshot at every gate.

> See `.claude/instructions/autopilot-rules.md` for full Autopilot operating rules.

**Manual:** Pause at every gate for user approval.

---

## Step 1 — Session Summary

Read `CLAUDE.md` and `pipeline.md`. Display:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project : {name}  |  Client: {client}  |  Phase: {phase}

  Pipeline Status (from pipeline.md)
  #   Stage                  Status          Last Run
  ──  ─────────────────────  ──────────────  ──────────
  1   requirements-analyst   ✅/⏳/🔄/❌    date/—
  2   solution-architect     ...
  (all stages from pipeline.md)

  Commands: "run pipeline" | "run agent {name}" | "run retrospective"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Always re-read `pipeline.md` fresh** when status is requested — another session may be updating it.

---

## Step 2 — First-Session Detection

If ALL stages are "Not started":

**Autopilot:** Auto-resolve stack placeholders, register requirements, git init if needed, then **immediately execute `run pipeline`** — do not wait.

**Manual:** Guide user through setup one question at a time:
1. Stack details (unfilled placeholders in `stack.md`)
2. GitHub repo URLs
3. Requirements files import (copy/browse/skip)
4. Git init reminder
5. "Ready to start" prompt

---

## Step 3 — Requirements Drift Check

Compare `<!-- last-updated: -->` tags in requirements files against `Last Reviewed` in `specs/requirements.md`.

**Autopilot:** Log drift, auto-acknowledge, update Last Reviewed, proceed.
**Manual:** Alert user, ask to review changes.

---

## Step 4 — API Spec Change Request Review

Check `artifacts/development/api-spec-change-requests-*.md` for `Status: PENDING APPROVAL`.

**Autopilot:** Auto-approve if consistent with requirements, auto-reject if contradicts. Log decision.
**Manual:** Present changes, ask approve/reject.

Change requests must never be self-approved by the raising agent.
