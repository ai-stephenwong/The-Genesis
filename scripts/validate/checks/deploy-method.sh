#!/usr/bin/env bash
# =============================================================================
# deploy-method.sh — Verify CI/CD workflows don't use prohibited deploy commands
#
# Usage: ./deploy-method.sh <project-root>
# Exit:  0 = PASS, 1 = FAIL
# =============================================================================
set -euo pipefail

PROJECT="${1:?Usage: deploy-method.sh <project-root>}"
WORKFLOWS_DIR="$PROJECT/.github/workflows"

if [[ ! -d "$WORKFLOWS_DIR" ]]; then
  echo "SKIP: No .github/workflows/ directory found"
  exit 0
fi

# Prohibited deploy commands (Railway exception: `railway up` inside CI is allowed)
PROHIBITED_PATTERNS=(
  'vercel deploy'
  'vercel --prod'
  'wrangler deploy'
  'wrangler publish'
  'mcp__vercel__deployments-create-deployment'
  'mcp__cloudflare-api.*deploy'
)

VIOLATIONS=""
for pattern in "${PROHIBITED_PATTERNS[@]}"; do
  MATCHES=$(grep -rn "$pattern" "$WORKFLOWS_DIR" 2>/dev/null || true)
  if [[ -n "$MATCHES" ]]; then
    VIOLATIONS="$VIOLATIONS$MATCHES\n"
  fi
done

if [[ -n "$VIOLATIONS" ]]; then
  echo "FAIL: Prohibited deploy commands found in CI/CD workflows"
  echo -e "$VIOLATIONS"
  echo ""
  echo "All deployments must be triggered by git push / git merge."
  echo "See devops-engineer.md for the Railway exception (railway up only)."
  exit 1
fi

echo "PASS: No prohibited deploy commands in CI/CD workflows"
exit 0
