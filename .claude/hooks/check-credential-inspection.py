#!/usr/bin/env python3
"""
Credential Inspection Guard — Claude Code PreToolUse Hook
Blocks Bash commands that attempt to read or exfiltrate environment variables.
Protects against prompt injection attacks that try to leak credentials.
"""

import json
import re
import sys

data = json.load(sys.stdin)
cmd = data.get("command", "")

BLOCKED_PATTERNS = [
    (r"\bprintenv\b",                   "printenv — prints all environment variables"),
    (r"(?<!\w)env(?!\w)\s*$",           "env with no args — lists all environment variables"),
    (r"echo\s+\$[A-Z_][A-Z0-9_]*",     "echoing an environment variable value"),
    (r"printf\s+.*\$[A-Z_][A-Z0-9_]*", "printf with environment variable"),
    (r"cat\s+/proc/self/environ",       "reading /proc/self/environ"),
    (r"/etc/environment\b",             "reading /etc/environment"),
    (r"os\.environ",                    "Python os.environ access"),
    (r"process\.env\b",                 "Node.js process.env access"),
    (r"\bexport\s+-p\b",               "export -p — lists all exported variables"),
    (r"\bset\b.*\|",                    "set | — pipes all shell variables"),
    (r"\bdeclare\s+-p\b",              "declare -p — lists all declared variables"),
    (r"compgen\s+-v\b",                "compgen -v — lists all variable names"),
]

for pattern, description in BLOCKED_PATTERNS:
    if re.search(pattern, cmd, re.IGNORECASE):
        print(f"[SECURITY] BLOCKED: credential inspection detected — {description}", file=sys.stderr)
        print(f"[SECURITY] Command was: {cmd[:120]}", file=sys.stderr)
        sys.exit(1)

sys.exit(0)
