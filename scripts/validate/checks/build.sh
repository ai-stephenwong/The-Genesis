#!/usr/bin/env bash
# =============================================================================
# build.sh — Verify project builds successfully from clean state
#
# Usage: ./build.sh <project-dir> [<build-command>]
# Exit:  0 = PASS, 1 = FAIL
# =============================================================================
set -euo pipefail

PROJECT_DIR="${1:?Usage: build.sh <project-dir> [<build-command>]}"
BUILD_CMD="${2:-npm run build}"

if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
  echo "SKIP: No package.json found in $PROJECT_DIR"
  exit 0
fi

cd "$PROJECT_DIR"

echo "Running: npm ci"
if ! npm ci --silent 2>&1 | tail -5; then
  echo "FAIL: npm ci failed"
  exit 1
fi

echo ""
echo "Running: $BUILD_CMD"
if ! eval "$BUILD_CMD" 2>&1 | tail -20; then
  echo "FAIL: Build failed"
  exit 1
fi

# TypeScript check (if tsconfig exists)
if [[ -f "tsconfig.json" ]]; then
  echo ""
  echo "Running: npx tsc --noEmit"
  if ! npx tsc --noEmit 2>&1 | tail -20; then
    echo "FAIL: TypeScript type check failed"
    exit 1
  fi
fi

echo ""
echo "PASS: Build succeeded"
exit 0
