# Claude Code Instructions

## Feature Preservation (CRITICAL)

This project uses a **feature manifest** (`FEATURES.json`) that declares every key functional
requirement — routes, sidebar links, critical files, and API endpoints. A previous AI session
accidentally deleted an entire feature (Processing Queue) by rewriting shared files without
awareness of existing functionality. These rules exist to prevent that from happening again.

### Rules

1. **Never delete or rename files listed in `FEATURES.json` `critical_files`** without explicit
   user confirmation. If you believe a file should be removed, ask first.

2. **Never use the Write tool on shared files.** The following files are modified by many features
   and must only be edited with the Edit tool (additive changes, not full rewrites):
   - `frontend/src/api/types.ts`
   - `frontend/src/api/images.ts`
   - `frontend/src/App.tsx`
   - `frontend/src/components/layout/Sidebar.tsx`
   - `backend/app/main.py`

3. **When modifying shared files**, first Read the current file and preserve ALL existing:
   - Imports and exports in `types.ts`
   - Routes in `App.tsx`
   - Nav items in `Sidebar.tsx`
   - Router registrations in `main.py`

4. **Run feature validation before committing**: `python scripts/validate-features.py`
   If it fails, stop and fix the issue — do not commit broken features.

5. **When adding a new feature**, add a corresponding entry to `FEATURES.json` with:
   - `id`, `name`, `route` (if applicable), `sidebar_label` (if applicable)
   - `critical_files` — every file that, if deleted, would break the feature
   - `api_endpoints` — every backend endpoint the feature depends on

6. **When intentionally removing a feature**, update `FEATURES.json` first (remove the entry),
   then remove the code. Never the other way around.

### Pre-commit Hook

A git pre-commit hook runs `python scripts/validate-features.py --quiet` automatically.
If validation fails, the commit is blocked. Do not bypass this with `--no-verify`.

## Defect Logging

GitHub Issues are the **primary tracker** for defects. Local defect files are supplementary references.

When the user reports a bug, defect, or broken behavior:

1. **Get the next ID** from `defects/DEFECT_LOG.md` (see "Next ID" in Metrics).
2. **Create a GitHub issue first** using `gh issue create`:
   - **Title**: `DEF-{NNN}: <short description>`
   - **Labels**: `bug`
   - **Body**: Symptoms, Root Cause, Fix Plan (or "TBD"), Linked Defect path
3. **Create a local defect file** `defects/DEF-{NNN}.md` with the GitHub issue URL and key details.
   Use existing `DEF-*.md` files as format examples.
4. **Update `defects/DEFECT_LOG.md`**:
   - Add a row to the Recent Defects table with the GitHub issue link
   - Update the Metrics (total, open count, next ID)
   - If the table exceeds 5 entries, move the oldest to `defects/DEFECT_ARCHIVE.md`
5. **Status lifecycle**: OPEN → FIXED → VERIFIED → CLOSED
   - When status changes, comment on the GitHub issue and close it at CLOSED
6. When writing tests that cover a defect, update status to VERIFIED in both the local file and GitHub issue.
