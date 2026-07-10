#!/usr/bin/env bash
# Package a Flutter Linux release bundle for distribution.
#
# Usage:
#   scripts/linux/package_release.sh \
#     --bundle build/linux/x64/release/bundle \
#     --version 1.0.3 \
#     --output-dir .
set -euo pipefail

BUNDLE_DIR=""
VERSION=""
OUTPUT_DIR="."

usage() {
  cat <<'EOF'
Usage: scripts/linux/package_release.sh --bundle DIR --version VERSION [--output-dir DIR]

Creates:
  VibePaint-<version>-linux-x64.tar.gz
  VibePaint-<version>-linux-x64.AppImage
  VibePaint-<version>-linux-x64.deb
  VibePaint-<version>-linux-x64.rpm
  VibePaint-<version>-linux-x64.pkg.tar.zst
  VibePaint-<version>-linux-x64.flatpak
  VibePaint-<version>-linux-x64.snap
  VibePaint-<version>-linux-x64-aur.tar.gz  (PKGBUILD for AUR / yay / paru)
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --bundle)
      BUNDLE_DIR="$2"
      shift 2
      ;;
    --version)
      VERSION="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      echo "error: unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$BUNDLE_DIR" || -z "$VERSION" ]]; then
  echo "error: --bundle and --version are required" >&2
  usage >&2
  exit 1
fi

if [[ ! -x "$BUNDLE_DIR/vibepaint" ]]; then
  echo "error: expected executable at $BUNDLE_DIR/vibepaint" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/vibepaint-linux-pkg.XXXXXX")"
mkdir -p "$OUTPUT_DIR"
OUTPUT_DIR="$(cd "$OUTPUT_DIR" && pwd)"

cleanup_work() {
  if [[ -n "${CI:-}" ]] && command -v sudo >/dev/null 2>&1; then
    sudo rm -rf "$WORK" 2>/dev/null || rm -rf "$WORK" 2>/dev/null || true
  else
    rm -rf "$WORK"
  fi
}
trap cleanup_work EXIT

PREFIX="VibePaint-${VERSION}-linux-x64"
TARBALL="${OUTPUT_DIR}/${PREFIX}.tar.gz"
APPIMAGE="${OUTPUT_DIR}/${PREFIX}.AppImage"
DEB="${OUTPUT_DIR}/${PREFIX}.deb"
RPM="${OUTPUT_DIR}/${PREFIX}.rpm"
ARCH_PKG="${OUTPUT_DIR}/${PREFIX}.pkg.tar.zst"
AUR_SRC="${OUTPUT_DIR}/${PREFIX}-aur.tar.gz"
FLATPAK="${OUTPUT_DIR}/${PREFIX}.flatpak"
SNAP="${OUTPUT_DIR}/${PREFIX}.snap"

echo "==> Portable tarball"
tar -C "$(dirname "$BUNDLE_DIR")" -czf "$TARBALL" "$(basename "$BUNDLE_DIR")"
ls -lh "$TARBALL"

ensure_nfpm() {
  if command -v nfpm >/dev/null 2>&1; then
    return
  fi

  local nfpm_version="2.47.0"
  local tarball="nfpm_${nfpm_version}_Linux_x86_64.tar.gz"
  echo "==> Downloading nfpm ${nfpm_version}"
  curl -fsSL \
    "https://github.com/goreleaser/nfpm/releases/download/v${nfpm_version}/${tarball}" \
    | tar -xz -C "$WORK" nfpm
  chmod +x "$WORK/nfpm"
  export PATH="$WORK:$PATH"
}

render_nfpm_config() {
  local template="$1"
  local output="$2"
  local bundle_dir="$3"
  local bundle_dir_abs
  bundle_dir_abs="$(cd "$bundle_dir" && pwd)"

  sed \
    -e "s|@BUNDLE_DIR@|${bundle_dir_abs}|g" \
    -e "s|@VERSION@|${VERSION}|g" \
    "$template" > "$output"
}

build_deb_and_rpm() {
  ensure_nfpm

  local pkg_root="$WORK/pkg-root"
  local nfpm_config="$WORK/nfpm.yaml"
  local nfpm_arch_config="$WORK/nfpm-arch.yaml"
  mkdir -p "$pkg_root"
  cp -a "$BUNDLE_DIR"/. "$pkg_root/"

  render_nfpm_config "$ROOT/linux/nfpm.yaml" "$nfpm_config" "$pkg_root"
  render_nfpm_config "$ROOT/linux/nfpm-arch.yaml" "$nfpm_arch_config" "$pkg_root"

  echo "==> Debian package"
  nfpm pkg \
    --config "$nfpm_config" \
    --packager deb \
    --target "$DEB"

  echo "==> RPM package"
  nfpm pkg \
    --config "$nfpm_config" \
    --packager rpm \
    --target "$RPM"

  echo "==> Arch Linux package"
  nfpm pkg \
    --config "$nfpm_arch_config" \
    --packager archlinux \
    --target "$ARCH_PKG"

  ls -lh "$DEB" "$RPM" "$ARCH_PKG"
}

build_aur_source() {
  echo "==> AUR source bundle"
  local aur_dir="$WORK/aur"
  mkdir -p "$aur_dir"

  sed "s/VERSION_PLACEHOLDER/${VERSION}/g" "$ROOT/linux/aur/PKGBUILD" >"$aur_dir/PKGBUILD"

  cat >"$aur_dir/.SRCINFO" <<EOF
pkgbase = vibepaint-bin
	pkgname = vibepaint-bin
	pkgdesc = A vibe coded paint app
	pkgver = ${VERSION}
	pkgrel = 1
	url = https://github.com/merklegroot/vibepaint
	arch = x86_64
	license = MIT
	depends = gtk3
	depends = libsecret
	provides = vibepaint
	conflicts = vibepaint
	options = !strip
	source = https://github.com/merklegroot/vibepaint/releases/download/v${VERSION}/VibePaint-${VERSION}-linux-x64.pkg.tar.zst
	sha256sums = SKIP

pkgname = vibepaint-bin
EOF

  tar -C "$aur_dir" -czf "$AUR_SRC" PKGBUILD .SRCINFO
  ls -lh "$AUR_SRC"
}

build_appimage() {
  echo "==> AppImage"
  local appdir="$WORK/VibePaint.AppDir"
  local appimagetool="$WORK/appimagetool"

  mkdir -p "$appdir"
  cp -a "$BUNDLE_DIR"/. "$appdir/"

  cat >"$appdir/AppRun" <<'EOF'
#!/bin/sh
HERE="$(dirname "$(readlink -f "$0" 2>/dev/null || echo "$0")")"
cd "$HERE" || exit 1
exec ./vibepaint "$@"
EOF
  chmod +x "$appdir/AppRun"

  cat >"$appdir/vibepaint.desktop" <<EOF
[Desktop Entry]
Name=VibePaint
Comment=A vibe coded paint app
Exec=AppRun
Icon=vibepaint
Terminal=false
Type=Application
Categories=Graphics;
StartupNotify=true
X-AppImage-Name=VibePaint
X-AppImage-Version=${VERSION}
EOF

  cp "$ROOT/linux/icons/hicolor/256x256/apps/com.merklegroot.vibepaint.png" \
    "$appdir/vibepaint.png"
  cp "$appdir/vibepaint.png" "$appdir/.DirIcon"

  if [[ ! -x "$appimagetool" ]]; then
    curl -fsSL -o "$appimagetool" \
      "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage"
    chmod +x "$appimagetool"
  fi

  # Avoid FUSE in CI: run the tool via its own AppImage launcher.
  ARCH=x86_64 "$appimagetool" --appimage-extract-and-run "$appdir" "$APPIMAGE"
  chmod +x "$APPIMAGE"
  ls -lh "$APPIMAGE"
}

build_flatpak() {
  if ! command -v flatpak-builder >/dev/null 2>&1; then
    echo "warning: flatpak-builder not found; skipping Flatpak bundle" >&2
    return
  fi

  echo "==> Flatpak"
  local flatpak_root="$WORK/flatpak"
  local repo="$WORK/flatpak-repo"
  local build_dir="$WORK/flatpak-app"
  local bundle_stage="$flatpak_root/bundle"
  local flatpak_user_args=()
  if [[ -n "${CI:-}" ]]; then
    flatpak_user_args=(--user)
  fi

  mkdir -p "$bundle_stage/icons/hicolor/256x256/apps" \
    "$bundle_stage/icons/hicolor/128x128/apps"
  cp -a "$BUNDLE_DIR"/. "$bundle_stage/"
  cp "$ROOT/linux/com.merklegroot.vibepaint.desktop" "$bundle_stage/"
  cp "$ROOT/linux/icons/hicolor/256x256/apps/com.merklegroot.vibepaint.png" \
    "$bundle_stage/icons/hicolor/256x256/apps/"
  cp "$ROOT/linux/icons/hicolor/128x128/apps/com.merklegroot.vibepaint.png" \
    "$bundle_stage/icons/hicolor/128x128/apps/"
  cp "$ROOT/linux/flatpak/com.merklegroot.vibepaint.yml" "$flatpak_root/"

  if ! flatpak remote-list "${flatpak_user_args[@]}" | grep -q flathub; then
    flatpak remote-add --if-not-exists "${flatpak_user_args[@]}" flathub \
      https://flathub.org/repo/flathub.flatpakrepo
  fi

  flatpak-builder "${flatpak_user_args[@]}" \
    --repo="$repo" \
    --force-clean \
    --install-deps-from=flathub \
    "$build_dir" \
    "$flatpak_root/com.merklegroot.vibepaint.yml"

  flatpak build-bundle "$repo" "$FLATPAK" com.merklegroot.vibepaint
  ls -lh "$FLATPAK"
}

build_snap() {
  if ! command -v snapcraft >/dev/null 2>&1; then
    echo "warning: snapcraft not found; skipping Snap package" >&2
    return
  fi

  echo "==> Snap"
  local snap_root="$WORK/snap-build"
  local built_snap=""

  mkdir -p "$snap_root/bundle" "$snap_root/icons"
  cp -a "$BUNDLE_DIR"/. "$snap_root/bundle/"
  cp "$ROOT/linux/com.merklegroot.vibepaint.desktop" "$snap_root/"
  cp "$ROOT/linux/icons/hicolor/256x256/apps/com.merklegroot.vibepaint.png" \
    "$snap_root/icons/icon.png"
  sed "s/VERSION_PLACEHOLDER/${VERSION}/g" "$ROOT/linux/snap/snapcraft.yaml" \
    >"$snap_root/snapcraft.yaml"

  if ! (cd "$snap_root" && SNAPCRAFT_BUILD_ENVIRONMENT=host snapcraft pack --destructive-mode); then
    echo "warning: snapcraft failed; skipping Snap package" >&2
    return
  fi

  built_snap="$(find "$snap_root" -maxdepth 1 -name '*.snap' -print -quit)"
  if [[ -z "$built_snap" ]]; then
    echo "warning: snapcraft did not produce a .snap file; skipping Snap package" >&2
    return
  fi

  mv "$built_snap" "$SNAP"
  ls -lh "$SNAP"
}

build_deb_and_rpm
build_aur_source
build_appimage
build_flatpak
build_snap

echo
echo "Linux release artifacts:"
ls -lh "$TARBALL" "$APPIMAGE" "$DEB" "$RPM" "$ARCH_PKG" "$AUR_SRC" "${FLATPAK}" "$SNAP" 2>/dev/null || true
