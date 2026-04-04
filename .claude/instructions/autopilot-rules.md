# Autopilot & Co-pilot Rules

Referenced by `orchestrator.md`. Contains detailed operating rules for Autopilot and Co-pilot modes.

---

## Autopilot Prerequisites

All must be satisfied **before** launching Claude Code:

| # | Prerequisite | How | Frequency |
|---|---|---|---|
| 1 | `DATABASE_URL` in shell | `source .secrets/load-credentials.sh` | Per session |
| 2 | Doppler unattended | `DOPPLER_TOKEN=dp.st....` in `~/.zshrc` | One-time |
| 3 | Tool permissions | Pre-approve in `.claude/settings.json` | One-time per project |
| 4 | MCP auth | All MCP servers authenticated | One-time |

Only `DATABASE_URL` needs shell loading — all other credentials are handled by MCP servers.

---

## Try-First Rule

**Never declare "human action required" without testing first.** Probe the service, and only escalate if the probe fails.

| Service | Probe | On success |
|---|---|---|
| Doppler | `doppler configs list --project {name}` | Set secrets |
| GitHub | `gh secret list --repo {owner}/{repo}` | Set CI/CD secrets |
| Railway | `mcp__railway__list-projects` | Create services, deploy |
| Vercel | `mcp__vercel__projects-get-projects` | Set env vars, deploy |
| Cloudflare | `mcp__cloudflare-api__search` | Manage Workers, DNS |
| Neon | `mcp__neon__list_projects` | Create DBs, run SQL |
| Upstash | `mcp__upstash__redis_database_list_databases` | Create Redis |
| Resend | `mcp__resend__list-domains` | Manage email (DNS is human) |
| Sentry | `mcp__sentry__find_projects` | Create projects, get DSNs |

**Chain provisioning results:** When devops-engineer creates a resource, immediately set the resulting credentials in all downstream services (Doppler → GitHub → Railway/Vercel). Only the failed step is a blocker.

**Human action list rules:**
- YES: tasks needing human access (DNS registrar), failed probes (with error), human judgement (domain choice)
- NO: tasks doable via MCP/CLI but untried, tech debt, env vars the agent has values for

---

## Minimum Viable Deploy

Use test/sandbox modes to unblock — don't let production config block the pipeline.

| Service | Test mode | Production upgrade |
|---|---|---|
| Resend | `onboarding@resend.dev` | Verify custom domain (DNS) |
| Vercel | `*.vercel.app` | Add custom domain |
| Railway | `*.up.railway.app` | Add custom domain |
| Cloudflare | `*.workers.dev` | Add custom domain route |
| Neon | Free-tier branch | Upgrade plan |
| Upstash | Free-tier Redis | Upgrade plan |

Log production upgrades as to-dos — not blockers.

---

## Gate Behaviour (Autopilot)

1. Read agent output artifact
2. Apply Genesis standards as decision criteria
3. Decide: approve / reject / resolve
4. Update `pipeline.md` status to `Auto-approved`
5. Log decision with rationale
6. Create snapshot tag: `snapshot/{stage}-{HHmm}`
7. Continue to next stage

---

## Placeholder Convention

Never block for unknown config values. Use `PLACEHOLDER_<DESCRIPTION>` tokens. Track every placeholder (file, token, description). Deliver Configuration Handover at pipeline end.

---

## Snapshot Convention

Git tag at every gate: `snapshot/{stage}-{HHmm}`

To restart: `git checkout snapshot/{tag} && git checkout -b restart/from-{tag}`

---

## Co-pilot Mode

Same as Autopilot, but notify the master at each gate in real time:

```
[HH:mm]  Gate: {name}
         Decision: {approved/rejected} — {rationale}
         Continuing...
```

Produce Approval Summary at completion (see `agent_docs/templates/approval-summary.md`).

---

## Manual Mode

Present each gate to the master. Wait for response. No automatic approvals.
