#!/usr/bin/env python3
"""Validate that all features declared in FEATURES.json are intact.

Checks:
  - FEATURES.json is valid JSON with required top-level keys
  - Every feature has required fields (id, name, critical_files, api_endpoints)
  - Every critical_files path exists on disk
  - Every shared_files path exists on disk
  - No duplicate feature IDs

Usage:
  python scripts/validate-features.py          # verbose output
  python scripts/validate-features.py --quiet  # errors only (for pre-commit hook)
"""

import json
import os
import sys

REPO_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FEATURES_PATH = os.path.join(REPO_ROOT, "FEATURES.json")

REQUIRED_FEATURE_FIELDS = {"id", "name", "critical_files", "api_endpoints"}


def validate(quiet=False):
    errors = []

    # 1. Load FEATURES.json
    if not os.path.exists(FEATURES_PATH):
        errors.append("FEATURES.json not found")
        return errors

    try:
        with open(FEATURES_PATH, "r") as f:
            data = json.load(f)
    except json.JSONDecodeError as e:
        errors.append(f"FEATURES.json is not valid JSON: {e}")
        return errors

    # 2. Top-level structure
    if "features" not in data:
        errors.append("FEATURES.json missing 'features' array")
        return errors

    # 3. Validate shared_files
    for path in data.get("shared_files", []):
        full = os.path.join(REPO_ROOT, path)
        if not os.path.exists(full):
            errors.append(f"shared file missing: {path}")

    # 4. Validate each feature
    seen_ids = set()
    for i, feature in enumerate(data["features"]):
        fid = feature.get("id", f"<index {i}>")

        # Required fields
        missing = REQUIRED_FEATURE_FIELDS - set(feature.keys())
        if missing:
            errors.append(f"feature '{fid}' missing fields: {', '.join(sorted(missing))}")

        # Duplicate IDs
        if fid in seen_ids:
            errors.append(f"duplicate feature id: {fid}")
        seen_ids.add(fid)

        # Critical files exist
        for path in feature.get("critical_files", []):
            full = os.path.join(REPO_ROOT, path)
            if not os.path.exists(full):
                errors.append(f"feature '{fid}': critical file missing: {path}")

    return errors


def main():
    quiet = "--quiet" in sys.argv
    errors = validate(quiet)

    if errors:
        if not quiet:
            print("Feature validation FAILED:")
        for err in errors:
            print(f"  - {err}")
        sys.exit(1)
    else:
        if not quiet:
            print("Feature validation passed.")
        sys.exit(0)


if __name__ == "__main__":
    main()
