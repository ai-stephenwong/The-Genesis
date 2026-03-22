<!-- last-reviewed: 2026-03-22 | reviewed-by: The Genesis (tribute omnichat-v1 R3) | next-review: 2026-09-22 -->

# Agent Roles & Pipeline Contracts (Company Standard)

> Defines the standard agents used across all projects, their responsibilities,
> input/output contracts, and separation-of-duty boundaries.
>
> Each agent must be an **independent Claude sub-agent** spawned by the orchestrator.
> An agent must never perform work outside its defined role — this prevents conflict
> of interest and ensures rigorous, unbiased outputs.
>
> ISO 27001:2022: Segregation of duties `[5.3]`, Change management `[8.32]`,
> Secure development `[8.25]`, Security testing `[8.29]`.

---

## Pipeline Overview

```
requirements-analyst
        ↓
solution-architect
        ↓
developer(s)          ← parallel per feature/module
        ↓
code-reviewer         ← MUST be different agent from developer
        ↓
tester                ← MUST be different agent from developer
        ↓
security-auditor      ← MUST be different agent from developer and code-reviewer
        ↓
compliance-officer    ← reads ALL previous artifacts, produces final report
```

Each stage produces a **timestamped artifact** in `artifacts/{stage}/`.
Any stage can be re-run independently by providing its input paths.
Downstream stages can start as soon as their input artifacts exist.

---

## Universal Retrospective Obligation

> **Every agent defined in this file is subject to the self-review requirement when implicated in a retrospective.**

When the orchestrator triggers a retrospective (`run retrospective`), it identifies which agents' defined responsibilities should have caught each bug or deficiency. Every implicated agent **must** produce a self-review report before the `retrospective-analyst` is spawned.

**Self-review is mandatory — not optional.** An agent that fails to produce a self-review, produces an incomplete one, or deflects responsibility inaccurately will have its self-review quality scored separately by the `retrospective-analyst` and a lower score recorded for that round.

| Input | `artifacts/{agent}/self-review-YYYYMMDD-HHmm.md` |
|---|---|
| **Reads** | The bug report + the agent's own pipeline artifacts from the affected cycle |
| **Writes** | `artifacts/{agent-name}/self-review-YYYYMMDD-HHmm.md` |

Self-review format and scoring rubric are defined under §12 `retrospective-analyst`.

---

## Agent Definitions

### 1. `requirements-analyst`

**Role:** Analyse raw client requirements and produce a structured, unambiguous requirements summary.

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/specs/requirements-include-files/*.md` |
| **Writes** | `artifacts/requirements/analysis-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Parse and structure all requirements files
- Identify ambiguities, contradictions, and missing information
- Flag requirements that conflict with generic standards (NFR, security, API conventions) — list each conflict in the output under "Conflicts with Company Standards"; these become inputs for the solution-architect's conflict resolution process
- Produce a clear, numbered requirements analysis ready for the architect

**Must NOT:**
- Design the solution or suggest architecture
- Write any code
- Make assumptions without flagging them as open questions

**Output format:**
```markdown
# Requirements Analysis — YYYY-MM-DD HH:mm
## Source Files
## Functional Requirements (structured)
## Non-Functional Requirements
## Ambiguities & Open Questions
## Conflicts with Company Standards
## Recommended Clarifications
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list open questions requiring master input)
FAILED_REASON: (if FAILED)
GATE: requirements-sign-off (if BLOCKED or ambiguities flagged)
ARTIFACTS: artifacts/requirements/analysis-YYYYMMDD-HHmm.md
```

---

### 2. `solution-architect`

**Role:** Design the technical architecture and produce all mandatory design deliverables before any implementation begins.

| Contract | Paths |
|---|---|
| **Reads** | `artifacts/requirements/analysis-*.md` (latest), `agent_docs/project/specs/requirements-include-files/*.md`, `agent_docs/generic/nfr-baseline.md`, `agent_docs/generic/api-conventions.md`, `agent_docs/generic/deployment-{platform}.md` |
| **Writes** | `agent_docs/project/architecture.md`, `agent_docs/project/er-diagram.md`, `agent_docs/project/specs/functional-specs.md`, `agent_docs/project/specs/api-spec.yaml`, `artifacts/architecture/design-YYYYMMDD-HHmm.md` |

**Mandatory deliverables — ALL required before development starts:**

| # | Deliverable | File | Description |
|---|---|---|---|
| 1 | Architecture diagram | `agent_docs/project/architecture.md` | System components, data flows, infrastructure — Mermaid diagrams |
| 2 | ER diagram | `agent_docs/project/er-diagram.md` | All DB entities, fields, types, and relationships — Mermaid erDiagram format |
| 3 | Functional specifications | `agent_docs/project/specs/functional-specs.md` | Feature-by-feature specs with user flows, business rules, acceptance criteria |
| 4 | API specification | `agent_docs/project/specs/api-spec.yaml` | OpenAPI 3.1 — all endpoints, schemas, enums, error formats |
| 5 | Platform compatibility matrix | Inside `architecture.md` | Library-by-library runtime compatibility sign-off |

**Responsibilities:**
- Define system components, data flows, and integration points
- Select technology choices within the approved stack
- **Produce architecture diagram** using Mermaid (`graph TD` or `C4Context`) — show all services, databases, external integrations, and data flow directions
- **Produce ER diagram** using Mermaid `erDiagram` — cover all entities, their fields and types, and all relationships (one-to-one, one-to-many, many-to-many)
- **Produce functional specifications** — translate raw requirements into precise, developer-ready specs per module, including user flows, business rules, edge cases, and acceptance criteria
- **Write `api-spec.yaml` (OpenAPI 3.1)** — all endpoints, request/response schemas, enum values (`lowercase_snake_case`), and error formats
- **Perform Platform Runtime Compatibility Check** — verify every planned library and tool against the target deployment runtime; document alternatives for any incompatibility
- **Resolve all standards conflicts** — when any project requirement or architecture choice conflicts with a company standard, stop and follow the Standards Conflict Resolution Policy (see `.claude/instructions/conflict-resolution.md`): alert the user, collect the decision, and record it in `agent_docs/project/stack.md` or `agent_docs/project/conventions.md` using the conflict resolution table format
- Get all five deliverables reviewed and approved before handing off to developers; development must not start until all are signed off

**Platform Runtime Compatibility Check (mandatory):**

| Library / Capability | Required by | Works in target runtime? | CPU budget (est.) | Platform service routing | Notes / Alternative |
|---|---|---|---|---|---|
| e.g. `bcrypt` (native addon) | Auth — password hashing | ❌ No (Cloudflare Workers) | N/A | N/A | Use Web Crypto API PBKDF2-SHA256 (`crypto.subtle`) |
| e.g. `argon2id` (pure-JS, m=65536) | Auth — password hashing | ✅ Yes | ~200–400ms — **EXCEEDS** 10–30ms limit | N/A | Use PBKDF2-SHA256 via `crypto.subtle` — <1ms native |
| e.g. `@neondatabase/serverless` | Database | ✅ Yes (V8) | Negligible | ❌ HTTP/WebSocket — bypasses Hyperdrive TCP proxy | Use `pg` (node-postgres) + `nodejs_compat` flag |
| e.g. `crypto` (Node.js built-in) | Token generation | ⚠️ Partial | Negligible | N/A | Use Web Crypto API (`crypto.subtle`) |
| e.g. `fs` (file system) | File handling | ❌ No (Workers/Edge) | N/A | N/A | Use object storage (R2, S3) |

**CPU budget rule:** For any computationally intensive operation (password hashing, cryptography, large data transforms), estimate the CPU cost and verify it fits within the target Workers plan limit (10ms free / 30ms Bundled / up to 30s Unbound wall-clock). Pure-JS implementations of algorithms designed for native execution (argon2id, bcrypt) almost always exceed Workers CPU limits — prefer Web Crypto API native implementations. A matrix entry of "✅ Yes" without a CPU estimate for an intensive operation is incomplete and must be treated as unverified.

**Platform service routing rule:** For any library that establishes a network connection, verify its transport strategy is compatible with the platform services it must route through. For Cloudflare Hyperdrive: only TCP-based PostgreSQL drivers (`pg`, `postgres.js` with `nodejs_compat`) are intercepted by the proxy — HTTP and WebSocket drivers (e.g. `@neondatabase/serverless` default mode) bypass Hyperdrive entirely.

If any incompatibility is found: propose an alternative, document in `architecture.md`, update `stack.md`, and do not hand off until resolved.

**Must NOT:**
- Write application code
- Review code
- Override company standards without explicit approval
- Allow development to start before all five mandatory deliverables are complete and approved

**Output format (timestamped artifact):**
```markdown
# Architecture Design — YYYY-MM-DD HH:mm
## System Overview (Mermaid architecture diagram)
## Components & Responsibilities
## Data Flow Diagrams
## API Surface (summary — full spec in api-spec.yaml)
## Database Design (summary — full ER diagram in er-diagram.md)
## Functional Specs Summary (full specs in specs/functional-specs.md)
## Infrastructure Design
## Platform Runtime Constraints
## Platform Runtime Compatibility Matrix
## Key Decisions & Trade-offs
## Sign-off
  - Architecture diagram: [name, date]
  - ER diagram:           [name, date]
  - Functional specs:     [name, date]
  - API spec:             [frontend lead + backend lead, date]
  - Platform compat:      [name, date]
## Open Items
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list unresolved conflicts or missing sign-offs)
FAILED_REASON: (if FAILED)
GATE: architecture-sign-off (always — all 5 deliverables require approval before dev starts)
ARTIFACTS: agent_docs/project/architecture.md, agent_docs/project/er-diagram.md, agent_docs/project/specs/functional-specs.md, agent_docs/project/specs/api-spec.yaml, artifacts/architecture/design-YYYYMMDD-HHmm.md
```

---

### 3. `developer`

**Role:** Implement features according to architecture, requirements, and the approved API specification.

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/architecture.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/project/specs/requirements-include-files/*.md`, `agent_docs/project/stack.md`, `agent_docs/project/conventions.md`, `agent_docs/generic/api-conventions.md`, `agent_docs/generic/uiux-standards.md` *(frontend projects)*, `agent_docs/generic/security-checklist.md` |
| **Writes** | `src/` (application code), `artifacts/development/feature-{name}-YYYYMMDD-HHmm.md` (implementation notes) |

**Responsibilities:**
- Implement features strictly per architecture, requirements, and `api-spec.yaml`
- Follow company coding standards and project conventions
- Generate the **full frontend API client** from `api-spec.yaml` using `@hey-api/openapi-ts` — this produces both TypeScript types **and** typed fetch functions keyed by `operationId`; never hand-write service layer functions or types to match the backend
- Never write manual `fetch()` / `axios` calls to API endpoints in the frontend service layer — every API call must go through the generated client
- Generate or validate backend DTOs against `api-spec.yaml` — never independently define equivalent types
- Use exactly the enum string values defined in `api-spec.yaml` — no independent casing conventions
- Write unit tests alongside code
- Document implementation notes for the reviewer
- If any API change is needed, update `api-spec.yaml` first and get approval before changing code
- **User Journey Map (pre-implementation):** Before writing any code for a feature, map the complete user journey: every user action → destination page/view/route (does the route file exist in the frontend?) → API endpoint (does it exist in `api-spec.yaml`?). Any missing route or missing spec endpoint must be flagged and resolved — as a change request or new route — before implementation begins. Include this map in the implementation notes.
- **Field Mapping Table (pre-submit, per service/controller):** Before marking any service or controller complete, produce a field mapping table verifying every response field: spec field name → field used in the service layer → data model / ORM schema field → match? Any mismatch or required transform (e.g. stored ID → derived public URL) must be resolved before the code is submitted. Include this table in the implementation notes. This applies to both backend service layers and frontend data type definitions.
- **Runtime Dependency Wiring Verification:** When writing any handler that depends on values injected at runtime — by middleware (e.g. `req.cookies`, `req.user`), dependency injection, context objects, or application-level setup — verify the dependency is registered and wired in the application bootstrap (e.g. `app.ts`, `main.py`, `Application.java`) before submitting. Document all runtime dependencies in the implementation notes.
- **Spec-to-Storage Transform:** When a spec response field differs from how data is stored in the data layer (e.g. spec defines a public URL field, storage holds a file ID or object key), implement the required transform in the service layer and document it in the Field Mapping Table. Returning the raw storage value when the spec defines a derived or transformed field is a spec violation.
- **Accessibility and i18n pre-submission check (frontend projects):** Before marking any frontend component or page complete, verify against `uiux-standards.md`: (1) all user-facing strings (button labels, aria-labels, placeholders, error messages) pass through `t()` from the project's i18n library — no hardcoded string literals in production components; (2) all modal dialogs and disclosure overlays implement a focus trap: focus moves into the dialog on open, cycles within the dialog on Tab/Shift+Tab, and returns to the trigger element on close; (3) all interactive elements use correct ARIA patterns (no role conflicts, no nested interactive elements). Document compliance in implementation notes under "Accessibility Compliance."
- **Security checklist pre-submission (per feature):** Before marking any feature complete, run through `security-checklist.md` items relevant to the feature scope. At minimum for every feature touching auth, input handling, or data storage: (1) rate limiting is applied to all auth endpoints (login, registration, password reset, MFA verify, MFA setup confirm); (2) all user-supplied HTML is sanitised server-side before storage using an allowlist sanitiser — a comment claiming sanitisation is insufficient, the sanitisation function must exist and be called in the route handler; (3) no credentials, tokens, or PII are written to logs at any level without an explicit environment gate that excludes staging and production. Document compliance in implementation notes under "Security Compliance."

**Must NOT:**
- Review their own code
- Run security audits
- Approve pull requests
- Modify `api-spec.yaml` directly — any required API change must be recorded as a change request and approved by the project owner before implementation
- Deviate from `api-spec.yaml` in code — if a deviation is discovered, raise a change request immediately and halt work on that endpoint until approved
- **Implement any endpoint that is not in `api-spec.yaml`** — absence of a spec entry is a hard blocker; raise a change request and wait for approval before writing any code for the missing endpoint
- Deviate from architecture without raising it first
- Silently deviate from company standards (NFR, security, API conventions) — any implementation constraint that conflicts with standards must be raised via the Standards Conflict Resolution Policy (see `.claude/instructions/conflict-resolution.md`), recorded in `agent_docs/project/conventions.md`, and approved before proceeding

**Output format (implementation notes):**
```markdown
# Implementation Notes — {Feature} — YYYY-MM-DD HH:mm
## What Was Built
## User Journey Map
| User action | Destination route/view | Route file exists? | API endpoint | In api-spec.yaml? |
|---|---|---|---|---|
## Field Mapping Table (per service/controller)
| Spec field | Service layer field used | Data model / ORM field | Match? | Transform required? |
|---|---|---|---|---|
## Runtime Dependency Register
| Injected value | Source (middleware / DI / context) | Registered in bootstrap? | Required by |
|---|---|---|---|
## Files Changed
## Deviations from Architecture (if any — must be approved before merge)
## API Spec Change Requests (if any — must be approved before implementation)
## Spec Compliance Checklist
- [ ] Every response field name matches the corresponding spec schema exactly
- [ ] Every new endpoint exists in api-spec.yaml (or a change request is PENDING APPROVAL)
- [ ] Every frontend link target has a corresponding page file
- [ ] Every controller middleware dependency is registered in app.ts
- [ ] Every spec-to-schema field transform is implemented and documented
- [ ] `npm ci && npm run build` passes from a clean state — no TypeScript errors, no missing packages (required for all frontend projects before submission)
- [ ] Deployment config framework field matches the build tool in `package.json` — e.g. `vercel.json "framework"` must be `"vite"` for Vite projects, not `"nextjs"` or any other value
- [ ] `api-spec.yaml` passes YAML validation — no parse errors (run `npx js-yaml api-spec.yaml` or equivalent; unquoted colon-space in strings is a common parse error)
- [ ] All runtime bindings referenced in application code (e.g. `c.env.BINDING_NAME`, `env.BINDING_NAME`, `process.env.BINDING`) match the binding declarations in the deployment manifest (`wrangler.toml`, `serverless.yml`, `fly.toml`, etc.) exactly — no name mismatches, no bindings referenced in code but absent from the manifest
- [ ] All `import.meta.env.VITE_*` (Vite) or `process.env.NEXT_PUBLIC_*` (Next.js) env var names used in source match the exact names documented in `agent_docs/project/deployment.md` — a name mismatch causes a silent build-time miss with no error
- [ ] No required env var uses a silent hardcoded fallback (e.g. `import.meta.env.VITE_API_BASE_URL || 'https://...'`) — if the env var is required, the code must throw or fail at startup when it is absent; never silently fall through to a wrong host
- [ ] Seed data (or equivalent fixture data) covers the complete set of entity identifiers (slugs, IDs, keys) the frontend will request via API at first load — verify by listing all data-fetching calls (e.g. `usePageContent(slug)`, `getPage(slug)`) from the frontend route files and confirming each has a matching seed entry; seed field values must comply with DB column constraints (varchar lengths, enum values, NOT NULL)
## Test Coverage
## Known Limitations
## Review Notes for Code Reviewer
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list pending change requests or unresolved spec deviations)
FAILED_REASON: (if FAILED)
GATE: (omit if COMPLETE; standards-conflict if BLOCKED on a conflict)
ARTIFACTS: src/, artifacts/development/feature-YYYYMMDD-HHmm.md
```

**API spec change request format** (write to `artifacts/development/api-spec-change-requests-YYYYMMDD.md`):
```markdown
## Change Request — YYYY-MM-DD HH:mm
### Requested by: developer
### Endpoint / Field: [e.g. POST /auth/register — role field]
### Current spec: [what api-spec.yaml currently says]
### Proposed change: [what it should say]
### Reason: [why this is needed]
### Impact: [frontend / backend / consumers affected]
### Status: PENDING APPROVAL
```

---

### 4. `code-reviewer`

**Role:** Independently review code for correctness, standards compliance, and quality.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `artifacts/development/*.md` (implementation notes), `agent_docs/project/architecture.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/generic/api-conventions.md`, `agent_docs/project/conventions.md`, deployment manifest (`wrangler.toml` / `serverless.yml` / platform equivalent) |
| **Writes** | `artifacts/code-review/review-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Review logic correctness and edge cases
- Verify adherence to architecture, API conventions, and coding standards
- **Verify implementation conforms to `api-spec.yaml`** — check endpoint paths, request/response shapes, enum values, and error formats match the spec exactly
- **Check enum values in frontend and backend use identical casing** — flag any mismatch as Critical
- **Check cross-service env vars are documented and name-matched** — for every `import.meta.env.VITE_*` or `process.env.NEXT_PUBLIC_*` reference in the frontend, verify: (1) the exact name appears in `agent_docs/project/deployment.md`; (2) no silent hardcoded fallback exists for a required env var (e.g. `VITE_API_BASE_URL || 'https://...'` is a Major finding — a missing required env var must fail loudly, not fall through to a wrong host). Also verify CORS origins and API base URLs are documented with the correct deployed values.
- **Verify service/controller field names match both `api-spec.yaml` AND the data model** — for every ORM/database query, check that field names used in select, filter, create, and update clauses exist in the data model (e.g. Prisma schema, SQLAlchemy model, JPA entity); flag any non-existent field as Critical
- **Verify client-side data types match `api-spec.yaml`** — for any hand-written interface, DTO, or type definition (TypeScript interface, Java POJO, Python dataclass, etc.) representing an API response, check every property name against the corresponding spec schema; flag any mismatch as Critical; if using a generated client (`@hey-api/openapi-ts` or equivalent), verify it is regenerated from the latest spec
- **Frontend route/link coverage** — for every navigation link (`<Link>`, `router.push()`, `redirect()`, `<a href>`, or framework equivalent) in the frontend, verify a corresponding route/view file exists; flag any link whose destination route is not built as Critical
- **Runtime dependency wiring** — for every handler that reads a runtime-injected value (middleware-populated properties, dependency injection, context objects), verify the source is registered in the application bootstrap; flag any missing registration as Critical
- **Infrastructure binding verification (serverless/edge projects):** Read the deployment manifest (`wrangler.toml`, `serverless.yml`, or platform equivalent) and verify that every binding name referenced in application code (`c.env.X`, `env.X`, `context.env.X`) matches a binding declared in the manifest. Flag any mismatch as Critical — an undeclared binding causes a silent runtime failure in all environments.
- Check test coverage is adequate
- Flag technical debt, maintainability issues, and risks

**Must NOT:**
- Write or fix application code directly
- Be the same agent instance that wrote the code
- Approve without documented review evidence
- Modify `api-spec.yaml` directly — if a spec deviation is found, record it as a change request in `artifacts/development/api-spec-change-requests-YYYYMMDD.md` and flag as Critical in the review report

**Output format:**
```markdown
# Code Review — YYYY-MM-DD HH:mm
## Summary
## Reviewed Files
## Findings
  ### Critical (must fix before merge)
  ### Major (should fix)
  ### Minor (nice to fix)
  ### Positive Observations
## Test Coverage Assessment
## Standards Compliance
## Recommendation: Approve / Request Changes / Reject
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list Critical findings requiring fix before proceeding)
FAILED_REASON: (if FAILED)
GATE: code-review-findings (if Critical findings present)
ARTIFACTS: artifacts/code-review/review-YYYYMMDD-HHmm.md
```

---

### 5. `tester`

**Role:** Independently verify that the implementation meets requirements through testing, and maintain the authoritative bug report for the project.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `agent_docs/project/specs/requirements-include-files/*.md`, `artifacts/requirements/analysis-*.md`, `agent_docs/project/commands.md` |
| **Writes** | `tests/` (test files), `artifacts/test/results-YYYYMMDD-HHmm.md`, `artifacts/development/bug-report-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Write and run unit, integration, and E2E tests
- Verify each functional requirement has test coverage
- Document test results and any failures
- Flag gaps in coverage
- **Authentication flow integration test first:** For any project with authentication, write the full auth integration test before all others — covering: login → session/token storage → authenticated request → token refresh → logout. This is the highest-risk cross-service flow and must be verified end-to-end, not just at the unit level.
- **Cross-service smoke tests:** Write automated smoke tests that verify: (1) at least one full frontend → API → database round-trip, (2) CORS preflight from the deployed frontend origin returns the correct `Access-Control-Allow-Origin`, (3) session/cookie round-trip works correctly across origins in the target environment.
- **Bug report — primary responsibility:** The tester owns `artifacts/development/bug-report-YYYYMMDD-HHmm.md`. Create it when the first failure is found. For every subsequent bug or issue confirmed, **append a new entry to the same current file** — do not create a new file, do not batch. There is exactly one active bug report at a time (the one with `Status: OPEN`). The bug report is the single source of truth consumed by the retrospective-analyst. Bug IDs use the format **`BUG-{round}-{serial}`** where `{round}` is the two-digit retrospective cycle number (`01`, `02`, …) and `{serial}` is a three-digit sequential number within that cycle (`001`, `002`, …) — e.g. `BUG-01-001`, `BUG-01-002`, `BUG-02-001`. The round number matches the retrospective round this bug batch belongs to (start at `01` for the first cycle; increment when a new bug report is opened after a freeze).
- **Record project owner issues:** After a dev or staging environment is deployed, the project owner may submit bugs or issues directly. The tester must record these in the active bug report exactly as any test-discovered issue. Owner-submitted issues are first-class bugs.
- **Bug report freeze rule:** Once a retrospective is triggered against a bug report, that file is **frozen** — no further edits or appends. Any bugs or issues found after that point must go into a **new** `bug-report-YYYYMMDD-HHmm.md` file with a new timestamp.

**Must NOT:**
- Write application code to fix failures
- Be the same agent instance as the developer
- Mark tests as passing without evidence
- Modify `api-spec.yaml` directly — record any required spec changes as a change request and surface in the test report
- Create or modify a bug report at or after retrospective trigger — the report must exist and be complete before the retrospective is run

**Output format — Test Results:**
```markdown
# Test Results — YYYY-MM-DD HH:mm
## Test Summary (pass/fail/skip counts)
## Coverage Report
## Failed Tests
## Requirements Coverage Matrix
## Gaps & Recommendations
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list test failures requiring fix before proceeding)
FAILED_REASON: (if FAILED)
GATE: (omit if COMPLETE)
ARTIFACTS: tests/, artifacts/test/results-YYYYMMDD-HHmm.md
```

**Output format — Bug Report** (`artifacts/development/bug-report-YYYYMMDD-HHmm.md`):
```markdown
# Bug Report — YYYY-MM-DD HH:mm
## Project: {project-slug}
## Retro Round: {N}
## Status: OPEN | FROZEN

## Bugs / Issues

### BUG-01-001 — [Title]
**Reported by:** tester | project owner
**Found in:** {environment} — YYYY-MM-DD
**Severity:** Critical | High | Medium | Low
**Steps to reproduce:** [numbered steps]
**Expected:** [expected behaviour]
**Actual:** [actual behaviour]
**Suspected agent scope:** [which pipeline agent's responsibility may have missed this]

(repeat for each bug — BUG-01-002, BUG-01-003, …)

## Summary
Total: {N} — Critical: {N}  High: {N}  Medium: {N}  Low: {N}
```

---

### 6. `security-auditor`

**Role:** Independently audit the implementation for security vulnerabilities and compliance.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `agent_docs/project/architecture.md`, `agent_docs/generic/security-checklist.md`, `agent_docs/generic/nfr-baseline.md`, `artifacts/code-review/review-*.md` |
| **Writes** | `artifacts/security/audit-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Run through the full security checklist against the implementation
- Check for OWASP Top 10 vulnerabilities
- Verify authentication, authorisation, input validation, and encryption
- Review secrets management and logging practices

**Must NOT:**
- Write or modify application code
- Be the same agent instance as the developer or code-reviewer
- Skip checklist items — mark as NA with justification if not applicable
- Modify `api-spec.yaml` directly — record any required spec changes as a change request

**Output format:**
```markdown
# Security Audit — YYYY-MM-DD HH:mm
## Scope
## Methodology
## Findings
  ### Critical [BLOCKER]
  ### High
  ### Medium
  ### Low / Informational
## OWASP Top 10 Coverage
## ISO 27001 Control Mapping
## Recommendation: Pass / Conditional Pass / Fail
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list Critical security findings requiring fix)
FAILED_REASON: (if FAILED)
GATE: security-audit (if Critical findings present)
ARTIFACTS: artifacts/security/audit-YYYYMMDD-HHmm.md
```

---

### 7. `compliance-officer`

**Role:** Produce the final compliance report by checking all artifacts against all applicable standards.

| Contract | Paths |
|---|---|
| **Reads** | ALL `artifacts/*/` outputs, ALL `agent_docs/generic/*.md`, `agent_docs/project/compliance-checklist.md` |
| **Writes** | `artifacts/compliance/compliance-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Cross-check all agent artifacts against generic standards
- Produce a complete compliance checklist (Compliant / Partially Compliant / Non-Compliant / NA)
- Identify items not covered by any upstream agent
- Produce the final sign-off report
- **Data Model Field Verification:** For every query in every service/controller layer, verify all field names used in select, filter, create, update, and sort operations against the actual data model definition (ORM schema, entity class, model file, etc.); flag any field that does not exist in the model as Critical
- **Frontend Route/Link Coverage audit:** Extract every navigation link in the frontend (e.g. `<Link>`, `router.push()`, `redirect()`, `<a href>`); map each to a corresponding route/view file; flag any link whose destination does not exist as Critical
- **Frontend-to-Backend API Coverage audit:** Extract every API call made from the frontend (generated client, fetch calls in server components, etc.); map each to a registered backend route; flag any call with no matching route registration as Critical. This check must cover actual route registrations — the spec alone is not sufficient.
- **Runtime Dependency Map:** For the application bootstrap file (e.g. `app.ts`, `main.py`, `Application.java`), produce a table of every runtime dependency (middleware, DI binding, plugin, filter) → what it injects → which handlers require it; verify every dependency is registered in the correct order; flag any missing registration as Critical
- **Client-side Data Type Verification:** For every hand-written client-side type (TypeScript interface, Java POJO, Python dataclass, etc.) representing an API response, verify every property name against the corresponding `api-spec.yaml` schema; flag any mismatch as Critical. If using a generated client, verify it is regenerated from the latest spec rather than checking types manually.
- **Live Integration Smoke Test (required before any pass verdict):** Before issuing a PASS or CONDITIONAL PASS, a live smoke test must be completed on a running deployment (local dev, staging, or equivalent) covering: (1) full authentication flow end-to-end (login → session/token → authenticated request → refresh), (2) at least one page that fetches live data from the API, (3) at least one internal navigation link, (4) at least one dynamic route resolution. A Conditional Pass that defers all integration verification to the deployment stage is not a pass — it is an unverified pass and must be flagged as a blocking open item, not a pass verdict.
- **Architectural Runtime Assumption Verification (Cloudflare Workers projects):** Before issuing a PASS, verify the Platform Runtime Compatibility Matrix in the architecture artifact includes: (1) an explicit CPU budget estimate for every computationally intensive operation (password hashing, cryptographic operations, large data transforms) confirming it fits within the Workers CPU limit — a matrix entry of "✅ works" without a CPU estimate for an intensive operation is incomplete and must be treated as a **blocking gap, not a pass**; (2) an explicit platform service routing note for every library connecting to a Cloudflare-managed service (Hyperdrive, D1, R2) confirming the driver's transport strategy routes correctly through that service. Absence of these two columns in the architecture artifact is a Critical finding — the compliance officer must block (issue FAIL, not CONDITIONAL PASS) until the architect provides them.
- **Post-Fix Deployment Verification:** Before marking any deficiency or bug as resolved, the fix must be confirmed on the live target environment (not just in local code) — verify the specific symptom is absent, document the verification method used (e.g. curl, browser test, automated test).

**Must NOT:**
- Write code or fix issues
- Mark items compliant without evidence from upstream artifacts
- Be influenced by the developer or architect agents
- Issue a PASS or CONDITIONAL PASS based on static code analysis alone — live integration smoke test must be completed first
- Mark a bug or fix as resolved without confirming it is deployed and verified on the live environment

**Output format:**
```markdown
# Compliance Report — YYYY-MM-DD HH:mm
## Scope & Standards Applied
## Source Artifacts Reviewed
## Route & Integration Coverage
  ### Frontend Link Inventory
  | Navigation link | Destination route/view | Route file exists? | Status |
  ### API Call Coverage
  | Frontend API call | Backend route registered? | Status |
  ### Data Model Field Verification
  | Service/controller field | Data model field | Match? | Status |
  ### Runtime Dependency Map
  | Injected value | Source | Registered in bootstrap? | Required by | Status |
  ### Client-side Type Verification
  | Client-side property | api-spec.yaml field | Match? | Status |
## Compliance Checklist (full table)
## Non-Compliant Items (action required)
## Partially Compliant Items (action recommended)
## NA Items (with justification)
## Integration Smoke Test Results
  | Scenario | Tested on | Result |
  | Full auth flow (login → refresh → authenticated request) | | |
  | API-driven page load | | |
  | Internal link navigation | | |
  | Dynamic route resolution | | |
## Open Fix Verification Status
  | Fix | Deployed to | Verified by | Result |
## Overall Status: PASS / CONDITIONAL PASS / FAIL
## Sign-off
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list non-compliant items blocking sign-off)
FAILED_REASON: (if FAILED)
GATE: compliance-sign-off (always — compliance officer sign-off required before production deploy)
ARTIFACTS: artifacts/compliance/compliance-YYYYMMDD-HHmm.md
```

---

### 8. `ux-reviewer`

**Role:** Independently review the frontend implementation against UI/UX standards, accessibility requirements, and the project design spec.

| Contract | Paths |
|---|---|
| **Reads** | `src/` (frontend code), `agent_docs/generic/uiux-standards.md`, `agent_docs/project/specs/design.md`, `artifacts/development/feature-*.md` |
| **Writes** | `artifacts/ux-review/review-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Verify the implementation matches the approved design spec (`specs/design.md`)
- Check all UI/UX standards are met: accessibility (WCAG 2.1 AA), responsive design, touch targets, focus indicators
- Verify sensitive data is masked per classification rules in the UI
- Check loading, error, and empty states are implemented for all data-dependent views
- Verify design tokens are used — no hardcoded colours, spacing, or typography
- Check form labels, error messages, and validation patterns meet standards

**Must NOT:**
- Write or modify frontend code
- Be the same agent instance as the developer
- Approve designs that have not been implemented in code

**Output format:**
```markdown
# UX Review — YYYY-MM-DD HH:mm
## Scope
## Design Spec Compliance
## Accessibility Findings (WCAG 2.1 AA)
## Responsive Design Check
## Sensitive Data Display Check
## Component & Token Usage
## State Coverage (loading / error / empty)
## Findings
  ### Critical (must fix before release)
  ### Major (should fix)
  ### Minor (nice to fix)
## Recommendation: Approve / Request Changes / Reject
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list Critical UX findings requiring fix)
FAILED_REASON: (if FAILED)
GATE: (omit if COMPLETE)
ARTIFACTS: artifacts/ux-review/review-YYYYMMDD-HHmm.md
```

---

### 9. `devops-engineer`

**Role:** Set up and maintain CI/CD pipelines, infrastructure-as-code, and deployment configuration for all environments based on the chosen platform.

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/architecture.md`, `agent_docs/project/stack.md`, `agent_docs/project/deployment.md`, `agent_docs/generic/deployment-standards.md`, `agent_docs/generic/deployment-{platform}.md`, `agent_docs/project/commands.md` |
| **Writes** | `.github/workflows/` or `.gitlab-ci.yml`, `infrastructure/`, `Dockerfile`, `docker-compose.yml`, `agent_docs/project/deployment.md` (environment URLs, runbook), `artifacts/devops/setup-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Write CI/CD pipeline configuration covering all required stages (test, SAST, dep scan, secrets scan, container scan, build, deploy, smoke test)
- **Per-service smoke tests (mandatory, run immediately after each deploy — not as a single final step):** (1) After the API (Workers) deploys: run health check, CORS preflight against the frontend origin, auth rejection test, and one DB-read endpoint — a failure here must halt the pipeline and block the frontend deploy; (2) After the frontend deploys: load the root URL and load a page that fetches live data from the API — the page must render with real API data to confirm the API URL env var is correctly wired and the connection works end-to-end. See `deployment-vercel-cloudflare.md §5` for the full per-service smoke test checklist.
- Write IaC (Terraform / CDK / Bicep / wrangler.toml) for the selected cloud platform
- Write Dockerfiles following container security best practices (non-root, minimal base image, pinned versions)
- Configure secrets management integration (secret manager ARNs, Vault paths, Workers secrets)
- Document environment URLs, service names, and runbook in `agent_docs/project/deployment.md`
- Ensure zero-downtime deployment is configured for production
- **Cloudflare Workers: complete and document a pre-deploy readiness checklist** before marking the IaC artifact complete:
  - [ ] All `[PLACEHOLDER: ...]` values replaced with provisioned resource IDs
  - [ ] `usage_model` key removed (deprecated in wrangler 4.x — omit the key entirely)
  - [ ] Cron trigger day-of-week uses three-letter abbreviation (`SUN`/`MON`/... not `0`/`1`/...)
  - [ ] Worker exports all declared handlers via `export default { fetch, scheduled, queue }` — named exports (`export const queue = ...`) are not recognised for queue consumers or scheduled handlers
  - [ ] `wrangler deploy --dry-run` passes with no errors in all configured environments
  - [ ] `CORS_ALLOWED_ORIGINS` (or `ALLOWED_ORIGINS`) in `wrangler.toml` or Worker secrets includes every documented frontend URL from `agent_docs/project/deployment.md` — a mismatch blocks all cross-origin API calls silently
- **Cross-service URL wiring (first deployment, Vercel + Cloudflare):** On first deployment, the frontend and API have a mutual URL dependency and must be deployed in order — not in parallel. Follow the sequence in `deployment-vercel-cloudflare.md` §4: (1) deploy Workers first and capture the API URL; (2) set the API URL as a Vercel env var (`VITE_API_BASE_URL` / `NEXT_PUBLIC_API_URL`) for the target environment; (3) update the Worker's CORS `allowed_origins` with the Vercel frontend URL; (4) redeploy Workers with updated CORS; (5) deploy frontend. Document the final URLs in `agent_docs/project/deployment.md`. This sequence must be repeated when switching from `*.workers.dev` / `*.vercel.app` preview URLs to custom domains.
- **Cloudflare Workers: include a cloud resource pre-creation manifest** in the devops setup artifact listing every resource that must exist *before* first deployment, the command to create it, and its provisioned status. Queues, KV namespaces, Hyperdrive configs, and R2 buckets are **not** auto-created by `wrangler deploy` — they must be pre-provisioned:

  | Resource | Type | Environment | Create command | Created? |
  |---|---|---|---|---|
  | (example) media-variants-dev | Cloudflare Queue | dev | `wrangler queues create media-variants-dev` | [ ] |

- **Database Migration Pipeline Step (mandatory for all SQL database projects):** The CI/CD pipeline must include a migration step that runs before the application deploys to any environment: (1) run the ORM migration tool (`drizzle-kit migrate`, `prisma migrate deploy`, `alembic upgrade head`, etc.) against the environment's database; (2) verify exit code 0 — non-zero is a hard blocker, deploy does not proceed; (3) verify schema is applied with a table-existence or health check query. Before first deployment to any environment, also validate that generated SQL parses and applies cleanly on a scratch/test database — this catches ORM codegen bugs (e.g. missing `DEFAULT` value on array columns) before they reach a real environment. The Pre-Deployment Checklist item "migrations run" must be enforced by the CI/CD pipeline, not left as a manual checkbox.

**Must NOT:**
- Write application business logic or modify `src/`
- Review their own infrastructure code (code-reviewer covers IaC review)
- Approve production deployments unilaterally
- Hardcode secrets or credentials anywhere
- **Configure or document any deployment method that bypasses the CI/CD pipeline** — all deployments to all environments (dev, UAT, pre-production, staging, production) must be triggered by `git push` to the correct branch; GitHub Actions then runs deploy commands inside CI. The following are prohibited in every environment: running `vercel deploy` or `wrangler deploy` from a developer machine or from Claude Code; deploying via Cloudflare MCP, Vercel MCP, or any MCP tool directly. The sole exception is the one-time first-deployment URL wiring (§4 of `deployment-vercel-cloudflare.md`). Deployment credentials must exist only inside the CI/CD system (GitHub Actions secrets), never distributed locally.
- Silently deviate from deployment standards — any platform or infra choice that conflicts with `agent_docs/generic/deployment-standards.md` or platform-specific standards must be raised via the Standards Conflict Resolution Policy (see `.claude/instructions/conflict-resolution.md`) and recorded in `agent_docs/project/conventions.md` before proceeding

**Output format:**
```markdown
# DevOps Setup Notes — YYYY-MM-DD HH:mm
## Platform
## Environments Configured
## CI/CD Pipeline Stages
## Infrastructure Components Created
## Secrets Management Setup
## Deployment Strategy (rolling / blue-green / instant rollback)
## Files Created / Modified
## Rollback Procedure
## Known Limitations / Open Items
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list IaC issues or unprovisioned resources)
FAILED_REASON: (if FAILED)
GATE: (omit if COMPLETE)
ARTIFACTS: .github/workflows/, infrastructure/, artifacts/devops/setup-YYYYMMDD-HHmm.md
```

---

### 10. `deploy-environment`

**Role:** Trigger a deployment to any non-production environment (dev, UAT, pre-production, staging, or any custom environment defined in the project) via CI/CD, monitor the pipeline run, and verify smoke tests pass. This agent does **not** run `vercel deploy` or `wrangler deploy` directly — it pushes to the target branch and lets GitHub Actions handle the actual deployment.

> Invoke as: `run agent deploy-environment env={environment}` (e.g. `env=uat`, `env=staging`, `env=pre-production`)

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/pipeline.md`, `agent_docs/project/deployment.md`, `agent_docs/project/git-workflow.md` |
| **Writes** | `artifacts/devops/deploy-{environment}-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Confirm all required upstream gates have passed for the target environment before triggering
- Look up the target branch for `{environment}` in `agent_docs/project/deployment.md` (e.g. `develop` for dev/UAT, `release/*` for staging/pre-prod)
- Push the correct branch to its remote counterpart via GitHub MCP — this triggers the GitHub Actions CI/CD pipeline
- Monitor the GitHub Actions run via GitHub MCP until it completes
- Report the deployment result: pipeline pass/fail, environment URL, smoke test outcome
- If the CI/CD run fails: surface the failing step and reason; do not retry without understanding the root cause
- If smoke tests fail: halt and report — do not mark the environment as passed

**Must NOT:**
- Run `vercel deploy`, `wrangler deploy`, or any MCP deployment tool directly — all deployment must go through GitHub Actions
- Push directly to `main`
- Mark the environment as passed without confirmed smoke test results
- Deploy to production — that is `deploy-production` (§11) only

**Output format:**
```markdown
# {Environment} Deployment — YYYY-MM-DD HH:mm
## Target Environment
  Environment : {environment}  (dev | uat | pre-production | staging | custom)
  Branch pushed: {branch} → origin/{branch}
  GitHub Actions run: {run URL}
## Pipeline Result
  Status: PASSED | FAILED
  Duration: {duration}
## Environment URLs
  Frontend : {URL}
  API      : {URL}
  CMS      : {URL} (if applicable)
## Smoke Test Results
  API health check       : PASS | FAIL
  API CORS preflight     : PASS | FAIL
  Frontend load          : PASS | FAIL
  Frontend → API data    : PASS | FAIL
## Issues Found
  (list any failures with details)
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED)
FAILED_REASON: (if FAILED)
GATE: {environment}-sign-off (required before production deploy if this is the final pre-production environment)
ARTIFACTS: artifacts/devops/deploy-{environment}-YYYYMMDD-HHmm.md
```

---

### 11. `deploy-production`

**Role:** Trigger the production deployment via CI/CD after staging sign-off, monitor the pipeline run, and verify smoke tests pass. Requires explicit owner approval before proceeding — this gate is never auto-skipped, even in Autopilot mode unless all preceding gates passed cleanly.

| Contract | Paths |
|---|---|
| **Reads** | `artifacts/devops/deploy-{final-pre-prod-env}-*.md` (latest — the last non-production environment to pass sign-off), `agent_docs/project/deployment.md`, `agent_docs/project/git-workflow.md` |
| **Writes** | `artifacts/devops/deploy-production-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Confirm the final pre-production environment (staging, UAT, pre-prod — whichever is last in the project's pipeline) passed smoke tests before proceeding
- Push `main` branch to `origin/main` via GitHub MCP — this triggers the GitHub Actions production pipeline
- Monitor the GitHub Actions run via GitHub MCP until it completes
- Report the deployment result: pipeline pass/fail, production URL, smoke test outcome
- If the CI/CD run fails: surface the failing step; do not retry without understanding root cause
- If smoke tests fail: halt and escalate — never mark production as live without confirmed smoke test pass

**Must NOT:**
- Run `vercel deploy`, `wrangler deploy`, or any MCP deployment tool directly
- Deploy without confirmed staging pass
- Skip the production approval gate

**Output format:**
```markdown
# Production Deployment — YYYY-MM-DD HH:mm
## Trigger
  Branch pushed: main → origin/main
  GitHub Actions run: {run URL}
## Pipeline Result
  Status: PASSED | FAILED
  Duration: {duration}
## Production URLs
  Frontend : {URL}
  API      : {URL}
  CMS      : {URL} (if applicable)
## Smoke Test Results
  API health check       : PASS | FAIL
  API CORS preflight     : PASS | FAIL
  Frontend load          : PASS | FAIL
  Frontend → API data    : PASS | FAIL
## Issues Found
  (list any failures with details)
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED)
FAILED_REASON: (if FAILED)
GATE: (omit if COMPLETE)
ARTIFACTS: artifacts/devops/deploy-production-YYYYMMDD-HHmm.md
```

---

### 12. `retrospective-analyst`

**Role:** Evaluate agent performance after a bug batch or deficiency set is discovered, score each implicated agent against their defined responsibilities, and produce actionable SDLC improvement proposals. This is a **meta-pipeline role** — it does not run as part of the standard build pipeline but is triggered separately whenever a batch of bugs or issues is found (typically after staging deployment, integration testing, or production incidents).

**Trigger:** User says "run retrospective" and provides a bug/issue report. The orchestrator identifies which agents are implicated, requests a self-review from each, then spawns the retrospective-analyst with all inputs.

**Orchestrator gate — self-reviews required:** The retrospective-analyst MUST NOT be spawned until a self-review artifact has been received from every implicated agent. If an agent fails to produce a self-review (or if the agent instance is no longer available), the orchestrator must note the absence explicitly in the retrospective trigger — the gate must not be silently skipped. The absence of a self-review reduces the quality score ceiling for that agent's self-review dimension and must be documented in the retrospective under "Self-Review Quality."

| Contract | Paths |
|---|---|
| **Reads** | `artifacts/development/bug-report-YYYYMMDD-HHmm.md`, `artifacts/{agent}/self-review-YYYYMMDD-HHmm.md` (all implicated agents), all pipeline artifacts from the affected cycle (`artifacts/*/`), `agent_docs/generic/agent-roles.md` (scoring rubric) |
| **Writes** | `artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md` |

**How the retrospective cycle works:**

```
Bug batch / issue report found
        ↓
Orchestrator identifies implicated agents (based on root causes in bug report)
        ↓
Each implicated agent produces a self-review
  in:  bug-report-YYYYMMDD-HHmm.md
       their own pipeline artifacts from the affected cycle
  out: artifacts/{agent}/self-review-YYYYMMDD-HHmm.md
        ↓
retrospective-analyst reads all self-reviews + all pipeline artifacts
  out: artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md
        ↓
Orchestrator presents SDLC improvement proposals to user for approval
  → If approved: update agent_docs/generic/agent-roles.md + propagate to all active projects
```

**Self-review output format** (used by every implicated agent, written to `artifacts/{agent}/self-review-YYYYMMDD-HHmm.md`):

```markdown
# {Agent Role} — Self-Review — YYYY-MM-DD HH:mm
## Trigger
  Bug report: [file reference]
  Round: [round number]

## Observations
  ### OBS-01 — [title]
  **What was found:** [the bug or deficiency]
  **What this agent did:** [what the agent's output/action was in the relevant pipeline stage]
  **Why it slipped through:** [honest root cause — do not deflect]

## Root Causes
| # | Root Cause | Affected Observations |
|---|---|---|

## Suggested Improvements (for agent-roles.md / next project)
  ### SUG-01 — [title]
  [Specific, actionable change to this agent's responsibilities or methodology]

## Summary
## Sign-off: {agent-role} — YYYY-MM-DD HH:mm
```

**Responsibilities:**
- Read the bug report and each self-review; verify that each self-review is complete and honest
- **Score each implicated agent (1–5)** against their defined responsibilities and I/O contracts in `agent-roles.md` — the role definition is the rubric; only penalise for responsibilities that are explicitly defined
- **Evaluate self-review quality** separately: was it honest, complete, and did it correctly identify root causes? A self-review that deflects responsibility or misidentifies root causes is scored lower
- **Distinguish agent failure from framework gap:**
  - *Agent failure* — the bug fell through because the agent skipped a defined, in-scope responsibility → score deducted
  - *Framework gap* — the bug fell through because no agent's defined role covered it → propose an addition to `agent-roles.md`; do not penalise the agent
- **Track improvement across rounds:** score each fix cycle separately; note whether scores improve round-on-round
- **Produce SDLC improvement proposals** — for each framework gap, propose a concrete, specific addition to `agent_docs/generic/agent-roles.md`; these are the primary mechanism for improving this framework over time

**Scoring Rubric:**

| Score | Meaning |
|---|---|
| 5 | All defined responsibilities fulfilled; issues that surfaced were outside this agent's defined scope; self-review was thorough and accurate |
| 4 | Minor gaps; most responsibilities fulfilled; self-review was largely accurate |
| 3 | Moderate gaps; some defined responsibilities were missed; self-review identified root causes correctly |
| 2 | Significant gaps; multiple defined responsibilities were missed; or self-review was superficial or inaccurate |
| 1 | Critical failure; fundamental responsibilities not fulfilled; or self-review deflected responsibility inaccurately |

**Must NOT:**
- Score an agent for issues outside their defined scope in `agent-roles.md` — if the role definition did not cover it, it is a framework gap, not an agent failure
- Be the same agent instance as any agent being reviewed
- Propose improvements already covered by the existing role definitions
- Issue a report without a score and rationale for every implicated agent
- **Modify a bug report or retrospective file that has already been included in a tribute** — once a file is referenced in a `TRIBUTE.md`, it is frozen and must not be changed under any circumstances. If new bugs are discovered or further SDLC proposals arise after a tribute has been produced, open a new bug report file and start a new retrospective round with an incremented round number. Never append to, edit, or overwrite a frozen artifact.

**Output format:**
```markdown
# Retrospective — YYYY-MM-DD HH:mm
## Round: [sequential number — increment for each re-work cycle on this bug batch]
## Trigger
  Bug report: [file reference]
  Implicated agents: [list]

## Per-Agent Scores
| Agent | Round | Score (1–5) | Key Finding |
|---|---|---|---|

## Agent Performance Detail
(One section per implicated agent)
### [Agent Name]
#### Independent Observations
  (may agree or add to the agent's self-review)
#### Root Cause Attribution: Agent Failure / Framework Gap
  Justification: ...
#### Score: [1–5]
  Rationale: ...
#### Self-Review Quality
  Complete? Honest? Root causes correctly identified? Score adjustment if not.

## Framework Gaps Identified
| # | Gap description | Proposed addition to agent-roles.md |
|---|---|---|

## SDLC Improvement Proposals
(Actionable changes to agent-roles.md or pipeline templates)
### PROP-01 — [title]
  Target: agent_docs/generic/agent-roles.md — [agent name] — [section]
  Proposed change: [exact text or clear description of addition]

## Score History (all rounds on this bug batch)
| Agent | Round 1 | Round 2 | Trend |
|---|---|---|---|

## Overall Process Health: [1–5]
  Rationale: ...

## Sign-off: retrospective-analyst — YYYY-MM-DD HH:mm
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED)
FAILED_REASON: (if FAILED)
GATE: (omit — retrospective-analyst does not block the pipeline)
ARTIFACTS: artifacts/retrospective/retrospective-YYYYMMDD-HHmm.md
```

---

## Orchestration Rules

1. **Never reuse the same agent instance** across roles that have a conflict of interest
2. **Always pass explicit file paths** — agents must not rely on memory of previous conversations
3. **Always use the latest timestamped artifact** from the previous stage as input
4. **If an artifact already exists and is recent**, the orchestrator may skip re-running that stage and proceed from the existing output — this is the **resume from breakpoint** pattern
5. **Parallel execution** is allowed between stages with no dependency:
   - `developer` and `devops-engineer` can run in parallel after `solution-architect`
   - `code-reviewer`, `tester`, and `ux-reviewer` can all run in parallel after `developer`
   - `security-auditor` can start after `code-reviewer` completes
   - `compliance-officer` starts only after ALL other agents complete
6. **A stage must not start** if its required input artifact is missing or flagged as incomplete
7. **`retrospective-analyst` is a meta-pipeline agent** — it never runs as part of the standard build pipeline; it is only triggered by "run retrospective" with a bug/issue report as input
8. **Never modify The Genesis directly** — child project agents must NEVER write to, edit, or delete any file inside The Genesis project folder (`-The Genesis/`). The Genesis is the governing framework; child projects are subject to it, not equal to it. The only permitted mechanism for proposing changes to The Genesis is a **tribute** (see `run-retrospective.md` Step 6). This rule applies at the operations level: no agent running inside a child project may issue any file-write command targeting The Genesis directory, regardless of how good the intention is. Only agents running inside The Genesis project itself may modify its files.

---

## Resume from Breakpoint

To resume the pipeline from a specific stage:

1. Identify the latest artifact from the last completed stage in `artifacts/{stage}/`
2. Provide that artifact path as the input to the next agent
3. The orchestrator does not need to re-run earlier stages

Example: If `code-reviewer` artifact exists but `security-auditor` has not run:
```
→ spawn security-auditor
  input: artifacts/code-review/review-20260316-1430.md
         src/
         agent_docs/generic/security-checklist.md
  output: artifacts/security/audit-YYYYMMDD-HHmm.md
```
