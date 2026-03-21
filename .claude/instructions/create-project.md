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
| Description  | (one sentence: what it does and who it's for)                      |
| Cloud        | AWS / GCP / Alibaba Cloud / On-Premise / Vercel+Cloudflare         |
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
| Description | Not empty; must be at least one meaningful sentence |
| Cloud | Must be one of: `AWS`, `GCP`, `Alibaba Cloud`, `On-Premise`, `Vercel+Cloudflare` |
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

  Folder name  : {suggested kebab-case slug}
  Full path    : /Users/stephen.wong/Projects-AI-Agents/{slug}

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
   - 6) Multiple (specify which)
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

```
{project-slug}/
├── CLAUDE.md                          ← use template at bottom of this file
├── .claude/
│   └── settings.json                  ← copy from .claude/settings.json
├── agent_docs/
│   ├── generic/                       ← copy ALL generic files
│   │   ├── api-conventions.md
│   │   ├── nfr-baseline.md
│   │   ├── security-checklist.md
│   │   ├── deployment-standards.md
│   │   ├── deployment-{platform}.md   ← only the selected platform(s)
│   │   ├── git-workflow.md
│   │   └── agent-roles.md             ← agent pipeline contracts
│   └── project/                       ← copy from templates/, fill all placeholders
│       ├── stack.md
│       ├── architecture.md
│       ├── commands.md
│       ├── conventions.md
│       ├── deployment.md
│       ├── git-workflow.md
│       ├── pipeline.md                ← project-specific agent pipeline config
│       ├── compliance-checklist.md
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
├── src/                               ← all application source code repositories
│   └── {repo-name}/                   ← one sub-folder per repo
└── artifacts/                         ← agent pipeline outputs (timestamped)
    ├── requirements/
    ├── architecture/
    ├── development/
    ├── code-review/
    ├── ux-review/
    ├── test/
    ├── security/
    ├── devops/
    ├── retrospective/
    ├── compliance/
    └── tributes/                      ← tribute packages for The Genesis (one folder per round)
```

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

---

## Step 7 — After creation

Display this message to the user:

```
✅ Project successfully created!

📁 Folder: {full-path-to-project-folder}

Please open this folder in your IDE (VS Code: File → Open Folder).
Once opened, Claude Code will guide you through the first-session setup.

─────────────────────────────────────────
Platform deployment file included: {deployment-platform-filename}
─────────────────────────────────────────
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

## Overview

[One paragraph: what this system does and who it's for]

## Client

- **Client:** [Client Name]
- **Cloud:** [AWS / GCP / Alicloud / On-Premise / Vercel + Cloudflare]
- **Environments:** dev / staging / production

## Tech Stack

- **Backend:** [Java Spring Boot / Node.js TypeScript / Python FastAPI] + [Database]
- **Frontend:** React 18 + TypeScript + [Tailwind / MUI / Ant Design]
- **Auth:** [OAuth2 / JWT / Keycloak / Auth0]
- **CI/CD:** GitHub Actions → [ECR/ACR/Artifact Registry] → [ECS/AKS/Cloud Run]

## Parent Framework

- **Framework:** The Genesis
- **Location:** `[Genesis Path]`
- **Standards source:** All `agent_docs/generic/` files in this project are inherited from The Genesis — do not edit them directly; raise improvements via the retrospective process in The Genesis
- **Propagating improvements:** When the `retrospective-analyst` identifies SDLC improvements in this project, they are applied to The Genesis first, then propagated to all active sibling projects

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
