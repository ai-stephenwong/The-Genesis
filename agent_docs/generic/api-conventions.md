<!-- last-reviewed: 2026-03-17 | reviewed-by: Stephen Wong | next-review: 2026-09-17 -->

# API Conventions (Company Standard)

> These rules apply to all projects. Do not override without explicit approval.
> ISO 27001:2022 Annex A control references are noted as `[ISO 27001: X.XX]`.

## API-First Design (Mandatory)

All projects **must** follow API-first design. The OpenAPI 3.1 specification is the **single source of truth** for all API contracts.

### Rules

- The API spec (`agent_docs/project/specs/api-spec.yaml`) **must be written and approved before any implementation begins**
- The spec is owned by the `solution-architect` agent and reviewed by both frontend and backend leads before development starts
- Frontend **must** use a fully generated API client from the spec using `@hey-api/openapi-ts` — this generates both TypeScript types **and** typed fetch functions keyed by `operationId`; never hand-write service layer functions or types
- No manual `fetch()` / `axios` calls to API endpoints in the frontend service layer — every API call must go through the generated client
- Backend DTOs/validators **must** be generated from or validated against the spec using `openapi-generator` (Java) or equivalent
- Code that diverges from the spec is considered a **bug**, not a feature
- CI/CD must validate that the running API conforms to the spec (use `swagger-request-validator` or equivalent)

### API Spec Change Control (MUST NOT be violated)

The `api-spec.yaml` is a **controlled document**. No agent may modify it unilaterally during implementation.

If any agent discovers that a change to `api-spec.yaml` is needed during development or review:

1. **STOP** — do not modify `api-spec.yaml` or write code that deviates from the current spec
2. **Record** the proposed change in `artifacts/development/api-spec-change-requests-YYYYMMDD.md` with:
   - Which endpoint / field / schema needs to change
   - Why the change is needed (requirement gap, technical constraint, etc.)
   - Impact on frontend, backend, and any downstream consumers
3. **Wait** — the orchestrator will present all collected change requests to the project owner for approval
4. **Only after explicit approval** may the spec be updated and the implementation follow

**Change request format:**
```markdown
## Change Request — YYYY-MM-DD HH:mm
### Requested by: [agent name]
### Endpoint / Field: [e.g. POST /auth/register — role field]
### Current spec: [what the spec currently says]
### Proposed change: [what it should say]
### Reason: [why this is needed]
### Impact: [frontend / backend / consumers affected]
### Status: PENDING APPROVAL
```

This rule applies to **all agents** — developer, code-reviewer, tester, ux-reviewer, security-auditor. None may approve their own change requests.

### Enum & String Value Contract

- All enum values in the API **must** be `lowercase_snake_case` strings — never uppercase, never camelCase
- Enum values must be explicitly listed in the OpenAPI spec under `enum:` — no free-form strings for bounded value sets
- Frontend TypeScript enums/unions **must** use the exact string values from the spec — never independently define equivalent constants
- Example: if the spec defines `role: {enum: [candidate, employer]}`, the frontend must use `"candidate"` and `"employer"` — not `UserRole.CANDIDATE`

### API Spec Location

```
agent_docs/project/specs/
├── api-spec.yaml          ← OpenAPI 3.1 — primary contract (required)
├── requirements.md        ← requirements registry
└── design.md              ← UI/UX design references
```

---

## URL Structure

- Base path: `/api/v1/`
- Use nouns for resources, never verbs: `/users`, not `/getUsers`
- Kebab-case for multi-word segments: `/user-profiles`
- Nested resources (max 2 levels): `/users/{id}/orders`
- Actions that don't map to CRUD use a verb sub-resource: `POST /orders/{id}/cancel`

## HTTP Verbs

| Verb   | Use                                       | Idempotent |
|--------|-------------------------------------------|------------|
| GET    | Retrieve resource(s)                      | Yes        |
| POST   | Create a new resource                     | No         |
| PUT    | Replace a resource entirely               | Yes        |
| PATCH  | Partial update                            | No         |
| DELETE | Remove a resource                         | Yes        |

## Request / Response Rules

- All timestamps: ISO 8601 UTC — `2024-01-15T10:30:00Z`
- All IDs: strings (UUID v4 preferred) — never expose sequential integer IDs publicly
- Currency: integer cents — never floating point
- Boolean fields: `isActive`, `hasAccess` (never `active`, `access`)
- Nullable fields must be explicitly `null`, never omitted

## Pagination

Query params: `?page=1&limit=20` (default limit: 20, max: 100)

Response envelope:
```json
{
  "data": [],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 145,
    "totalPages": 8
  }
}
```

## Error Envelope

All errors must use this exact shape — do not deviate:
```json
{
  "error": {
    "code": "RESOURCE_NOT_FOUND",
    "message": "User with ID 123 was not found.",
    "details": {}
  }
}
```

- `code`: SCREAMING_SNAKE_CASE, machine-readable
- `message`: human-readable, suitable for logging (not necessarily shown to end users)
- `details`: optional structured info (e.g. field validation errors)

## HTTP Status Codes

| Status | When to use                                      |
|--------|--------------------------------------------------|
| 200    | Successful GET / PUT / PATCH                     |
| 201    | Successful POST — resource created               |
| 204    | Successful DELETE — no body                      |
| 400    | Validation error (client fault)                  |
| 401    | Not authenticated                                |
| 403    | Authenticated but not authorised                 |
| 404    | Resource not found                               |
| 409    | Conflict (e.g. duplicate email)                  |
| 422    | Business rule violation                          |
| 429    | Rate limit exceeded                              |
| 500    | Unexpected server error                          |

## Versioning

- Version in URL path: `/api/v1/`, `/api/v2/`
- Never remove fields from a version — add a new version instead
- Deprecation: add `Deprecation` response header with sunset date

## Health Endpoint

Every service must expose:
```
GET /health
→ 200 {
  "status": "ok",
  "version": "1.2.3",
  "git_commit": "abc1234f",
  "git_commit_time": "2026-03-22T08:30:00Z",
  "deploy_time": "2026-03-22T08:45:12Z",
  "uptime": 3600
}
```

| Field | Source | Description |
|---|---|---|
| `status` | hardcoded `"ok"` | Service is healthy and reachable |
| `version` | package.json / app constant | Semantic version of the deployed artifact |
| `git_commit` | env var `GIT_COMMIT` (injected by CI) | Short SHA of the deployed commit |
| `git_commit_time` | env var `GIT_COMMIT_TIME` (injected by CI) | ISO 8601 timestamp of the commit |
| `deploy_time` | env var `DEPLOY_TIME` (injected by CI) | ISO 8601 timestamp of when this deployment completed |
| `uptime` | runtime calculation | Seconds since process start |

`git_commit`, `git_commit_time`, and `deploy_time` are injected as environment variables by the CI/CD pipeline at deploy time (see devops-engineer responsibilities in `agent-roles.md`). If the env vars are absent (e.g. local dev), omit those fields or return `null` — never return placeholder strings.

**Frontend build info** — for Vite/Next.js frontends, inject the same values at build time as `VITE_GIT_COMMIT` / `NEXT_PUBLIC_GIT_COMMIT` etc. and expose them in an HTML `<meta name="build-info">` tag or a static `GET /build-info.json` endpoint so the deployment can be traced from the browser.

## Data Classification in Responses
`ISO 27001: 5.12, 5.13, 8.11`

APIs must not return data above the caller's classification clearance:

| Classification | Examples                                      | Rule                                              |
|----------------|-----------------------------------------------|---------------------------------------------------|
| Public         | Product names, public prices                  | Freely returnable                                 |
| Internal       | User display names, non-sensitive metadata    | Require authentication                            |
| Confidential   | Email addresses, phone numbers, addresses     | Require authentication + authorisation            |
| Restricted     | Passwords, tokens, payment details, health data | Never returned in full — mask or omit entirely  |

- Never return full credit card numbers, passwords, or secret keys in any response
- Mask sensitive fields where partial display is needed: `"card": "****1234"`
- Audit log all access to Confidential and Restricted data `[ISO 27001: 8.15]`

## Audit Logging Requirements
`ISO 27001: 8.15`

The following API actions must emit a structured audit log entry regardless of project:

| Action                                  | Log must include                                      |
|-----------------------------------------|-------------------------------------------------------|
| Successful / failed authentication      | userId (if known), IP, timestamp, outcome             |
| Access to Confidential / Restricted data | userId, resource type, resource ID, timestamp        |
| Create / update / delete of any record  | userId, resource type, resource ID, before/after diff |
| Privilege or role change                | actorId, targetUserId, old role, new role, timestamp  |
| Data export / bulk download             | userId, dataset, record count, timestamp              |
| Password / credential change            | userId, timestamp, IP                                 |

Audit log format (append to standard request log):
```json
{
  "audit": true,
  "action": "USER_DATA_ACCESSED",
  "actorId": "uuid",
  "resourceType": "User",
  "resourceId": "uuid",
  "timestamp": "2024-01-15T10:30:00Z",
  "ip": "1.2.3.4",
  "requestId": "X-Request-ID value"
}
```

## Sensitive Data Handling
`ISO 27001: 8.11, 8.12`

- Never log request bodies that may contain passwords, tokens, or PII
- Redact `Authorization`, `Cookie`, and `X-API-Key` headers from all logs
- Do not include sensitive fields in error `details` responses returned to the client
- Responses containing PII must not be cached by CDN or shared proxies (`Cache-Control: no-store`)
