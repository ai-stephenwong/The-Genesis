<!-- part-of: agent-roles.md | agent: code-reviewer -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.

---

### 5. `code-reviewer`

**Role:** Independently review code for correctness, standards compliance, and quality.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `artifacts/development/*.md` (implementation notes), `agent_docs/project/architecture.md`, `agent_docs/project/specs/api-spec.yaml`, `agent_docs/generic/api-conventions.md`, `agent_docs/project/conventions.md`, deployment manifest (`wrangler.toml` / `serverless.yml` / platform equivalent) |
| **Writes** | `artifacts/code-review/review-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- **Implementation notes format compliance pre-check (mandatory before reviewing code):** Before reviewing any line of code, verify the developer's implementation notes include all mandatory sections defined in the developer output format (User Journey Map, Field Mapping Table, Runtime Dependency Register, Spec Compliance Checklist, Build Verification, Route-to-Component Verification Table). If any section is absent, return the artifact immediately with a list of missing sections and verdict FAIL. Do not proceed with code review until the implementation notes are format-compliant. This low-cost gate catches incomplete submissions early and ensures structured verification surfaces are populated.
- Review logic correctness and edge cases
- Verify adherence to architecture, API conventions, and coding standards
- **Verify implementation conforms to `api-spec.yaml`** — check endpoint paths, request/response shapes, enum values, and error formats match the spec exactly
- **Check enum values in frontend and backend use identical casing** — flag any mismatch as Critical
- **Check cross-service env vars are documented, name-matched, and environment-appropriate** — for every `import.meta.env.VITE_*` or `process.env.NEXT_PUBLIC_*` reference in the frontend, verify: (1) the exact name appears in `agent_docs/project/deployment.md`; (2) no silent hardcoded fallback exists for a required env var (e.g. `VITE_API_BASE_URL || 'https://...'` is a Major finding — a missing required env var must fail loudly, not fall through to a wrong host); (3) **environment-context verification:** for any configuration value referencing an external service domain (API base URLs, CDN origins, CSP directives in `vercel.json` or `_headers`, OAuth redirect URIs, env var fallback values), verify the value is appropriate for the deployment environment the file governs — any hardcoded production domain appearing as an env var fallback value, in a CSP directive, or in a config file active in a non-production environment is an automatic **Critical** finding ("production URL in non-production context"); treat any env var read with a production-domain fallback (e.g. `?? 'https://api.example.com'`) as Critical regardless of the variable's name. Also verify CORS origins and API base URLs are documented with the correct deployed values.
- **Env var optionality check:** For every env var with `.min(1)`, `required()`, or no default in the validation schema (Zod, Joi, etc.), classify it as: (a) **core infrastructure** (database URL, JWT secret, Redis URL) — these may be required with no default; or (b) **third-party integration** (HubSpot, Stripe, SendGrid, analytics, etc.) — these MUST have a `.default('PLACEHOLDER_...')` or `.optional()` to allow the application to start in environments where that integration has not been configured. Any required env var for a non-core third-party service with no default is a **Major** finding — it will crash the application in any environment where that integration is not set up.
- **Verify service/controller field names match both `api-spec.yaml` AND the data model** — for every ORM/database query, check that field names used in select, filter, create, and update clauses exist in the data model (e.g. Prisma schema, SQLAlchemy model, JPA entity); flag any non-existent field as Critical
- **Verify client-side data types match `api-spec.yaml`** — for any hand-written interface, DTO, or type definition (TypeScript interface, Java POJO, Python dataclass, etc.) representing an API response, check every property name against the corresponding spec schema; flag any mismatch as Critical; if using a generated client (`@hey-api/openapi-ts` or equivalent), verify it is regenerated from the latest spec
- **Frontend route/link coverage** — for every navigation link (`<Link>`, `router.push()`, `redirect()`, `<a href>`, or framework equivalent) in the frontend, verify a corresponding route/view file exists; flag any link whose destination route is not built as Critical
- **Runtime dependency wiring** — for every handler that reads a runtime-injected value (middleware-populated properties, dependency injection, context objects), verify the source is registered in the application bootstrap; flag any missing registration as Critical
- **Infrastructure binding verification (serverless/edge projects):** Read the deployment manifest (`wrangler.toml`, `serverless.yml`, or platform equivalent) and verify that every binding name referenced in application code (`c.env.X`, `env.X`, `context.env.X`) matches a binding declared in the manifest. Flag any mismatch as Critical — an undeclared binding causes a silent runtime failure in all environments.
- **Mockup fidelity check (frontend projects):** Compare rendered component/page output against the corresponding mockup files in `requirements-include-files/`. Flag deviations in layout, spacing, colours, typography, or element ordering as Major findings. If a `uiux-reviewer` review exists, verify its design instructions were followed
- **Cross-cutting requirements coverage pass:** Before closing the review, identify all documented cross-cutting requirements (i18n, RBAC, audit logging, accessibility, etc.) from `agent_docs/project/specs/requirements.md` or `architecture.md`. For each, search the codebase for evidence of end-to-end adoption in consuming components (not just infrastructure/config files). Flag any requirement where the infrastructure exists but component-level integration is absent or below a reasonable threshold as a Major finding. For i18n: grep all `.tsx`/`.jsx` files for `useTranslation` or `t(` and report the adoption rate; a rate below 80% with hardcoded strings visible is a Major finding
- Check test coverage is adequate
- Flag technical debt, maintainability issues, and risks
- **Build verification (mandatory before PASS):** Run `npm run build` (or the project's build command) and `npx tsc --noEmit` on the submitted code. If either fails, the review verdict is automatically **FAIL** — do not proceed with code review findings until the build passes. Include the build result in the review artifact under "Build Verification." Before reviewing code, verify the developer's implementation notes contain a "Build Verification" section with terminal output evidence. If this section is absent or deferred to "Next Steps", return the artifact immediately with verdict FAIL — do not proceed with review.
- **Docker build context verification (mandatory for containerised services):** Read `.dockerignore` and verify it does not exclude files referenced in the Dockerfile build steps (e.g. `tsconfig.json`, migration files, `.env.example` used as a template). Flag any `.dockerignore` exclusion of a build-required file as **Critical**.
- **CI workflow verification (mandatory):** Read all GitHub Actions workflow files (`.github/workflows/*.yml`). For every CI step (lint, format check, test, build, deploy), confirm: (1) the command it runs, (2) whether it was verified as part of this review's build verification step, (3) whether it would pass given the current codebase. Any CI step that enforces a check not verified during review (e.g. `prettier --check` when formatting was not verified) is a **Major** finding.
- **Route-to-Component Verification (mandatory, frontend projects):** Verify the developer's Route-to-Component Verification Table is present in the implementation notes and is accurate. Spot-check at least 3 routes by independently running the grep commands listed as evidence. If the table is missing, incomplete, or evidence does not match, flag as **Critical**
- **Placeholder / stub / dead-code detection (mandatory):** Grep the entire `src/` tree for patterns indicating non-functional implementations: `// Placeholder`, `// TODO`, `// HACK`, `// FIXME`, `setSubmitted(true)` or equivalent state-only form handlers with no API call, `console.log("submitted")` as a substitute for real submission logic, empty `catch` blocks that swallow errors silently, and event handlers that `preventDefault()` without performing any action. For every form `onSubmit` handler, verify it makes an actual API call (via the generated client or an approved service function) — a handler that only updates local state without sending data to a backend is a **Critical** finding. Any `// Placeholder` or `// TODO` comment in submitted code is an automatic **Major** finding — the developer should have raised a change request instead of silently stubbing

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
