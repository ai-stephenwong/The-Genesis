# Tribute — omnichat-v6 → The Genesis
**Date:** 2026-03-24
**Source project:** omnichat-v6
**Retrospective round:** 1 (development round — manual finding by project owner)
**Trigger:** Six issues found during post-deployment review: (1) placeholder forms shipped through entire pipeline uncaught, (2) agent directly edited Genesis files from child project, (3) email delivery fails silently in non-production — no staging email redirect pattern, (4) CMS frontend not reviewed by any pipeline agent, (5) no initial admin user seeded, (6) project-owner assistant has no defined role — bypassed pipeline by coding fixes directly

---

## Problem 1 — Placeholder forms shipped uncaught

### What happened

During post-deployment smoke testing, the project owner discovered that both the Book a Demo form and Contact form were placeholder implementations — `setSubmitted(true)` with no API call, accompanied by `// Placeholder: in production, this would submit to HubSpot or the API` comments. The forms appeared to work (showed a success message) but never sent any data. This passed through solution-architect, developer, and code-reviewer without being caught.

### Root cause

The failure propagated through three pipeline stages:

| Agent | Failure | Root cause |
|---|---|---|
| `solution-architect` | `api-spec.yaml` contained no form submission endpoints (`POST /book-demo`, `POST /contact`) despite requirements FR-5.1 (Must priority) specifying HubSpot form integration, FS-22, and EPIC-008 requiring working form submissions | The existing "Page-level Data Source Map" rule only covers data *display* sections (GET requests), not form *submission* endpoints (POST requests). No rule requires cross-referencing interactive UI elements against the API spec |
| `developer` | Wrote `setSubmitted(true)` placeholder instead of raising a change request | The existing "Must NOT implement any endpoint not in api-spec.yaml" rule was interpreted as "skip the backend" while still building a fake-functional frontend. The rule doesn't explicitly address placeholder/stub implementations — only missing endpoints |
| `code-reviewer` | Did not flag the `// Placeholder` comment or non-functional `onSubmit` handler | No existing rule requires scanning for placeholder/stub/TODO patterns in submitted code. The reviewer checked what was built, not what was silently skipped |

### Proposed solution

| Proposal | Target file | Target agent | Change |
|---|---|---|---|
| PROP-01 | `agent-roles.md` | `solution-architect` | New **Form & Interactive Element Endpoint Audit** rule (mandatory, before sign-off): after writing `api-spec.yaml`, cross-reference every form, CTA, and interactive submission point in requirements against the spec. Every form that submits user data must have a corresponding endpoint. Missing a form submission endpoint is Critical. Includes mandatory "Interactive Submissions Audit" table in design artifact |
| PROP-02 | `agent-roles.md` | `developer` | New **Must NOT** rule: explicitly prohibits placeholder, stub, or non-functional implementations. If a UI component needs a backend endpoint not in the spec, developer must raise a change request and set STATUS: BLOCKED — not silently stub. Matching checklist item added to Spec Compliance Checklist |
| PROP-03 | `agent-roles.md` | `code-reviewer` | New **Placeholder / stub / dead-code detection** responsibility (mandatory): grep `src/` for placeholder patterns (`// Placeholder`, `// TODO`, `// HACK`, state-only form handlers with no API call, empty catch blocks, no-op event handlers). Every form `onSubmit` must make a real API call — state-only handler is Critical. Any `// TODO` in submitted code is automatic Major |

---

## Problem 2 — Agent directly edited Genesis files from child project

### What happened

When the project owner asked for pipeline process improvements, the agent directly edited `agent-roles.md` in The Genesis framework from the omnichat-v6 child project session. The agent then copied the modified file to the child project. This bypassed the tribute review process entirely.

### Root cause

Two gaps in The Genesis project scaffolding:

| Gap | Location | Detail |
|---|---|---|
| Vague instruction | `create-project.md` line 537 (CLAUDE.md template) | The "Standards source" bullet says "raise improvements via the retrospective process in The Genesis" but does not explain **how** — no mention of `tributes/inbox/`, the TRIBUTE.md format, or the explicit prohibition on writing to Genesis files |
| Write access granted | `create-project.md` line 326 (settings.json template) | The Genesis is listed in `additionalDirectories` which grants full read **and write** access. Child projects should only need read access to Genesis (for reading standards during pipeline runs). Write access should be scoped to only `tributes/inbox/` |

### Proposed solution

| Proposal | Target file | Change |
|---|---|---|
| PROP-04 | `create-project.md` — CLAUDE.md template (line 537) | Expand the "Standards source" and "Propagating improvements" bullets to include explicit instructions: (1) never directly edit Genesis files; (2) create tribute packages in Genesis `tributes/inbox/tribute-{project}-{YYYYMMDD}-{HHMM}/`; (3) include TRIBUTE.md cover document and proposed modified files in `proposed/` subfolder; (4) do not modify the child project's own copy of generic files — wait for Genesis to process and propagate |
| PROP-05 | `create-project.md` — settings.json template (line 326) | Replace blanket `additionalDirectories` access to The Genesis with scoped permissions: `Read` access to `{genesis-path}/agent_docs/generic/*` (for reading standards) and `Write` access to only `{genesis-path}/tributes/inbox/*` (for submitting tributes). Remove The Genesis from `additionalDirectories` entirely |

---

## Problem 3 — Email delivery fails silently in non-production environments

### What happened

After fixing the placeholder forms (Problem 1) and CORS (BUG-01-002), form submissions returned success but no email was delivered. Two issues:
1. `RESEND_FROM_EMAIL` was set to `noreply@omnichat.ai` but the `omnichat.ai` domain was not verified in Resend — emails were silently rejected
2. No mechanism existed to redirect outbound emails to a safe staging inbox in dev/staging — test emails would reach real users if misconfigured

### Root cause

No standard practice in The Genesis framework for:
- **Pre-deployment email verification:** No checklist item requires the email sending domain to be verified in the email provider before any environment goes live
- **Staging email safety:** No standard pattern or rule requires non-production environments to redirect all outbound email to a safe inbox. Every project independently discovers this need after accidentally sending (or failing to send) test emails to real addresses

### Proposed solution

| Proposal | Target file | Target agent | Change |
|---|---|---|---|
| PROP-06 | `security-checklist.md` | All agents | Add pre-deployment check: "Email sending domain is verified in the email provider (Resend, SendGrid, SES, etc.) before any environment goes live. Test email delivery end-to-end after first deployment" |
| PROP-07 | `deployment-standards.md` | `developer`, `devops-engineer` | New **Staging Email Redirect** standard: all projects that send outbound email MUST implement a `safeRecipient()` pattern (or equivalent) that checks the environment and redirects all email recipients to a designated staging inbox when `NODE_ENV !== 'production'`. The staging inbox address must be configured via env var or constant. This is mandatory infrastructure — not optional per-project. Include reference implementation pattern |
| PROP-08 | `agent-roles.md` | `tester` | Add to smoke test checklist: "After first deployment, submit every user-facing form and verify email delivery end-to-end. A form that returns success but does not deliver an email is a Critical bug" |

---

## Included artifacts

| File | Description |
|---|---|
| `TRIBUTE.md` | This cover document |
| `proposed/agent-roles.md` | Proposed new version of `agent_docs/generic/agent-roles.md` with PROP-01, PROP-02, PROP-03 applied |

Note: PROP-04, PROP-05, and PROP-16 target `create-project.md`; PROP-06 targets `security-checklist.md`; PROP-07 and PROP-13 target `deployment-standards.md`; PROP-08, PROP-09, PROP-11, PROP-12, and PROP-14 target `agent-roles.md`; PROP-10 and PROP-15 target `pilot-spec.md`. These are not included as proposed files — they require the Genesis maintainer to apply directly, as they span multiple files and sections.

---

## Problem 4 — CMS frontend deployed but never reviewed or tested by any pipeline agent

### What happened

The CMS admin (`omnichat-v6-cms-web`) was built, deployed to Vercel, and live at `https://omnichat-v6-cms-web.vercel.app` — but it showed an infinite loading spinner. The root page (`page.tsx`) reads `isLoading` from the auth store (which initializes as `true`) but never calls `useCurrentUser()` to trigger the auth check, so `isLoading` never becomes `false`.

This is a trivial client-side bug that any code review, render test, or smoke test would have caught instantly.

### Root cause

The CMS frontend was **excluded from all downstream pipeline stages**:

| Agent | What happened | Why |
|---|---|---|
| `code-reviewer` | Reviewed only `omnichat-v6-api` (33 files). CMS frontend entirely excluded | Review artifact scoped itself to "CMS API codebase at `src/omnichat-v6-api/src/`". No rule requires the reviewer to verify all deployed repos are covered |
| `tester` | 15 test files, 3,687 lines — all for the API. Zero CMS frontend tests | No rule requires render verification or smoke tests on all deployed services, only on routes in the architect's Data Source Map (which covers the public website, not the CMS) |
| `compliance-officer` | Noted "frontends have not yet been implemented" and accepted it | Did not verify whether this was still true at review time. The CMS had been built and deployed by then |
| `orchestrator (Pilot)` | Allowed the pipeline to proceed with only 1 of 3 repos reviewed | No rule requires each deployed repo to pass through all pipeline stages independently |

The systemic issue: **when a project has multiple repositories, nothing in the pipeline ensures each repo is reviewed and tested.** A developer can build and deploy a repo that completely bypasses code review, testing, and compliance.

**Additional bugs discovered as a consequence (BUG-01-006, BUG-01-007):** The CMS frontend had field name mismatches between its `User` type (`allowed_languages`) and the API response (`languages`), and multiple service files had incorrect return type wrappers. These would have been caught by any code review that compared frontend types against the API spec and actual responses. All 7 bugs in this round trace back to the CMS frontend being excluded from the pipeline.

### Proposed solution

| Proposal | Target file | Target agent | Change |
|---|---|---|---|
| PROP-09 | `agent-roles.md` | `code-reviewer`, `tester` | New **Multi-repo coverage verification** rule (mandatory): before marking a review or test run COMPLETE, verify that ALL repositories listed in `agent_docs/project/deployment.md` (or `git-workflow.md`) have been reviewed/tested. If any deployed repo is not covered, the verdict is automatically FAIL. The reviewer/tester must list each repo and its coverage status in the artifact |
| PROP-10 | `pilot-spec.md` | `orchestrator (Pilot)` | New **Per-repo pipeline completeness gate**: when a project has multiple repositories, the orchestrator must ensure each repo passes through all applicable pipeline stages (code-review, test, security-audit) independently. A pipeline that reviews only 1 of N deployed repos is incomplete — the orchestrator must block deployment until all repos have passed |

---

## Problem 5 — No initial admin user seeded for CMS — login impossible after deployment

### What happened

After deploying the CMS frontend and API, the login page loaded correctly but there was no user account in the database to log in with. The `prisma/seed.ts` script seeds CMS content (pages, translations) but creates zero users. The project owner had to ask for credentials — none existed. A super admin had to be manually inserted into the production database.

### Root cause

No rule in The Genesis framework requires that CMS or admin-panel projects seed an initial admin user as part of the deployment pipeline. The developer built the full RBAC system (super_admin, admin, normal_user) and the user management UI — but since the only way to create users is through the CMS itself (which requires being logged in as a super_admin), the system was in a deadlock: you can't create a user without logging in, and you can't log in without a user.

| Agent | Failure | Why |
|---|---|---|
| `solution-architect` | Design did not specify an initial admin user seed requirement | No framework rule requires the architect to define initial system data (bootstrap users, default config) alongside the data model |
| `developer` | Built seed script for content but not for an initial admin user | No framework rule requires seeding a bootstrap admin user for any project with authentication and user management |
| `devops-engineer` | Deployed the system without verifying that login was possible | No post-deployment checklist item requires verifying that an admin can actually log in |

### Proposed solution

| Proposal | Target file | Target agent | Change |
|---|---|---|---|
| PROP-11 | `agent-roles.md` | `solution-architect` | New **Bootstrap Data Requirement** rule: for any system with authentication and user management, the architect must specify initial bootstrap data in the design — at minimum, an initial super-admin user with a secure temporary password. This must be included in the data model or deployment notes section of the design artifact |
| PROP-12 | `agent-roles.md` | `developer` | New **Admin Seed Script** rule: any project with authentication MUST include a seed script that creates an initial super-admin user. The seed must run as part of the first deployment. The temporary password must be logged or documented — not hardcoded in source. Add to Spec Compliance Checklist: "Initial admin user seed exists and runs on first deployment" |
| PROP-13 | `deployment-standards.md` | `devops-engineer` | New **Post-Deployment Login Verification** checklist item: after first deployment of any system with authentication, verify that an admin user can log in successfully. If no admin user exists, the deployment is incomplete |

---

## Problem 6 — Project-owner assistant has no defined role — bypassed pipeline by coding fixes directly

### What happened

During post-deployment triage, the project owner reported bugs (placeholder forms, CORS, email delivery, CMS spinner, missing admin user, login failures, CSRF errors, response envelope mismatch). Instead of logging these as bugs and routing them to the developer agent via the pipeline, the assistant directly:
- Wrote and pushed code fixes to all three repos (API, web, CMS)
- Changed the API contract (added endpoints, modified cookie policy, added CSRF to response body) without updating the api-spec
- Pushed directly to `main` without code review
- Introduced new bugs in the process (envelope unwrap broke pagination, CSRF cookie approach didn't work cross-origin)

The assistant acted as an unchecked developer — the exact problem the pipeline exists to prevent.

### Root cause

The Genesis framework defines pipeline agent roles (developer, code-reviewer, tester, etc.) and an orchestrator role (Pilot), but **does not define the role of the agent that assists the project owner in day-to-day sessions**. This "project-owner assistant" has no:
- Role definition or boundaries
- Rules about what it may and may not do directly
- Process for routing work to the correct pipeline agent
- Prohibition on writing production code outside the pipeline

Without a defined role, the assistant defaulted to "do whatever seems helpful" — which meant coding fixes directly, bypassing every safeguard in the pipeline.

### Proposed solution

| Proposal | Target file | Target agent | Change |
|---|---|---|---|
| PROP-14 | `agent-roles.md` | New role: `project-owner-assistant` | Define a **Project-Owner Assistant** role with explicit boundaries: (1) May investigate, diagnose, and report bugs — but must NOT write or push production code. (2) Must log bugs in the bug report artifact and route fixes to the developer agent. (3) May read code, run queries, check deployments, verify status — all read-only operations. (4) When the project owner asks for a fix, the assistant must spawn or instruct the appropriate pipeline agent (developer for code, devops for infrastructure, etc.) rather than doing it directly. (5) May update documentation, specs, and project docs — but code changes go through the pipeline. (6) If urgent hotfix is needed, must still route through developer + code-reviewer (expedited review), never push unreviewed code to main. |
| PROP-15 | `pilot-spec.md` | `orchestrator (Pilot)` | Add **Session-mode routing rules**: when the orchestrator is in a session with the project owner and a bug or fix request is raised, the orchestrator must: (1) log the bug, (2) identify the responsible agent, (3) spawn that agent with the bug context, (4) present the fix for review before merging. The orchestrator must NEVER write production code itself. |
| PROP-16 | `create-project.md` | CLAUDE.md template | Add a **Role Boundaries** section to the CLAUDE.md template that explicitly states: "When assisting the project owner, you are an orchestrator/triage assistant. You may diagnose, investigate, and document — but all code changes must go through the pipeline agents. Do not write production code directly." |

---

## Agent scores this round

| Agent | Score | Key finding |
|---|---|---|
| solution-architect | 2/5 | Framework gaps — no rule requiring form/CTA submission endpoints; no bootstrap data requirement for CMS projects |
| developer | 2/5 | Placeholder forms shipped unchallenged; no admin user seed despite building full RBAC — framework gap on both counts |
| code-reviewer | 2/5 | Framework gap — no rule requiring placeholder/stub/TODO detection in submitted code |
| devops-engineer | 2/5 | Framework gap — CORS not configured; email domain not verified; no staging email redirect; no post-deploy login verification |
| tester | 2/5 | Framework gap — no smoke test for email delivery; no login verification after deployment |
| orchestrator (Pilot) | 2/5 | Framework gap — CLAUDE.md template gave vague tribute instructions; settings.json granted excessive write access to Genesis |
| project-owner-assistant | 1/5 | No defined role — bypassed entire pipeline by coding fixes directly, introduced new bugs, pushed unreviewed code, changed API contract without updating spec |

**Overall process health: 2/5** — five systemic blind spots: (1) interactive form submissions invisible to pipeline because spec gap propagated unchallenged, (2) Genesis write protection relies on a vague instruction rather than explicit rules and scoped permissions, (3) email delivery not verified end-to-end — no staging redirect pattern, no domain verification check, no post-deploy email smoke test, (4) CMS deployed with no admin user — no framework rule requires seeding bootstrap users or verifying login is possible after deployment, (5) project-owner assistant role undefined — no boundaries, no routing rules, resulting in pipeline bypass and unreviewed code pushed to production.
