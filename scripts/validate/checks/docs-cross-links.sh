#!/usr/bin/env bash
# =============================================================================
# docs-cross-links.sh — Verify markdown links in CLAUDE.md and key docs.
#
# Checks every relative markdown link `[text](path)` in:
#   - CLAUDE.md
#   - agent_docs/project/pipeline.md
#   - agent_docs/project/specs/requirements-index.md (if present)
# resolves to a file that actually exists.
#
# Harness principle: docs are machine-readable artifacts. Dead links in a
# map file silently misdirect agents. Catch them at the gate, not at runtime.
#
# Exit codes:
#   0  — all links resolve
#   1  — one or more dead links
# =============================================================================

set -euo pipefail

files_to_check=()
[ -f CLAUDE.md ] && files_to_check+=(CLAUDE.md)
[ -f agent_docs/project/pipeline.md ] && files_to_check+=(agent_docs/project/pipeline.md)
[ -f agent_docs/project/specs/requirements-index.md ] && files_to_check+=(agent_docs/project/specs/requirements-index.md)

if [ ${#files_to_check[@]} -eq 0 ]; then
  echo "[docs-cross-links.sh] No target docs found — skipping"
  exit 0
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "[docs-cross-links.sh] python3 not found — skipping" >&2
  exit 0
fi

python3 - "${files_to_check[@]}" <<'PYEOF'
import re
import sys
from pathlib import Path

link_re = re.compile(r"\[[^\]]+\]\(([^)]+)\)")

errors = []

for doc in sys.argv[1:]:
    doc_path = Path(doc)
    text = doc_path.read_text()
    for m in link_re.finditer(text):
        target = m.group(1).strip()
        # Skip absolute URLs, anchors, and mailto
        if target.startswith(("http://", "https://", "mailto:", "#")):
            continue
        # Strip in-file anchors from relative paths
        target = target.split("#", 1)[0]
        if not target:
            continue
        resolved = (doc_path.parent / target).resolve()
        if not resolved.exists():
            errors.append(f"{doc}: dead link → {target}")

if errors:
    print("[docs-cross-links.sh] FAIL — dead links:")
    for e in errors:
        print(f"  {e}")
    sys.exit(1)

print(f"[docs-cross-links.sh] PASS — checked {len(sys.argv) - 1} docs, all relative links resolve")
PYEOF
