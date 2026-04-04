# Pre-Deployment Check

Run a pre-flight checklist before deploying any service. Do ALL checks and report results in a single table.

## Checks to run

### 1. Build verification
- Run the project's build command (`npm run build`, `tsc --noEmit`, or equivalent from `package.json`)
- Report: PASS / FAIL with error summary

### 2. Environment variables
- Read `.env`, `.env.local`, `.env.production` (whichever exist)
- Flag any values containing: `placeholder`, `changeme`, `xxx`, `TODO`, `your-`, empty values
- Cross-check against `agent_docs/project/env-contract.md` if it exists — flag missing vars
- Report: PASS / FAIL with list of problematic vars

### 3. Auth verification
- Check GitHub auth: `gh auth status`
- Check Doppler auth: `doppler secrets get --plain --project {project} --config dev` (use project name from current directory)
- Report: PASS / FAIL per service

### 4. Service connectivity
- If Vercel project: `vercel whoami` or check MCP connection
- If Railway project: check MCP connection or `railway status`
- If Neon database: check MCP connection
- Report: PASS / FAIL per service

### 5. Dependencies
- Check for known vulnerabilities: `npm audit --production` (if Node.js)
- Report: PASS / N critical / N high

## Output format

```
Pre-Deployment Check — {project-name}
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Build          : PASS / FAIL
  Env vars       : PASS / FAIL (N issues)
  GitHub auth    : PASS / FAIL
  Doppler auth   : PASS / FAIL
  Vercel         : PASS / FAIL / N/A
  Railway        : PASS / FAIL / N/A
  Neon DB        : PASS / FAIL / N/A
  Vulnerabilities: PASS / N critical, N high
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Ready to deploy: YES / NO
  Blockers: (list any FAIL items)
```

- Do NOT ask questions — just run all checks and report
- If a check cannot run (tool not installed, not applicable), mark as N/A
- If ANY check fails, set "Ready to deploy: NO"
