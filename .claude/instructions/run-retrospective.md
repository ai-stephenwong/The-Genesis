# Trigger: Run Retrospective

Execute this when the user says **"run retrospective"**.

> **The bug report must already exist before a retrospective can run.**
> Bug reports are created and maintained by the `tester` as issues are found — not at retrospective time.
> If no bug report exists in `artifacts/development/`, halt and ask the tester to produce one first.

---

## Step 1 — Locate and freeze the bug report

1. Find the latest `artifacts/development/bug-report-YYYYMMDD-HHmm.md` that has `Status: OPEN`.
2. If none exists: halt. Inform the user that a bug report must be created by the tester before the retrospective can run.
3. **Immediately mark the file `Status: FROZEN`** — write this change before doing anything else. This prevents any further edits to that file. All new bugs found after this point must go into a new `bug-report-YYYYMMDD-HHmm.md`.
4. Read the frozen bug report and determine which agents' defined responsibilities (from `agent_docs/generic/agent-roles.md`) should have caught each issue.

If the user has not specified which agents are implicated, determine automatically from the root causes. Ask the user to confirm the list before proceeding.

---

## Step 2 — Spawn self-reviews (parallel)

Spawn one agent instance per implicated role, in parallel. Each agent:
- Reads the **frozen** bug report
- Reads its own pipeline artifacts from the affected cycle
- Writes a self-review to `artifacts/{agent-name}/self-review-YYYYMMDD-HHmm.md`

**Self-review format (all agents must follow):**

```markdown
# {Agent Name} — Self-Review Report
**Date:** YYYY-MM-DD HH:mm
**Author:** {agent-name} agent
**Trigger:** [bug batch description]
**Reference:** [bug report path], [relevant artifact paths]

## Purpose
[What this self-review covers and why]

## Observations
### OBS-01 — [Title]
**What was found:** [description of the bug/issue]
**What the agent did:** [what the agent's check covered]
**Why it slipped through:** [honest root cause analysis]

(repeat for each observation)

## Root Causes
| # | Root Cause | Affected Observations |
|---|---|---|
| RC-01 | [description] | OBS-XX |

## Suggested Improvements
### SUG-01 — [Title]
[Concrete change to agent responsibilities or checklist to prevent recurrence]

(repeat for each suggestion)

## Summary
[Overall assessment — honest, not defensive]

**Sign-off:** {agent-name} agent (self-review) — YYYY-MM-DD HH:mm
```

---

## Step 3 — Spawn retrospective-analyst

Once all self-reviews are complete, spawn the `retrospective-analyst` with:
- The bug report
- All self-reviews from Step 2
- All pipeline artifacts from the affected cycle (`artifacts/*/`)
- `agent_docs/generic/agent-roles.md` as the scoring rubric

The retrospective-analyst writes `artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md` and updates **both** retrospective tables in `agent_docs/project/pipeline.md`:
- **Retrospective History** — append one row: round number, date, bug report reference, overall score, artifact path
- **Agent Scores by Round** — add the new round's score column for each reviewed agent; update the Trend column (↑ improved / → unchanged / ↓ declined vs previous round)

**retrospective-analyst scoring criteria (per agent):**
- Were all defined responsibilities fulfilled?
- Were the issues within the agent's defined scope to catch?
- Was the self-review complete, honest, and correctly identified root causes?
- Were the agent's suggested improvements actionable and accurate?
- Distinguish agent failure (skipped a defined responsibility) from framework gap (no agent's role covered it)

**retrospective-analyst output format:**

```markdown
# Retrospective — YYYY-MM-DD HH:mm
**Round:** N
**Trigger:** [bug report reference]
**Agents reviewed:** [list]

## Per-Agent Scores
| Agent | Score | Trend | Key Finding |
|---|---|---|---|
| developer | X/5 | ↑/→/↓ | [one line] |
| compliance-officer | X/5 | ↑/→/↓ | [one line] |

## Agent Performance Detail

### {Agent Name}
**Score:** X/5
**Observations:** [from self-review + independent assessment]
**Root Cause Attribution:** [agent failure vs framework gap]
**Score Rationale:** [why this score]
**Self-Review Quality:** [was it honest and accurate?]

(repeat per agent)

## Framework Gaps Identified
[Issues not attributable to any single agent — systemic gaps requiring agent-roles.md updates]

## SDLC Improvement Proposals
### PROP-01 — [Title]
**Target:** agent_docs/generic/agent-roles.md — {section}
**Change:** [exactly what to add/modify]
**Rationale:** [why this would have prevented the issue]

(repeat per proposal)

## Overall Process Health Score
**Score:** X/5
**Summary:** [overall assessment of this delivery cycle]

**Sign-off:** retrospective-analyst — YYYY-MM-DD HH:mm
```

---

## Step 4 — Present SDLC improvement proposals

If the retrospective report contains `PROP-XX` entries, present them to the user:

```
📋 The retrospective-analyst has proposed improvements to agent-roles.md:

  PROP-01 — [title]: [one-line summary]
  PROP-02 — [title]: [one-line summary]

Would you like to apply these to agent_docs/generic/agent-roles.md? [Y/n/review each]
```

- **Y:** Apply all proposals to `agent_docs/generic/agent-roles.md` in **The Genesis**, then propagate to all active sibling project folders that have `agent_docs/generic/agent-roles.md`
- **Review each:** Go through proposals one by one, apply only those approved
- **N:** Mark proposals as reviewed but not adopted in the retrospective artifact

---

## Step 5 — Multiple rounds

If a second bug batch is found after fixes are applied, repeat with an incremented round number. The retrospective-analyst tracks scores across rounds and notes trend direction.

### Freeze rules — immutability at two points

**Point 1 — Retrospective trigger (Step 1 above):**
> The bug report is frozen the moment a retrospective is triggered against it.
> No agent — including the tester — may edit or append to it after that point.
> New bugs found after this point → new `bug-report-YYYYMMDD-HHmm.md`.

**Point 2 — Tribute produced:**
> Once a bug report or retrospective file has been referenced in a `TRIBUTE.md`, it is **frozen** a second time (tribute-level freeze).
> No agent may modify, append to, or overwrite it for any reason.
>
> - Further SDLC proposals → **new retrospective round** (increment round number) → **new tribute**
> - The frozen files remain as the permanent record of what that round found and proposed.
>
> This ensures tributes remain self-consistent — The Genesis always reviews exactly what was submitted.

---

## Step 6 — Produce a Tribute (when SDLC proposals exist)

A **tribute** is the formal output package that the retrospective-analyst produces when it has SDLC improvement proposals ready to be absorbed by The Genesis. It is the mechanism by which a child project humbly submits lessons learned back upstream for The Genesis to judge.

> **The Genesis is the governing framework — child projects are subject to it, not equal to it.**
> A tribute is a petition, not an order. The retrospective-analyst proposes; The Genesis decides.
> Child project agents must **NEVER** directly modify any file inside The Genesis project folder.
> The tribute is the only permitted channel for suggesting change.

**When to create:** At the end of any retrospective round that produces at least one `PROP-XX` entry.

**The retrospective-analyst creates a tribute folder:**

```
tribute-{project-slug}-{YYYYMMDD-HHmm}/
├── TRIBUTE.md                          ← cover document (required)
├── retrospective-{YYYYMMDD-HHmm}.md    ← full retrospective artifact
├── bug-report-{YYYYMMDD-HHmm}.md       ← the triggering bug report
├── self-review-{YYYYMMDD-HHmm}.md      ← one per implicated agent
│   (or self-review-{agent}-{YYYYMMDD-HHmm}.md if multiple agents)
└── proposed/                           ← proposed new versions of generic files
    └── {filename}.md                   ← one file per generic file that needs updating
```

**`TRIBUTE.md` format:**

```markdown
# Tribute — {project-slug} → The Genesis
**Date:** YYYY-MM-DD
**Source project:** {project-slug}
**Retrospective round:** N
**Retrospective artifact:** retrospective-YYYYMMDD-HHmm.md

---

## What happened
[One paragraph: what bug batch or failure triggered this retrospective and why it matters]

---

## Proposed changes to The Genesis

### File 1: `agent_docs/generic/{filename}`

| Proposal | Target agent | Change |
|---|---|---|
| PROP-01 | `{agent}` | [one-line description of change] |

(repeat for each file)

---

## Included artifacts

| File | Description |
|---|---|
| `TRIBUTE.md` | This cover document |
| `retrospective-YYYYMMDD-HHmm.md` | Full retrospective |
| `bug-report-YYYYMMDD-HHmm.md` | Triggering bug report |
| `self-review-YYYYMMDD-HHmm.md` | [agent] self-review |
| `proposed/{filename}` | Proposed new version of `agent_docs/generic/{filename}` |

---

## Agent scores this round

| Agent | Score | Key finding |
|---|---|---|
| {agent} | X/5 | [one line] |

**Overall process health: X/5** — [one-line summary]
```

**Child project Genesis file-access rule:**

> Child project agents **MUST NEVER** copy, edit, or delete any file inside The Genesis project folder.
> The **only permitted exception** is copying a tribute folder into The Genesis `tributes/inbox/`.
> All other Genesis files — `agent_docs/generic/`, `.claude/instructions/`, `CLAUDE.md`, etc. — are read-only from a child project's perspective. Suggestions for change must go through the tribute mechanism only.

**Tribute folder structure (child project):**

Tributes live in the child project's `artifacts/tributes/` folder, split into two states:

```
[child project] artifacts/tributes/
    tribute-{project-slug}-{YYYYMMDD-HHmm}/    ← unpaid (not yet submitted to The Genesis)
        ├── TRIBUTE.md
        ├── retrospective-{YYYYMMDD-HHmm}.md
        ├── bug-report-{YYYYMMDD-HHmm}.md
        ├── self-review-*.md
        └── proposed/
            └── {filename}.md
    paid/
        tribute-{project-slug}-{YYYYMMDD-HHmm}/    ← already submitted to The Genesis inbox
```

**"Pay tribute(s) to The Genesis"** — when the user says this (or similar intent), execute:

1. Find all tribute folders directly inside `artifacts/tributes/` (not inside `paid/`) — these are unpaid.
2. For each unpaid tribute folder, copy it into The Genesis `tributes/inbox/`.
3. Move the tribute folder from `artifacts/tributes/` into `artifacts/tributes/paid/`.
4. Commit: `chore(tribute): pay tribute {tribute-folder-name} to The Genesis`.

After this, The Genesis picks up the tribute from its `tributes/inbox/` for review.

```
[The Genesis] tributes/
    ├── inbox/       ← tribute lands here, awaiting review by The Genesis
    └── processed/   ← moved here after The Genesis has reviewed and absorbed (or rejected) it
```

Once The Genesis reviews and acts on a tribute, it moves the folder from `inbox/` to `processed/`.

---

## Tribute Processing (when running inside The Genesis)

> This section governs how The Genesis handles incoming tributes from child projects.
> It is triggered when the user says "process tribute", "process it", or when a tribute
> is found in `tributes/inbox/`.

### HARD RULE — NO CHANGES WITHOUT EXPLICIT APPROVAL

> **The Genesis must NEVER apply any change to any file — including `agent_docs/generic/`,**
> **`.claude/instructions/`, `CLAUDE.md`, or any other file — based on a tribute**
> **without the user's explicit written approval.**
>
> Analysis and recommendation are permitted. Application is not.
> Silence is not approval. Enthusiasm is not approval.
> Only an explicit "yes", "approve", "apply", or equivalent direct confirmation counts.
> This rule has no exceptions.

---

### Step T1 — Read the tribute

Read all files in the tribute folder:
- `TRIBUTE.md` — cover document and summary of proposals
- `retrospective-*.md` — full retrospective with root cause analysis
- `proposed/*.md` — proposed new versions of generic files
- Self-review files — agent self-assessments

---

### Step T2 — Analyse each proposal independently

For each `PROP-XX` in the tribute:
- Read the current version of the target file in `agent_docs/generic/`
- Compare with the proposed version
- Assess: Is the gap real? Is the proposed change correct and well-scoped? Is it Vercel/Cloudflare-specific (acceptable) or over-fitted to one incident?
- Reach a verdict: **Accept**, **Reject**, or **Accept with modification**

Do NOT apply anything yet.

---

### Step T2b — Conflict check (mandatory before T3)

For every proposal with verdict **Accept** or **Accept with modification**, perform an explicit conflict check:

1. **Text conflict** — does the proposed addition duplicate, contradict, or overlap any existing sentence, bullet, or checklist item in the target file? Identify the exact lines.
2. **Semantic conflict** — does the proposed responsibility duplicate the intent of an existing responsibility under a different name? If so, note which two items overlap and how.
3. **Scope conflict** — does the proposal modify a role in a way that blurs the separation-of-duty boundaries defined in the Pipeline Overview (e.g. a developer responsibility that encroaches on the code-reviewer's defined scope)?
4. **Standards conflict** — does the proposed change contradict any other file in `agent_docs/generic/` (NFR baseline, security checklist, API conventions, deployment standards)?

For each conflict found: downgrade the verdict to **Accept with modification** and state the required adjustment. If no conflicts are found, explicitly state "No conflicts found" for that proposal.

Include the conflict-check results in the verdict table presented at Step T3.

---

### Step T3 — Present summary and WAIT

Present a verdict table to the user and STOP. Do not proceed until the user responds.

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Tribute   : {tribute folder name}
  Source    : {project-slug}
  Round     : {N}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Proposal verdicts:

  | Proposal | Target | Verdict | Reason |
  |---|---|---|---|
  | PROP-01 | solution-architect | Accept | [one line] |
  | PROP-02 | devops-engineer    | Accept | [one line] |
  | PROP-03 | developer          | Reject | [one line] |

Files that would be changed if approved:
  - agent_docs/generic/agent-roles.md
  - agent_docs/generic/deployment-vercel-cloudflare.md

Awaiting your approval before any changes are made.
Reply "apply all", "apply PROP-01 PROP-02", or "reject all".
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**STOP HERE. Do not touch any file until the user responds.**

---

### Step T4 — Apply only what was approved

Apply only the proposals the user explicitly approved:
- Copy the relevant sections from `proposed/` into `agent_docs/generic/`
- Update the `<!-- last-reviewed -->` header in each modified file
- Propagate updated files to all active sibling projects

For rejected proposals: note the rejection reason but make no file changes.

---

### Step T5 — Move tribute and commit

1. Move the tribute folder from `tributes/inbox/` to `tributes/processed/`
2. Commit all changes (applied files + tribute move) in a single commit
3. Push to GitHub
