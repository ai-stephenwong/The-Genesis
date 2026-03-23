# MCP Server Setup Guide

Complete setup guide for configuring all MCP servers on a new machine.

---

## Prerequisites

### 1. Install Doppler CLI (all tokens are stored here)

```bash
# macOS (Homebrew)
brew install dopplerhq/cli/doppler

# Login (one-time, persistent session)
doppler login
```

### 2. Install Node.js (v20+)

```bash
brew install node
```

### 3. Install Claude Code

```bash
npm install -g @anthropic-ai/claude-code
```

---

## Doppler Secrets Required

All tokens are stored in Doppler project `genesis`, config `dev`. Verify they exist:

```bash
doppler secrets --project genesis --config dev
```

| Doppler Key | Service | How to get the token |
|---|---|---|
| `GITHUB_API_KEY` | GitHub | https://github.com/settings/tokens > Classic token > scopes: `repo`, `workflow` |
| `VERCEL_API_KEY` | Vercel | https://vercel.com/account/settings/tokens |
| `NEON_API_KEY` | Neon | https://console.neon.tech > Profile > API Keys |
| `RESEND_API_KEY` | Resend | https://resend.com/api-keys |
| `UPSTASH_EMAIL` | Upstash | Your Upstash account email |
| `UPSTASH_API_KEY` | Upstash | https://console.upstash.com/account/api > Management API |
| `RAILWAY_API_TOKEN` | Railway | https://railway.com/account/tokens > Account scope |
| `SENTRY_AUTH_TOKEN` | Sentry | https://sentry.io/settings/auth-tokens/ > User Auth Token |

---

## Add MCP Servers (one by one)

**IMPORTANT:** Replace `DOPPLER_PATH` below with the actual path to your doppler binary. Find it with `which doppler`.

### 1. GitHub

```bash
claude mcp add -s user github -- /bin/bash -c \
  "export GITHUB_PERSONAL_ACCESS_TOKEN=\$(DOPPLER_PATH secrets get GITHUB_API_KEY --plain --project genesis --config dev) && npx -y @modelcontextprotocol/server-github"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `@modelcontextprotocol/server-github` |
| Env var name | `GITHUB_PERSONAL_ACCESS_TOKEN` |
| Token type | Classic PAT, scopes: `repo`, `workflow` |

---

### 2. Vercel

```bash
claude mcp add -s user vercel -- /bin/bash -c \
  "npx -y --package @vercel/sdk -- mcp start --bearer-token=\$(DOPPLER_PATH secrets get VERCEL_API_KEY --plain --project genesis --config dev)"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `@vercel/sdk` |
| Start command | `mcp start --bearer-token=<token>` |
| Token type | Vercel API Token (full account scope) |

---

### 3. Neon

```bash
claude mcp add -s user neon -- /bin/bash -c \
  "export NEON_API_KEY=\$(DOPPLER_PATH secrets get NEON_API_KEY --plain --project genesis --config dev) && npx -y @neondatabase/mcp-server-neon"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `@neondatabase/mcp-server-neon` |
| Env var name | `NEON_API_KEY` |
| Token type | Neon API Key |

---

### 4. Resend

```bash
claude mcp add -s user resend -- /bin/bash -c \
  "export RESEND_API_KEY=\$(DOPPLER_PATH secrets get RESEND_API_KEY --plain --project genesis --config dev) && npx -y resend-mcp"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `resend-mcp` |
| Env var name | `RESEND_API_KEY` |
| Token type | Resend API Key |

---

### 5. Upstash

```bash
claude mcp add -s user upstash -- /bin/bash -c \
  "npx -y @upstash/mcp-server@latest --email \$(DOPPLER_PATH secrets get UPSTASH_EMAIL --plain --project genesis --config dev) --api-key \$(DOPPLER_PATH secrets get UPSTASH_API_KEY --plain --project genesis --config dev)"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `@upstash/mcp-server@latest` |
| Args | `--email <email> --api-key <key>` |
| Token type | Upstash Management API Key |

---

### 6. Cloudflare

```bash
claude mcp add -s user --transport http cloudflare-api https://mcp.cloudflare.com/mcp
```

| Field | Value |
|---|---|
| Transport | HTTP/OAuth (browser auth) |
| URL | `https://mcp.cloudflare.com/mcp` |
| Token | None needed — authenticates via browser on first use |
| Note | May need re-auth between sessions. If stuck on "needs authentication", clear cache: `echo '{}' > ~/.claude/mcp-needs-auth-cache.json` then restart |

---

### 7. Railway

```bash
claude mcp add -s user railway -- /bin/bash -c \
  "export RAILWAY_API_TOKEN=\$(DOPPLER_PATH secrets get RAILWAY_API_TOKEN --plain --project genesis --config dev) && npx -y @railway/mcp-server"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `@railway/mcp-server` |
| Env var name | `RAILWAY_API_TOKEN` |
| Token type | Railway API Token (Account scope) |

---

### 8. Sentry

```bash
claude mcp add -s user sentry -- /bin/bash -c \
  "npx -y @sentry/mcp-server --access-token=\$(DOPPLER_PATH secrets get SENTRY_AUTH_TOKEN --plain --project genesis --config dev)"
```

| Field | Value |
|---|---|
| Transport | stdio |
| NPM package | `@sentry/mcp-server` |
| Args | `--access-token=<token>` |
| Token type | Sentry User Auth Token (not org token) |

---

## Verify All Servers

After adding all servers, restart Claude Code and run `/mcp` to check status. All should show "connected" except cloudflare-api which may show "needs authentication" until you complete the browser OAuth flow.

## Troubleshooting

| Problem | Fix |
|---|---|
| Server shows "needs authentication" | For HTTP/OAuth servers: clear cache `echo '{}' > ~/.claude/mcp-needs-auth-cache.json` then restart |
| Server shows "failed" | Run the command manually in terminal to see the error. Usually a wrong token or missing npm package |
| `doppler: command not found` | Use full path (e.g. `/opt/homebrew/bin/doppler`). Find with `which doppler` |
| Token expired | Generate a new token from the service's dashboard, update in Doppler: `doppler secrets set <KEY> --project genesis --config dev` |
| `npx` hangs or fails | Ensure Node.js v20+ is installed. Try `npx -y <package> --help` manually first |
