# Manual Merge Guide

When `propagate-updates.sh` skips a file with a **⚠ Manual merge required** warning,
it means the file exists in your project AND has been updated in the template.
Blindly overwriting would destroy project-specific data (filled statuses, custom paths, etc.).

Follow the steps below for each flagged file.

---

## File: `agent_docs/project/compliance-checklist.md`

### Why it's skipped
The template's checklist version is newer than the project's copy.
New sections or items have been added that your project copy doesn't have yet.
Your existing compliance statuses (✅ ⚠️ ❌) must be preserved.

### How to merge

1. **Open both files side by side:**
   ```
   Left:  agent_docs/project/compliance-checklist.md   ← your project (has statuses)
   Right: [The Genesis]/agent_docs/templates/compliance-checklist.md  ← latest template
   ```

2. **Update the Source File Versions table** at the top of your project copy:
   - Copy the updated `Last Reviewed (source)` and `Synced to Checklist` dates from the template
   - Update `<!-- checklist-version: YYYY-MM-DD -->` to match the template

3. **Add new sections** that exist in the template but not in your project copy:
   - Compare section numbers — find any sections present in the template but missing in your file
   - Copy those entire sections to the bottom of your file (above the Action Items section)
   - All new items will have empty Status columns — that is correct

4. **Add new items to existing sections** that have been extended:
   - For each section, compare item numbers — find any new items (e.g. 24.21, 24.22, 26.12)
   - Append those rows to the relevant section in your project copy
   - Do NOT change existing rows or their statuses

5. **Never change existing statuses** — only add new rows with empty statuses

6. **Checklist to confirm merge is complete:**
   - [ ] `checklist-version` tag updated to match template
   - [ ] All source file version dates updated
   - [ ] All new sections added
   - [ ] All new items within existing sections added
   - [ ] No existing statuses changed

---

## File: `agent_docs/project/pipeline.md`

### Why it's skipped
The pipeline template has been updated (e.g. new agents added, new artifact paths,
updated stage diagrams). Your project copy may have project-specific agent paths,
active/inactive agent toggles, or a Pipeline Status table with run history.

### How to merge

1. **Open both files side by side:**
   ```
   Left:  agent_docs/project/pipeline.md               ← your project (has custom config)
   Right: [The Genesis]/agent_docs/templates/pipeline.md  ← latest template
   ```

2. **Update the Project Paths table:**
   - Add any new paths from the template that are missing in your project copy
   - Keep your project-specific values (actual URLs, real paths) — do not revert to placeholders

3. **Update the Pipeline Stages diagram:**
   - Add any new agents from the template (e.g. `uiux-reviewer`, `devops-engineer`)
   - Keep your project-specific input/output paths
   - Mark any agents as `[INACTIVE]` if they don't apply to this project

4. **Update the Active Agents table:**
   - Add rows for any new agents from the template
   - Set status to `Active` or `Inactive` based on project needs

5. **Do NOT overwrite:**
   - Pipeline Status table (has real run history)
   - Project-specific artifact paths
   - Agent-specific notes added for this project

6. **Checklist to confirm merge is complete:**
   - [ ] All new paths added to Project Paths table
   - [ ] All new agents reflected in the pipeline diagram
   - [ ] Active Agents table updated
   - [ ] Pipeline Status table preserved intact

---

## Quick Reference — What `propagate-updates.sh` does automatically

| File / Folder | Action | Safe? |
|---|---|---|
| `agent_docs/generic/*.md` | Overwrite with latest | ✅ Always safe |
| New generic files not yet in project | Add | ✅ Always safe |
| `agent_docs/project/specs/api-spec.yaml` | Add if missing | ✅ Safe (new file) |
| `artifacts/` subfolders | Create if missing | ✅ Safe |
| `agent_docs/project/compliance-checklist.md` | Warn & skip | ⚠️ Manual merge |
| `agent_docs/project/pipeline.md` | Warn & skip | ⚠️ Manual merge |
| `CLAUDE.md` | Never touched | 🔒 Project-specific |
| All other `agent_docs/project/*.md` | Never touched | 🔒 Project-specific |
