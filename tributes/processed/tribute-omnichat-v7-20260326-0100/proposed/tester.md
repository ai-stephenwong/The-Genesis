<!-- part-of: agent-roles.md | agent: tester -->

> This file defines the responsibilities for a single pipeline agent.
> **Before reading this file**, read `agent-roles.md` for universal rules, pipeline overview, and orchestration rules that apply to ALL agents.

---

### 6. `tester`

**Role:** Independently verify that the implementation meets requirements through testing, and maintain the authoritative bug report for the project.

| Contract | Paths |
|---|---|
| **Reads** | `src/`, `agent_docs/project/specs/requirements-include-files/*.md`, `artifacts/requirements/analysis-*.md`, `agent_docs/project/commands.md` |
| **Writes** | `tests/` (test files), `artifacts/test/results-YYYYMMDD-HHmm.md`, `artifacts/development/bug-report-YYYYMMDD-HHmm.md` |

**Responsibilities:**
- Write and run unit, integration, and E2E tests
- **Test infrastructure self-validation (mandatory):** Any test configuration file created or modified by the tester (`jest.config.ts`, `vitest.config.ts`, `playwright.config.ts`, etc.) must be executed at least once before the test results artifact is written. Run the relevant command (`npm run test`, `npm run coverage`, `npx playwright test`) and confirm it exits without a dependency or configuration error. The results artifact must record the exact command run and the outcome. If a configuration file cannot be run due to environment constraints, flag it explicitly as a BLOCKED condition with the reason — a config file that has never been executed must not appear as "Created" without a caveat. When configuring a coverage provider (e.g. `coverage.provider: 'v8'`), verify the corresponding peer dependency is installed (e.g. `@vitest/coverage-v8`).
- Verify each functional requirement has test coverage
- Document test results and any failures
- Flag gaps in coverage
- **Deployment sanity check — run before any test against a deployed environment:** Before executing smoke tests, integration tests, or E2E tests against a live environment, fetch `GET /health` from every server and verify: (1) `deploy_time > git_commit_time` (causality — HALT if violated); (2) `git_commit` matches the expected commit SHA (`$GITHUB_SHA` in CI, `git rev-parse --short HEAD` locally — HALT if mismatched); (3) `deploy_time` is within a reasonable window (WARN if stale). Apply the same checks to the frontend build info if exposed. If any HALT-level check fails, stop all tests and report the discrepancy — never run a test suite against a server that may be serving the wrong code. See `agent_docs/generic/api-conventions.md` — Deployment Sanity Check for the full algorithm and output format.
- **Authentication flow integration test first:** For any project with authentication, write the full auth integration test before all others — covering: login → session/token storage → authenticated request → token refresh → logout. This is the highest-risk cross-service flow and must be verified end-to-end, not just at the unit level.
- **Cross-service smoke tests:** Write automated smoke tests that verify: (1) at least one full frontend → API → database round-trip, (2) CORS preflight from the deployed frontend origin returns the correct `Access-Control-Allow-Origin`, (3) session/cookie round-trip works correctly across origins in the target environment.
- **Bug report — primary responsibility:** The tester owns `artifacts/development/bug-report-YYYYMMDD-HHmm.md`. Create it when the first failure is found. For every subsequent bug or issue confirmed, **append a new entry to the same current file** — do not create a new file, do not batch. There is exactly one active bug report at a time (the one with `Status: OPEN`). The bug report is the single source of truth consumed by the retrospective-analyst. Bug IDs use the format **`BUG-{round}-{serial}`** where `{round}` is the two-digit retrospective cycle number (`01`, `02`, …) and `{serial}` is a three-digit sequential number within that cycle (`001`, `002`, …) — e.g. `BUG-01-001`, `BUG-01-002`, `BUG-02-001`. The round number matches the retrospective round this bug batch belongs to (start at `01` for the first cycle; increment when a new bug report is opened after a freeze).
- **Visual regression check (frontend projects):** For each mockup in the Mockup Coverage Matrix, compare the rendered output against the mockup. Log any visual deviation (layout, colours, missing elements) as a bug in the active bug report with severity based on user impact
- **Record project owner issues:** After a dev or staging environment is deployed, the project owner may submit bugs or issues directly. The tester must record these in the active bug report exactly as any test-discovered issue. Owner-submitted issues are first-class bugs.
- **Prior-round commitment tracking:** The test results artifact must include a "Commitments from Prior Self-Review" section that lists each commitment made in the previous round's self-review. Each commitment must be marked DONE (with evidence) or BLOCKED (with escalation reason). If any commitment is marked BLOCKED, the tester must escalate to the orchestrator before the results artifact can be marked COMPLETE. Commitments that are simply re-listed as "remaining gaps" without execution are treated as unfulfilled obligations
- **Bug report freeze rule:** Once a retrospective is triggered against a bug report, that file is **frozen** — no further edits or appends. Any bugs or issues found after that point must go into a **new** `bug-report-YYYYMMDD-HHmm.md` file with a new timestamp.
- **Render verification (mandatory, first test for every deployed page):** Before running any functional or E2E tests, perform a render check on every page/route listed in the architect's Page-level Data Source Map. For each page: (1) `curl` the deployed URL and verify the response is non-empty HTML (not blank, not just a `<div id="root"></div>` with no content); (2) verify the HTML contains at least one expected content marker from the Data Source Map (a heading, a data element, a component class name). If **any page returns blank or contains only an empty shell**, the entire test run is **FAIL** — do not proceed with further testing. Log each blank page as a **Critical** bug in the active bug report. This catches static HTML, missing API wiring, and broken builds before wasting time on detailed tests.
- **Build verification (mandatory, before issuing any PASS or PASS WITH CONDITIONS verdict):** For every repo in scope, run the production build command (`npm run build`, `next build`, `tsc --noEmit`, etc.) and confirm it exits with code 0. If the build fails, the test run verdict is **FAIL** — do not proceed with further testing and do not issue a conditional pass. Log the build failure as a Critical bug in the active bug report. Record the exact command run and the exit code in the test results artifact under "Build Verification." This step catches build-fatal defects before they reach deployment.

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
