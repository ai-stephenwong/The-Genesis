# Retrospective — 2026-03-21 00:00

## Round: 1

## Trigger

**Bug batch:** Deficiencies surfaced across the full initial pipeline review cycle — no formal bug-report artifact was raised prior to this retrospective; the trigger is the combined set of critical and major findings from all review stages.

**Source artifacts:**
- `artifacts/code-review/review-20260321-0000.md` — 5 Critical, 11 Major, 8 Minor, 4 Nit
- `artifacts/ux-review/review-20260321-0000.md` — 4 Critical, 10 Major, 9 Minor, 5 Nit
- `artifacts/security/audit-20260321-0000.md` — 5 Blockers, 6 HIGH, 7 MEDIUM, 4 LOW
- `artifacts/compliance/compliance-20260321-0000.md` (initial, pre-fix) — 5 Blocking issues, 15 non-blocking tech debt items
- Fix artifacts: `bugfix-review-20260321-0000.md`, `bugfix-security-20260321-0000.md`, `bugfix-compliance-20260321-0000.md`
- `artifacts/compliance/compliance-20260321-0001.md` — PASS (all blockers resolved)

**Implicated agents:** developer, code-reviewer, tester, ux-reviewer, security-auditor, compliance-officer

**Note on self-reviews:** The standard retrospective process calls for each implicated agent to produce a self-review artifact before the retrospective-analyst runs. No self-review artifacts were collected for this round — the orchestrator triggered the retrospective directly from the review pipeline artifacts. Scoring below is based on independent observation of each agent's output vs. their defined responsibilities in `agent-roles.md`. Self-reviews should be collected in future rounds.

---

## Per-Agent Scores

| Agent | Round | Score (1–5) | Key Finding |
|---|---|---|---|
| developer | R1 | 2 | Systemic field-name mismatches across 6 API service calls, KV binding misconfiguration, 15 missing endpoints, missing server-side sanitisation, missing auth rate limits, debug token log in production |
| code-reviewer | R1 | 4 | Found all 5 critical spec violations and most in-scope defects; missed the missing server-side sanitisation gap in `content.ts` |
| tester | R1 | 3 | Substantial new tests written; all three repos remained below 80% coverage; mandatory auth integration test and cross-service smoke tests not written |
| ux-reviewer | R1 | 5 | Comprehensive 28-finding report; correctly prioritised critical WCAG failures; systemic i18n gap correctly identified as global issue |
| security-auditor | R1 | 5 | All 5 blockers found with correct OWASP categorisation; infrastructure binding mismatch identified before any deployment |
| compliance-officer | R1 | 4 | Found BLOCK-004 (wrong demo URL) that no upstream agent caught; synthesised upstream findings correctly; some findings were repetitions rather than novel synthesis |

---

## Agent Performance Detail

---

### developer

#### Independent Observations

The developer demonstrated genuine expertise in security-critical cryptographic areas: PBKDF2-SHA256 at 600,000 iterations, AES-256-GCM TOTP secret encryption, constant-time HMAC verification via Web Crypto, refresh token rotation, maker-checker self-approval prevention, and comprehensive CORS implementation. These are non-trivial Workers-runtime implementations and are well above the baseline.

However, against this technical capability, the volume and class of defects in the initial build is notable. The failures are not random oversights — they cluster around responsibilities that are explicitly defined in `agent-roles.md`:

1. **Field Mapping Table violations (CR-003, CR-004, CR-009, CR-010, CR-011, CR-012):** Six separate API service layer calls in `omnichat-v4-cms-web/src/services/api.ts` sent field names that did not match the API spec — `mfa_session_token` instead of `mfaSessionToken`, `fields` instead of `value/fieldType`, `requires_mfa` instead of `status`, missing `setupToken`, `scheduled_at` instead of `scheduledAt`, `name`/`lang_access`/`is_active` instead of `displayName`/`langScope`/`isActive`. The Field Mapping Table responsibility in the developer role exists precisely to prevent this class of error. The table was either not produced or not used to cross-check the service layer.

2. **Runtime Dependency Wiring failure (SEC-001):** `wrangler.toml` declared `RATE_LIMIT_KV`, `SESSION_KV`, and `CONTENT_CACHE_KV`. All application code referenced `KV_STORE`, a binding that does not exist. The "Runtime Dependency Wiring Verification" responsibility requires the developer to verify every runtime-injected dependency is registered in the application bootstrap. This check would have immediately revealed the mismatch. Its absence means rate limiting, session storage, and content caching were all silently non-functional.

3. **Spec Compliance Checklist gaps (CR-006, CR-002, CR-005):** Fifteen API endpoints defined in `api-spec.yaml` were not implemented. The Spec Compliance Checklist item "Every new endpoint exists in api-spec.yaml (or a change request is PENDING APPROVAL)" implies the inverse — every spec endpoint must be implemented. A password-reset JWT was logged to production output (`console.info('[DEV] Password reset token:', resetToken)`) with no environment gate. The QR code response was a `data:text/plain` stub despite the spec defining an SVG data URI; the `otpauth` package was listed as a dependency but never called.

4. **Security omissions within developer scope (SEC-002, SEC-003, SEC-004, BLOCK-004):** The save-draft content endpoint accepted HTML with no server-side sanitisation despite the `RichText.tsx` comment claiming "server-side sanitised before storage." The forgot-password endpoint lacked rate limiting despite the project implementing `checkAuthRateLimit` elsewhere. MFA verify had no per-user attempt counter. The canonical demo URL `/book-a-demo/` was used incorrectly as `/book-demo/` in 11 locations across 9 files — this conflicts with Master Decision #5 in the requirements analysis.

5. **i18n wiring not completed (UX-002 systemic gap):** `react-i18next` was initialised and locale JSON files were created, but no component called `useTranslation()` or `t()`. The i18n infrastructure was built but never wired in — a significant omission for a project explicitly requiring multi-locale support across 7 locales including CJK.

**Mitigating factors:** The developer correctly flagged several known limitations in the implementation notes (no CI, Resend TODO, workflow path mismatch pending change request). Some UX accessibility issues (focus traps, ARIA patterns) are outside the developer's defined reads contract (uiux-standards.md is not in the developer's reads — see Framework Gaps). The QR code package substitution (`qrcode-svg` for `qrcode`) demonstrates good Workers-runtime awareness.

#### Root Cause Attribution: Agent Failure / Framework Gap

Mixed — primarily agent failure with one framework gap component.

**Agent failure:** Field mapping table not used, runtime dependency wiring not verified, spec compliance checklist not completed, password logging, missing sanitisation, missing rate limits, wrong demo URL. All of these are explicitly within the developer's defined responsibilities.

**Framework gap:** UX-002 (i18n `t()` wiring) and UX-003/UX-004 (focus traps) — the developer contract does not include `uiux-standards.md` in its reads, so the developer had no explicit mandate to verify these patterns. This is a gap in the framework rather than solely an agent failure (see PROP-01).

#### Score: 2

**Rationale:** Multiple defined responsibilities were missed across several distinct categories — field mapping, runtime dependency wiring, spec compliance, security patterns, and requirements fidelity. The defects are high-severity (5 security blockers, 5 critical code review findings, 5 compliance blockers) and many were preventable by following the defined pre-submission checklists. Score of 2 reflects significant gaps with partial credit for strong cryptographic implementation and honest documentation of known limitations.

#### Self-Review Quality

No self-review artifact was collected for this round. Unable to assess.

---

### code-reviewer

#### Independent Observations

The code review was thorough and structured. The reviewer found all five critical spec-compliance violations (CR-003, CR-004, CR-009, CR-010, CR-011 — frontend field name mismatches), the password logging vulnerability (CR-002), the scheduler concurrency bug (CR-001), the QR code stub (CR-005), and the 15 missing API endpoints (CR-006). They also identified the cursor pagination bug (CR-007), the RBAC over-guard on `GET /v1/users/me` (CR-008), the missing `@hono/zod-validator` package (CR-015), and the env var naming inconsistency (CR-016). The "What Was Done Well" section was substantive and accurate.

**One in-scope miss identified:** The save-draft endpoint in `src/omnichat-v4-api/src/routes/content.ts` accepted `value: z.string().nullable()` for rich-text fields and stored it directly to the database with no sanitisation. The `RichText.tsx` component contained a comment claiming "server-side sanitised before storage" — a false claim that a thorough code reviewer reading both files should have caught. The code reviewer reads `src/` and therefore had access to both files. This gap was subsequently caught by the security auditor (SEC-002). It is an in-scope miss.

The code reviewer correctly did not attempt to evaluate the infrastructure binding mismatch (SEC-001) — `wrangler.toml` is not in their reads contract, so that is a framework gap rather than a code review failure.

#### Root Cause Attribution: Agent Failure / Framework Gap

Primarily strong performance. The one miss (missing server-side sanitisation in `content.ts`) is an agent failure — it was in-scope and findable by reading both the API route and the consuming widget.

#### Score: 4

**Rationale:** Comprehensive review that found all critical spec violations and most in-scope defects. The report directly led to fixes for 12 critical/major issues. One in-scope miss (server-side sanitisation gap) prevents a 5. Strong "What Was Done Well" analysis and structured severity classification.

#### Self-Review Quality

No self-review artifact was collected for this round. Unable to assess.

---

### tester

#### Independent Observations

The tester wrote 13 new test files covering significant critical paths: auth middleware (JWT extraction, RBAC, lang scope), rate limiting and lockout logic, error handler envelope, audit log service, content workflow state machine, public API contracts, health endpoint, MFA Setup Wizard 3-step flow, RequireMfa guard, useAuth hook, authStore Zustand machine, useLocale hook, and CJK i18n rendering.

These are the correct areas to test — auth, RBAC, and content workflow are the highest-risk paths. The test quality described in the results artifact is good: real assertions, not stubs.

**Coverage shortfall:** All three repos remained below the 80% minimum after the tester's pass (API ~55-60%, web ~45%, CMS ~45%), and required a further pass in the compliance bugfix cycle to reach 80%. The qa.md standard is unambiguous: "Unit + integration: minimum 80% line coverage." This shortfall is an agent failure.

**Mandatory auth integration test not written:** The tester role definition explicitly requires: "For any project with authentication, write the full auth integration test before all others — covering: login → session/token storage → authenticated request → token refresh → logout." This test was not written. The tester acknowledged in the results artifact that "Live integration tests for auth routes require a mock KV store and Drizzle schema fixtures" — but the requirement does not allow the absence of a test environment to permanently waive the requirement. Mock KV and Drizzle fixtures are achievable with Vitest and the Workers test runtime.

**Mandatory cross-service smoke tests not written:** The tester role also requires "at least one full frontend → API → database round-trip" and "CORS preflight from the deployed frontend origin" smoke tests. Neither was produced.

**Mitigating factor:** The developer acknowledged "no CI yet" in their implementation notes, and no test database or workers runtime test infrastructure was set up by the devops-engineer at the point of the tester's pass. This is a legitimate blocking constraint for live integration tests. However, the tester should have documented this as a blocker and flagged it to the orchestrator rather than treating it as an implicit acceptance.

#### Root Cause Attribution: Agent Failure / Framework Gap

Agent failure — coverage below 80%, mandatory auth integration test absent, and mandatory cross-service smoke tests absent. The constraint around CI infrastructure explains but does not excuse the gaps; the tester should have raised these as blockers.

#### Score: 3

**Rationale:** Substantial new test coverage written across the highest-risk paths. Root causes were identified correctly in the results artifact. However, three explicitly defined responsibilities were not fulfilled: 80% coverage minimum, auth integration test first, and cross-service smoke tests. The honest acknowledgement of gaps in the results artifact is noted positively.

#### Self-Review Quality

No self-review artifact was collected for this round. Unable to assess.

---

### ux-reviewer

#### Independent Observations

The UX review was comprehensive: 28 findings across 4 critical, 10 major, 9 minor, and 5 nit categories. All four critical findings are genuine WCAG 2.1 AA failures with specific file and line references, correct standard citations, and actionable recommendations.

Notable strengths:
- Correctly identified UX-002 (hardcoded English strings across all 33 widgets) as a systemic gap, not 33 individual findings — this is the correct abstraction.
- Accurately mapped the focus trap requirement for both the public website lightbox (UX-003) and the CMS add-widget dialog (UX-004).
- Identified UX-007 (ProfilePage dark-mode colours in a light CmsLayout) which is a near-invisible contrast failure.
- Identified UX-027 (CmsLayout import inconsistency causing a TypeScript/runtime error) — a code correctness issue that fell through code review.
- The "What Was Done Well" section accurately recognised 12 genuinely strong implementation choices.

No meaningful misses were identified when cross-referencing the findings against the final compliance report's tech debt list (TD-013, TD-014 are subsets of UX findings; no UX issues appear in the compliance report that were not already in the UX review).

#### Root Cause Attribution: Agent Failure / Framework Gap

No agent failure identified. All findings reflect in-scope responsibilities executed correctly.

#### Score: 5

**Rationale:** All defined responsibilities fulfilled. The review was precise, well-evidenced, correctly severity-ranked, and identified issues across the full scope (web app, CMS frontend). The systemic i18n gap abstraction (UX-002) prevented the review from being diluted by 33 repetitive line-level findings — this is exactly the quality expected of the role.

#### Self-Review Quality

No self-review artifact was collected for this round. Unable to assess.

---

### security-auditor

#### Independent Observations

The security audit found all five critical blockers with correct OWASP Top 10 categorisations and specific code-level evidence:

- **SEC-001** (KV binding mismatch): Correctly identified as a silent runtime failure that disabled rate limiting, session storage, and content caching — with precise evidence from both `wrangler.toml` and `env.ts`.
- **SEC-002** (Stored XSS via dangerouslySetInnerHTML): Correctly traced the full path from CMS editor → API save without sanitisation → public website render, and identified the additional `allow-same-origin` sandbox escape vector in `CustomHtmlEmbed`.
- **SEC-003** (No rate limit on forgot-password): Correctly calculated the abuse surface (100 req/min per IP under global limit = sufficient for email enumeration).
- **SEC-004** (No MFA brute-force protection): Correctly identified both the setup/confirm and ongoing verify endpoints as unprotected.
- **SEC-005** (Audit log cursor direction): Correctly identified the `gt` vs `lt` mismatch against the `DESC` sort direction and correctly framed it as a security monitoring failure (broken audit log pagination = inaccessible forensic evidence).

The security auditor also correctly found SEC-006 (PII in audit log), SEC-007 (MFA re-enrolment without credential validation), SEC-009 (settings endpoint accessible to all authenticated users), and SEC-016 (CMS audit API calling wrong path).

The password reset token logging (CR-002) was caught by the code reviewer. The security audit artifact read was truncated at 100 lines; it cannot be confirmed whether the security auditor independently found this same issue. No credit deduction is applied for an unverifiable overlap.

#### Root Cause Attribution: Agent Failure / Framework Gap

No agent failure identified. All defined responsibilities were fulfilled at a high standard.

#### Score: 5

**Rationale:** All blockers found. Infrastructure-level vulnerability (KV binding mismatch) identified before any deployment — this required reading beyond `src/` into `wrangler.toml`, which the security-auditor correctly did as part of the "full codebase — plus all infrastructure configs and CI/CD workflows" scope. Detailed, precise findings with specific file/line evidence across all five BLOCKER items.

#### Self-Review Quality

No self-review artifact was collected for this round. Unable to assess.

---

### compliance-officer

#### Independent Observations

The compliance officer synthesised findings from all upstream agents and produced the final gate report. Key contributions:

- **BLOCK-001** (missing CSP header): Carried forward correctly from CR-013 and SEC-011.
- **BLOCK-002** (client-side DOMPurify missing): Correctly identified as a defence-in-depth gap separate from the server-side sanitisation finding — requires both layers.
- **BLOCK-003** (GET /v1/settings/languages missing role guard): The security bugfix (SEC-009) added a role guard to `GET /v1/settings` but left `GET /v1/settings/languages` unguarded — the compliance officer correctly caught this gap that slipped through the security bugfix pass.
- **BLOCK-004** (wrong demo URL `/book-demo/`): This was not found by the code reviewer or security auditor. The compliance officer identified it by cross-checking the canonical URL in the requirements analysis (Master Decision #5) against the source code — exactly the cross-artifact synthesis the role is defined to perform.
- **BLOCK-005** (test coverage below 80%): Correctly applied the qa.md 80% minimum as a blocking condition and quantified the gap per repo.

The 15 non-blocking tech debt items (TD-001 to TD-015) were correctly catalogued with accurate traceability to source findings. The deployment readiness statement was precise in distinguishing staging clearance from production readiness.

**Minor gap:** Several TD items (TD-001 through TD-012) are direct repetitions of code-review and security-audit findings, numbered and listed without additional compliance-level analysis. The compliance officer's synthesis value is highest where it adds cross-artifact insight (BLOCK-003, BLOCK-004) — the TD list would benefit from grouping by risk category and owner rather than sequential listing.

#### Root Cause Attribution: Agent Failure / Framework Gap

No significant agent failure. The minor gap (repetitive TD listing without additional synthesis) is a quality note, not a responsibility failure.

#### Score: 4

**Rationale:** Found BLOCK-004 through genuine cross-artifact synthesis that no upstream agent caught. Correctly identified the BLOCK-003 gap that slipped through a prior bugfix. Clear, precise deployment readiness statement. Minor deduction for TD list being primarily a restatement of upstream findings rather than novel compliance-level analysis.

#### Self-Review Quality

No self-review artifact was collected for this round. Unable to assess.

---

## Framework Gaps Identified

| # | Gap description | Proposed addition to agent-roles.md |
|---|---|---|
| FG-01 | Developer does not read `uiux-standards.md` — UX/accessibility patterns (i18n `t()` wiring, focus traps, ARIA patterns) are not in the developer's mandatory reads, leaving them without an explicit standard to implement against | Add `agent_docs/generic/uiux-standards.md` to developer Reads for frontend projects; add responsibility to verify accessibility patterns before submission (see PROP-01) |
| FG-02 | No agent is explicitly responsible for cross-verifying infrastructure binding declarations (e.g. `wrangler.toml` KV namespaces) against application code binding references — the devops-engineer writes the config; the developer writes the code; no role checks both together | Add binding cross-check to developer Spec Compliance Checklist and to code-reviewer responsibilities (see PROP-02 and PROP-03) |
| FG-03 | Developer does not read `security-checklist.md` — authentication security patterns (rate limiting on all auth endpoints, sanitisation of user-supplied HTML before storage) are not in the developer's explicit reads, creating a systematic gap between implementation and the security standard | Add `agent_docs/generic/security-checklist.md` to developer Reads; add pre-submission responsibility to check security-checklist items within feature scope (see PROP-04) |
| FG-04 | No explicit requirement for the orchestrator to collect agent self-reviews before triggering the retrospective-analyst — this round ran without self-reviews, reducing the quality of the retrospective and removing the self-assessment accountability mechanism | Add an orchestrator gate: self-reviews must be collected from all implicated agents before the retrospective-analyst is spawned (see PROP-05) |

---

## SDLC Improvement Proposals

### PROP-01 — Add `uiux-standards.md` to developer reads for frontend development

**Target:** `agent_docs/generic/agent-roles.md` — developer — Reads contract and Responsibilities

**Proposed change — Reads:**
Add `agent_docs/generic/uiux-standards.md` to the developer's Reads table, conditional on the project having a frontend component.

**Proposed change — Responsibilities:**
Add the following bullet after the existing i18n/a11y-adjacent items:

> **Accessibility and i18n pre-submission check (frontend projects):** Before marking any frontend component or page complete, verify against `uiux-standards.md`: (1) all user-facing strings (button labels, aria-labels, placeholders, error messages) pass through `t()` from the project's i18n library — no hardcoded string literals in production components; (2) all modal dialogs and disclosure overlays implement a focus trap: focus moves into the dialog on open, cycles within the dialog on Tab/Shift+Tab, and returns to the trigger element on close; (3) all interactive elements use correct ARIA patterns (no role conflicts, no nested interactive elements). Document compliance in implementation notes under "Accessibility Compliance."

### PROP-02 — Add infrastructure binding cross-check to developer Spec Compliance Checklist

**Target:** `agent_docs/generic/agent-roles.md` — developer — Spec Compliance Checklist section

**Proposed change:**
Add the following item to the Spec Compliance Checklist:

> `- [ ] All runtime bindings referenced in application code (e.g. `c.env.BINDING_NAME`, `env.BINDING_NAME`, `process.env.BINDING`) match the binding declarations in the deployment manifest (`wrangler.toml`, `serverless.yml`, `fly.toml`, etc.) exactly — no name mismatches, no bindings referenced in code but absent from the manifest`

### PROP-03 — Add infrastructure binding verification to code-reviewer responsibilities

**Target:** `agent_docs/generic/agent-roles.md` — code-reviewer — Reads contract and Responsibilities

**Proposed change — Reads:**
Add deployment config files to the code-reviewer's Reads: `wrangler.toml` / `serverless.yml` / equivalent platform deployment manifest.

**Proposed change — Responsibilities:**
Add the following bullet:

> **Infrastructure binding verification (serverless/edge projects):** For projects using Cloudflare Workers, AWS Lambda, or equivalent serverless runtimes, read the deployment manifest (`wrangler.toml`, `serverless.yml`) and verify that every binding name referenced in application code (`c.env.X`, `env.X`, `context.env.X`) matches a binding declared in the manifest. Flag any mismatch as Critical — an undeclared binding causes a silent runtime failure in all environments.

### PROP-04 — Add `security-checklist.md` to developer reads and pre-submission responsibilities

**Target:** `agent_docs/generic/agent-roles.md` — developer — Reads contract and Responsibilities

**Proposed change — Reads:**
Add `agent_docs/generic/security-checklist.md` to the developer's Reads.

**Proposed change — Responsibilities:**
Add the following bullet after the existing security-adjacent items:

> **Security checklist pre-submission (per feature):** Before marking any feature complete, run through the security-checklist.md items relevant to the feature scope. At minimum for every feature touching auth, input handling, or data storage: (1) rate limiting is applied to all auth endpoints (login, registration, password reset, MFA verify, MFA setup confirm); (2) all user-supplied HTML content is sanitised server-side before storage using an allowlist sanitiser — a comment claiming sanitisation is insufficient, the sanitisation function must exist and be called in the route handler; (3) no credentials, tokens, or PII are written to logs at any level (debug, info, warn, error) without an explicit environment gate that excludes staging and production. Document compliance in implementation notes under "Security Compliance."

### PROP-05 — Require self-reviews before retrospective-analyst is spawned

**Target:** `agent_docs/generic/agent-roles.md` — retrospective-analyst — How the retrospective cycle works

**Proposed change:**
Add an explicit orchestrator gate to the retrospective cycle description:

> **Orchestrator gate — self-reviews required:** The retrospective-analyst MUST NOT be spawned until a self-review artifact has been received from every implicated agent. If an agent fails to produce a self-review within the allocated time (or if spawning a self-review is not possible because the agent instance is no longer available), the orchestrator must note the absence in the retrospective trigger and proceed with independent observation only — but the gate must not be silently skipped. The absence of a self-review reduces the quality score ceiling for that agent's self-review dimension.

---

## Score History (all rounds on this bug batch)

| Agent | Round 1 | Round 2 | Trend |
|---|---|---|---|
| developer | 2 | — | — |
| code-reviewer | 4 | — | — |
| tester | 3 | — | — |
| ux-reviewer | 5 | — | — |
| security-auditor | 5 | — | — |
| compliance-officer | 4 | — | — |

---

## Overall Process Health: 3

**Rationale:** The pipeline's review stages (code-reviewer, ux-reviewer, security-auditor, compliance-officer) functioned at a high standard and collectively caught all critical defects before staging deployment — this is the intended safety net. However, the initial developer build carried an unusually high defect density: 5 security blockers, 5 critical code review findings, 4 critical UX violations, and 5 compliance blocking issues, requiring three separate bugfix passes before the compliance gate passed. A well-functioning SDLC should catch most of this at the developer stage, not downstream.

The framework has three identified gaps (uiux-standards.md not in developer reads, no infrastructure binding cross-check responsibility, security-checklist.md not in developer reads) that directly explain several of the highest-severity developer failures. Addressing these gaps via the proposals above is expected to shift the catch-point left — from the review stages to the developer stage — which reduces cycle time and fix cost.

Score of 3 reflects: review pipeline working correctly (positive), developer defect density unacceptably high (negative), framework gaps identified and addressed via proposals (recovery path clear).

---

## Sign-off: retrospective-analyst — 2026-03-21 00:00

## PILOT STATUS
STATUS: COMPLETE
GATE: (omit — retrospective-analyst does not block the pipeline)
ARTIFACTS: artifacts/retrospective/retrospective-20260321-0000.md
