# solution-architect — Self-Review — 2026-03-21 15:30

## Trigger
  Bug report: artifacts/development/bug-report-20260321-1530.md
  Round: 2 (deployment round — distinct from Pipeline Run 1 code defects)

---

## Observations

### OBS-01 — Pure-JS argon2id exceeded Workers CPU time limit (DEPLOY-CRIT-01)

**What was found:**
The deployed Worker returned error 1102 (CPU time limit exceeded) on every login attempt.
argon2id with parameters m=65536, t=3, p=4 — the standard OWASP-recommended settings —
requires approximately 200–400ms of CPU time in pure JavaScript. Cloudflare Workers'
CPU limit is 10ms (free tier) or 30ms (Bundled paid plan). The Unbound plan allows up
to 30 seconds of wall-clock time but the Workers CPU scheduler is still tight. In
practice, pure-JS argon2id with any parameters sufficient for security exceeds the
Workers CPU budget.

**What this agent did:**
The Platform Runtime Compatibility Matrix in `architecture.md` correctly documented
that the *native* `argon2` package (N-API) is incompatible with Workers. It then
recommended `@noble/hashes argon2id (pure-JS)` as the compliant alternative. This
recommendation was architecturally well-intentioned — pure-JS libraries are generally
compatible with V8 isolates — but I did not validate that the pure-JS argon2id
implementation could complete within the Workers CPU budget. The compat matrix
checked the category "works in target runtime?" as binary (yes/no) without a separate
dimension for "stays within runtime resource limits?"

**Why it slipped through:**
The Platform Runtime Compatibility Check as defined in `agent-roles.md` and
`deployment-vercel-cloudflare.md` asks only whether a library *works* in the runtime,
not whether it *performs acceptably* within the runtime's resource constraints. The
checklist item reads: "No native addons (N-API): bcrypt, argon2 (native) → bcryptjs
or @noble/hashes, Web Crypto API." I followed the documented alternative without
running a CPU budget analysis. The framework has no step requiring the architect to
benchmark or estimate the CPU cost of computationally intensive operations against
the Workers CPU limit. This is a framework gap in the Platform Runtime Compatibility
Check definition.

Additionally, the correct solution was available all along and is even documented in
the same table row: "Web Crypto API." PBKDF2-SHA256 via `crypto.subtle` runs in
native C++ within the V8 engine and completes in sub-millisecond time. I should have
recommended this as the primary option rather than defaulting to a pure-JS
argon2id shim.

---

### OBS-02 — Neon serverless driver bypasses Hyperdrive (DEPLOY-CRIT-02)

**What was found:**
The `@neondatabase/serverless` driver uses Neon's proprietary HTTP API endpoint
(`https://<project>.neon.tech`) regardless of any connection string passed to it.
Cloudflare Hyperdrive works by intercepting outbound TCP connections to the PostgreSQL
port (5432) and proxying them through its connection pool. Because the Neon driver
sends HTTP requests rather than TCP packets, Hyperdrive never intercepts them.
The result: every database query bypassed Hyperdrive entirely, and the DB health
check returned `false` on every deployment because the Worker could not reach Neon's
HTTP endpoint from within the production networking configuration.

**What this agent did:**
The architecture document mandated Hyperdrive for database access and listed it in
the Platform Runtime Compatibility Matrix as the approved database access pattern.
However, the approved driver was `@neondatabase/serverless` — which is listed in
Neon's own documentation as "Hyperdrive compatible" under the WebSocket mode
(`neonConfig.webSocketConstructor`). I treated "Neon says it works with Hyperdrive"
as sufficient confirmation without verifying the specific compatibility condition:
Hyperdrive's connection interception requires the driver to establish a TCP connection
to the Hyperdrive endpoint, not an HTTP or WebSocket connection to Neon's own
infrastructure.

**Why it slipped through:**
The Platform Runtime Compatibility Matrix checked "Does this library work in
Cloudflare Workers?" — and the answer for `@neondatabase/serverless` is technically
yes. But the more precise question was: "Does this library's connection routing
method (HTTP/WebSocket to Neon's endpoint) work *with Hyperdrive's TCP interception
model*?" That is a different question, and it was not on the compat matrix. The
framework does not currently require the architect to verify not just runtime
compatibility but also **inter-service routing compatibility** — i.e., whether a
library's connection strategy is compatible with other platform services it is
expected to interact with. This is a framework gap.

---

## Root Causes

| # | Root Cause | Affected Observations |
|---|---|---|
| RC-01 | Platform Runtime Compatibility Check is binary (works / does not work) and does not include a resource-budget dimension — computationally intensive operations are not benchmarked against Workers CPU/memory limits | OBS-01 |
| RC-02 | Platform Runtime Compatibility Check verifies library-to-runtime compatibility but not library-to-platform-service routing compatibility — i.e., whether a library's transport strategy (HTTP, WebSocket, TCP) is compatible with other platform infrastructure it must route through (Hyperdrive) | OBS-02 |
| RC-03 | Both issues were strictly architectural decisions made before coding — neither could have been caught by any downstream agent (code-reviewer, security-auditor, compliance-officer) through code inspection alone; they require actual deployment or explicit architectural knowledge of Workers CPU limits and Hyperdrive routing | OBS-01, OBS-02 |

---

## Suggested Improvements

### SUG-01 — Add a CPU/Memory Budget Analysis dimension to the Platform Runtime Compatibility Matrix

The `solution-architect` responsibilities in `agent-roles.md` and the Architecture
Checklist in `deployment-vercel-cloudflare.md` should require, for every
computationally intensive operation (password hashing, cryptographic operations,
large data transforms), an explicit CPU budget estimate against the target Workers
plan. The compat matrix should gain a "CPU budget analysis" column:

| Library / Operation | CPU cost estimate | Workers CPU limit | Verdict |
|---|---|---|---|
| argon2id (pure-JS, m=65536) | ~200–400ms | 10–30ms | FAIL — use Web Crypto API |
| PBKDF2-SHA256 (600k iter, native) | <1ms (V8 native) | 10–30ms | PASS |

Any operation estimated to exceed the Workers CPU limit is a hard architectural
blocker — an alternative must be identified and documented before development starts.

### SUG-02 — Add an inter-service routing compatibility check to the Platform Runtime Compatibility Matrix

For every library that establishes a network connection to an external service,
the compat matrix must verify not only "does it work in the runtime?" but also
"does its transport strategy route correctly through the platform infrastructure
it is paired with?" Specifically for Cloudflare:

- Libraries using Hyperdrive: must use TCP-based PostgreSQL drivers (`pg`, `postgres.js`)
  — HTTP or WebSocket drivers bypass Hyperdrive entirely
- Libraries using Cloudflare D1: must use the D1 binding, not a remote HTTP client
- Libraries using R2: must use the R2 binding or S3-compatible API, not a local-fs shim

The compat matrix table should gain a "Platform service routing" column with a
mandatory check for any library that connects to a Cloudflare-managed service.

---

## Summary

Both DEPLOY-CRIT-01 and DEPLOY-CRIT-02 are architectural decisions made at design
time that caused hard deployment failures only discovered when actual cloud
infrastructure was provisioned. Neither could have been caught by code review,
security audit, or compliance review — they require either deployment experience
or explicit architectural knowledge of Workers CPU constraints and Hyperdrive routing.

This is the most important class of finding: defects that are **invisible to all
downstream pipeline agents** because they manifest only at deployment time. The
framework must add explicit checks at the architect level to prevent this class of
issue from propagating into the code, because once coded and reviewed, no subsequent
agent has the information or access to find them.

---

## Sign-off: solution-architect — 2026-03-21 15:30
