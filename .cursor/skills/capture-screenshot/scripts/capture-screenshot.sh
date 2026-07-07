#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../../../.." && pwd)"
cd "$repo_root"

mkdir -p docs
flutter test --update-goldens test/generate_screenshot_test.dart

if [[ ! -f docs/screenshot.png ]]; then
  echo "error: docs/screenshot.png was not created" >&2
  exit 1
fi

echo "Screenshot saved to docs/screenshot.png"
