#!/usr/bin/env bash
# =============================================================================
# env-vars.sh — Verify env var names in code match env-contract.md
#
# Usage: ./env-vars.sh <project-root> [<src-dir>]
# Exit:  0 = PASS, 1 = FAIL
# =============================================================================
set -euo pipefail

PROJECT="${1:?Usage: env-vars.sh <project-root> [<src-dir>]}"
SRC_DIR="${2:-$PROJECT/src}"
CONTRACT="$PROJECT/agent_docs/project/env-contract.md"

if [[ ! -f "$CONTRACT" ]]; then
  echo "SKIP: env-contract.md not found — cannot validate"
  exit 0
fi

# Extract declared env var keys from the contract table (column 1, rows with |)
DECLARED=$(grep -E '^\|[^|]*`[A-Z_]+`' "$CONTRACT" | grep -oE '`[A-Z][A-Z0-9_]+`' | tr -d '`' | sort -u)

if [[ -z "$DECLARED" ]]; then
  echo "SKIP: No env vars found in contract — table may be empty/template"
  exit 0
fi

# Extract env var references from source code
# Covers: process.env.X, import.meta.env.X, c.env.X, env.X (in Hono/Workers context)
CODE_REFS=$(grep -rhoE '(process\.env\.|import\.meta\.env\.|c\.env\.|env\.)[A-Z][A-Z0-9_]+' "$SRC_DIR" --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist --exclude-dir=build 2>/dev/null \
  | grep -oE '[A-Z][A-Z0-9_]+$' \
  | sort -u || true)

if [[ -z "$CODE_REFS" ]]; then
  echo "PASS: No env var references found in source code"
  exit 0
fi

# Find env vars in code that are NOT in the contract
VIOLATIONS=""
while IFS= read -r var; do
  if ! echo "$DECLARED" | grep -qx "$var"; then
    VIOLATIONS="$VIOLATIONS  - $var (in code but not in env-contract.md)\n"
  fi
done <<< "$CODE_REFS"

if [[ -n "$VIOLATIONS" ]]; then
  echo "FAIL: Env var names in code do not match env-contract.md"
  echo -e "$VIOLATIONS"
  echo ""
  echo "Declared in contract:"
  echo "$DECLARED" | sed 's/^/  /'
  exit 1
fi

echo "PASS: All env var names in code match env-contract.md"
echo "  Checked: $(echo "$CODE_REFS" | wc -l | tr -d ' ') var(s)"
exit 0
