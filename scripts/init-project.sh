#!/usr/bin/env bash
# init-project.sh — scaffold a new Claude Code project from the global template
#
# Usage (interactive):
#   ./scripts/init-project.sh
#
# Usage (non-interactive):
#   ./scripts/init-project.sh "My Project Name" /path/to/destination
#
# What it does:
#   1. Creates the destination directory
#   2. Copies CLAUDE.md (with project name substituted)
#   3. Copies .claude/settings.json
#   4. Copies agent_docs/generic/ (company standards — unchanged)
#   5. Copies agent_docs/templates/ → agent_docs/project/ (ready to fill in)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# ── Banner ────────────────────────────────────────────────────────────────────
echo ""
echo "╔══════════════════════════════════════════╗"
echo "║    Claude Code — New Project Scaffold    ║"
echo "╚══════════════════════════════════════════╝"
echo ""

# ── Inputs: arguments or interactive prompts ──────────────────────────────────
PROJECT_NAME="${1:-}"
DEST="${2:-}"
CLOUD_CHOICE="${3:-}"

if [[ -z "$PROJECT_NAME" ]]; then
  read -rp "  Project name: " PROJECT_NAME
fi
if [[ -z "$PROJECT_NAME" ]]; then
  echo "Error: project name cannot be empty."
  exit 1
fi

if [[ -z "$DEST" ]]; then
  SLUG="${PROJECT_NAME// /-}"
  SLUG="${SLUG,,}"
  DEFAULT_DEST="$HOME/Projects/$SLUG"
  read -rp "  Destination path [$DEFAULT_DEST]: " DEST
  DEST="${DEST:-$DEFAULT_DEST}"
fi

DEST="$(eval echo "$DEST")"  # expand ~ if present

# ── Cloud / Deployment Architecture ──────────────────────────────────────────
if [[ -z "$CLOUD_CHOICE" ]]; then
  echo ""
  echo "  Cloud / deployment architecture:"
  echo "    1) AWS"
  echo "    2) GCP"
  echo "    3) Alibaba Cloud"
  echo "    4) On-Premise"
  echo "    5) Vercel (frontend) + Cloudflare (API/edge)"
  echo "    6) Multiple (copy all)"
  echo ""
  read -rp "  Select [1-6]: " CLOUD_CHOICE
fi

case "$CLOUD_CHOICE" in
  1) CLOUD_LABEL="AWS";                           CLOUD_FILES=("deployment-aws.md") ;;
  2) CLOUD_LABEL="GCP";                           CLOUD_FILES=("deployment-gcp.md") ;;
  3) CLOUD_LABEL="Alibaba Cloud";                 CLOUD_FILES=("deployment-alicloud.md") ;;
  4) CLOUD_LABEL="On-Premise";                    CLOUD_FILES=("deployment-onpremise.md") ;;
  5) CLOUD_LABEL="Vercel + Cloudflare";           CLOUD_FILES=("deployment-vercel-cloudflare.md") ;;
  6) CLOUD_LABEL="Multiple";                      CLOUD_FILES=("deployment-aws.md" "deployment-gcp.md" "deployment-alicloud.md" "deployment-onpremise.md" "deployment-vercel-cloudflare.md") ;;
  *)
    echo "Error: invalid selection '$CLOUD_CHOICE'. Choose 1–6."
    exit 1
    ;;
esac

# ── Confirm ───────────────────────────────────────────────────────────────────
echo ""
echo "  Project name  : $PROJECT_NAME"
echo "  Cloud platform: $CLOUD_LABEL"
echo "  Destination   : $DEST"
echo "  Template      : $TEMPLATE_DIR"
echo ""
read -rp "  Proceed? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# ── Guard: destination must not exist ─────────────────────────────────────────
if [[ -d "$DEST" ]]; then
  echo "Error: destination already exists: $DEST"
  echo "Choose a new path or delete the existing directory first."
  exit 1
fi

# ── Create destination structure ──────────────────────────────────────────────
mkdir -p "$DEST/.claude"
mkdir -p "$DEST/agent_docs/generic"
mkdir -p "$DEST/agent_docs/project/specs"
mkdir -p "$DEST/agent_docs/project/specs/requirements-include-files"
mkdir -p "$DEST/artifacts/requirements"
mkdir -p "$DEST/artifacts/architecture"
mkdir -p "$DEST/artifacts/development"
mkdir -p "$DEST/artifacts/code-review"
mkdir -p "$DEST/artifacts/test"
mkdir -p "$DEST/artifacts/security"
mkdir -p "$DEST/artifacts/compliance"

# ── Copy and patch CLAUDE.md ──────────────────────────────────────────────────
sed -e "s/\[Project Name\]/$PROJECT_NAME/g" \
    -e "s/\[AWS \/ GCP \/ Azure\]/$CLOUD_LABEL/g" \
  "$TEMPLATE_DIR/CLAUDE.md" > "$DEST/CLAUDE.md"
echo "  ✓ CLAUDE.md"

# ── Copy .claude/settings.json ────────────────────────────────────────────────
cp "$TEMPLATE_DIR/.claude/settings.json" "$DEST/.claude/settings.json"
echo "  ✓ .claude/settings.json"

# ── Copy generic docs (platform-agnostic only + selected cloud file/s) ───────
GENERIC_SKIP=("deployment-aws.md" "deployment-gcp.md" "deployment-alicloud.md" "deployment-onpremise.md" "deployment-vercel-cloudflare.md")

for f in "$TEMPLATE_DIR/agent_docs/generic/"*.md; do
  filename="$(basename "$f")"
  # Skip all cloud-specific files — copy selectively below
  skip=false
  for skip_name in "${GENERIC_SKIP[@]}"; do
    [[ "$filename" == "$skip_name" ]] && skip=true && break
  done
  $skip && continue
  cp "$f" "$DEST/agent_docs/generic/$filename"
  echo "  ✓ agent_docs/generic/$filename"
done

# Copy only the selected cloud deployment file(s)
for cloud_file in "${CLOUD_FILES[@]}"; do
  src="$TEMPLATE_DIR/agent_docs/generic/$cloud_file"
  if [[ -f "$src" ]]; then
    cp "$src" "$DEST/agent_docs/generic/$cloud_file"
    echo "  ✓ agent_docs/generic/$cloud_file"
  else
    echo "  ! Warning: $cloud_file not found in template — skipping"
  fi
done

# ── Copy templates → project (substitute project name) ───────────────────────
for f in "$TEMPLATE_DIR/agent_docs/templates/"*.md; do
  filename="$(basename "$f")"
  sed -e "s/\[Project Name\]/$PROJECT_NAME/g" \
      -e "s/\[AWS \/ GCP \/ Azure\]/$CLOUD_LABEL/g" \
      -e "s/\[AWS \/ GCP \/ Alicloud \/ On-Premise\]/$CLOUD_LABEL/g" \
    "$f" > "$DEST/agent_docs/project/$filename"
  echo "  ✓ agent_docs/project/$filename"
done

for f in "$TEMPLATE_DIR/agent_docs/templates/specs/"*.md; do
  filename="$(basename "$f")"
  sed "s/\[Project Name\]/$PROJECT_NAME/g" "$f" > "$DEST/agent_docs/project/specs/$filename"
  echo "  ✓ agent_docs/project/specs/$filename"
done

# ── Seed requirements folder with starter file ───────────────────────────────
TODAY=$(date +%Y-%m-%d)
cat > "$DEST/agent_docs/project/specs/requirements-include-files/01-functional.md" << EOF
<!-- last-updated: $TODAY -->

# Functional Requirements

> Paste or write client functional requirements here.
> Keep the \`last-updated\` tag current whenever this file changes.
> Register this file in \`agent_docs/project/specs/requirements.md\`.
EOF
echo "  ✓ agent_docs/project/specs/requirements-include-files/01-functional.md"

# ── Add .gitkeep files so artifact folders are tracked by git ─────────────────
for dir in requirements architecture development code-review test security compliance; do
  touch "$DEST/artifacts/$dir/.gitkeep"
done
echo "  ✓ artifacts/ subfolders (with .gitkeep)"

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "  Project scaffolded at: $DEST"
echo ""
echo "  Next steps:"
echo "    1. Fill in agent_docs/project/stack.md with exact versions"
echo "    2. Paste client requirements into agent_docs/project/specs/requirements-include-files/01-functional.md"
echo "    3. Register requirements files in agent_docs/project/specs/requirements.md"
echo "    4. Review agent_docs/project/pipeline.md — confirm active agents and paths"
echo "    5. git init && git add . && git commit -m 'chore: initialise project scaffold'"
echo ""

# ── Offer to open in VS Code ──────────────────────────────────────────────────
if command -v code &>/dev/null; then
  read -rp "  Open in VS Code? [Y/n]: " OPEN_CODE
  OPEN_CODE="${OPEN_CODE:-Y}"
  if [[ "$OPEN_CODE" =~ ^[Yy]$ ]]; then
    code "$DEST"
    echo "  Opened: $DEST"
  fi
else
  echo "  (VS Code CLI not found — open the folder manually)"
fi
echo ""
