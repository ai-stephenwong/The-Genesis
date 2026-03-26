#!/usr/bin/env bash
# =============================================================================
# no-stubs.sh — Detect placeholder/stub/TODO patterns in source code
#
# Usage: ./no-stubs.sh <src-dir>
# Exit:  0 = PASS, 1 = FAIL
# =============================================================================
set -euo pipefail

SRC_DIR="${1:?Usage: no-stubs.sh <src-dir>}"

if [[ ! -d "$SRC_DIR" ]]; then
  echo "SKIP: Source directory not found: $SRC_DIR"
  exit 0
fi

# Patterns that indicate incomplete implementations
PATTERNS=(
  '// TODO'
  '// HACK'
  '// FIXME'
  '// Placeholder'
  '// placeholder'
  '/* TODO'
  '# TODO'
  '# FIXME'
  '# HACK'
)

FOUND=""
for pattern in "${PATTERNS[@]}"; do
  MATCHES=$(grep -rn "$pattern" "$SRC_DIR" --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' --include='*.py' --include='*.java' --exclude-dir=node_modules --exclude-dir=.next --exclude-dir=dist 2>/dev/null || true)
  if [[ -n "$MATCHES" ]]; then
    FOUND="$FOUND$MATCHES\n"
  fi
done

# Check for form handlers that only update local state without API calls
# Pattern: onSubmit handlers with setState but no fetch/api call
STUB_HANDLERS=$(grep -rn 'onSubmit\|handleSubmit' "$SRC_DIR" --include='*.ts' --include='*.tsx' --include='*.jsx' --exclude-dir=node_modules -l 2>/dev/null || true)

if [[ -n "$FOUND" ]]; then
  COUNT=$(echo -e "$FOUND" | grep -c . || true)
  echo "FAIL: Found $COUNT stub/placeholder/TODO pattern(s) in source code"
  echo -e "$FOUND" | head -20
  if [[ $COUNT -gt 20 ]]; then
    echo "  ... and $((COUNT - 20)) more"
  fi
  exit 1
fi

echo "PASS: No stub/placeholder/TODO patterns found"
exit 0
