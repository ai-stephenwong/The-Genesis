#!/usr/bin/env bash
# =============================================================================
# no-todo-markers.sh — Fail if src/ contains TODO/FIXME/XXX/HACK markers.
#
# Golden rule: the developer completes work or raises a change request.
# A TODO left in committed code is a silent defect masked as a breadcrumb.
# If a comment starting with one of these markers is needed for a genuine
# hidden constraint, prefix it with "NOTE:" instead — that is not a defect.
#
# Exit codes:
#   0  — clean
#   1  — markers found (details printed)
# =============================================================================

set -euo pipefail

if [ ! -d "src" ]; then
  echo "[no-todo-markers.sh] src/ not present — skipping (nothing to check)"
  exit 0
fi

# Case-sensitive — NOTE:, todo in prose, or to-do in docs are not flagged.
pattern='\b(TODO|FIXME|XXX|HACK)\b'

# Limit to source file extensions; skip node_modules, dist, build outputs.
matches=$(grep -rEn "$pattern" src/ \
  --include='*.ts' --include='*.tsx' --include='*.js' --include='*.jsx' \
  --include='*.py' --include='*.java' --include='*.go' --include='*.rs' \
  --exclude-dir=node_modules --exclude-dir=dist --exclude-dir=build \
  --exclude-dir=.next --exclude-dir=coverage 2>/dev/null || true)

if [ -z "$matches" ]; then
  echo "[no-todo-markers.sh] PASS — no TODO/FIXME/XXX/HACK markers in src/"
  exit 0
fi

echo "[no-todo-markers.sh] FAIL — TODO/FIXME/XXX/HACK markers found in src/:"
echo "$matches" | sed 's/^/  /'
echo
echo "Remove the marker or replace the intent with a change request."
exit 1
