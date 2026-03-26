#!/usr/bin/env bash
# =============================================================================
# propagate-updates.sh
#
# Propagates updated generic files from the Global Project Structure template
# to one or more existing project folders.
#
# Usage:
#   ./propagate-updates.sh <project-path> [<project-path> ...]
#   ./propagate-updates.sh --all        # propagate to all sibling projects
#
# Behaviour:
#   OVERWRITE   — platform-agnostic generic files (always latest company standards)
#   PLATFORM    — only the deployment-{platform}.md matching project's cloud
#   REMOVE      — deployment platform files that don't match the project's cloud
#   ADD ONLY    — new template files not yet present in the target project
#   WARN & SKIP — compliance-checklist.md, pipeline.md (may have filled data)
#   NEVER TOUCH — CLAUDE.md, agent_docs/project/*.md (project-specific)
# =============================================================================

set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PARENT_DIR="$(dirname "$SRC")"

# Colours
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Counters
OVERWRITTEN=0
ADDED=0
REMOVED=0
WARNED=0

# =============================================================================
# Platform detection
# Reads CLAUDE.md and returns space-separated list of applicable deployment files
# =============================================================================
detect_platform_files() {
  local claude_md="$1"
  local cloud_line
  cloud_line=$(grep -i "^\*\*Cloud:\*\*\|^- \*\*Cloud:\*\*" "$claude_md" 2>/dev/null | head -1 | tr '[:upper:]' '[:lower:]')

  local files=()

  [[ "$cloud_line" =~ aws ]]                          && files+=("deployment-aws.md")
  [[ "$cloud_line" =~ gcp || "$cloud_line" =~ google ]] && files+=("deployment-gcp.md")
  [[ "$cloud_line" =~ alibaba || "$cloud_line" =~ alicloud ]] && files+=("deployment-alicloud.md")
  [[ "$cloud_line" =~ on.premise || "$cloud_line" =~ on_premise || "$cloud_line" =~ onpremise ]] && files+=("deployment-onpremise.md")
  [[ "$cloud_line" =~ vercel || "$cloud_line" =~ cloudflare ]] && files+=("deployment-vercel-cloudflare.md")

  # If nothing matched (e.g. pitching template / unknown) — include all
  if [[ ${#files[@]} -eq 0 ]]; then
    files=(deployment-aws.md deployment-gcp.md deployment-alicloud.md deployment-onpremise.md deployment-vercel-cloudflare.md)
  fi

  echo "${files[@]}"
}

# All platform-specific deployment files (used to identify which to remove)
ALL_PLATFORM_FILES=(
  deployment-aws.md
  deployment-gcp.md
  deployment-alicloud.md
  deployment-onpremise.md
  deployment-vercel-cloudflare.md
)

# Platform-agnostic generic files (always copied regardless of cloud)
AGNOSTIC_FILES=(
  api-conventions.md
  nfr-baseline.md
  security-checklist.md
  deployment-standards.md
  git-workflow.md
  uiux-standards.md
  agent-roles.md
)

# =============================================================================
# Resolve target projects
# =============================================================================
TARGETS=()

if [[ "${1:-}" == "--all" ]]; then
  echo -e "${CYAN}Scanning for projects in ${PARENT_DIR}...${NC}"
  while IFS= read -r -d '' dir; do
    project_dir="$(dirname "$dir")"
    if [[ "$project_dir" != "$SRC" && "$project_dir" != "${SRC}.bak" ]]; then
      TARGETS+=("$project_dir")
      echo "  Found: $(basename "$project_dir")"
    fi
  done < <(find "$PARENT_DIR" -maxdepth 2 -name "CLAUDE.md" -not -path "$SRC/*" -not -path "${SRC}.bak/*" -print0)
else
  if [[ $# -eq 0 ]]; then
    echo -e "${RED}Error: no target project path provided.${NC}"
    echo "Usage: $0 <project-path> [<project-path> ...]"
    echo "       $0 --all"
    exit 1
  fi
  for arg in "$@"; do
    TARGETS+=("$(cd "$arg" && pwd)")
  done
fi

if [[ ${#TARGETS[@]} -eq 0 ]]; then
  echo -e "${RED}No target projects found.${NC}"
  exit 1
fi

echo ""
echo -e "${BOLD}Source template:${NC} $SRC"
echo -e "${BOLD}Targets:${NC} ${#TARGETS[@]} project(s)"
echo ""

# =============================================================================
# Process each target project
# =============================================================================
for DEST in "${TARGETS[@]}"; do
  PROJECT_NAME="$(basename "$DEST")"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BOLD}Project: ${CYAN}${PROJECT_NAME}${NC}"
  echo -e "${BOLD}Path:${NC} $DEST"
  echo ""

  if [[ ! -f "$DEST/CLAUDE.md" ]]; then
    echo -e "  ${RED}✗ Skipping — no CLAUDE.md found. Not a valid project folder.${NC}"
    echo ""
    continue
  fi

  GENERIC_SRC="$SRC/agent_docs/generic"
  GENERIC_DEST="$DEST/agent_docs/generic"
  mkdir -p "$GENERIC_DEST"

  # Detect which platform files apply to this project
  IFS=' ' read -r -a APPLICABLE_PLATFORM_FILES <<< "$(detect_platform_files "$DEST/CLAUDE.md")"
  echo -e "  ${BOLD}Platform files:${NC} ${APPLICABLE_PLATFORM_FILES[*]}"
  echo ""

  # ---------------------------------------------------------------------------
  # 1. OVERWRITE — platform-agnostic generic files
  # ---------------------------------------------------------------------------
  echo -e "  ${BOLD}[1] Updating platform-agnostic generic files...${NC}"

  for filename in "${AGNOSTIC_FILES[@]}"; do
    src_file="$GENERIC_SRC/$filename"
    dest_file="$GENERIC_DEST/$filename"

    [[ ! -f "$src_file" ]] && continue

    if [[ -f "$dest_file" ]]; then
      if ! diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
        cp "$src_file" "$dest_file"
        echo -e "    ${GREEN}↺  Updated:${NC} agent_docs/generic/$filename"
        ((OVERWRITTEN++))
      else
        echo -e "    —  No change: agent_docs/generic/$filename"
      fi
    else
      cp "$src_file" "$dest_file"
      echo -e "    ${GREEN}+  Added:${NC} agent_docs/generic/$filename"
      ((ADDED++))
    fi
  done
  echo ""

  # ---------------------------------------------------------------------------
  # 1b. OVERWRITE — agent role definition files (agents/*.md)
  # ---------------------------------------------------------------------------
  echo -e "  ${BOLD}[1b] Updating agent role definitions...${NC}"

  AGENTS_SRC="$GENERIC_SRC/agents"
  AGENTS_DEST="$GENERIC_DEST/agents"
  mkdir -p "$AGENTS_DEST"

  # Sync all agent files from Genesis to child project
  for src_file in "$AGENTS_SRC"/*.md; do
    [[ ! -f "$src_file" ]] && continue
    filename="$(basename "$src_file")"
    dest_file="$AGENTS_DEST/$filename"

    if [[ -f "$dest_file" ]]; then
      if ! diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
        cp "$src_file" "$dest_file"
        echo -e "    ${GREEN}↺  Updated:${NC} agent_docs/generic/agents/$filename"
        ((OVERWRITTEN++))
      else
        echo -e "    —  No change: agent_docs/generic/agents/$filename"
      fi
    else
      cp "$src_file" "$dest_file"
      echo -e "    ${GREEN}+  Added:${NC} agent_docs/generic/agents/$filename"
      ((ADDED++))
    fi
  done

  # Remove agent files in child that no longer exist in Genesis (e.g. pilot-spec.md merged into orchestrator.md)
  for dest_file in "$AGENTS_DEST"/*.md; do
    [[ ! -f "$dest_file" ]] && continue
    filename="$(basename "$dest_file")"
    if [[ ! -f "$AGENTS_SRC/$filename" ]]; then
      rm "$dest_file"
      echo -e "    ${RED}✗  Removed (no longer in Genesis):${NC} agent_docs/generic/agents/$filename"
      ((REMOVED++))
    fi
  done

  # Remove pilot-spec.md from generic/ root if it exists (merged into agents/orchestrator.md)
  if [[ -f "$GENERIC_DEST/pilot-spec.md" ]]; then
    rm "$GENERIC_DEST/pilot-spec.md"
    echo -e "    ${RED}✗  Removed (merged into agents/orchestrator.md):${NC} agent_docs/generic/pilot-spec.md"
    ((REMOVED++))
  fi
  echo ""

  # ---------------------------------------------------------------------------
  # 2. PLATFORM — copy only applicable deployment files, remove others
  # ---------------------------------------------------------------------------
  echo -e "  ${BOLD}[2] Syncing platform-specific deployment files...${NC}"

  for platform_file in "${ALL_PLATFORM_FILES[@]}"; do
    src_file="$GENERIC_SRC/$platform_file"
    dest_file="$GENERIC_DEST/$platform_file"
    applicable=false

    for applicable_file in "${APPLICABLE_PLATFORM_FILES[@]}"; do
      [[ "$platform_file" == "$applicable_file" ]] && applicable=true && break
    done

    if [[ "$applicable" == true ]]; then
      # Should be present — copy or update
      if [[ ! -f "$src_file" ]]; then
        echo -e "    ${YELLOW}⚠  Source missing: agent_docs/generic/$platform_file${NC}"
        continue
      fi
      if [[ -f "$dest_file" ]]; then
        if ! diff -q "$src_file" "$dest_file" > /dev/null 2>&1; then
          cp "$src_file" "$dest_file"
          echo -e "    ${GREEN}↺  Updated:${NC} agent_docs/generic/$platform_file"
          ((OVERWRITTEN++))
        else
          echo -e "    —  No change: agent_docs/generic/$platform_file"
        fi
      else
        cp "$src_file" "$dest_file"
        echo -e "    ${GREEN}+  Added:${NC} agent_docs/generic/$platform_file"
        ((ADDED++))
      fi
    else
      # Should NOT be present — remove if exists
      if [[ -f "$dest_file" ]]; then
        rm "$dest_file"
        echo -e "    ${RED}✗  Removed (wrong platform):${NC} agent_docs/generic/$platform_file"
        ((REMOVED++))
      fi
    fi
  done
  echo ""

  # ---------------------------------------------------------------------------
  # 3. ADD ONLY — new template files not yet present in the target
  # ---------------------------------------------------------------------------
  echo -e "  ${BOLD}[3] Adding new template files (if missing)...${NC}"

  # api-spec.yaml
  API_SPEC_SRC="$SRC/agent_docs/templates/specs/api-spec.yaml"
  API_SPEC_DEST="$DEST/agent_docs/project/specs/api-spec.yaml"
  mkdir -p "$DEST/agent_docs/project/specs"

  if [[ ! -f "$API_SPEC_DEST" ]]; then
    cp "$API_SPEC_SRC" "$API_SPEC_DEST"
    echo -e "    ${GREEN}+  Added:${NC} agent_docs/project/specs/api-spec.yaml"
    echo -e "    ${YELLOW}   ⚠  ACTION REQUIRED: fill in api-spec.yaml with actual endpoints before development starts${NC}"
    ((ADDED++))
  else
    echo -e "    —  Exists: agent_docs/project/specs/api-spec.yaml (skipped)"
  fi

  # requirements-include-files folder
  REQ_DIR="$DEST/agent_docs/project/specs/requirements-include-files"
  if [[ ! -d "$REQ_DIR" ]]; then
    mkdir -p "$REQ_DIR"
    STARTER="$SRC/agent_docs/templates/specs/requirements-include-files/01-functional.md"
    if [[ -f "$STARTER" ]]; then
      cp "$STARTER" "$REQ_DIR/01-functional.md"
      echo -e "    ${GREEN}+  Added:${NC} agent_docs/project/specs/requirements-include-files/01-functional.md"
      ((ADDED++))
    else
      echo -e "    ${GREEN}+  Created:${NC} agent_docs/project/specs/requirements-include-files/"
    fi
  fi

  # artifacts subfolders
  for artifact_dir in requirements architecture development code-review uiux-review test security devops compliance; do
    artifact_path="$DEST/artifacts/$artifact_dir"
    if [[ ! -d "$artifact_path" ]]; then
      mkdir -p "$artifact_path"
      echo -e "    ${GREEN}+  Created:${NC} artifacts/$artifact_dir/"
      ((ADDED++))
    fi
  done
  echo ""

  # ---------------------------------------------------------------------------
  # 4. WARN & SKIP — files that may have filled-in project data
  # ---------------------------------------------------------------------------
  echo -e "  ${BOLD}[4] Checking files that need manual merge...${NC}"

  NEEDS_MERGE=()

  # compliance-checklist.md
  CHECKLIST_DEST="$DEST/agent_docs/project/compliance-checklist.md"
  CHECKLIST_SRC="$SRC/agent_docs/templates/compliance-checklist.md"
  if [[ -f "$CHECKLIST_DEST" ]]; then
    SRC_VERSION=$(grep -m1 "checklist-version:" "$CHECKLIST_SRC" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "unknown")
    DEST_VERSION=$(grep -m1 "checklist-version:" "$CHECKLIST_DEST" | grep -oE '[0-9]{4}-[0-9]{2}-[0-9]{2}' || echo "unknown")
    if [[ "$SRC_VERSION" != "$DEST_VERSION" ]]; then
      NEEDS_MERGE+=("agent_docs/project/compliance-checklist.md (template: $SRC_VERSION — project: $DEST_VERSION)")
      ((WARNED++))
    else
      echo -e "    —  Up to date: agent_docs/project/compliance-checklist.md"
    fi
  fi

  # pipeline.md
  PIPELINE_DEST="$DEST/agent_docs/project/pipeline.md"
  PIPELINE_SRC="$SRC/agent_docs/templates/pipeline.md"
  if [[ -f "$PIPELINE_DEST" && -f "$PIPELINE_SRC" ]]; then
    if ! diff -q "$PIPELINE_SRC" "$PIPELINE_DEST" > /dev/null 2>&1; then
      NEEDS_MERGE+=("agent_docs/project/pipeline.md (pipeline stages have been updated)")
      ((WARNED++))
    else
      echo -e "    —  Up to date: agent_docs/project/pipeline.md"
    fi
  fi

  if [[ ${#NEEDS_MERGE[@]} -gt 0 ]]; then
    echo -e "    ${YELLOW}⚠  Manual merge required for:${NC}"
    for item in "${NEEDS_MERGE[@]}"; do
      echo -e "    ${YELLOW}   • $item${NC}"
    done
    echo -e "    ${YELLOW}   See scripts/MERGE-GUIDE.md for instructions.${NC}"
  fi

  echo ""
  echo -e "  ${BOLD}Done:${NC} $PROJECT_NAME"
  echo ""
done

# =============================================================================
# Summary
# =============================================================================
echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}Summary${NC}"
echo -e "  ${GREEN}Updated/overwritten:${NC} $OVERWRITTEN file(s)"
echo -e "  ${GREEN}Added (new):${NC}         $ADDED file(s)"
echo -e "  ${RED}Removed (wrong platform):${NC} $REMOVED file(s)"
echo -e "  ${YELLOW}Needs manual merge:${NC}  $WARNED file(s)"
echo ""
if [[ $WARNED -gt 0 ]]; then
  echo -e "  ${YELLOW}See scripts/MERGE-GUIDE.md for how to merge skipped files.${NC}"
  echo ""
fi
echo -e "${GREEN}Propagation complete.${NC}"
