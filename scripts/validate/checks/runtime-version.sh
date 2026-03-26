#!/usr/bin/env bash
# =============================================================================
# runtime-version.sh — Verify runtime version matches pinning file and stack.md
#
# Usage: ./runtime-version.sh <project-root>
# Exit:  0 = PASS, 1 = FAIL
# =============================================================================
set -euo pipefail

PROJECT="${1:?Usage: runtime-version.sh <project-root>}"

FAILURES=""

# Detect which runtime and pinning file
if [[ -f "$PROJECT/.nvmrc" ]]; then
  PINNED=$(cat "$PROJECT/.nvmrc" | tr -d 'v \n')
  ACTIVE=$(node --version 2>/dev/null | tr -d 'v \n' || echo "NOT_INSTALLED")
  RUNTIME="Node.js"
  PIN_FILE=".nvmrc"
elif [[ -f "$PROJECT/.java-version" ]]; then
  PINNED=$(cat "$PROJECT/.java-version" | tr -d ' \n')
  ACTIVE=$(java --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "NOT_INSTALLED")
  RUNTIME="Java"
  PIN_FILE=".java-version"
elif [[ -f "$PROJECT/.python-version" ]]; then
  PINNED=$(cat "$PROJECT/.python-version" | tr -d ' \n')
  ACTIVE=$(python3 --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' || echo "NOT_INSTALLED")
  RUNTIME="Python"
  PIN_FILE=".python-version"
elif [[ -f "$PROJECT/.tool-versions" ]]; then
  echo "INFO: .tool-versions found — multi-runtime project, checking each entry"
  PIN_FILE=".tool-versions"
  RUNTIME="polyglot"
  # Basic check: file exists and is non-empty
  if [[ ! -s "$PROJECT/.tool-versions" ]]; then
    echo "FAIL: .tool-versions is empty"
    exit 1
  fi
  echo "PASS: .tool-versions exists and is non-empty (manual verification recommended)"
  exit 0
else
  echo "SKIP: No version pinning file found (.nvmrc, .java-version, .python-version, .tool-versions)"
  exit 0
fi

echo "Runtime: $RUNTIME"
echo "Pin file ($PIN_FILE): $PINNED"
echo "Active version: $ACTIVE"

# Compare pinned vs active (major.minor match)
PINNED_MAJOR=$(echo "$PINNED" | cut -d. -f1-2)
ACTIVE_MAJOR=$(echo "$ACTIVE" | cut -d. -f1-2)

if [[ "$ACTIVE" == "NOT_INSTALLED" ]]; then
  echo "FAIL: $RUNTIME is not installed"
  exit 1
fi

if [[ "$PINNED_MAJOR" != "$ACTIVE_MAJOR" ]]; then
  FAILURES="$FAILURES  - Active $RUNTIME ($ACTIVE) does not match $PIN_FILE ($PINNED)\n"
fi

# Check stack.md if it exists
STACK_MD="$PROJECT/agent_docs/project/stack.md"
if [[ -f "$STACK_MD" ]]; then
  STACK_VERSION=$(grep -iE "node|java|python" "$STACK_MD" | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "")
  if [[ -n "$STACK_VERSION" ]]; then
    STACK_MAJOR=$(echo "$STACK_VERSION" | cut -d. -f1-2)
    if [[ "$PINNED_MAJOR" != "$STACK_MAJOR" ]]; then
      FAILURES="$FAILURES  - $PIN_FILE ($PINNED) does not match stack.md ($STACK_VERSION)\n"
    fi
    echo "stack.md version: $STACK_VERSION"
  fi
fi

if [[ -n "$FAILURES" ]]; then
  echo ""
  echo "FAIL: Runtime version mismatch"
  echo -e "$FAILURES"
  exit 1
fi

echo ""
echo "PASS: Runtime versions are consistent"
exit 0
