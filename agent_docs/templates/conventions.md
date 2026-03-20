# Project Conventions — [Project Name]

> Company-wide API conventions and security rules are in `agent_docs/generic/`.
> This file captures only project-specific rules and overrides.

## Conflict Resolutions

<!-- Agent instruction: When any conflict between project requirements and company standards arises
     (API conventions, pagination style, token expiry, rate limits, security exceptions, etc.),
     stop and follow the Standards Conflict Resolution Policy in CLAUDE.md. Record every decision
     here — even when the company standard is kept unchanged. Permanent audit trail; never delete. -->

_No conflicts logged yet._

<!--
| Conflict | Original | Replaced by | Reason |
|---|---|---|---|
| CONFLICT-01 | ~~rejected option~~ | **chosen option** | reason |
-->

---

## Naming

<!-- Any naming rules specific to this project beyond the company standard.
     Example: "All background job class names must end in 'Job': SendWelcomeEmailJob" -->

## Project-Specific API Rules

<!-- Deviations from or additions to generic/api-conventions.md.
     Example: "This project uses cursor-based pagination instead of page/limit." -->

## Environment Variables

- Backend vars documented in `backend/.env.example`
- Frontend vars documented in `frontend/.env.example`
- Naming convention: `[SERVICE]_[RESOURCE]_[DETAIL]` — e.g. `DB_PRIMARY_URL`, `REDIS_CACHE_URL`

## Domain / Business Rules

<!-- Rules Claude must always respect when generating code for this project.
     Example: "A subscription cannot be downgraded within 30 days of an upgrade."
     Example: "All financial transactions must be idempotent — use idempotency keys." -->

## Data Rules

<!-- Schema or data-handling constraints specific to this project.
     Example: "Never hard-delete user records — use soft deletes (deletedAt timestamp)."
     Example: "All user PII must be stored in the `pii` schema, not the default schema." -->

## What NOT to Do

<!-- Anti-patterns or past mistakes to avoid in this project.
     Example: "Do not use cascade deletes in the ORM — clean up relations explicitly."
     Example: "Do not use the legacy /v0/ endpoints — they are deprecated." -->

## Third-Party Constraints

<!-- Any constraints imposed by client-chosen tools, legacy systems, or integrations.
     Example: "The CRM API is rate-limited to 100 requests/minute — always queue bulk operations." -->
