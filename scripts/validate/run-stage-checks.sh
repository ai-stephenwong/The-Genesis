#!/usr/bin/env bash
# =============================================================================
# run-stage-checks.sh
#
# Runs validation checks for a given pipeline stage.
# Called by the orchestrator between pipeline stages.
#
# Usage:
#   ./run-stage-checks.sh <stage> <project-root> [<src-dir>]
#
# Stages:
#   post-architect    — after solution-architect completes
#   post-developer    — after developer completes
#   post-devops       — after devops-engineer completes
#   pre-review        — before code-reviewer starts
#   pre-compliance    — before compliance-officer starts
#
# Output:
#   Prints each check result. Exit code 0 = all pass, 1 = any failure.
# =============================================================================
set -euo pipefail

STAGE="${1:?Usage: run-stage-checks.sh <stage> <project-root> [<src-dir>]}"
PROJECT="${2:?Usage: run-stage-checks.sh <stage> <project-root> [<src-dir>]}"
SRC_DIR="${3:-$PROJECT/src}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CHECKS_DIR="$SCRIPT_DIR/checks"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

TOTAL=0
PASSED=0
FAILED=0
SKIPPED=0

run_check() {
  local name="$1"
  shift
  local script="$CHECKS_DIR/$name.sh"

  if [[ ! -f "$script" ]]; then
    echo -e "  ${YELLOW}⚠  $name: script not found${NC}"
    ((SKIPPED++))
    return
  fi

  ((TOTAL++))
  echo -e "  ${BOLD}▶  $name${NC}"
  EXIT_CODE=0
  OUTPUT=$(bash "$script" "$@" 2>&1) || EXIT_CODE=$?

  if [[ $EXIT_CODE -eq 0 ]]; then
    STATUS=$(echo "$OUTPUT" | grep -E '^(PASS|SKIP)' | head -1)
    echo -e "     ${GREEN}✓  ${STATUS:-PASS}${NC}"
    ((PASSED++))
  else
    STATUS=$(echo "$OUTPUT" | grep -E '^FAIL' | head -1)
    echo -e "     ${RED}✗  ${STATUS:-FAIL}${NC}"
    # Show details (indented, max 10 lines)
    echo "$OUTPUT" | grep -v '^FAIL' | head -10 | sed 's/^/        /'
    ((FAILED++))
  fi
  echo ""
}

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Validation: ${STAGE}${NC}"
echo -e "${BOLD}Project:${NC} $(basename "$PROJECT")"
echo ""

case "$STAGE" in
  post-architect)
    run_check "runtime-version" "$PROJECT"
    run_check "env-vars" "$PROJECT" "$SRC_DIR"
    ;;

  post-developer)
    run_check "runtime-version" "$PROJECT"
    run_check "env-vars" "$PROJECT" "$SRC_DIR"
    run_check "no-stubs" "$SRC_DIR"
    run_check "routes" "$SRC_DIR"
    # Find latest implementation notes artifact
    LATEST_NOTES=$(ls -t "$PROJECT/artifacts/development/"*.md 2>/dev/null | head -1 || echo "")
    if [[ -n "$LATEST_NOTES" ]]; then
      run_check "impl-notes-format" "$LATEST_NOTES"
    else
      echo -e "  ${YELLOW}⚠  impl-notes-format: No implementation notes found in artifacts/development/${NC}"
      ((SKIPPED++))
    fi
    ;;

  post-devops)
    run_check "deploy-method" "$PROJECT"
    run_check "env-vars" "$PROJECT" "$SRC_DIR"
    ;;

  pre-review)
    run_check "env-vars" "$PROJECT" "$SRC_DIR"
    run_check "no-stubs" "$SRC_DIR"
    run_check "deploy-method" "$PROJECT"
    LATEST_NOTES=$(ls -t "$PROJECT/artifacts/development/"*.md 2>/dev/null | head -1 || echo "")
    if [[ -n "$LATEST_NOTES" ]]; then
      run_check "impl-notes-format" "$LATEST_NOTES"
    fi
    ;;

  pre-compliance)
    run_check "env-vars" "$PROJECT" "$SRC_DIR"
    run_check "no-stubs" "$SRC_DIR"
    run_check "deploy-method" "$PROJECT"
    run_check "runtime-version" "$PROJECT"
    ;;

  *)
    echo -e "${RED}Unknown stage: $STAGE${NC}"
    echo "Valid stages: post-architect, post-developer, post-devops, pre-review, pre-compliance"
    exit 1
    ;;
esac

# Summary
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Results:${NC} $TOTAL checks run"
echo -e "  ${GREEN}Passed:${NC}  $PASSED"
echo -e "  ${RED}Failed:${NC}  $FAILED"
echo -e "  ${YELLOW}Skipped:${NC} $SKIPPED"

if [[ $FAILED -gt 0 ]]; then
  echo ""
  echo -e "${RED}OVERALL: FAIL — $FAILED check(s) failed. Fix before proceeding.${NC}"
  exit 1
else
  echo ""
  echo -e "${GREEN}OVERALL: PASS${NC}"
  exit 0
fi
