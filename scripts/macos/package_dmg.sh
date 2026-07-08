#!/usr/bin/env bash
# Build a distributable macOS DMG for VibePaint.
#
# Usage:
#   scripts/macos/package_dmg.sh path/to/VibePaint.app [output.dmg] [version]
#
# Optional:
#   CREATE_DMG=0  force the hdiutil fallback even if create-dmg is installed
set -euo pipefail

APP_PATH="${1:?Usage: $0 path/to/App.app [output.dmg] [version]}"
VERSION="${3:-}"
if [[ -z "$VERSION" ]]; then
  VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$APP_PATH/Contents/Info.plist" 2>/dev/null || echo "0.0.0")"
fi
OUTPUT="${2:-VibePaint-${VERSION}-macos.dmg}"

if [[ ! -d "$APP_PATH" ]]; then
  echo "error: app bundle not found: $APP_PATH" >&2
  exit 1
fi

APP_NAME="$(basename "$APP_PATH")"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/vibepaint-dmg.XXXXXX")"
STAGE="$WORK/stage"
mkdir -p "$STAGE"
trap 'rm -rf "$WORK"' EXIT

ditto "$APP_PATH" "$STAGE/$APP_NAME"
ln -s /Applications "$STAGE/Applications"

VOLNAME="VibePaint ${VERSION}"
rm -f "$OUTPUT"

use_create_dmg=false
if [[ "${CREATE_DMG:-1}" != "0" ]] && command -v create-dmg >/dev/null 2>&1; then
  use_create_dmg=true
fi

if [[ "$use_create_dmg" == true ]]; then
  echo "Creating DMG with create-dmg…"
  CREATE_STAGE="$WORK/create-stage"
  mkdir -p "$CREATE_STAGE"
  ditto "$APP_PATH" "$CREATE_STAGE/$APP_NAME"

  BACKGROUND_ARGS=()
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
  BG="${SCRIPT_DIR}/../../macos/dmg/background.png"
  if [[ -f "$BG" ]]; then
    BACKGROUND_ARGS=(--background "$BG")
  fi

  set +e
  create-dmg \
    --volname "$VOLNAME" \
    --window-pos 200 120 \
    --window-size 660 400 \
    --icon-size 128 \
    --icon "$APP_NAME" 180 190 \
    --hide-extension "$APP_NAME" \
    --app-drop-link 480 190 \
    "${BACKGROUND_ARGS[@]}" \
    --hdiutil-quiet \
    "$OUTPUT" \
    "$CREATE_STAGE"
  create_status=$?
  set -e

  # create-dmg may exit non-zero after a successful write when Finder bless fails in CI.
  if [[ ! -f "$OUTPUT" ]]; then
    echo "create-dmg did not produce $OUTPUT (exit $create_status); falling back to hdiutil…"
  else
    echo "create-dmg finished (exit $create_status)"
  fi
fi

if [[ ! -f "$OUTPUT" ]]; then
  echo "Creating DMG with hdiutil…"
# Prefer sparse compressed HFS+ images for wider Finder drop-link UX when create-dmg is unavailable.
  TMP_DMG="$WORK/raw.dmg"
  hdiutil create \
    -volname "$VOLNAME" \
    -srcfolder "$STAGE" \
    -ov \
    -fs HFS+ \
    -format UDZO \
    -imagekey zlib-level=9 \
    "$TMP_DMG"
  mv "$TMP_DMG" "$OUTPUT"
fi

xattr -cr "$OUTPUT" 2>/dev/null || true

echo "Wrote $OUTPUT"
ls -lh "$OUTPUT"
