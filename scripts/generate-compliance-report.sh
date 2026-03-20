#!/usr/bin/env bash
# generate-compliance-report.sh — create a dated compliance checklist in reports/
#
# Usage (interactive):
#   ./scripts/generate-compliance-report.sh
#
# Usage (non-interactive):
#   ./scripts/generate-compliance-report.sh "My Project" "v1.2.0" "John Smith" "AWS" "production"

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
GENERIC_DIR="$PROJECT_DIR/agent_docs/generic"
TEMPLATE="$PROJECT_DIR/agent_docs/project/compliance-checklist.md"

# Fall back to the master template if project copy hasn't been created yet
if [[ ! -f "$TEMPLATE" ]]; then
  TEMPLATE="$PROJECT_DIR/agent_docs/templates/compliance-checklist.md"
fi

# ── Helper: extract last-reviewed date from a generic md file ─────────────────
get_last_reviewed() {
  local file="$1"
  grep -m1 'last-reviewed:' "$file" 2>/dev/null \
    | sed 's/.*last-reviewed:[[:space:]]*//' \
    | sed 's/[[:space:]].*//' \
    | tr -d ' ' \
    || echo "unknown"
}

# ── Helper: extract synced date from checklist template for a given file ───────
get_synced_date() {
  local file="$1"
  local filename
  filename="$(basename "$file")"
  grep -m1 "| $filename" "$TEMPLATE" 2>/dev/null \
    | awk -F'|' '{print $3}' \
    | tr -d ' ' \
    || echo "unknown"
}

# ── Step 1: Drift check — compare source file dates to checklist sync dates ───
echo ""
echo "╔══════════════════════════════════════════════╗"
echo "║  Claude Code — Generate Compliance Report   ║"
echo "╚══════════════════════════════════════════════╝"
echo ""
echo "  Checking source file versions against checklist..."
echo ""

DRIFT_FOUND=false
DRIFT_FILES=()

while IFS= read -r -d '' source_file; do
  filename="$(basename "$source_file")"
  source_date="$(get_last_reviewed "$source_file")"
  synced_date="$(get_synced_date "$source_file")"

  if [[ "$source_date" == "unknown" || "$synced_date" == "unknown" ]]; then
    printf "  %-32s  source: %-12s  synced: %-12s  ⚠️  (could not parse dates)\n" \
      "$filename" "$source_date" "$synced_date"
  elif [[ "$source_date" > "$synced_date" ]]; then
    printf "  %-32s  source: %-12s  synced: %-12s  ❌ OUTDATED\n" \
      "$filename" "$source_date" "$synced_date"
    DRIFT_FOUND=true
    DRIFT_FILES+=("$filename (source: $source_date, synced: $synced_date)")
  else
    printf "  %-32s  source: %-12s  synced: %-12s  ✅\n" \
      "$filename" "$source_date" "$synced_date"
  fi
done < <(find "$GENERIC_DIR" -name "*.md" -print0 | sort -z)

echo ""

if [[ "$DRIFT_FOUND" == "true" ]]; then
  echo "  ⚠️  WARNING: The following source files have been updated since the"
  echo "  checklist was last synchronised:"
  echo ""
  for f in "${DRIFT_FILES[@]}"; do
    echo "    • $f"
  done
  echo ""
  echo "  The checklist may be missing new items from these files."
  echo "  You should review the changed files and update the checklist"
  echo "  template before generating a report."
  echo ""
  read -rp "  Continue anyway? [y/N]: " CONTINUE_ANYWAY
  CONTINUE_ANYWAY="${CONTINUE_ANYWAY:-N}"
  if [[ ! "$CONTINUE_ANYWAY" =~ ^[Yy]$ ]]; then
    echo ""
    echo "  Aborted. Please update the checklist template first:"
    echo "    agent_docs/templates/compliance-checklist.md"
    echo ""
    echo "  After updating, bump the 'Synced to Checklist' dates in the"
    echo "  'Source File Versions' table to match the source file dates."
    echo ""
    exit 0
  fi
  echo ""
fi

# ── Inputs ────────────────────────────────────────────────────────────────────
PROJECT_NAME="${1:-}"
RELEASE="${2:-}"
REVIEWER="${3:-}"
CLOUD="${4:-}"
ENVIRONMENT="${5:-}"

# Read project name from CLAUDE.md if not provided
if [[ -z "$PROJECT_NAME" && -f "$PROJECT_DIR/CLAUDE.md" ]]; then
  PROJECT_NAME=$(grep -m1 "^\*\*Project\*\*\|^# Project:" "$PROJECT_DIR/CLAUDE.md" \
    | sed 's/.*Project[^:]*:[ ]*//' | tr -d '[]' | xargs)
fi

if [[ -z "$PROJECT_NAME" ]]; then
  read -rp "  Project name: " PROJECT_NAME
fi

if [[ -z "$RELEASE" ]]; then
  read -rp "  Release / version / sprint: " RELEASE
fi

if [[ -z "$REVIEWER" ]]; then
  read -rp "  Reviewer name: " REVIEWER
fi

if [[ -z "$CLOUD" ]]; then
  echo ""
  echo "  Cloud / deployment architecture:"
  echo "    1) AWS"
  echo "    2) GCP"
  echo "    3) Alibaba Cloud"
  echo "    4) On-Premise"
  echo "    5) Multiple"
  echo ""
  read -rp "  Select [1-5]: " CLOUD_CHOICE
  case "$CLOUD_CHOICE" in
    1) CLOUD="AWS" ;;
    2) CLOUD="GCP" ;;
    3) CLOUD="Alibaba Cloud" ;;
    4) CLOUD="On-Premise" ;;
    5) CLOUD="Multiple" ;;
    *) CLOUD="$CLOUD_CHOICE" ;;
  esac
fi

if [[ -z "$ENVIRONMENT" ]]; then
  echo ""
  echo "  Target environment:"
  echo "    1) Staging"
  echo "    2) Production"
  echo ""
  read -rp "  Select [1-2]: " ENV_CHOICE
  case "$ENV_CHOICE" in
    1) ENVIRONMENT="Staging" ;;
    2) ENVIRONMENT="Production" ;;
    *) ENVIRONMENT="$ENV_CHOICE" ;;
  esac
fi

# ── Generate timestamp ────────────────────────────────────────────────────────
TIMESTAMP="$(date '+%Y%m%d-%H%M%S')"
REVIEW_DATE="$(date '+%Y-%m-%d')"
REPORT_DIR="$PROJECT_DIR/reports"
REPORT_FILE="$REPORT_DIR/compliance-check-$TIMESTAMP.md"

# ── Confirm ───────────────────────────────────────────────────────────────────
echo ""
echo "  Project     : $PROJECT_NAME"
echo "  Release     : $RELEASE"
echo "  Reviewer    : $REVIEWER"
echo "  Platform    : $CLOUD"
echo "  Environment : $ENVIRONMENT"
echo "  Output file : reports/compliance-check-$TIMESTAMP.md"
echo ""
read -rp "  Generate report? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# ── Create reports directory ──────────────────────────────────────────────────
mkdir -p "$REPORT_DIR"

# ── Substitute placeholders and write report ──────────────────────────────────
sed \
  -e "s/\[Project Name\]/$PROJECT_NAME/g" \
  -e "s/\[Version \/ Sprint \/ Tag\]/$RELEASE/g" \
  -e "s/\[Name\]/$REVIEWER/g" \
  -e "s/\[AWS \/ GCP \/ Alicloud \/ On-Premise\]/$CLOUD/g" \
  -e "s/\[YYYY-MM-DD\]/$REVIEW_DATE/g" \
  -e "s/\[TIMESTAMP\]/$TIMESTAMP/g" \
  -e "/\[ \] Staging.*\[ \] Production/{ s/\[ \] Staging/[x] Staging/; s/\[ \] Production/[ ] Production/; }" \
  "$TEMPLATE" > "$REPORT_FILE"

# Set environment checkbox based on selection
if [[ "$ENVIRONMENT" == "Production" ]]; then
  sed -i '' \
    -e 's/\[x\] Staging/[ ] Staging/' \
    -e 's/\[ \] Production/[x] Production/' \
    "$REPORT_FILE"
fi

# ── Done ──────────────────────────────────────────────────────────────────────
echo "  ✓ Report created: $REPORT_FILE"
echo ""
echo "  Next steps:"
echo "    1. Open the report and fill in the Status column for every row"
echo "    2. Add Notes for every ⚠️ (Partially Compliant) and ❌ (Non-Compliant) item"
echo "    3. Complete the Action Items table at the bottom"
echo "    4. Fill in the Summary table once all rows are done"
echo "    5. Get sign-off from the lead developer before release"
echo ""

# ── Offer to open in VS Code ──────────────────────────────────────────────────
if command -v code &>/dev/null; then
  read -rp "  Open report in VS Code? [Y/n]: " OPEN_CODE
  OPEN_CODE="${OPEN_CODE:-Y}"
  if [[ "$OPEN_CODE" =~ ^[Yy]$ ]]; then
    code "$REPORT_FILE"
  fi
fi
echo ""
