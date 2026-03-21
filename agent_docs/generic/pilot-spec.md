<!-- last-reviewed: 2026-03-21 | reviewed-by: Stephen Wong | next-review: 2026-09-21 -->

# Pilot Specification (Company Standard)

> A **Pilot** is any external autonomous orchestrator agent that drives The Genesis
> pipeline on behalf of a human master. OpenClaw and any future orchestrators are
> Pilots. This spec defines what every Pilot must implement and what The Genesis
> guarantees in return.
>
> The master is always in control — a Pilot acts on their behalf, never independently
> of their intent.

---

## What a Pilot Is

A Pilot:
- Invokes Claude Code sessions (The Genesis and child projects) programmatically
- Drives the full pipeline from project creation to live deployment
- Makes or forwards decisions at every approval gate depending on its operating mode
- Produces a human-readable record of every decision made
- Snapshots the project state at every gate so the master can roll back

A Pilot is **not** an agent inside the pipeline — it is the orchestrator outside it.
The pipeline agents (requirements-analyst, developer, etc.) remain unchanged.

---

## Operating Modes

At the start of every run, the Pilot must present the mode selection prompt:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project details received. Choose operating mode:

  1) Autopilot  — Pilot runs everything unattended.
                  You wake up to a live app + decision log.
                  Every gate is snapshotted for rollback.

  2) Co-pilot   — Pilot handles all approvals on your behalf.
                  You are notified at each gate in real time
                  but do not need to respond.
                  Pilot prepares an approval summary when done.

  3) Manual     — You approve every gate yourself.
                  (Standard behaviour — no Pilot involvement at gates)

  Choose [1 / 2 / 3]:
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Mode 1 — Autopilot

The Pilot runs the entire pipeline without waiting for the master at any point.

### Prerequisites — human actions required before the session starts

Autopilot is only truly unattended if all of the following are satisfied **before** Claude Code is launched. If any prerequisite is missing, Claude Code will pause mid-run waiting for human input, breaking the unattended promise.

| # | Prerequisite | How to satisfy | One-time or per-session? |
|---|---|---|---|
| 1 | **Shell credentials for CLI tools** | Run `source .secrets/load-credentials.sh` before starting Claude — only needed for tools not covered by MCP (see note below) | Per session |
| 2 | **1Password unattended access** | Set `OP_SERVICE_ACCOUNT_TOKEN=ops_...` in `~/.zshrc` — only required if prerequisite 1 is still needed | One-time setup |
| 3 | **Claude Code tool permissions** | All Bash commands, file operations, and external calls used during the pipeline must be pre-approved in `.claude/settings.json`. Any unapproved tool call will pause the session for human confirmation | One-time setup per project |
| 4 | **MCP server authentication** | All MCP servers (GitHub, Vercel, Cloudflare, Neon, Resend, Upstash) must be authenticated. OAuth tokens are persistent after first login — no action needed after initial setup | One-time setup |

**What MCP servers replace vs what still needs shell credentials:**

| Credential | Needed in shell? | Why |
|---|---|---|
| `GH_TOKEN` | ❌ No | GitHub MCP handles all Git/GitHub operations |
| `VERCEL_TOKEN` | ❌ No | Vercel MCP handles deployments and project management |
| `CLOUDFLARE_API_TOKEN` / `CLOUDFLARE_ACCOUNT_ID` | ✅ Yes | `wrangler deploy` CLI still requires these as env vars |
| `DATABASE_URL` (dev / staging / production) | ✅ Yes | `prisma migrate` CLI reads `DATABASE_URL` from the environment |
| `RESEND_API_KEY` | ❌ No | Resend MCP handles email sending |
| `UPSTASH_REDIS_URL` / `UPSTASH_REDIS_TOKEN` | ❌ No | Upstash MCP handles Redis operations |

> If prerequisite 1 is not met, `wrangler deploy` and `prisma migrate` will fail with credential errors.
> If prerequisite 3 is not met, Claude Code will pause at the first unapproved tool call.
> The session is not unattended until all prerequisites are satisfied.

> Every intermediate deliverable that would normally require the master's approval
> (requirements sign-off, architecture sign-off, API spec sign-off, security verdict,
> compliance gate, production deploy) is **approved automatically on the master's behalf**
> using The Genesis standards as the decision criteria.
>
> Every such approval is recorded in the Decision Log, which is delivered in full when
> the Pilot finishes. The master must review the Decision Log before accepting the output
> — if any approval does not reflect their intent, they can roll back to that gate's
> snapshot and restart from that point.

### Pilot behaviour at every gate

1. Read the agent's output artifact
2. Apply The Genesis standards as the decision criteria
3. Decide: approve / reject / resolve ambiguity
4. Update the stage status in `agent_docs/project/pipeline.md` to `🤖 Auto-approved` — never `✅ Completed`; this signals to the owner that the approval was made automatically on their behalf, not by a human
5. Log the decision with rationale (see Decision Log format below)
6. Take a snapshot (git tag) immediately after the decision
7. Continue to the next stage

### Placeholder Convention

In Autopilot mode, the Pilot must **never block or pause** to ask for unknown configuration values. Instead:

- Use `PLACEHOLDER_<DESCRIPTION>` tokens wherever a value requires project owner input:
  - Environment URLs (e.g. `PLACEHOLDER_STAGING_URL`)
  - Database / cache connection strings (e.g. `PLACEHOLDER_DB_CONNECTION_STRING`)
  - API keys and secrets (e.g. `PLACEHOLDER_STRIPE_SECRET_KEY`)
  - Third-party credentials and account IDs (e.g. `PLACEHOLDER_CF_ACCOUNT_ID`)
  - Any other value that cannot be derived from the codebase or standards

- Track every placeholder used: file path, placeholder token, and a plain-English description of what value is needed.

- After all pipeline stages complete, deliver a **Configuration Handover** block immediately before the Decision Log (see format below).

The application will not run until all placeholders are replaced with real values. The Configuration Handover block is the project owner's checklist to do so.

### Snapshot convention

Every gate produces a git tag in the child project repository:

```
snapshot/{stage}-{HHmm}
```

| Stage | Tag example |
|---|---|
| Project created | `snapshot/project-created-1001` |
| Requirements approved | `snapshot/requirements-approved-1008` |
| Architecture approved | `snapshot/architecture-approved-1025` |
| API spec approved | `snapshot/api-spec-approved-1026` |
| Development complete | `snapshot/development-complete-1312` |
| Reviews passed | `snapshot/reviews-passed-1340` |
| Security passed | `snapshot/security-passed-1355` |
| Compliance passed | `snapshot/compliance-passed-1410` |
| Staging deployed | `snapshot/staging-deployed-1418` |
| Production approved | `snapshot/production-approved-1419` |
| Production deployed | `snapshot/production-deployed-1423` |

To restart from any snapshot:
```bash
git checkout snapshot/architecture-approved-1025
git checkout -b restart/from-architecture-1025
```

### Decision Log (delivered to master on completion)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  AUTOPILOT COMPLETE — Decision Log
  Project  : {project-name}
  Pilot    : {pilot-name}
  Started  : YYYY-MM-DD HH:mm
  Finished : YYYY-MM-DD HH:mm
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  #   Time   Gate                        Decision                      Snapshot
  ─── ─────  ──────────────────────────  ────────────────────────────  ──────────────────────────────
  1   HH:mm  Requirements ambiguity      [what was decided + reason]   snapshot/requirements-approved-HHmm
  2   HH:mm  Architecture sign-off       [approved / issues resolved]  snapshot/architecture-approved-HHmm
  3   HH:mm  API spec sign-off           [approved / changes made]     snapshot/api-spec-approved-HHmm
  4   HH:mm  Code review findings        [accepted / deferred to debt] snapshot/reviews-passed-HHmm
  5   HH:mm  Production deploy           [approved — reason]           snapshot/production-approved-HHmm

  Application : https://...
  CMS         : https://...
  Test account: {email} / {password}

  ⚠️  The approvals above were made automatically on your behalf.
  Every intermediate deliverable — requirements, architecture, API spec,
  code review, security, compliance, and production deploy — was decided
  by the Pilot using The Genesis standards. No human reviewed them during
  the run.

  Please review each gate before accepting the output as final.
  If any approval does not reflect your intent:
    1. Identify the gate number
    2. Check out its snapshot:  git checkout snapshot/{tag}
    3. Branch and restart:      git checkout -b restart/from-{gate}
    4. Re-run from that stage:  "run agent {stage-name}"

  ─────────────────────────────────────────────
  CONFIGURATION HANDOVER
  The following placeholders must be replaced before the application runs:

  #   File                            Placeholder                      Description
  ─── ──────────────────────────────  ───────────────────────────────  ──────────────────────────────────
  1   .env.production                 PLACEHOLDER_DB_CONNECTION_STRING PostgreSQL connection string
  2   .env.production                 PLACEHOLDER_JWT_SECRET           JWT signing secret (min 32 chars)
  3   wrangler.toml                   PLACEHOLDER_CF_ACCOUNT_ID        Cloudflare account ID
  4   wrangler.toml                   PLACEHOLDER_CF_DATABASE_ID       Cloudflare D1 database ID
  5   vercel.json / env               PLACEHOLDER_VERCEL_PROJECT_ID    Vercel project ID
  (list every PLACEHOLDER_* token used across all files)

  Once all values are filled in, re-run the deploy steps:
    deploy-staging    : "run agent deploy-staging"
    deploy-production : "run agent deploy-production"
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Mode 2 — Co-pilot

The Pilot intercepts every approval gate, reads the artifacts, and answers on behalf
of the master. The master is notified in real time but does not need to respond.

### Pilot behaviour at every gate

1. Receive the agent's approval request
2. Read the relevant artifacts
3. Apply The Genesis standards as the decision criteria
4. Respond with approval, rejection, or a counter-proposal
5. Notify the master of the decision in the live feed
6. Log the decision for the approval summary

### Live feed format (real-time notifications to master)

```
[HH:mm] ⏸  Gate: Architecture sign-off
         Pilot reviewed architecture.md, er-diagram.md, api-spec.yaml
         Decision: ✅ Approved — all 5 mandatory deliverables present,
         platform compat matrix complete, no blockers found.
         Continuing...

[HH:mm] ⏸  Gate: Code review — 2 Major findings
         Pilot reviewed findings.
         Decision: ✅ Accepted with conditions — majors are non-blocking;
         logged as technical debt for next sprint.
         Continuing...
```

### Approval Summary (delivered to master on completion)

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  CO-PILOT APPROVAL SUMMARY
  Project  : {project-name}
  Pilot    : {pilot-name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Gate 1 — Requirements sign-off              ✅ Approved
  Pilot reasoning: [what was reviewed and why it was approved]

  Gate 2 — Architecture sign-off              ✅ Approved
  Pilot reasoning: [what was reviewed and why it was approved]

  Gate 3 — API spec sign-off                  ✅ Approved
  Pilot reasoning: [what was reviewed and why it was approved]

  Gate 4 — Code review findings               ✅ Approved with conditions
  Pilot reasoning: [what was accepted, what was deferred, why]

  Gate 5 — Security audit                     ✅ Passed
  Pilot reasoning: [summary of findings and verdict]

  Gate 6 — Compliance sign-off                ✅ Passed
  Pilot reasoning: [summary of compliance verdict]

  Gate 7 — Production deploy                  ✅ Approved
  Pilot reasoning: [why production was cleared for go-live]

  Application : https://...
  CMS         : https://...
  Test account: {email} / {password}

  Do these approvals make sense? If not, identify the gate number
  and the Pilot will explain further or roll back.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Pipeline Gates (all modes)

These are the points where a Pilot must make or forward a decision:

| # | Gate | Trigger | Autopilot action | Co-pilot action |
|---|---|---|---|---|
| 1 | Requirements ambiguities | `STATUS: BLOCKED` from requirements-analyst | Resolve conservatively per NFR baseline | Answer on master's behalf |
| 2 | Architecture sign-off | All 5 deliverables present, awaiting approval | Approve if standards met; reject if gaps | Answer on master's behalf |
| 3 | API spec sign-off | `api-spec.yaml` produced, awaiting approval | Approve if OpenAPI valid and complete | Answer on master's behalf |
| 4 | Standards conflict | `STATUS: BLOCKED` from any agent | Resolve per conflict-resolution policy | Answer on master's behalf |
| 5 | Code review findings | Review artifact produced | Accept non-blockers; reject blockers | Answer on master's behalf |
| 6 | Security audit verdict | Security artifact produced | Accept PASS/CONDITIONAL PASS; reject FAIL | Answer on master's behalf |
| 7 | Compliance sign-off | Compliance artifact produced | Accept PASS; reject FAIL | Answer on master's behalf |
| 8 | Production deploy | Staging passed, awaiting go-live approval | Approve if all gates passed | Answer on master's behalf |

---

## What The Genesis Guarantees to Every Pilot

Every agent output artifact ends with a machine-readable status block:

```markdown
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (populated if STATUS is BLOCKED)
FAILED_REASON: (populated if STATUS is FAILED)
GATE: (gate name from the Pipeline Gates table above, if this output requires a Pilot decision)
ARTIFACTS: (comma-separated list of output file paths)
```

This allows any Pilot to parse pipeline progress without reading full artifact content.

---

## How a Pilot Invokes The Genesis Pipeline

**Option A — Claude Code CLI (recommended for getting started)**

```bash
# Create project (invoke The Genesis)
claude --print -p "create new project [table]" \
       --cwd "/path/to/-The Genesis"

# Run each pipeline stage (invoke child project)
claude --print -p "run agent requirements-analyst" \
       --cwd "/path/to/child-project"
```

**Option B — Anthropic Claude API / Agent SDK (recommended for production Pilots)**

Load `CLAUDE.md` + the relevant instruction file as system context.
Pass the stage instruction as the user message.
Parse `PILOT STATUS` block from the response to determine next action.

---

## Pilot Contract (what every Pilot must implement)

| Requirement | Description |
|---|---|
| Mode selection | Must present the three-mode prompt before starting |
| Gate handling | Must handle all gates in the Pipeline Gates table |
| Snapshotting (Autopilot) | Must create a git tag at every gate immediately after deciding |
| Decision log (Autopilot) | Must produce the Decision Log format on completion |
| Approval summary (Co-pilot) | Must produce the Approval Summary format on completion |
| Final delivery message | Must end with application URL and test credentials |
| Standards compliance | Must use The Genesis standards as the decision criteria — never invent its own |
| No Genesis modification | Must never write to The Genesis project folder — tribute only |
