# Trim Docs

Audit and trim markdown documentation files for bloat, duplication, and context waste. The goal is to keep files lean so they don't overwhelm AI context windows.

## When to use

- After adding new sections to role files, instructions, or specs
- When files grow beyond their target line count
- When multiple files cover overlapping topics
- Periodically as a hygiene check

## How to run

Accepts optional arguments:
- No args: audit all files in `agent_docs/generic/agents/` and `.claude/instructions/`
- File path(s): audit specific files
- `--fix`: apply the trims (default is audit-only, report what would change)

## Audit steps

### 1. Size check

For each file, report lines/words and flag against these targets:

| File type | Target | Warning | Critical |
|-----------|--------|---------|----------|
| Agent role (agents/*.md) | <100 lines | >150 lines | >250 lines |
| Instruction (.claude/instructions/*.md) | <200 lines | >300 lines | >450 lines |
| Skill (skills/*/SKILL.md) | <100 lines | >150 lines | >200 lines |
| Custom agent (.claude/agents/*.md) | <40 lines | >60 lines | >80 lines |

### 2. Duplication detection

Compare all files pairwise. For each pair, check:
- Sections with identical or near-identical headings
- Paragraphs or tables that appear in both files (>3 consecutive similar lines)
- Rules or procedures restated in multiple places

Report: which content appears where, and which file should be the single source of truth.

### 3. Reference vs inline check

For each duplicated section, recommend:
- **Keep inline** if the file is read in isolation (e.g. agent role files read by sub-agents)
- **Extract and reference** if files are always loaded together (e.g. orchestrator.md + run-pipeline.md)

### 4. Trim recommendations

For each file over target, suggest:
- Sections to extract into a shared reference file
- Verbose explanations that can be condensed (e.g. 5-line explanation → 1-line rule)
- Examples that can be removed (keep 1 example max per concept)
- Tables that can be simplified
- Format templates that can move to `agent_docs/templates/`

## Output format

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Doc Trim Audit
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  FILE SIZE REPORT
  File                              Lines   Target   Status
  ────────────────────────────────  ──────  ───────  ────────
  agents/orchestrator.md              528     <100   CRITICAL
  instructions/run-pipeline.md        479     <200   CRITICAL
  agents/developer.md                 131     <100   WARNING
  ...

  DUPLICATION REPORT
  Content                         File A                    File B
  ──────────────────────────────  ────────────────────────  ──────────────────
  Remediation attempt limits      orchestrator.md:68        run-pipeline.md:196
  Decision log format             orchestrator.md:277       run-pipeline.md:341
  ...

  TRIM PLAN
  #  Action                                          Saves
  ── ──────────────────────────────────────────────  ──────
  1  Extract remediation rules → remediation.md       ~150 lines from 2 files
  2  Move decision log format → templates/            ~50 lines from orchestrator
  3  Condense Autopilot prerequisites table           ~30 lines
  ...

  Total savings: ~XXX lines across N files
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## When --fix is passed

1. Show the audit report first
2. For each trim action, apply the change:
   - Extract duplicated content into new shared file
   - Replace inline content with a reference: `> See [{filename}]({path}) for {topic}.`
   - Condense verbose sections
   - Move format templates to `agent_docs/templates/`
3. After all changes, re-run the size check to confirm targets are met
4. Propagate changed files to child projects if propagate-updates.sh exists
