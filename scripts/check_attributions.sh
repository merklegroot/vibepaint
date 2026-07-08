#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
registry="$root/assets/ATTRIBUTIONS.yaml"

if [[ ! -f "$registry" ]]; then
  echo "Missing attribution registry: assets/ATTRIBUTIONS.yaml" >&2
  exit 1
fi

python3 - "$registry" <<'PY'
import pathlib
import re
import sys

registry_path = pathlib.Path(sys.argv[1])
text = registry_path.read_text()

if "version:" not in text:
    raise SystemExit("assets/ATTRIBUTIONS.yaml must define version:")

collections = re.split(r"\n  - id: ", text)[1:]
if not collections:
    raise SystemExit("No collections found in assets/ATTRIBUTIONS.yaml")

errors = []

for block in collections:
    lines = block.splitlines()
    collection_id = lines[0].strip()
    section = f"collection '{collection_id}'"

    path_matches = re.findall(r"^\s+- (assets/.+/?)$", block, re.MULTILINE)
    if not path_matches:
        errors.append(f"{section}: missing paths")
        continue

    asset_files = re.findall(r"^\s+- asset: (.+)$", block, re.MULTILINE)
    if not asset_files:
        errors.append(f"{section}: missing files list")

    for tracked_path in path_matches:
        absolute = registry_path.parent.parent / tracked_path
        if not absolute.exists():
            errors.append(f"{section}: tracked path does not exist: {tracked_path}")
            continue

        if tracked_path.endswith("/"):
            present = sorted(p.name for p in absolute.iterdir() if p.is_file())
            expected = sorted(asset_files)
            if present != expected:
                errors.append(
                    f"{section}: file list mismatch in {tracked_path}\n"
                    f"  expected: {expected}\n"
                    f"  present:  {present}"
                )

if errors:
    print("Attribution check failed:", file=sys.stderr)
    for error in errors:
        print(f"  - {error}", file=sys.stderr)
    raise SystemExit(1)

print(f"Attribution registry OK ({len(collections)} collection(s)).")
PY
