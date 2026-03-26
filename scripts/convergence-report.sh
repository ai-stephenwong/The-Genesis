#!/usr/bin/env bash
# =============================================================================
# convergence-report.sh
#
# Analyses pipeline run history to measure whether the Genesis closed loop
# is converging — i.e. each successive run produces fewer issues.
#
# Usage:
#   ./convergence-report.sh <project-root>
#
# Reads:
#   artifacts/runs/run-*.json  (pipeline run records)
#
# Output:
#   Prints a convergence summary to stdout.
# =============================================================================
set -euo pipefail

PROJECT="${1:?Usage: convergence-report.sh <project-root>}"
RUNS_DIR="$PROJECT/artifacts/runs"

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

if [[ ! -d "$RUNS_DIR" ]]; then
  echo -e "${YELLOW}No run history found at $RUNS_DIR${NC}"
  echo "Pipeline run tracking has not been set up yet."
  exit 0
fi

# Collect all run files sorted by name (chronological due to YYYYMMDD-HHmm naming)
RUN_FILES=()
while IFS= read -r f; do
  RUN_FILES+=("$f")
done < <(ls -1 "$RUNS_DIR"/run-*.json 2>/dev/null | sort)

if [[ ${#RUN_FILES[@]} -eq 0 ]]; then
  echo -e "${YELLOW}No completed pipeline runs found.${NC}"
  exit 0
fi

TOTAL_RUNS=${#RUN_FILES[@]}

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Convergence Report${NC}"
echo -e "${BOLD}Project:${NC} $(basename "$PROJECT")"
echo -e "${BOLD}Runs analysed:${NC} $TOTAL_RUNS"
echo ""

# Header
printf "${BOLD}%-22s  %8s  %8s  %8s  %8s  %8s  %5s${NC}\n" \
  "Run" "Time(s)" "Remeds" "V.Total" "V.Pass" "V.Fail" "Score"
echo "────────────────────────────────────────────────────────────────────────────"

PREV_FAIL=""
PREV_REMED=""
IMPROVING=0
REGRESSING=0

for run_file in "${RUN_FILES[@]}"; do
  RUN_ID=$(python3 -c "import json,sys; d=json.load(open('$run_file')); print(d.get('run_id','?'))" 2>/dev/null || echo "?")
  PROC_TIME=$(python3 -c "import json,sys; d=json.load(open('$run_file')); print(d['totals'].get('process_time_seconds',0))" 2>/dev/null || echo "0")
  REMEDS=$(python3 -c "import json,sys; d=json.load(open('$run_file')); print(d['totals'].get('total_remediation_rounds',0))" 2>/dev/null || echo "0")
  V_TOTAL=$(python3 -c "import json,sys; d=json.load(open('$run_file')); print(d['totals'].get('validation_checks_total',0))" 2>/dev/null || echo "0")
  V_PASS=$(python3 -c "import json,sys; d=json.load(open('$run_file')); print(d['totals'].get('validation_checks_passed',0))" 2>/dev/null || echo "0")
  V_FAIL=$(python3 -c "import json,sys; d=json.load(open('$run_file')); print(d['totals'].get('validation_checks_failed',0))" 2>/dev/null || echo "0")
  SCORE=$(python3 -c "import json,sys; d=json.load(open('$run_file')); s=d.get('retrospective',{}).get('overall_score','—'); print(s if s else '—')" 2>/dev/null || echo "—")

  # Trend indicator
  TREND=""
  if [[ -n "$PREV_FAIL" ]]; then
    if [[ "$V_FAIL" -lt "$PREV_FAIL" ]]; then
      TREND="${GREEN}▼${NC}"
      ((IMPROVING++))
    elif [[ "$V_FAIL" -gt "$PREV_FAIL" ]]; then
      TREND="${RED}▲${NC}"
      ((REGRESSING++))
    else
      TREND="="
    fi
  fi

  printf "%-22s  %8s  %8s  %8s  %8s  %8s  %5s  %b\n" \
    "$RUN_ID" "$PROC_TIME" "$REMEDS" "$V_TOTAL" "$V_PASS" "$V_FAIL" "$SCORE" "$TREND"

  PREV_FAIL="$V_FAIL"
  PREV_REMED="$REMEDS"
done

echo ""
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

# Summary
if [[ $TOTAL_RUNS -lt 2 ]]; then
  echo -e "${YELLOW}Need at least 2 runs to measure convergence.${NC}"
elif [[ $IMPROVING -gt $REGRESSING ]]; then
  echo -e "${GREEN}CONVERGING${NC} — validation failures trending down across runs."
elif [[ $REGRESSING -gt $IMPROVING ]]; then
  echo -e "${RED}DIVERGING${NC} — validation failures trending up. Review recent tributes."
else
  echo -e "${YELLOW}FLAT${NC} — no clear improvement trend. The loop may need stronger feedback."
fi

echo ""
echo -e "${BOLD}Legend:${NC} ${GREEN}▼${NC} = fewer failures than previous run  ${RED}▲${NC} = more failures  = = same"
echo ""
