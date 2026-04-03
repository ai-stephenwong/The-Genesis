<!-- part-of: agent-roles.md | agent: developer -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.
>
> **Validation:** After this agent completes, the orchestrator runs `scripts/validate/post-developer.sh` to verify outputs. Fix any failures before handing off.

---

### 4. `developer`

**Role:** Implement features according to architecture, requirements, and the approved API specification. When module decomposition is active, each developer sub-agent is scoped to a single module.

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/architecture.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/project/specs/requirements-include-files/*.md`, `agent_docs/project/stack.md`, `agent_docs/project/conventions.md`, `agent_docs/generic/api-conventions.md`, `agent_docs/generic/uiux-standards.md` *(frontend projects)*, `agent_docs/generic/security-checklist.md` |
| **Reads (module mode)** | `agent_docs/project/modules/module-{assigned-module}.md` (own module spec), `agent_docs/project/modules/module-*.md` (interface contracts only — for imports) |
| **Writes** | `src/` (application code — in module mode, only files within the module's owned scope), `artifacts/development/feature-{name}-YYYYMMDD-HHmm.md` (implementation notes) |

**Module mode (when `agent_docs/project/modules/` exists with module specs):**

The orchestrator launches one developer sub-agent per module. Each sub-agent:
1. Reads **only** its assigned module spec (`module-{name}.md`) for scope and interface contracts
2. Reads other modules' specs **only** for their exported interfaces (to consume as imports)
3. Writes code **only** within the directories/files listed in the module's `Scope → Owns` section
4. Must implement all exports listed in the module's interface contract
5. Must consume imports exactly as defined (matching types and signatures)
6. Must not create files outside its owned scope — if something is needed that belongs to another module, raise a change request

**Build phases (orchestrator enforces this order):**
- **Phase 0 — shared/common:** Built first. All other modules depend on its exports (shared types, utilities, config).
- **Phase 1 — independent:** Built in parallel after Phase 0 completes. Each module gets its own developer sub-agent.
- **Phase 2 — integration:** Built after Phase 1 completes. These modules depend on Phase 1 outputs.

After all modules complete, the orchestrator runs an **integration verification** step: build the full project and check for interface mismatches (type errors, missing exports, circular dependencies).

**Responsibilities:**
- Implement features strictly per architecture, requirements, and `api-spec.yaml`
- Implement against mockups from `requirements-include-files/` — match layout, spacing, colours, typography
- Follow company coding standards, project conventions, and `security-checklist.md`
- Generate the frontend API client from `api-spec.yaml` using `@hey-api/openapi-ts` — never hand-write service layer types or fetch functions
- Use exactly the enum values and field names defined in `api-spec.yaml`
- Use env var key names exactly as defined in `env-contract.md` — never invent names
- Write unit tests alongside code
- Review framework version-specific conventions (migration guides, breaking changes) before coding — document in implementation notes
- Produce implementation notes with all required sections (see output format below)
- Build must pass (`npm run build` + `tsc --noEmit` from clean state) before submission
- If any API change, env var, or tool is needed, raise a change request and wait for approval — never edit `api-spec.yaml`, `env-contract.md`, or `architecture.md` directly

**Change request procedures:**
- API change → `artifacts/development/api-spec-change-requests-YYYYMMDD.md`
- Env var change → `artifacts/development/env-var-change-requests-YYYYMMDD.md`
- Tool/service change → `artifacts/development/tool-change-requests-YYYYMMDD.md`

**Must NOT:**
- Review their own code, run security audits, or approve pull requests
- Deviate from architecture, api-spec.yaml, or Data Source Map without a change request
- Edit `api-spec.yaml` or `env-contract.md` directly
- Leave placeholder, stub, or non-functional implementations — if an endpoint is missing from the spec, raise a change request and set STATUS: BLOCKED
- Implement any endpoint not in `api-spec.yaml`
- Write code outside the module's owned scope (module mode) — if a shared utility is needed, request it via change request to the shared module
- Use hardcoded fallbacks for required env vars (e.g. `VITE_API_BASE_URL || 'https://...'`)

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
## Version-Specific Requirements
## Build Verification
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

**Change request formats:**

Tool Selection — `artifacts/development/tool-change-requests-YYYYMMDD.md`:
```markdown
## Tool Change Request — YYYY-MM-DD HH:mm
### Requested by: developer
### Tool / Service / Env var key: [e.g. Resend / NEXT_PUBLIC_ANALYTICS_ID]
### Category: [e.g. Transactional email / Frontend env var]
### Why needed: [what requirement or feature requires this]
### Impact: [what changes to architecture, dependencies, deployment]
### Status: PENDING APPROVAL
```

API Spec — `artifacts/development/api-spec-change-requests-YYYYMMDD.md`:
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

Env Var — `artifacts/development/env-var-change-requests-YYYYMMDD.md`:
```markdown
## Env Var Change Request — YYYY-MM-DD HH:mm
### Requested by: developer | devops-engineer
### Action: ADD | RENAME | REMOVE
### Env var key: [e.g. NEXT_PUBLIC_ANALYTICS_ID]
### Service: [e.g. Frontend (Next.js)]
### Required?: [Yes / No]
### Source: [e.g. GTM dashboard → Vercel env var]
### Reason: [why this env var is needed]
### Status: PENDING APPROVAL
```

---
