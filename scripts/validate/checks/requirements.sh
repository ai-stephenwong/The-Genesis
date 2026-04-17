#!/usr/bin/env bash
# =============================================================================
# requirements.sh — Validate structured requirement YAML files.
#
# Runs after the requirements-analyst completes. Checks:
#   1. Every file in agent_docs/project/specs/requirements/*.yaml parses
#   2. Schema compliance — required fields present with valid values
#   3. REQ-IDs are unique across the whole project
#   4. REQ-IDs match the pattern REQ-<CATEGORY>-<NNN>
#   5. status=assumed → assumption_reason is non-empty
#   6. status=gap     → open_questions is non-empty
#   7. source.file    → referenced file exists in requirements-include-files/
#                       (skipped when status=assumed AND source.file is "—")
#   8. requirements-index.md lists every REQ-ID (and only existing REQ-IDs)
#
# Exit codes:
#   0  — all checks pass
#   1  — one or more checks failed (details printed to stderr)
#   2  — environment problem (python3 missing, etc.)
# =============================================================================

set -euo pipefail

REQ_DIR="agent_docs/project/specs/requirements"
INDEX="agent_docs/project/specs/requirements-index.md"
INCLUDE_DIR="agent_docs/project/specs/requirements-include-files"

if ! command -v python3 >/dev/null 2>&1; then
  echo "[requirements.sh] python3 not found — cannot validate YAML" >&2
  exit 2
fi

if [ ! -d "$REQ_DIR" ]; then
  echo "[requirements.sh] FAIL: $REQ_DIR not found" >&2
  exit 1
fi

python3 - "$REQ_DIR" "$INDEX" "$INCLUDE_DIR" <<'PYEOF'
import os
import re
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("[requirements.sh] PyYAML not installed. Run: pip3 install pyyaml", file=sys.stderr)
    sys.exit(2)

req_dir = Path(sys.argv[1])
index_path = Path(sys.argv[2])
include_dir = Path(sys.argv[3])

errors = []
warnings = []

ID_PATTERN = re.compile(r"^REQ-(AUTH|USER|JOB|CMS|UI|VISUAL|DATA|INTEGRATION|NFR-PERF|NFR-SECURITY|NFR-ACCESS|NFR-I18N|BIZ|OPS)-\d{3}$")
VALID_CATEGORIES = {
    "auth", "user", "job", "cms", "ui", "visual", "data", "integration",
    "nfr-perf", "nfr-security", "nfr-access", "nfr-i18n", "biz", "ops",
}
VALID_STATUS = {"confirmed", "assumed", "gap"}
VALID_PRIORITY = {"P0", "P1", "P2", "P3"}
REQUIRED_FIELDS = ["id", "category", "priority", "status", "source", "statement", "acceptance_criteria"]

yaml_files = sorted(req_dir.glob("REQ-*.yaml"))
if not yaml_files:
    errors.append(f"No REQ-*.yaml files found in {req_dir}")

all_ids = {}

for f in yaml_files:
    try:
        data = yaml.safe_load(f.read_text())
    except Exception as e:
        errors.append(f"{f.name}: YAML parse error — {e}")
        continue

    if not isinstance(data, dict):
        errors.append(f"{f.name}: root must be a mapping")
        continue

    for field in REQUIRED_FIELDS:
        if field not in data or data[field] in (None, "", []):
            errors.append(f"{f.name}: missing required field `{field}`")

    req_id = data.get("id", "")
    if req_id:
        if not ID_PATTERN.match(req_id.upper()):
            errors.append(f"{f.name}: id `{req_id}` does not match REQ-<CATEGORY>-<NNN> pattern")
        if req_id in all_ids:
            errors.append(f"{f.name}: duplicate id `{req_id}` (also in {all_ids[req_id]})")
        else:
            all_ids[req_id] = f.name
        expected_name = f"{req_id}.yaml"
        if f.name != expected_name:
            warnings.append(f"{f.name}: filename should be `{expected_name}` to match id")

    if data.get("category") and data["category"] not in VALID_CATEGORIES:
        errors.append(f"{f.name}: invalid category `{data['category']}`")

    if data.get("priority") and data["priority"] not in VALID_PRIORITY:
        errors.append(f"{f.name}: invalid priority `{data['priority']}`")

    status = data.get("status")
    if status and status not in VALID_STATUS:
        errors.append(f"{f.name}: invalid status `{status}`")

    if status == "assumed" and not data.get("assumption_reason"):
        errors.append(f"{f.name}: status=assumed but assumption_reason is empty")

    if status == "gap" and not data.get("open_questions"):
        errors.append(f"{f.name}: status=gap but open_questions is empty")

    src = data.get("source") or {}
    src_file = src.get("file") if isinstance(src, dict) else None
    if src_file and src_file != "—" and status != "assumed":
        if include_dir.exists() and not (include_dir / src_file).exists():
            errors.append(f"{f.name}: source.file `{src_file}` not found in {include_dir}")

    acs = data.get("acceptance_criteria") or []
    if isinstance(acs, list):
        for i, ac in enumerate(acs):
            if not isinstance(ac, dict):
                errors.append(f"{f.name}: acceptance_criteria[{i}] must be a mapping")
                continue
            for req in ("id", "given", "then"):
                if not ac.get(req):
                    errors.append(f"{f.name}: acceptance_criteria[{i}] missing `{req}`")

if index_path.exists():
    index_text = index_path.read_text()
    index_ids = set(re.findall(r"REQ-[A-Z0-9]+(?:-[A-Z0-9]+)*-\d{3}", index_text))
    for req_id in all_ids:
        if req_id not in index_ids:
            errors.append(f"requirements-index.md: missing row for `{req_id}`")
    for idx_id in index_ids:
        if idx_id not in all_ids:
            errors.append(f"requirements-index.md: references `{idx_id}` but no matching YAML file")
else:
    errors.append(f"{index_path} not found — analyst must produce the index")

gap_ids = [rid for rid, fname in all_ids.items() if (yaml.safe_load((req_dir / fname).read_text()) or {}).get("status") == "gap"]

print()
print("=" * 70)
print("Requirements validation")
print("=" * 70)
print(f"Files checked: {len(yaml_files)}")
print(f"Unique REQ-IDs: {len(all_ids)}")
print(f"Gaps blocking gate: {len(gap_ids)}")
if gap_ids:
    for gid in gap_ids:
        print(f"  - {gid}")
print()
if warnings:
    print("Warnings:")
    for w in warnings:
        print(f"  WARN  {w}")
    print()
if errors:
    print("Errors:")
    for e in errors:
        print(f"  FAIL  {e}")
    print()
    print(f"Result: FAIL ({len(errors)} errors)")
    sys.exit(1)
print("Result: PASS")
sys.exit(0)
PYEOF
