#!/usr/bin/env bash
# Sign a Flutter macOS .app (Developer ID + hardened runtime) and notarize it.
# Also supports signing/notarizing a .dmg produced from a stapled app.
#
# Required env (when signing):
#   MACOS_CERTIFICATE          base64-encoded .p12 (Developer ID Application)
#   MACOS_CERTIFICATE_PWD      password for the .p12
#   MACOS_CERTIFICATE_NAME     codesign identity, e.g. "Developer ID Application: Name (TEAMID)"
#   MACOS_CI_KEYCHAIN_PWD      temporary keychain password (any strong random string)
#
# Notarization (App Store Connect API key — preferred):
#   APPLE_API_KEY_BASE64       base64-encoded AuthKey_XXXXXX.p8
#   APPLE_API_KEY_ID           key id (e.g. AB12CD34EF)
#   APPLE_API_ISSUER_ID        issuer UUID
#
# Or Apple ID + app-specific password:
#   APPLE_ID
#   APPLE_APP_SPECIFIC_PASSWORD
#   APPLE_TEAM_ID
#
# Usage:
#   scripts/macos/sign_and_notarize.sh path/to/VibePaint.app
#   scripts/macos/sign_and_notarize.sh path/to/VibePaint.dmg
set -euo pipefail

TARGET="${1:?Usage: $0 path/to/App.app|.dmg}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
ENTITLEMENTS="${ENTITLEMENTS:-$REPO_ROOT/macos/Runner/Release.entitlements}"

if [[ ! -e "$TARGET" ]]; then
  echo "error: path not found: $TARGET" >&2
  exit 1
fi

if [[ -z "${MACOS_CERTIFICATE:-}" || -z "${MACOS_CERTIFICATE_NAME:-}" ]]; then
  echo "Skipping code signing (MACOS_CERTIFICATE / MACOS_CERTIFICATE_NAME not set)."
  exit 0
fi

: "${MACOS_CERTIFICATE_PWD:?MACOS_CERTIFICATE_PWD is required when signing}"
: "${MACOS_CI_KEYCHAIN_PWD:?MACOS_CI_KEYCHAIN_PWD is required when signing}"

KEYCHAIN_PATH="${RUNNER_TEMP:-/tmp}/vibepaint-signing.keychain-db"
CERT_PATH="${RUNNER_TEMP:-/tmp}/vibepaint-certificate.p12"
API_KEY_PATH=""

cleanup() {
  security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
  rm -f "$CERT_PATH" ${API_KEY_PATH:+"$API_KEY_PATH"}
}
trap cleanup EXIT

echo "Importing Developer ID certificate…"
echo "$MACOS_CERTIFICATE" | base64 --decode > "$CERT_PATH"
security delete-keychain "$KEYCHAIN_PATH" 2>/dev/null || true
security create-keychain -p "$MACOS_CI_KEYCHAIN_PWD" "$KEYCHAIN_PATH"
security set-keychain-settings -lut 21600 "$KEYCHAIN_PATH"
security unlock-keychain -p "$MACOS_CI_KEYCHAIN_PWD" "$KEYCHAIN_PATH"
security import "$CERT_PATH" -k "$KEYCHAIN_PATH" -P "$MACOS_CERTIFICATE_PWD" \
  -T /usr/bin/codesign -T /usr/bin/security >/dev/null
security list-keychain -d user -s "$KEYCHAIN_PATH"
security set-key-partition-list -S apple-tool:,apple:,codesign: -s \
  -k "$MACOS_CI_KEYCHAIN_PWD" "$KEYCHAIN_PATH" >/dev/null

sign_bin() {
  local path="$1"
  shift
  /usr/bin/codesign \
    --force \
    --options runtime \
    --timestamp \
    "$@" \
    --sign "$MACOS_CERTIFICATE_NAME" \
    "$path"
}

sign_app() {
  local app_path="$1"
  echo "Signing nested frameworks and libraries (no app entitlements)…"
  # Inside-out signing — do not use --deep; do not apply app entitlements to nested code.
  while IFS= read -r -d '' framework; do
    sign_bin "$framework"
  done < <(find "$app_path/Contents/Frameworks" -name "*.framework" -print0 2>/dev/null || true)

  while IFS= read -r -d '' dylib; do
    sign_bin "$dylib"
  done < <(find "$app_path/Contents/Frameworks" -name "*.dylib" -print0 2>/dev/null || true)

  if [[ -d "$app_path/Contents/MacOS" ]]; then
    while IFS= read -r -d '' helper; do
      # Skip the main executable; it is signed with the app bundle below.
      [[ "$(basename "$helper")" == "$(basename "$app_path" .app)" ]] && continue
      sign_bin "$helper"
    done < <(find "$app_path/Contents/MacOS" -type f -perm -111 -print0 2>/dev/null || true)
  fi

  echo "Signing app bundle with entitlements…"
  sign_bin "$app_path" --entitlements "$ENTITLEMENTS"

  echo "Verifying signature…"
  /usr/bin/codesign --verify --deep --strict --verbose=2 "$app_path"
}

sign_dmg() {
  local dmg_path="$1"
  echo "Signing DMG…"
  # DMGs take a simple signature (no hardened-runtime options required).
  /usr/bin/codesign --force --timestamp --sign "$MACOS_CERTIFICATE_NAME" "$dmg_path"
  /usr/bin/codesign --verify --verbose=2 "$dmg_path"
}

notarize_path() {
  local path="$1"
  local submit_path="$path"
  local remove_zip=false

  if [[ "$path" == *.app ]]; then
    submit_path="${RUNNER_TEMP:-/tmp}/vibepaint-notary.zip"
    rm -f "$submit_path"
    /usr/bin/ditto -c -k --keepParent "$path" "$submit_path"
    remove_zip=true
  fi

  echo "Submitting for notarization: $path"
  if [[ -n "${APPLE_API_KEY_BASE64:-}" ]]; then
    API_KEY_PATH="${RUNNER_TEMP:-/tmp}/AuthKey_${APPLE_API_KEY_ID}.p8"
    echo "$APPLE_API_KEY_BASE64" | base64 --decode > "$API_KEY_PATH"
    xcrun notarytool submit "$submit_path" \
      --key "$API_KEY_PATH" \
      --key-id "$APPLE_API_KEY_ID" \
      --issuer "$APPLE_API_ISSUER_ID" \
      --wait
  else
    xcrun notarytool submit "$submit_path" \
      --apple-id "$APPLE_ID" \
      --password "$APPLE_APP_SPECIFIC_PASSWORD" \
      --team-id "$APPLE_TEAM_ID" \
      --wait
  fi

  if [[ "$remove_zip" == true ]]; then
    rm -f "$submit_path"
  fi

  echo "Stapling notarization ticket…"
  xcrun stapler staple "$path"
  xcrun stapler validate "$path"
}

NOTARIZE=false
if [[ -n "${APPLE_API_KEY_BASE64:-}" && -n "${APPLE_API_KEY_ID:-}" && -n "${APPLE_API_ISSUER_ID:-}" ]]; then
  NOTARIZE=true
elif [[ -n "${APPLE_ID:-}" && -n "${APPLE_APP_SPECIFIC_PASSWORD:-}" && -n "${APPLE_TEAM_ID:-}" ]]; then
  NOTARIZE=true
fi

if [[ "$TARGET" == *.dmg ]]; then
  sign_dmg "$TARGET"
  if [[ "$NOTARIZE" == true ]]; then
    notarize_path "$TARGET"
  else
    echo "Skipping notarization (Apple credentials not set)."
  fi
  echo "Done: $TARGET"
  exit 0
fi

if [[ "$TARGET" != *.app || ! -d "$TARGET" ]]; then
  echo "error: expected a .app bundle or .dmg file" >&2
  exit 1
fi

# Clear Finder/quarantine extended attributes that can break notarization.
xattr -cr "$TARGET" 2>/dev/null || true

sign_app "$TARGET"

if [[ "$NOTARIZE" == true ]]; then
  notarize_path "$TARGET"
else
  echo "Skipping notarization (Apple credentials not set)."
fi

echo "Done: $TARGET"
