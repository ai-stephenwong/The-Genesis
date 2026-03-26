#!/usr/bin/env bash
# =============================================================================
# pipeline-runner.sh
#
# State-machine pipeline runner for The Genesis.
# Sits ABOVE the orchestrator — determines which stage to run next,
# enforces transition guards, runs validation scripts, and updates
# the pipeline state file between stages.
#
# Each stage gets its own Claude Code session (fresh context window).
# State is persisted in pipeline-run.json between stages.
# If a stage crashes, resume from where it stopped.
#
# Usage:
#   ./pipeline-runner.sh <project-root> [--mode autopilot|co-pilot|manual]
#   ./pipeline-runner.sh <project-root> --resume
#   ./pipeline-runner.sh <project-root> --status
#
# Requirements:
#   - claude CLI available in PATH
#   - python3 available (for JSON manipulation)
#   - project must have agent_docs/templates/pipeline-run.json
# =============================================================================
set -euo pipefail

PROJECT="${1:?Usage: pipeline-runner.sh <project-root> [--mode autopilot|co-pilot|manual]}"
PROJECT="$(cd "$PROJECT" && pwd)"
ACTION="${2:---run}"
MODE="${3:-autopilot}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUNS_DIR="$PROJECT/artifacts/runs"
TEMPLATES_DIR="$PROJECT/agent_docs/templates"
VALIDATE_SCRIPT="$PROJECT/scripts/validate/run-stage-checks.sh"
LOG_FILE=""  # set during init

# Colours
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Stage definitions ───────────────────────────────────────────────────────
# Order matters. Stages in the same group run in parallel.
# Format: "stage_name:validation_script:depends_on"
#   depends_on = comma-separated list of stages that must be "complete"

STAGE_ORDER=(
  "requirements-analyst:::"
  "solution-architect:post-architect:requirements-analyst"
  "developer:post-developer:solution-architect"
  "devops-engineer:post-devops:solution-architect"
  "code-reviewer:pre-review:developer,devops-engineer"
  "tester::developer"
  "uiux-reviewer::developer"
  "security-auditor::code-reviewer,tester"
  "compliance-officer:pre-compliance:security-auditor"
  "deploy-environment::compliance-officer"
  "deploy-production::deploy-environment"
)

# Parallel groups — stages that can run concurrently
# The runner launches all stages in a group simultaneously
PARALLEL_GROUPS=(
  "developer,devops-engineer"
  "code-reviewer,tester,uiux-reviewer"
)

# ─── Helper functions ─────────────────────────────────────────────────────────

timestamp() {
  date "+%Y-%m-%d %H:%M"
}

timestamp_compact() {
  date "+%Y%m%d-%H%M"
}

log() {
  local msg="$1"
  echo -e "$msg"
  if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
    # Strip ANSI colours for log file
    echo "$msg" | sed 's/\x1B\[[0-9;]*m//g' >> "$LOG_FILE"
  fi
}

log_event() {
  local event_type="$1"
  local stage="$2"
  local details="$3"
  if [[ -n "$LOG_FILE" && -f "$LOG_FILE" ]]; then
    cat >> "$LOG_FILE" <<EOF

### [$(date "+%H:%M")] ${event_type} — ${stage}
- **Action:** ${details}
EOF
  fi
}

# Read a field from pipeline-run.json
state_get() {
  local json_file="$1"
  local query="$2"
  python3 -c "
import json, sys
with open('$json_file') as f:
    d = json.load(f)
keys = '$query'.split('.')
val = d
for k in keys:
    if isinstance(val, dict):
        val = val.get(k)
    else:
        val = None
        break
print(val if val is not None else '')
" 2>/dev/null
}

# Update a field in pipeline-run.json
state_set() {
  local json_file="$1"
  local query="$2"
  local value="$3"
  python3 -c "
import json
with open('$json_file') as f:
    d = json.load(f)
keys = '$query'.split('.')
obj = d
for k in keys[:-1]:
    obj = obj.setdefault(k, {})
# Try to parse value as JSON (for numbers, bools, lists)
try:
    parsed = json.loads('$value')
except (json.JSONDecodeError, TypeError):
    parsed = '$value'
obj[keys[-1]] = parsed
with open('$json_file', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null
}

# Update totals in pipeline-run.json
update_totals() {
  local json_file="$1"
  python3 -c "
import json
with open('$json_file') as f:
    d = json.load(f)
totals = d['totals']
totals['process_time_seconds'] = 0
totals['total_remediation_rounds'] = 0
totals['validation_checks_total'] = 0
totals['validation_checks_passed'] = 0
totals['validation_checks_failed'] = 0
totals['stages_completed'] = 0
totals['stages_failed'] = 0
for stage_data in d['stages'].values():
    if stage_data.get('process_time_seconds'):
        totals['process_time_seconds'] += stage_data['process_time_seconds']
    totals['total_remediation_rounds'] += stage_data.get('remediation_rounds', 0)
    v = stage_data.get('validation', {})
    totals['validation_checks_total'] += v.get('checks_total', 0)
    totals['validation_checks_passed'] += v.get('checks_passed', 0)
    totals['validation_checks_failed'] += v.get('checks_failed', 0)
    if stage_data.get('status') == 'complete':
        totals['stages_completed'] += 1
    elif stage_data.get('status') == 'failed':
        totals['stages_failed'] += 1
with open('$json_file', 'w') as f:
    json.dump(d, f, indent=2)
" 2>/dev/null
}

# ─── Guard check ──────────────────────────────────────────────────────────────
# Returns 0 if all dependencies are met, 1 otherwise

check_guards() {
  local json_file="$1"
  local stage="$2"
  local deps=""

  # Find dependencies for this stage
  for entry in "${STAGE_ORDER[@]}"; do
    local name="${entry%%:*}"
    if [[ "$name" == "$stage" ]]; then
      # Extract depends_on (third colon-separated field)
      deps=$(echo "$entry" | cut -d: -f4)
      break
    fi
  done

  if [[ -z "$deps" ]]; then
    return 0  # no dependencies
  fi

  IFS=',' read -ra DEP_LIST <<< "$deps"
  for dep in "${DEP_LIST[@]}"; do
    local dep_status
    dep_status=$(state_get "$json_file" "stages.$dep.status")
    if [[ "$dep_status" != "complete" ]]; then
      echo "Guard failed: $dep is '$dep_status' (must be 'complete')"
      return 1
    fi
    # Check validation passed (if the dependency had a validation script)
    local dep_vfail
    dep_vfail=$(state_get "$json_file" "stages.$dep.validation.checks_failed")
    if [[ -n "$dep_vfail" && "$dep_vfail" != "0" && "$dep_vfail" != "None" ]]; then
      echo "Guard failed: $dep has $dep_vfail validation failures"
      return 1
    fi
  done

  return 0
}

# ─── Get next stage(s) to run ─────────────────────────────────────────────────
# Returns space-separated list of stages ready to run (handles parallel groups)

get_next_stages() {
  local json_file="$1"
  local ready=()

  for entry in "${STAGE_ORDER[@]}"; do
    local name="${entry%%:*}"
    local status
    status=$(state_get "$json_file" "stages.$name.status")

    if [[ "$status" == "complete" || "$status" == "running" || "$status" == "skipped" ]]; then
      continue
    fi

    if check_guards "$json_file" "$name" > /dev/null 2>&1; then
      ready+=("$name")
    fi
  done

  # Check if any ready stages belong to the same parallel group
  local result=()
  local used=()

  for stage in "${ready[@]}"; do
    # Skip if already included
    local already=false
    for u in "${used[@]:-}"; do
      [[ "$u" == "$stage" ]] && already=true && break
    done
    $already && continue

    # Check if this stage is in a parallel group
    local found_group=false
    for group in "${PARALLEL_GROUPS[@]}"; do
      if [[ ",$group," == *",$stage,"* ]]; then
        # Add all ready members of this group
        IFS=',' read -ra GROUP_MEMBERS <<< "$group"
        for member in "${GROUP_MEMBERS[@]}"; do
          for r in "${ready[@]}"; do
            if [[ "$r" == "$member" ]]; then
              result+=("$member")
              used+=("$member")
            fi
          done
        done
        found_group=true
        break
      fi
    done

    if [[ "$found_group" == false ]]; then
      result+=("$stage")
      used+=("$stage")
      break  # Only one non-parallel stage at a time
    fi

    # If we found a parallel group, don't add more non-group stages
    [[ ${#result[@]} -gt 0 ]] && break
  done

  echo "${result[@]:-}"
}

# ─── Run validation script ───────────────────────────────────────────────────

run_validation() {
  local json_file="$1"
  local stage="$2"
  local validation_script=""

  # Find validation script for this stage
  for entry in "${STAGE_ORDER[@]}"; do
    local name="${entry%%:*}"
    if [[ "$name" == "$stage" ]]; then
      validation_script=$(echo "$entry" | cut -d: -f2)
      break
    fi
  done

  if [[ -z "$validation_script" ]]; then
    log "  ${YELLOW}⚠  No validation script for $stage${NC}"
    return 0
  fi

  if [[ ! -x "$VALIDATE_SCRIPT" ]]; then
    log "  ${YELLOW}⚠  Validation runner not found: $VALIDATE_SCRIPT${NC}"
    return 0
  fi

  log "  ${BOLD}Running validation: $validation_script${NC}"
  local exit_code=0
  local output
  output=$(bash "$VALIDATE_SCRIPT" "$validation_script" "$PROJECT" 2>&1) || exit_code=$?

  # Parse results from output
  local checks_total checks_passed checks_failed
  checks_total=$(echo "$output" | grep -oP 'checks run' | head -1 || echo "")
  checks_passed=$(echo "$output" | grep -oP 'Passed:\s+\K\d+' || echo "0")
  checks_failed=$(echo "$output" | grep -oP 'Failed:\s+\K\d+' || echo "0")
  checks_total=$(echo "$output" | grep -oP '\d+(?= checks run)' || echo "0")

  state_set "$json_file" "stages.$stage.validation.checks_total" "$checks_total"
  state_set "$json_file" "stages.$stage.validation.checks_passed" "$checks_passed"
  state_set "$json_file" "stages.$stage.validation.checks_failed" "$checks_failed"

  if [[ $exit_code -eq 0 ]]; then
    log "  ${GREEN}✓  Validation passed ($checks_passed/$checks_total checks)${NC}"
    log_event "VALIDATION" "$stage" "Passed — $checks_passed/$checks_total checks"
  else
    log "  ${RED}✗  Validation failed ($checks_failed failures)${NC}"
    log_event "VALIDATION" "$stage" "FAILED — $checks_failed/$checks_total checks failed"
    echo "$output" | tail -20
  fi

  return $exit_code
}

# ─── Run a single stage ──────────────────────────────────────────────────────

run_stage() {
  local json_file="$1"
  local stage="$2"

  log ""
  log "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  log "${BOLD}Stage: ${CYAN}${stage}${NC}"
  log "${BOLD}Time:${NC}  $(timestamp)"
  log ""

  # Update state: running
  state_set "$json_file" "stages.$stage.status" "running"
  state_set "$json_file" "stages.$stage.started" "$(timestamp)"
  log_event "STAGE-START" "$stage" "Agent invoked"

  # Invoke Claude Code for this stage
  local start_seconds
  start_seconds=$(date +%s)

  log "  ${BOLD}Invoking Claude Code...${NC}"

  local claude_exit=0
  claude --print -p "run agent $stage" --cwd "$PROJECT" 2>&1 || claude_exit=$?

  local end_seconds
  end_seconds=$(date +%s)
  local duration=$((end_seconds - start_seconds))

  state_set "$json_file" "stages.$stage.completed" "$(timestamp)"
  state_set "$json_file" "stages.$stage.process_time_seconds" "$duration"

  if [[ $claude_exit -ne 0 ]]; then
    log "  ${RED}✗  Claude Code exited with code $claude_exit${NC}"
    state_set "$json_file" "stages.$stage.status" "failed"
    log_event "STAGE-FAILED" "$stage" "Claude Code exit code: $claude_exit (${duration}s)"
    update_totals "$json_file"
    return 1
  fi

  # Run validation
  local val_exit=0
  run_validation "$json_file" "$stage" || val_exit=$?

  if [[ $val_exit -ne 0 ]]; then
    log "  ${YELLOW}Stage $stage completed but validation failed${NC}"
    state_set "$json_file" "stages.$stage.status" "failed"
    log_event "STAGE-FAILED" "$stage" "Validation failed after ${duration}s"
    update_totals "$json_file"
    return 1
  fi

  # Success
  state_set "$json_file" "stages.$stage.status" "complete"
  log_event "STAGE-COMPLETE" "$stage" "Completed successfully in ${duration}s"
  update_totals "$json_file"

  log ""
  log "  ${GREEN}✓  $stage complete (${duration}s)${NC}"
  return 0
}

# ─── Status display ──────────────────────────────────────────────────────────

show_status() {
  local json_file="$1"

  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}Pipeline Status${NC}"
  echo -e "${BOLD}Project:${NC} $(basename "$PROJECT")"
  echo -e "${BOLD}Run:${NC}     $(state_get "$json_file" "run_id")"
  echo -e "${BOLD}Mode:${NC}    $(state_get "$json_file" "mode")"
  echo ""

  printf "  ${BOLD}%-22s  %-12s  %8s  %6s  %6s${NC}\n" \
    "Stage" "Status" "Time(s)" "V.Pass" "V.Fail"
  echo "  ──────────────────────────────────────────────────────────────"

  for entry in "${STAGE_ORDER[@]}"; do
    local name="${entry%%:*}"
    local status
    status=$(state_get "$json_file" "stages.$name.status")
    local ptime
    ptime=$(state_get "$json_file" "stages.$name.process_time_seconds")
    local vpass
    vpass=$(state_get "$json_file" "stages.$name.validation.checks_passed")
    local vfail
    vfail=$(state_get "$json_file" "stages.$name.validation.checks_failed")

    local colour="$NC"
    case "$status" in
      complete)    colour="$GREEN" ;;
      running)     colour="$CYAN" ;;
      failed)      colour="$RED" ;;
      not-started) colour="$NC" ;;
    esac

    printf "  %-22s  ${colour}%-12s${NC}  %8s  %6s  %6s\n" \
      "$name" "${status:-not-started}" "${ptime:-—}" "${vpass:-—}" "${vfail:-—}"
  done

  echo ""
  local total_time
  total_time=$(state_get "$json_file" "totals.process_time_seconds")
  local total_stages
  total_stages=$(state_get "$json_file" "totals.stages_completed")
  local total_failed
  total_failed=$(state_get "$json_file" "totals.stages_failed")
  echo -e "  ${BOLD}Total:${NC} ${total_time:-0}s  |  ${GREEN}${total_stages:-0} completed${NC}  |  ${RED}${total_failed:-0} failed${NC}"
  echo ""
}

# ─── Find latest run file ────────────────────────────────────────────────────

find_latest_run() {
  ls -1 "$RUNS_DIR"/run-*.json 2>/dev/null | sort | tail -1
}

# ─── Initialise a new run ────────────────────────────────────────────────────

init_run() {
  local mode="$1"
  local run_id="run-$(timestamp_compact)"
  local json_file="$RUNS_DIR/$run_id.json"

  mkdir -p "$RUNS_DIR"

  # Copy template
  if [[ ! -f "$TEMPLATES_DIR/pipeline-run.json" ]]; then
    echo -e "${RED}Error: pipeline-run.json template not found at $TEMPLATES_DIR${NC}"
    exit 1
  fi

  cp "$TEMPLATES_DIR/pipeline-run.json" "$json_file"

  # Fill in run metadata
  local genesis_version
  genesis_version=$(git -C "$PROJECT" log -1 --format="%h" 2>/dev/null || echo "unknown")

  state_set "$json_file" "run_id" "$run_id"
  state_set "$json_file" "project" "$(basename "$PROJECT")"
  state_set "$json_file" "started" "$(timestamp)"
  state_set "$json_file" "mode" "$mode"
  state_set "$json_file" "genesis_version" "$genesis_version"

  # Initialise all stage statuses
  for entry in "${STAGE_ORDER[@]}"; do
    local name="${entry%%:*}"
    state_set "$json_file" "stages.$name.status" "not-started"
  done

  # Create log file
  LOG_FILE="$RUNS_DIR/log-$(timestamp_compact).md"
  cp "$TEMPLATES_DIR/pipeline-log.md" "$LOG_FILE" 2>/dev/null || cat > "$LOG_FILE" <<EOF
# Pipeline Execution Log

---

## Run: $run_id
**Started:** $(timestamp)
**Mode:** $mode
**Genesis version:** $genesis_version

---
EOF

  # Replace placeholders in log template
  if [[ -f "$LOG_FILE" ]]; then
    sed -i '' "s/{run-id}/$run_id/g" "$LOG_FILE" 2>/dev/null || true
    sed -i '' "s/{YYYY-MM-DD HH:mm}/$(timestamp)/g" "$LOG_FILE" 2>/dev/null || true
    sed -i '' "s/{autopilot | co-pilot | manual}/$mode/g" "$LOG_FILE" 2>/dev/null || true
    sed -i '' "s/{commit hash}/$genesis_version/g" "$LOG_FILE" 2>/dev/null || true
  fi

  echo "$json_file"
}

# ─── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}The Genesis — Pipeline Runner${NC}"
  echo -e "${BOLD}Project:${NC} $(basename "$PROJECT")"
  echo ""

  local json_file=""

  case "$ACTION" in
    --status)
      json_file=$(find_latest_run)
      if [[ -z "$json_file" ]]; then
        echo -e "${YELLOW}No pipeline runs found.${NC}"
        exit 0
      fi
      show_status "$json_file"
      exit 0
      ;;

    --resume)
      json_file=$(find_latest_run)
      if [[ -z "$json_file" ]]; then
        echo -e "${RED}No pipeline run to resume.${NC}"
        exit 1
      fi
      LOG_FILE=$(ls -1 "$RUNS_DIR"/log-*.md 2>/dev/null | sort | tail -1)
      log "${CYAN}Resuming run: $(state_get "$json_file" "run_id")${NC}"
      log_event "RESUME" "pipeline" "Resumed from previous session"
      ;;

    --run|--mode)
      if [[ "$ACTION" == "--mode" ]]; then
        MODE="$3"
      fi
      json_file=$(init_run "$MODE")
      log "${GREEN}New run initialised: $(state_get "$json_file" "run_id")${NC}"
      log "  Mode: $MODE"
      log "  State: $json_file"
      log "  Log:   $LOG_FILE"
      ;;

    *)
      echo -e "${RED}Unknown action: $ACTION${NC}"
      echo "Usage: pipeline-runner.sh <project-root> [--run|--resume|--status] [--mode autopilot|co-pilot|manual]"
      exit 1
      ;;
  esac

  # ─── Main loop ─────────────────────────────────────────────────────────────
  local max_iterations=50  # safety limit
  local iteration=0

  while [[ $iteration -lt $max_iterations ]]; do
    ((iteration++))

    local next_stages
    next_stages=$(get_next_stages "$json_file")

    if [[ -z "$next_stages" ]]; then
      # Check if all stages are complete or if we're blocked
      local any_failed=false
      local all_done=true
      for entry in "${STAGE_ORDER[@]}"; do
        local name="${entry%%:*}"
        local status
        status=$(state_get "$json_file" "stages.$name.status")
        if [[ "$status" == "failed" ]]; then
          any_failed=true
        fi
        if [[ "$status" != "complete" && "$status" != "skipped" && "$status" != "failed" ]]; then
          all_done=false
        fi
      done

      if [[ "$all_done" == true ]]; then
        if [[ "$any_failed" == true ]]; then
          log ""
          log "${RED}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          log "${RED}PIPELINE FINISHED WITH FAILURES${NC}"
          state_set "$json_file" "completed" "$(timestamp)"
        else
          log ""
          log "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
          log "${GREEN}PIPELINE COMPLETE — ALL STAGES PASSED${NC}"
          state_set "$json_file" "completed" "$(timestamp)"
        fi
        break
      else
        log ""
        log "${RED}PIPELINE BLOCKED — no stages can proceed${NC}"
        log "Check guard dependencies and fix failed stages."
        break
      fi
    fi

    # Run stage(s)
    IFS=' ' read -ra STAGES_TO_RUN <<< "$next_stages"

    if [[ ${#STAGES_TO_RUN[@]} -gt 1 ]]; then
      log ""
      log "${BOLD}Parallel group: ${STAGES_TO_RUN[*]}${NC}"

      # Run parallel stages sequentially for now
      # (true parallel would need background processes + wait)
      # TODO: implement true parallel with background processes
      for stage in "${STAGES_TO_RUN[@]}"; do
        run_stage "$json_file" "$stage" || true
      done
    else
      run_stage "$json_file" "${STAGES_TO_RUN[0]}" || true
    fi

    show_status "$json_file"
  done

  # Final status
  show_status "$json_file"
  update_totals "$json_file"

  log ""
  log "${BOLD}State file:${NC} $json_file"
  log "${BOLD}Log file:${NC}   $LOG_FILE"
  log ""
  log "To check convergence across runs:"
  log "  ${CYAN}scripts/convergence-report.sh $PROJECT${NC}"
  log ""
}

main
