# devops-engineer — Self-Review — 2026-03-21 15:30

## Trigger
  Bug report: artifacts/development/bug-report-20260321-1530.md
  Round: 2 (deployment round)

---

## Observations

### OBS-01 — wrangler.toml contained placeholder values, deprecated config, invalid cron, wrong export pattern (DEPLOY-MAJ-01)

**What was found:**
On first `wrangler deploy`, four distinct issues blocked deployment:

1. `[PLACEHOLDER: ...]` strings for all Hyperdrive IDs, KV namespace IDs, R2 bucket
   names — wrangler config parser rejected these as invalid UUIDs/names.
2. `usage_model = "standard"` is deprecated in wrangler 4.x and caused validation
   warnings that halted deployment.
3. Cron expression `0 3 * * 0` (numeric day-of-week `0` for Sunday) is not accepted
   by Cloudflare Workers — must use the three-letter abbreviation `SUN`.
4. The `queue` handler was exported as a named export (`export const queue = ...`)
   alongside `export default app`. Cloudflare Workers only recognises the `queue`
   handler when exported as part of the default export object:
   `export default { fetch, scheduled, queue }`.

**What this agent did:**
I wrote `wrangler.toml` with placeholder values for all IDs that were not yet
provisioned, intending them as reminders for the provisioning step. I did not replace
them before submitting the IaC artifact, nor did I document a pre-deploy checklist
requiring their replacement. For the cron format and export pattern, I did not verify
the Cloudflare-specific syntax requirements against the Cloudflare documentation
before finalising the config. I treated standard Unix cron syntax as applicable to
Workers without checking the platform's specific parser behaviour.

**Why it slipped through:**
There was no pre-deployment readiness checklist in my role definition that required
me to verify: (a) all placeholder values are replaced before the artifact is
submitted, (b) cron expressions use Workers-compatible format, (c) the Workers
handler export pattern matches the declared bindings. The `devops-engineer` role
defines responsibilities at the level of "write IaC" and "configure CI/CD" but
does not include a Cloudflare Workers-specific configuration readiness checklist.
These are platform-specific gotchas that are not covered by general IaC principles.

---

### OBS-02 — Cloudflare Queues not pre-created before Worker deployment (DEPLOY-MAJ-02)

**What was found:**
`wrangler deploy` failed with "queue does not exist" errors for all six referenced
queues (three primary queues and three dead-letter queues across dev, staging, and
production environments). Cloudflare Queues, unlike some other cloud queue services,
must be created as separate resources before any Worker binding that references them
can be deployed. They are not auto-created by `wrangler deploy`.

**What this agent did:**
I declared `[[queues.consumers]]` and `[[queues.producers]]` bindings in `wrangler.toml`
for all three environments without first creating the underlying queue resources.
I did not include a "pre-deploy infrastructure setup" step in the devops setup
artifact that enumerated which cloud resources must exist before the Worker can
be deployed for the first time.

**Why it slipped through:**
The devops role definition covers writing IaC and configuring CI/CD pipelines, but
does not include an explicit "cloud resource dependency order" step — i.e., a listing
of which resources must be created (and how) before the Worker can be deployed.
For Cloudflare specifically: KV namespaces and Hyperdrive configs are created via
`wrangler kv namespace create` and `wrangler hyperdrive create`; Queues must be
created via `wrangler queues create`; R2 buckets via `wrangler r2 bucket create`.
These are pre-conditions for deployment, not artefacts of deployment. The framework
does not distinguish between "infrastructure created by the deployment" and
"infrastructure that must exist before the deployment."

---

## Root Causes

| # | Root Cause | Affected Observations |
|---|---|---|
| RC-01 | No Cloudflare Workers-specific pre-deploy readiness checklist — platform-specific syntax requirements (cron format, export pattern, deprecated config keys) were not enumerated as verification steps before submitting the IaC artifact | OBS-01 |
| RC-02 | Placeholder values in `wrangler.toml` submitted without a documented replacement step in the devops artifact — no gate requiring all placeholders to be replaced before the artifact is considered complete | OBS-01 |
| RC-03 | No "cloud resource pre-creation" step in the devops workflow — resources that must exist before deployment (Queues, KV namespaces, Hyperdrive configs) were not distinguished from resources created by the deployment itself | OBS-02 |

---

## Suggested Improvements

### SUG-01 — Add a Cloudflare Workers pre-deploy readiness checklist to the devops-engineer responsibilities

For Cloudflare Workers projects, the devops-engineer must complete and document a
pre-deploy readiness checklist before the IaC artifact is marked complete:

- [ ] All `[PLACEHOLDER]` values replaced with provisioned resource IDs
- [ ] `usage_model` key removed (deprecated in wrangler 4.x)
- [ ] Cron expressions use Cloudflare-compatible day-of-week format (SUN/MON/... not 0/1/...)
- [ ] Worker exports all declared handlers via `export default { fetch, scheduled, queue }` — not named exports
- [ ] `wrangler deploy --dry-run` passes with no errors in all environments

### SUG-02 — Add a "cloud resource pre-creation manifest" to the devops setup artifact

The devops setup artifact must include a section listing every cloud resource that
must exist *before* first deployment, the command to create it, and a "created?" status:

| Resource | Type | Environment | Create command | Created? |
|---|---|---|---|---|
| omnichat-media-variants-dev | Cloudflare Queue | dev | wrangler queues create | [x] |
| ... | | | | |

This manifest must be completed and verified before any deployment attempt.

---

## Summary

Both findings are genuine execution failures attributable to this agent.
OBS-01 reflects a failure to verify Cloudflare Workers-specific configuration syntax
before submitting the IaC artifact. OBS-02 reflects a failure to distinguish resources
that must be pre-created from those auto-created by deployment. Both are addressable
by adding an explicit pre-deploy checklist and resource manifest to the devops
responsibilities. Neither would have been visible to code-review or compliance agents
since they are IaC configuration gaps, not source code defects.

---

## Sign-off: devops-engineer — 2026-03-21 15:30
