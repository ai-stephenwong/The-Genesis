# Trigger: Create New Project

Execute this workflow when the user says **"create new project"** or similar intent.

---

## Step 0 — Choose input mode

Ask the user:

```
How would you like to provide the project details?

  A) Quick mode — I'll give you a template to fill in and paste back (faster)
  B) Q&A mode  — you ask me one question at a time
```

- **If A:** follow **Quick Mode** below, then jump to Step 2.
- **If B:** follow **Q&A Mode** (Step 1) as normal.

---

## Quick Mode

### QM-1 — Show the template

Display this message exactly:

```
Copy the table below, fill in every field, and paste it back.
Replace the placeholder text — do not leave any field blank.
For fields with options listed, pick one of the listed values exactly.

| Field        | Value                                                              |
|--------------|--------------------------------------------------------------------|
| Client       |                                                                    |
| Project name |                                                                    |
| Folder name  | (kebab-case, e.g. my-project — this becomes the folder name)       |
| Description  | (one sentence: what it does and who it's for)                      |
| Cloud        | AWS / GCP / Alibaba Cloud / On-Premise / Vercel+Cloudflare / Vercel+Railway |
| Environments | dev / staging / production (or customise)                          |
| Backend      | Node.js+TypeScript+Express / Node.js+TypeScript+Fastify / Java+SpringBoot / Python+FastAPI |
| Database     | PostgreSQL / MySQL / MongoDB / Other: ___                          |
| Frontend     | React 18 / None                                                    |
| Styling      | Tailwind / MUI / Ant Design / Other: ___ / N/A                     |
| Auth         | JWT / Auth0 / Keycloak / Other: ___                                |
| Phase        | Discovery / Development / QA / Staging / Production                |
| Repo URL     | (GitHub/GitLab URL or "not yet created")                           |
| Conventions  | (any project-specific rules, or "none")                            |
```

Wait for the user to paste the filled table.

### QM-2 — Validate the input

Before doing anything else, validate every field against these rules:

| Field | Rule |
|---|---|
| Client | Not empty |
| Project name | Not empty |
| Folder name | Not empty; must be kebab-case (lowercase, hyphens only, no spaces or special characters) |
| Description | Not empty; must be at least one meaningful sentence |
| Cloud | Must be one of: `AWS`, `GCP`, `Alibaba Cloud`, `On-Premise`, `Vercel+Cloudflare`, `Vercel+Railway` |
| Environments | Not empty; must contain at least one environment name |
| Backend | Must be one of the listed options or a clearly specified "Other" |
| Database | Must be one of the listed options or a clearly specified "Other" |
| Frontend | Must be `React 18` or `None` |
| Styling | Required if Frontend is `React 18`; must not be blank or `N/A` in that case |
| Auth | Must be one of the listed options or a clearly specified "Other" |
| Phase | Must be one of: `Discovery`, `Development`, `QA`, `Staging`, `Production` |
| Repo URL | Must be a valid URL (starting with `https://`) or exactly `not yet created` |
| Conventions | Not empty; `none` is acceptable |

**If any field fails validation**, list all errors clearly and ask the user to correct and re-paste the full table. Do NOT proceed with partial data. Do NOT ask for corrections one by one — show all errors at once so the user can fix in one pass.

**If all fields pass**, proceed to QM-3.

### QM-3 — Show confirmation summary

Display a full confirmation summary and ask for explicit approval before creating anything:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Project summary — please confirm before creation
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  Client       : {value}
  Project name : {value}
  Description  : {value}
  Cloud        : {value}
  Environments : {value}
  Backend      : {value}
  Database     : {value}
  Frontend     : {value}
  Styling      : {value}
  Auth         : {value}
  Phase        : {value}
  Repo URL     : {value}
  Conventions  : {value}

  Folder name  : {folder name from table}
  Full path    : /Users/stephen.wong/Projects-AI-Agents/{folder name}

  Create project with these settings? [Y/n]
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**STOP. Do not create any files until the user replies Y or explicit confirmation.**
If the user replies N or requests changes, return to QM-1 with a fresh template pre-filled with their previous values.

Once confirmed, jump to **Step 4** (skip Step 1–3 of Q&A mode).

---

## Q&A Mode

## Step 1 — Ask questions ONE AT A TIME

**CRITICAL: Ask ONE question, wait for the answer, then ask the next. Never ask multiple questions in a single message.**

Ask in this exact order:

1. Who is the client?
2. What is the project name?
3. One sentence: what does this system do and who is it for?
4. Which cloud / deployment platform?
   - 1) AWS
   - 2) GCP
   - 3) Alibaba Cloud
   - 4) On-Premise
   - 5) Vercel (frontend) + Cloudflare (API/edge)
   - 6) Vercel (frontend) + Railway (API backend)
   - 7) Multiple (specify which)
5. Which environments are needed? (default: dev / staging / production — press Enter to accept)
6. Backend language and framework?
   - 1) Java + Spring Boot
   - 2) Node.js + TypeScript (Express or Fastify — which?)
   - 3) Python + FastAPI
   - 4) Other (specify)
   _(If option 2, follow up: Express or Fastify?)_
7. Database?
   - 1) PostgreSQL
   - 2) MySQL
   - 3) MongoDB
   - 4) Other (specify)
8. Frontend?
   - 1) React 18 + TypeScript (default)
   - 2) No frontend (API only)
   - 3) Other (specify)
9. _(Only if frontend selected)_ Styling library?
   - 1) Tailwind CSS
   - 2) MUI
   - 3) Ant Design
   - 4) Other
10. Auth approach?
    - 1) JWT (self-managed)
    - 2) Auth0
    - 3) Keycloak
    - 4) Other (specify)
11. Current phase? (Discovery / Development / QA / Staging / Production)
12. Git repo URL? (GitHub / GitLab / Bitbucket — or "not yet created")
13. Any project-specific conventions or constraints to note upfront? (or "none")

---

## Step 2 — Confirm folder name

Suggest a kebab-case folder name derived from the project name and ask the user to confirm or change it:

> Suggested folder name: `recruit-hk`
> Full path: `/Users/stephen.wong/Projects-AI-Agents/recruit-hk`
> Press Enter to accept, or type a different name:

---

## Step 3 — Confirm before creating

Show a full summary including the confirmed folder name and ask: **"Create project with these settings? [Y/n]"**

---

## Step 4 — Create the new project folder

- New project folder is created **parallel to this folder** (sibling directory)
- Folder name: confirmed in Step 2
- Full path: same parent directory as The Genesis folder

---

## Step 5 — Files to create in the new project

**Instruction files rule:** Copy **ALL** `.md` files from The Genesis `.claude/instructions/` into the child project's `.claude/instructions/`, **except** `create-project.md` (which is Genesis-only). Do not hard-code a list of filenames — always glob and copy so that any future instruction files are included automatically.

```
{project-slug}/
├── CLAUDE.md                          ← use template at bottom of this file
├── .claude/
│   ├── settings.json                  ← GENERATE (not copy) — see Step 5b below
│   ├── hooks/
│   │   └── check-credential-inspection.py  ← copy from .claude/hooks/
│   ├── skills/                          ← copy ALL skill folders from .claude/skills/
│   │   ├── team-pipeline/SKILL.md
│   │   ├── status/SKILL.md
│   │   ├── deploy-check/SKILL.md
│   │   └── (any future skills)
│   ├── agents/                          ← copy ALL .md files from .claude/agents/ (custom agent definitions)
│   │   ├── requirements-analyst.md
│   │   ├── solution-architect.md
│   │   ├── developer.md
│   │   ├── code-reviewer.md
│   │   ├── tester.md
│   │   ├── uiux-reviewer.md
│   │   ├── security-auditor.md
│   │   ├── compliance-officer.md
│   │   ├── devops-engineer.md
│   │   ├── retrospective-analyst.md
│   │   └── (any future agent definitions)
│   └── instructions/                    ← copy ALL .md files from .claude/instructions/ (except create-project.md)
│       ├── session-start.md
│       ├── run-pipeline.md
│       ├── run-retrospective.md
│       ├── conflict-resolution.md
│       ├── generate-compliance.md
│       └── (any future instruction files)
├── agent_docs/
│   ├── generic/                       ← copy ALL generic files (including deployment-vercel-cloudflare.md)
│   │   ├── api-conventions.md
│   │   ├── nfr-baseline.md
│   │   ├── security-checklist.md
│   │   ├── deployment-standards.md
│   │   ├── deployment-{platform}.md   ← only the selected platform(s)
│   │   ├── git-workflow.md
│   │   ├── agent-roles.md             ← agent pipeline contracts (shared header)
│   │   └── agents/                    ← individual agent role definitions (copy ALL)
│   │       ├── requirements-analyst.md
│   │       ├── uiux-reviewer.md
│   │       ├── solution-architect.md
│   │       ├── developer.md
│   │       ├── code-reviewer.md
│   │       ├── tester.md
│   │       ├── security-auditor.md
│   │       ├── compliance-officer.md
│   │       ├── devops-engineer.md
│   │       ├── deploy-environment.md
│   │       ├── deploy-production.md
│   │       └── retrospective-analyst.md
│   └── project/                       ← copy from templates/, fill all placeholders
│       ├── stack.md
│       ├── architecture.md
│       ├── commands.md
│       ├── conventions.md
│       ├── deployment.md
│       ├── git-workflow.md
│       ├── pipeline.md                ← project-specific agent pipeline config
│       ├── compliance-checklist.md
│       ├── env-contract.md            ← env var registry (solution-architect fills this in)
│       ├── requirements/              ← raw requirements files (one per topic)
│       │   └── 01-functional.md
│       └── specs/
│           ├── requirements.md        ← requirements registry (drift-checked)
│           ├── design.md
│           ├── functional-specs.md    ← template only; solution-architect fills this in
│           └── requirements-include-files/
│               └── 01-functional.md
│           ⚠️  api-spec.yaml is NOT pre-created — produced by solution-architect.
│           ⚠️  er-diagram.md is NOT pre-created — produced by solution-architect.
│               Pre-creating these files would falsely pass the architecture gate check.
├── scripts/                           ← deployment wrapper scripts (Claude calls these, never raw CLI)
│   ├── deploy-vercel.sh               ← copy from The Genesis scripts/
│   ├── deploy-wrangler.sh             ← copy from The Genesis scripts/
│   ├── db-migrate.sh                  ← copy from The Genesis scripts/
│   └── gh-push.sh                     ← copy from The Genesis scripts/
├── .secrets/                          ← gitignored — real credential files go here
│   ├── manifest.yaml.template         ← copy from The Genesis .secrets/ — fill in Doppler project name
│   ├── load-credentials.sh.template   ← copy from The Genesis .secrets/ — source before Autopilot
│   └── load-credentials.sh            ← auto-created: copy of template with {project} already filled in
├── src/                               ← all application source code repositories
│   └── {repo-name}/                   ← one sub-folder per repo
└── artifacts/                         ← agent pipeline outputs (timestamped)
    ├── requirements/
    ├── architecture/
    ├── development/
    ├── code-review/
    ├── uiux-review/
    ├── test/
    ├── security/
    ├── devops/
    ├── retrospective/
    ├── compliance/
    ├── runs/                          ← pipeline run records (pipeline-run.json per run)
    └── tributes/                      ← tribute packages for The Genesis (one folder per round)
```

---

## Step 5b — Generate `.claude/settings.json` with project permissions

**Do NOT copy The Genesis's `settings.json` — generate a fresh one for the child project.**

All file operations (Read, Write, Edit) within the project folder and all sub-folders must be pre-approved so the pipeline runs without prompting the user.

Generate `.claude/settings.json` with this structure. **No absolute paths** — all paths must be relative to the project root. Child projects are always siblings of The Genesis folder.

```json
{
  "permissions": {
    "allow": [
      "Read(./*)",
      "Write(./*)",
      "Edit(./*)",
      "Bash(*)",
      "WebSearch",
      "mcp__github__*",
      "mcp__vercel__*",
      "mcp__cloudflare-api__*",
      "mcp__neon__*",
      "mcp__resend__*",
      "mcp__upstash__*",
      "mcp__railway__*",
      "mcp__sentry__*",
      "mcp__google-tag-manager__*",
      "WebSearch",
      "WebFetch(domain:vercel.app)",
      "WebFetch(domain:vercel.com)",
      "WebFetch(domain:railway.com)",
      "WebFetch(domain:neon.tech)",
      "Bash(curl:https://*.vercel.app/*)",
      "Bash(curl:https://*.railway.app/*)",
      "Write(../-The Genesis/tributes/inbox/*)"
    ],
    "deny": [],
    "defaultMode": "bypassPermissions",
    "additionalDirectories": []
  },
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "python3 {full-project-path}/.claude/hooks/check-credential-inspection.py"
          }
        ]
      }
    ]
  }
}
```

---

## Step 5c — Add environment URLs when confirmed

When a deployment URL is confirmed (at creation or later), add to `settings.json`:
```json
"WebFetch(domain:{domain})"
```
This prevents smoke test prompts in Autopilot mode.

---

## Step 6 — Placeholder substitutions

Replace ALL of the following placeholders across every copied file:

| Placeholder | Replace with |
|---|---|
| `[Project Name]` | Project name from Q2 |
| `[Client Name]` | Client name from Q1 |
| `[AWS / GCP / Azure]` | Selected cloud platform from Q4 |
| `[AWS / GCP / Alicloud / On-Premise]` | Selected cloud platform from Q4 |
| `[Java Spring Boot / Node.js TypeScript / Python FastAPI]` | Backend from Q6 |
| `[Database]` | Database from Q7 |
| `[Tailwind / MUI / Ant Design]` | Styling from Q9 (or omit if no frontend) |
| `[OAuth2 / JWT / Keycloak / Auth0]` | Auth from Q10 |
| `[ECR/ACR/Artifact Registry]` | Correct registry for the chosen cloud |
| `[ECS/AKS/Cloud Run]` | Correct compute service for the chosen cloud |
| `[Discovery / Development / QA / Staging / Production]` | Phase from Q11 |
| `[GitHub URL]` | Repo URL from Q12 (or `TBD`) |
| `[Genesis Path]` | Full absolute path to The Genesis folder |

Also fill in the Overview paragraph in `CLAUDE.md` using the description from Q3,
and prefill any known conventions from Q13 into `agent_docs/project/conventions.md`.

In `.secrets/load-credentials.sh.template` and `.secrets/manifest.yaml.template`,
replace every `{project}` placeholder with the Doppler project name (same as the folder name).

---

## Step 7 — After creation

Display this message to the user:

```
✅ Project successfully created!

📁 Folder: {full-path-to-project-folder}

─────────────────────────────────────────
Credential setup (Doppler) — only needed when the project has a database:

  Doppler is already authenticated locally (via `doppler login`).
  The Genesis has auto-created .secrets/load-credentials.sh with the
  project name pre-filled. You only need to:

  1. Create a Doppler project named "{folder-name}" at dashboard.doppler.com
     (or run: doppler projects create {folder-name})
  2. Add DATABASE_URL to each config (dev / staging / production)

  No DOPPLER_TOKEN in ~/.zshrc is needed — local `doppler login` session is sufficient.
  DOPPLER_TOKEN is only required for CI/CD (GitHub Actions).

─────────────────────────────────────────
CLI login (one-time per machine) — for Vercel and Neon:

  Vercel and Neon MCP servers use OAuth and only connect
  in The Genesis session. In child projects, use CLI instead:

    vercel login       (opens browser, stores session locally)
    neonctl auth       (opens browser, stores session locally)

  After login, all vercel/neonctl commands work without
  tokens or env vars. This is a one-time setup.

  All other MCP servers (GitHub, Cloudflare, Resend, Upstash)
  use tokens and work in every project automatically.

─────────────────────────────────────────
Platform deployment file included: {deployment-platform-filename}
─────────────────────────────────────────

Please open this folder in your IDE (VS Code: File → Open Folder).
Once opened, Claude Code will guide you through the first-session setup.
```

---

## Step 8 — Import requirements files (optional)

Ask the user:

> Do you have existing requirements files to import? Choose an option:
>
> **A)** I'll copy the files myself — show me the destination folder
> **B)** I have a source folder — list the files for me to choose
> **C)** Skip for now

**If A:**
1. Display a clickable link to the destination folder:
   `📁 [agent_docs/project/specs/requirements-include-files/]({project-folder}/agent_docs/project/specs/requirements-include-files/)`
2. Say: "Please copy your requirements files into that folder and let me know when you're done."
3. When confirmed, for each new file:
   - Add `<!-- last-updated: YYYY-MM-DD -->` tag at the top if not already present
   - Register in `agent_docs/project/specs/requirements.md` with filename, brief description, today's date as Last Updated and Last Reviewed
4. Confirm which files were registered.

**If B:**
1. Ask: "What is the full path to the folder containing your requirements files?"
2. List all files found as a checklist — one checkbox per file
3. User selects files to import
4. Copy selected files into `{project-folder}/agent_docs/project/specs/requirements-include-files/`
5. Add `<!-- last-updated: YYYY-MM-DD -->` tag if not already present
6. Register each in `agent_docs/project/specs/requirements.md`
7. Confirm which files were imported and registered.

**If C:** Skip and finish.

---

## CLAUDE.md Template for New Projects

Use this block when writing `CLAUDE.md` into a new project:

```markdown
# Project: [Project Name]

## Always-On (every session)

At the start of every conversation, read and follow `.claude/instructions/session-start.md` before doing anything else.

## Overview

[One paragraph: what this system does and who it's for]

## Client

- **Client:** [Client Name]
- **Cloud:** [AWS / GCP / Alicloud / On-Premise / Vercel + Cloudflare / Vercel + Railway]
- **Environments:** dev / staging / production

## Tech Stack

- **Backend:** [Java Spring Boot / Node.js TypeScript / Python FastAPI] + [Database]
- **Frontend:** React 18 + TypeScript + [Tailwind / MUI / Ant Design]
- **Auth:** [OAuth2 / JWT / Keycloak / Auth0]
- **CI/CD:** GitHub Actions → [ECR/ACR/Artifact Registry] → [ECS/AKS/Cloud Run]

## Parent Framework

- **Framework:** The Genesis
- **Location:** `[Genesis Path]`
- **Standards source:** All `agent_docs/generic/` files in this project are inherited from The Genesis — **never directly edit Genesis files from this project**
- **Proposing improvements (tribute process):** When the `retrospective-analyst` identifies SDLC improvements, submit them as a **tribute** to The Genesis:
  1. Create a tribute folder: `{genesis-path}/tributes/inbox/tribute-{project-name}-{YYYYMMDD}-{HHMM}/`
  2. Write a `TRIBUTE.md` cover document describing the problem, root cause, and proposed changes
  3. Place proposed modified files in a `proposed/` subfolder within the tribute folder
  4. **Do not modify this project's own copy** of `agent_docs/generic/` files — wait for The Genesis to process and propagate
  5. The Genesis maintainer reviews, approves/rejects, applies changes, and propagates to all active projects
- **What is NOT permitted:** Directly editing, writing to, or deleting any file inside The Genesis project folder except `tributes/inbox/`. This includes `agent_docs/generic/`, `.claude/`, and all other Genesis directories. See `agent-roles.md` Orchestration Rule #8

## Documentation

### Company Standards (generic — do not edit per project)
- `agent_docs/generic/api-conventions.md` — REST conventions, error format, HTTP status codes
- `agent_docs/generic/nfr-baseline.md` — performance, availability, and security baselines
- `agent_docs/generic/security-checklist.md` — pre-release security checklist
- `agent_docs/generic/deployment-standards.md` — deployment pipeline and environment rules
- `agent_docs/generic/deployment-[platform].md` — [platform] specific deployment best practices
- `agent_docs/generic/git-workflow.md` — branching, commit, and PR conventions
- `agent_docs/generic/agent-roles.md` — agent pipeline roles, I/O contracts, separation-of-duty rules
- `agent_docs/generic/uiux-standards.md` — UI/UX design principles, accessibility, responsive design, sensitive data display rules
- `agent_docs/generic/agents/orchestrator.md` — Orchestrator role, operating modes, gate handling, decision log

### Project-Specific Docs (fill in per project)
- `agent_docs/project/stack.md` — exact versions and dependencies
- `agent_docs/project/architecture.md` — system design and data flow
- `agent_docs/project/commands.md` — build, test, and deploy commands
- `agent_docs/project/conventions.md` — project-specific rules and overrides
- `agent_docs/project/deployment.md` — environment URLs, service names, and runbook
- `agent_docs/project/git-workflow.md` — repo URL, reviewers, and branch protection settings
- `agent_docs/project/pipeline.md` — active agents, pipeline stages, paths, and pipeline status
- `agent_docs/project/specs/requirements.md` — requirements file registry (drift-checked each session)
- `agent_docs/project/specs/design.md` — UI/UX design references

## Project Status

- **Phase:** [Discovery / Development / QA / Staging / Production]
- **Sprint:** [current sprint or milestone]
- **Repo:** [GitHub URL]
- **CI/CD:** [GitHub Actions URL]
- **Staging URL:** TBD
- **Production URL:** TBD
```
