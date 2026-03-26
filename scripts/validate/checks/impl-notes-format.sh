#!/usr/bin/env bash
# =============================================================================
# impl-notes-format.sh — Verify implementation notes have all required sections
#
# Usage: ./impl-notes-format.sh <artifact-file>
# Exit:  0 = PASS, 1 = FAIL
# =============================================================================
set -euo pipefail

ARTIFACT="${1:?Usage: impl-notes-format.sh <artifact-file>}"

if [[ ! -f "$ARTIFACT" ]]; then
  echo "FAIL: Implementation notes file not found: $ARTIFACT"
  exit 1
fi

REQUIRED_SECTIONS=(
  "What Was Built"
  "User Journey Map"
  "Field Mapping Table"
  "Runtime Dependency Register"
  "Files Changed"
  "Build Verification"
  "Test Coverage"
  "PILOT STATUS"
)

MISSING=""
for section in "${REQUIRED_SECTIONS[@]}"; do
  if ! grep -q "$section" "$ARTIFACT"; then
    MISSING="$MISSING  - $section\n"
  fi
done

if [[ -n "$MISSING" ]]; then
  echo "FAIL: Implementation notes missing required sections:"
  echo -e "$MISSING"
  exit 1
fi

# Check Build Verification is not deferred
if grep -qi "next step\|to be done\|TODO\|TBD" "$ARTIFACT" | grep -qi "build" 2>/dev/null; then
  echo "FAIL: Build Verification appears to be deferred — must be completed before submission"
  exit 1
fi

echo "PASS: Implementation notes contain all required sections"
exit 0
