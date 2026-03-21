# Retrospective — 2026-03-21 15:30

## Round: 2 (Deployment Round — distinct from Pipeline Run 1 code defects)

## Trigger
  Bug report: artifacts/development/bug-report-20260321-1530.md
  Implicated agents: solution-architect, devops-engineer, developer

---

## Per-Agent Scores

| Agent | Round | Score (1–5) | Key Finding |
|---|---|---|---|
| solution-architect | 2 | 2 | Platform Runtime Compatibility Matrix checked library existence in the runtime but not CPU budget compliance or inter-service routing compatibility — two Critical deployment failures resulted from architectural decisions that no downstream agent could detect |
| devops-engineer | 2 | 2 | IaC submitted with unresolved placeholders, platform-specific syntax errors, and no cloud resource pre-creation step — four distinct blockers on first deploy |
| developer | 2 | 2 | Both frontends submitted without a clean-build verification; wrong framework in vercel.json; missing packages; non-existent npm packages listed in dependencies |

---

## Agent Performance Detail

### solution-architect

#### Independent Observations

The self-review is thorough and honest. The root cause analysis correctly identifies
two distinct framework gaps: (1) the compat matrix is binary and lacks a resource-
budget dimension, and (2) the compat matrix verifies library-runtime compatibility
but not library-to-platform-service routing compatibility.

I add one observation the self-review did not foreground:

**The user's observation is exactly correct: these problems were well-known before
coding started.** The Cloudflare Workers CPU limit and the Hyperdrive TCP routing
requirement are documented in `agent_docs/generic/deployment-vercel-cloudflare.md`
(the very document the architect is required to read). The deployment standard
explicitly lists `argon2 (native)` as incompatible and recommends `Web Crypto API`
as the alternative. The architect chose `@noble/hashes argon2id (pure-JS)` instead —
a middle path that the standard did not endorse — without verifying the CPU cost.
Similarly, the Hyperdrive constraint that only TCP-based drivers are intercepted is
derivable from basic reading of how a TCP proxy works. This is not an obscure edge
case; it is an architectural property of Hyperdrive that any architect familiar with
the platform should have verified.

The deeper failure is that **these issues cannot be detected by any downstream agent
through code inspection** — not by the code-reviewer reading `src/db/index.ts`, not
by the security-auditor reviewing `src/lib/password.ts`, not by the compliance-officer
running their audit. The compliance-officer's required Live Integration Smoke Test
*would* have caught these if it had been performed against an actual deployment.
However, the compliance-officer's role definition permits deferring the smoke test
to "staging or equivalent" without requiring that the architect's platform compat
choices be verified before development starts. This is a systemic pipeline gap:
the only opportunity to prevent deployment-time failures is at architecture sign-off,
but the sign-off process does not include a verification step that requires proof
of correct operation in the actual target environment.

#### Root Cause Attribution: Agent Failure + Framework Gap

The self-review correctly calls both root causes framework gaps. They are partially
framework gaps — the checklist does not require a CPU budget check or a routing
compatibility check. However, the Web Crypto API alternative was already documented
in the standard the architect was required to read, making this also an agent failure
of following the platform standard's own recommended alternative.

**Classification: Mixed — agent failure (chose an undocumented alternative to the
standard's recommendation) + framework gap (compat matrix lacks CPU budget and
inter-service routing dimensions).**

#### Score: 2
**Rationale:** Two Critical deployment failures resulted from architectural decisions.
Both were preventable with available information (the platform standard explicitly
recommends Web Crypto API; Hyperdrive's TCP-only model is fundamental to its design).
The self-review is honest and the suggested improvements are concrete and correct.
Score is 2 rather than 1 because both findings have a genuine framework gap component
and the self-review demonstrates accurate root cause analysis.

#### Self-Review Quality
Complete, honest, and correctly identifies root causes. Score not adjusted.

---

### devops-engineer

#### Independent Observations

The self-review accurately accounts for both findings and does not deflect. I add
two observations:

First, the placeholder issue (DEPLOY-MAJ-01) is particularly significant because
`wrangler.toml` with `[PLACEHOLDER: ...]` values was accepted by the pipeline as a
complete IaC artifact. The compliance-officer's artifact checklist does not include
a step to verify that IaC files contain no placeholder values. This is a gap shared
between the devops agent (submitting an incomplete artifact) and the compliance stage
(not checking for incomplete artifacts).

Second, the four blockers in DEPLOY-MAJ-01 (placeholder values, deprecated config,
cron format, export pattern) are all Cloudflare Workers-specific and are not covered
by general IaC standards. The `agent_docs/generic/deployment-vercel-cloudflare.md`
document, which the devops-engineer is required to read, does not enumerate these
specifics in its architecture checklist. This is a documentation gap in the standard.

#### Root Cause Attribution: Agent Failure + Framework Gap

Authoring IaC with unresolved placeholders and without verifying platform-specific
syntax is an agent failure. The absence of a Cloudflare Workers-specific pre-deploy
checklist is a framework gap. Both are present.

**Classification: Mixed — agent failure (incomplete IaC artifact submitted) +
framework gap (no Workers-specific pre-deploy checklist in the standard).**

#### Score: 2
**Rationale:** Two Major deployment blockers directly attributable to IaC quality.
The self-review is honest and the improvements are actionable. Score is 2 rather
than 1 because the lack of a Workers-specific checklist is a genuine framework gap
that amplified the risk.

#### Self-Review Quality
Complete and honest. Score not adjusted.

---

### developer

#### Independent Observations

The self-review accurately identifies the root cause: no clean-build verification
step. I add one observation not fully foregrounded in the self-review:

The `@radix-ui/react-badge` and `@hey-api/openapi-ts@^0.39.3` entries confirm that
packages were added to `package.json` without an `npm install` verification step.
The `npm install` command, which is the most basic verification, would have
immediately flagged both packages as not found. This is not a framework gap — it is
a basic due-diligence failure. The developer role definition requires writing code
that meets the spec; code that cannot be installed is not meeting that bar.

The TypeScript strict-mode violations (`noUnusedLocals`, `noUnusedParameters`) across
multiple files are also not subtle — these are visible as errors in most TypeScript-
aware editors. The volume of violations suggests the code was written without editor-
level TypeScript feedback enabled, or the violations were dismissed without correction.

#### Root Cause Attribution: Agent Failure + Framework Gap

Not running `npm run build` is an agent failure. The absence of a mandatory clean-
build step in the developer submission checklist is a framework gap (though a minor
one — this is basic hygiene that should be self-evident to any developer).

**Classification: Primarily agent failure; framework gap is minor.**

#### Score: 2
**Rationale:** Both frontends failed to build from clean install due to issues that
`npm run build` would have caught entirely. The volume and variety of errors (missing
packages, wrong package versions, unused imports across many files, missing config
files) indicates the build was not tested before submission. Score is 2 rather
than 1 because a meaningful framework gap exists (no explicit clean-build gate) and
the self-review is accurate.

#### Self-Review Quality
Complete and honest. Score not adjusted.

---

## Framework Gaps Identified

| # | Gap description | Proposed addition to agent-roles.md |
|---|---|---|
| FG-01 | Platform Runtime Compatibility Matrix has no CPU/memory budget dimension — computationally intensive operations in Workers are not benchmarked against the CPU time limit | Add a "CPU budget analysis" column and a mandatory CPU estimate check for any cryptographic or data-intensive operation in the `solution-architect` compat matrix |
| FG-02 | Platform Runtime Compatibility Matrix does not check inter-service routing compatibility — whether a library's transport strategy (HTTP/WS vs TCP) is compatible with the platform service it is paired with (Hyperdrive) | Add an "inter-service routing compatibility" check to the `solution-architect` compat matrix for all libraries that establish network connections to Cloudflare-managed services |
| FG-03 | No Cloudflare Workers-specific pre-deploy readiness checklist — platform-specific syntax requirements (cron format, export pattern, deprecated keys, placeholder replacement) are not enumerated as mandatory verification steps in the `devops-engineer` role | Add a Cloudflare Workers pre-deploy readiness checklist as a mandatory step before the IaC artifact is submitted |
| FG-04 | No cloud resource pre-creation manifest — resources that must exist before deployment (Queues, KV namespaces, Hyperdrive configs) are not distinguished from resources created by deployment | Require the `devops-engineer` to produce a pre-creation manifest listing all resources that must be provisioned before first `wrangler deploy` |
| FG-05 | No mandatory clean-build gate in the developer submission checklist — frontend code is not required to pass `npm ci && npm run build` from a clean state before submission | Add `npm ci && npm run build` (or framework equivalent) as a mandatory pre-submission step in the `developer` Spec Compliance Checklist |
| FG-06 | No `vercel.json` framework field verification step — the deployment config framework setting is not cross-checked against the actual framework in `package.json` | Add a vercel.json framework field verification step to the `developer` frontend checklist |
| FG-07 | **No downstream agent can detect deployment-time failures** — code-reviewer, security-auditor, and compliance-officer all review code in isolation; architectural choices that cause runtime failures (CPU limits, Hyperdrive routing) are invisible to them through code inspection alone. The compliance-officer's Live Integration Smoke Test is the only pipeline mechanism to catch deployment failures, but it can be deferred to staging | Require the compliance-officer to flag as a BLOCKING open item any architecture or IaC choice that has not been verified in the target runtime — specifically CPU-intensive operations and driver/transport choices — and require the smoke test to be performed on a real deployment before issuing any pass verdict (this constraint already exists in `agent-roles.md` but is not enforced as a pre-condition for sign-off) |
| FG-08 | `deployment-vercel-cloudflare.md` architecture checklist does not enumerate Workers-specific deployment blockers (cron format, export pattern, queue pre-creation) | Add a "Cloudflare Workers Deployment Readiness Checklist" section to `deployment-vercel-cloudflare.md` covering these platform-specific requirements |

---

## SDLC Improvement Proposals

These are the actionable changes to be propagated to The Genesis
(`agent_docs/generic/agent-roles.md` and `agent_docs/generic/deployment-vercel-cloudflare.md`).

---

### PROP-01 — Add CPU Budget Analysis to Platform Runtime Compatibility Matrix

**Target:** `agent_docs/generic/agent-roles.md` — `solution-architect` —
Platform Runtime Compatibility Check (mandatory)

**Also target:** `agent_docs/generic/deployment-vercel-cloudflare.md` —
Architecture Checklist

**Proposed change:**

Add the following to the Platform Runtime Compatibility Check table format:

```markdown
| Library / Operation | Replaces | Works in runtime? | CPU cost estimate | Workers CPU limit | Routing via | Verdict |
|---|---|---|---|---|---|---|
| argon2id pure-JS (m=65536) | bcrypt | Yes | ~200–400ms | 10–30ms | N/A | FAIL — use Web Crypto |
| PBKDF2-SHA256 (600k iter) | argon2id | Yes | <1ms (V8 native) | 10–30ms | N/A | PASS |
| pg (node-postgres) | @neondatabase/serverless | Yes (nodejs_compat) | Low | 10–30ms | TCP → Hyperdrive | PASS |
| @neondatabase/serverless | direct TCP | Yes | Low | 10–30ms | HTTP → Neon (bypasses Hyperdrive) | FAIL for Hyperdrive projects |
```

Add to the solution-architect Responsibilities section:

> **CPU Budget Analysis (mandatory for Cloudflare Workers):** For every cryptographic
> operation, data transformation, or computationally intensive step, estimate the
> CPU time against the Workers CPU limit (10ms free / 30ms paid). Any operation
> estimated to exceed this limit is a hard architectural blocker. Prefer Web Crypto
> API (`crypto.subtle`) for all cryptographic operations in Workers — it executes
> in native C++, not JavaScript.

> **Inter-Service Routing Compatibility (mandatory for Cloudflare Workers):** For
> every library that establishes a network connection to an external service, verify
> that its transport strategy routes correctly through the platform infrastructure
> it must pass through. For Hyperdrive: only TCP-based PostgreSQL drivers are
> intercepted — HTTP and WebSocket clients connect directly to their own endpoints
> and bypass Hyperdrive entirely.

Add to the Architecture Checklist in `deployment-vercel-cloudflare.md`:

```
- [ ] For every cryptographic operation: CPU cost estimated and within Workers CPU limit
- [ ] For every database driver: transport strategy is TCP (not HTTP/WS) when Hyperdrive is in use
- [ ] Platform Runtime Compatibility Matrix includes CPU budget column — no "TBD" entries
```

---

### PROP-02 — Add Cloudflare Workers Pre-Deploy Readiness Checklist

**Target:** `agent_docs/generic/agent-roles.md` — `devops-engineer` — Responsibilities

**Also target:** `agent_docs/generic/deployment-vercel-cloudflare.md` — new section

**Proposed change:**

Add to the devops-engineer Responsibilities section:

> **Cloudflare Workers Deployment Readiness (mandatory before IaC artifact is submitted):**
>
> Before submitting `wrangler.toml` or marking the devops setup artifact complete,
> verify and document the following:
>
> - [ ] All `[PLACEHOLDER]` values replaced with real provisioned resource IDs
> - [ ] `usage_model` key removed (deprecated in wrangler 4.x)
> - [ ] Cron expressions use Cloudflare day-of-week format (SUN/MON/TUE/WED/THU/FRI/SAT — not 0/1/...)
> - [ ] Worker exports all declared handler types (scheduled, queue) via
>       `export default { fetch, scheduled, queue }` — not named exports
> - [ ] `wrangler deploy --dry-run` passes in each environment with no errors
>
> **Cloud Resource Pre-Creation Manifest (mandatory for first deployment):**
>
> Produce a table in the devops setup artifact listing every cloud resource that
> must be created before the Worker can be deployed for the first time, the CLI
> command to create it, and confirmed status:
>
> | Resource | Type | Environment | Create command | Created? |
> |---|---|---|---|---|
> | omnichat-media-variants-dev | Cloudflare Queue | dev | wrangler queues create omnichat-media-variants-dev | [ ] |
>
> For Cloudflare Workers projects, resources in this category include:
> Queues (and DLQs), KV namespaces, Hyperdrive configs, R2 buckets, D1 databases.
> These must be created *before* the first `wrangler deploy` — they are not
> auto-created by the deploy command.

---

### PROP-03 — Add Mandatory Clean-Build Gate to Developer Submission Checklist

**Target:** `agent_docs/generic/agent-roles.md` — `developer` —
Spec Compliance Checklist

**Proposed change:**

Add to the Spec Compliance Checklist in the developer output format:

```markdown
- [ ] `npm ci && npm run build` passes from a clean install with no errors or warnings
      (catches: TypeScript strict-mode violations, missing packages, config errors,
       unused imports, vite-env.d.ts, vitest/config import)
- [ ] All packages in `package.json` verified to exist in the npm registry at the
      stated version range (run `npm install` in a clean directory)
- [ ] `vercel.json` (or equivalent) `"framework"` field matches the framework in
      `package.json`; rewrite rules and cache headers use the correct output paths
      for that framework
- [ ] `api-spec.yaml` validated with a YAML linter or OpenAPI parser before submission
```

---

### PROP-04 — Require Compliance Officer to Block on Unverified Architectural Runtime Choices

**Target:** `agent_docs/generic/agent-roles.md` — `compliance-officer` — Responsibilities

**Rationale:** This is the most important structural proposal. The current pipeline
has a blind spot: no agent can detect deployment-time failures through code inspection.
The compliance-officer is the last agent before sign-off and has the broadest scope.
Its Live Integration Smoke Test is already required, but the requirement is currently
framed as "must be completed before any pass verdict" without specifying that
architectural choices that have not been validated in the target runtime must be
blocked explicitly.

**Proposed change:**

Add to the compliance-officer Responsibilities section:

> **Deployment Runtime Validation (mandatory — cannot be deferred):**
>
> Before issuing any sign-off verdict, verify that the following have been confirmed
> in the actual target runtime (staging or equivalent), not through code inspection:
>
> 1. **Computationally intensive operations complete within runtime limits:** For every
>    cryptographic operation, hash, or CPU-intensive step, confirm it completes
>    without hitting the Workers CPU time limit. This cannot be verified by reading
>    `src/lib/password.ts` — it requires a live login/hash request against a deployed
>    Worker and a successful response (not error 1102).
>
> 2. **Database driver routes through the declared proxy:** If Hyperdrive is declared
>    in `wrangler.toml`, confirm the health check reports `"db": true` on the deployed
>    Worker, not `"db": false`. This verifies the driver is actually using the Hyperdrive
>    connection, not bypassing it.
>
> 3. **IaC contains no placeholder values:** Verify `wrangler.toml` and all deployment
>    manifests contain no `[PLACEHOLDER]` strings before issuing any pass verdict.
>
> Any of the above that cannot be confirmed produces a FAIL verdict, not a CONDITIONAL
> PASS. The reason: these failures are invisible to all upstream agents and can only
> be confirmed by deployment. Deferring them means they will be discovered by users.

Add to the compliance-officer output format under "Integration Smoke Test Results":

```markdown
| Scenario | Tested on | Result |
|---|---|---|
| CPU-intensive auth operation (login/hash) completes without error 1102 | staging | |
| DB health check returns `"db": true` (Hyperdrive/driver routing verified) | staging | |
| IaC deployment manifests contain no placeholder values | wrangler.toml review | |
| wrangler deploy --dry-run passes all environments | local | |
```

---

### PROP-05 — Add Cloudflare Workers Deployment Blockers to deployment-vercel-cloudflare.md

**Target:** `agent_docs/generic/deployment-vercel-cloudflare.md` — new section

**Proposed change:**

Add a new section "Cloudflare Workers First-Deployment Checklist" after the
"Architecture Checklist" section:

```markdown
## Cloudflare Workers First-Deployment Checklist

Before `wrangler deploy` is run for the first time in any environment:

### Resource Pre-Creation (must exist before deploy)
- [ ] All Cloudflare Queues created: `wrangler queues create <name>` (including DLQs)
- [ ] All KV namespaces created: `wrangler kv namespace create <name>`
- [ ] All Hyperdrive configs created: `wrangler hyperdrive create <name> --connection-string ...`
- [ ] All R2 buckets created: `wrangler r2 bucket create <name>`

### wrangler.toml Correctness
- [ ] No `[PLACEHOLDER]` values — all IDs are real provisioned resource UUIDs
- [ ] No `usage_model` key (deprecated wrangler 4.x)
- [ ] Cron expressions use day-of-week abbreviations (SUN/MON/...), not numbers (0/1/...)
- [ ] Handler exports use `export default { fetch, scheduled, queue }` pattern
- [ ] `wrangler deploy --dry-run` passes with no errors

### Driver and Library Compatibility
- [ ] Database driver uses TCP (not HTTP/WebSocket) if Hyperdrive is in the binding list
- [ ] No computationally intensive operations exceed Workers CPU limit (verify with a live request)
- [ ] `nodejs_compat` flag enabled if using any Node.js built-in APIs or TCP-based drivers
```

---

## Score History (all rounds)

| Agent | Round 1 (code defects) | Round 2 (deployment) | Trend |
|---|---|---|---|
| solution-architect | N/A (Round 1 scored separately) | 2 | — |
| devops-engineer | 2 (Round 1) | 2 | Flat |
| developer | 1 (Round 1) | 2 | +1 |
| code-reviewer | 2 (Round 1) | N/A (not implicated) | — |

---

## Overall Process Health: 2

**Rationale:** The deployment round exposed a systemic blind spot in the pipeline:
no agent in the standard review cycle (code-reviewer, security-auditor,
compliance-officer) can detect deployment-time failures through code inspection.
The only agents positioned to prevent these failures are the solution-architect
(at architecture time) and the compliance-officer (at live smoke test time).
The architect's Platform Runtime Compatibility Check missed two Critical deployment
blockers that were knowable before coding began. The compliance officer's Live
Integration Smoke Test was not performed before sign-off.

The user's observation — "those problems should be well known before start coding" —
is precisely correct. Both DEPLOY-CRIT-01 (argon2id CPU limit) and DEPLOY-CRIT-02
(Neon driver bypassing Hyperdrive) are properties of the Cloudflare platform that
are documented in the platform standard and are knowable through architectural
research. They did not require deployment to discover. The fact that they propagated
through the entire pipeline — requirements, architecture, development, code review,
security audit, compliance — and were only discovered at actual deployment is the
clearest evidence that the pipeline's Platform Runtime Compatibility Check is
not sufficiently rigorous.

The five SDLC proposals above (PROP-01 through PROP-05) address the root causes at
the correct pipeline stages. PROP-01 and PROP-04 are the most important: they add
the CPU budget check and inter-service routing check to the architect's mandatory
deliverables, and they require the compliance officer to block on unverified
architectural runtime choices rather than issuing a conditional pass.

---

## Sign-off: retrospective-analyst — 2026-03-21 15:30
