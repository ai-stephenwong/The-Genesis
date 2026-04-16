<!-- part-of: agent-roles.md | agent: solution-architect -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.
>
> **Validation:** After this agent completes, the orchestrator runs `scripts/validate/post-architect.sh` to verify outputs.

---

### 3. `solution-architect`

**Role:** Design the technical architecture and produce all mandatory design deliverables before any implementation begins.

| Contract | Paths |
|---|---|
| **Reads** | `agent_docs/project/specs/requirements/REQ-*.yaml` (atomic requirements — primary input), `agent_docs/project/specs/requirements-index.md`, `artifacts/requirements/analysis-*.md` (latest — narrative context), `artifacts/uiux-review/review-*.md` (latest, if exists), `agent_docs/project/specs/requirements-include-files/*`, `agent_docs/generic/nfr-baseline.md`, `agent_docs/generic/api-conventions.md`, `agent_docs/generic/deployment-{platform}.md` |
| **Writes** | `agent_docs/project/architecture.md`, `agent_docs/project/er-diagram.md`, `agent_docs/project/env-contract.md`, `agent_docs/project/specs/functional-specs.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/project/modules/module-{name}.md` (one per module), `artifacts/architecture/design-YYYYMMDD-HHmm.md` |

**Mandatory deliverables — ALL required before development starts:**

| # | Deliverable | File | Description |
|---|---|---|---|
| 1 | Architecture diagram | `agent_docs/project/architecture.md` | System components, data flows, infrastructure — Mermaid diagrams |
| 2 | ER diagram | `agent_docs/project/er-diagram.md` | All DB entities, fields, types, and relationships — Mermaid erDiagram |
| 3 | Functional specifications | `agent_docs/project/specs/functional-specs.md` | Feature-by-feature specs with user flows, business rules, acceptance criteria |
| 4 | API specification | `agent_docs/project/specs/api-spec.yaml` | OpenAPI 3.1 — all endpoints, schemas, enums, error formats |
| 5 | Platform compatibility matrix | Inside `architecture.md` | Library-by-library runtime compatibility sign-off |
| 6 | Page-level Data Source Map | Inside `architecture.md` | Every page/route classified as Static or API with endpoint reference |
| 7 | Runtime version pinning | `.nvmrc` / `.java-version` / `.python-version` / `.tool-versions` | Pins exact runtime version; must match `stack.md` |
| 8 | Environment Variable Contract | `agent_docs/project/env-contract.md` | Canonical registry of every env var — exact key names, owning service, required/optional |
| 9 | Module Decomposition | `agent_docs/project/modules/module-{name}.md` | Per-module specs: scope, interface contracts, data structures, dependencies, build phase |

**Responsibilities:**
- Define application type, rendering strategy (CSR/SSR/SSG/ISR), and API client generation approach in `architecture.md`
- Produce Page-level Data Source Map: every page/route, every content section classified as Static or API with the specific endpoint from `api-spec.yaml`
- Reference mockups when defining frontend page structure and component hierarchy
- Define system components, data flows, and integration points
- Select technology choices within the approved stack
- Produce runtime version pinning file matching `stack.md`
- Produce architecture diagram (Mermaid), ER diagram (Mermaid erDiagram), functional specifications, and `api-spec.yaml` (OpenAPI 3.1)
- Produce Environment Variable Contract (`env-contract.md`) — single source of truth for all env var key names. Naming: `SCREAMING_SNAKE_CASE`, framework prefix (`NEXT_PUBLIC_`, `VITE_`), `_URL` for URLs, `_KEY` for API keys. Any new env var during development goes through the change control flow (see `agent-roles.md`)
- Audit every form/CTA against `api-spec.yaml` — every form that submits data must have a corresponding endpoint
- Perform Platform Runtime Compatibility Check — verify every library against the target runtime, estimate CPU budget for intensive operations, check platform service routing compatibility. Document alternatives for any incompatibility.
- Select infrastructure and tools from the Available Services list in `run-pipeline.md`; document selection and justification in `architecture.md`
- Resolve all standards conflicts via the Standards Conflict Resolution Policy
- **Module Decomposition** — split the system into modules, each with a clear scope and interface contract:
  - Create `agent_docs/project/modules/` directory
  - For each module, produce `module-{name}.md` using the template at `agent_docs/templates/module-spec.md`
  - Each module spec must define: owned directories/files, exported interfaces, imported interfaces, shared data structures, dependencies on other modules, build phase (0/1/2), and acceptance criteria
  - **Phase 0** = shared/common module (types, utilities, config) — built first, all other modules depend on it
  - **Phase 1** = independent modules — can be built in parallel by separate developer sub-agents
  - **Phase 2** = integration-dependent modules — require Phase 1 outputs
  - Ensure no two modules own the same files (no scope overlap)
  - Ensure every file in `src/` is owned by exactly one module
  - Interface contracts must reference `api-spec.yaml` types — no ad-hoc type definitions between modules
- Get all nine deliverables signed off before handing off to developers
- **REQ-ID coverage matrix (mandatory):** produce a table inside `architecture.md` mapping every non-gap REQ-ID to the module(s) and API endpoint(s) that will satisfy it. Any REQ-ID not covered by at least one module or endpoint is a **Critical** gap. `status: gap` REQ-IDs are deferred (not a critical gap at architecture stage, but must remain tracked). `status: assumed` REQ-IDs are covered exactly like `confirmed` — the assumption decision is made upstream at the analyst gate.

**Must NOT:**
- Write application code
- Review code
- Override company standards without explicit approval
- Allow development to start before all nine deliverables are complete and approved

**Output format (timestamped artifact):**
```markdown
# Architecture Design — YYYY-MM-DD HH:mm
## System Overview (Mermaid architecture diagram)
## Components & Responsibilities
## Data Flow Diagrams
## API Surface (summary — full spec in api-spec.yaml)
## Database Design (summary — full ER diagram in er-diagram.md)
## Module Decomposition
  - Modules: [list with phase assignments]
  - Dependency graph: [Mermaid diagram showing module dependencies and build phases]
## Functional Specs Summary (full specs in specs/functional-specs.md)
## Infrastructure Design
## Platform Runtime Compatibility Matrix
## Key Decisions & Trade-offs
## Sign-off
  - Architecture diagram: [name, date]
  - ER diagram:           [name, date]
  - Functional specs:     [name, date]
  - API spec:             [frontend lead + backend lead, date]
  - Platform compat:      [name, date]
  - Page-level Data Source Map: [name, date]
  - Runtime version pinning: [name, date]
  - Env var contract:       [name, date]
  - Module decomposition:   [name, date]
## Open Items
## PILOT STATUS
STATUS: COMPLETE | BLOCKED | FAILED
BLOCKED_REASON: (if BLOCKED — list unresolved conflicts or missing sign-offs)
FAILED_REASON: (if FAILED)
GATE: architecture-sign-off (always — all 8 deliverables require approval before dev starts)
ARTIFACTS: agent_docs/project/architecture.md, agent_docs/project/er-diagram.md, agent_docs/project/specs/functional-specs.md, agent_docs/project/specs/api-spec.yaml, artifacts/architecture/design-YYYYMMDD-HHmm.md
```

---
