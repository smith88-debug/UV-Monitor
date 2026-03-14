# Claude Code Instructions

## Project Overview

UV Monitor is a dual-platform mobile app (iOS + Android) for monitoring UV index levels across Australian ARPANSA stations. It shows real-time UV readings, hourly forecasts, protection advice, and 30-day history.

- **iOS**: SwiftUI app in the root directory (`UVMonitor/`), built with XCGen (`project.yml`)
- **Android**: Jetpack Compose app in `android/`, built with Gradle

Both platforms share the same features, API endpoints, and station data. When adding or modifying a feature, apply changes to **both** iOS and Android.

## Feature Preservation (CRITICAL)

This project uses a **feature manifest** (`FEATURES.json`) that declares every key functional
requirement — routes, critical files, and API endpoints. A previous AI session
accidentally deleted an entire feature by rewriting shared files without
awareness of existing functionality. These rules exist to prevent that from happening again.

### Rules

1. **Never delete or rename files listed in `FEATURES.json` `critical_files`** without explicit
   user confirmation. If you believe a file should be removed, ask first.

2. **Never use the Write tool on shared files.** The following files are modified by many features
   and must only be edited with the Edit tool (additive changes, not full rewrites):

   **iOS shared files:**
   - `UVMonitor/Services/UVDataManager.swift`
   - `UVMonitor/Models/UVStation.swift`
   - `UVMonitor/Models/UVLevel.swift`
   - `UVMonitor/App/UVMonitorApp.swift`

   **Android shared files:**
   - `android/app/src/main/java/com/uvmonitor/app/UVDataManager.kt`
   - `android/app/src/main/java/com/uvmonitor/app/model/UVStation.kt`
   - `android/app/src/main/java/com/uvmonitor/app/model/UVLevel.kt`
   - `android/app/src/main/java/com/uvmonitor/app/UVMonitorApp.kt`

3. **When modifying shared files**, first Read the current file and preserve ALL existing
   functionality on both platforms.

4. **Run feature validation before committing**: `python scripts/validate-features.py`
   If it fails, stop and fix the issue — do not commit broken features.

5. **When adding a new feature**, add a corresponding entry to `FEATURES.json` with:
   - `id`, `name`, `description`
   - `critical_files` — files for **both** iOS and Android that, if deleted, would break the feature
   - `api_endpoints` — every backend endpoint the feature depends on

6. **When intentionally removing a feature**, update `FEATURES.json` first (remove the entry),
   then remove the code from **both platforms**. Never the other way around.

### Pre-commit Hook

A git pre-commit hook runs `python scripts/validate-features.py --quiet` automatically.
If validation fails, the commit is blocked. Do not bypass this with `--no-verify`.

## Dual-Platform Development

When modifying features, always update both platforms:

| iOS (Swift/SwiftUI) | Android (Kotlin/Compose) |
|---|---|
| `UVMonitor/Views/` | `android/.../ui/` |
| `UVMonitor/Models/` | `android/.../model/` |
| `UVMonitor/Services/` | `android/.../service/` |
| `UVMonitor/Notifications/` | `android/.../notification/` |
| SwiftData (`@Model`) | Room (`@Entity`) |
| BGTaskScheduler | WorkManager |
| CoreLocation | FusedLocationProvider |
| Swift Charts (Canvas) | Compose Canvas |

## API Endpoints

Both platforms consume the same APIs:
- **ARPANSA**: `https://uvdata.arpansa.gov.au/xml/uvvalues.xml` (XML, real-time UV)
- **Open-Meteo**: `https://api.open-meteo.com/v1/forecast` (JSON, hourly UV forecast)

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
