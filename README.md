# VibePaint

A vibe coded paint app.

![VibePaint screenshot](docs/screenshot.png)

## Features

### Drawing
- **Brush, pencil, line, rectangle, ellipse, eraser, paint bucket, text, magic wand & color picker** — soft brush strokes, crisp pencil lines, straight segments, outlined or filled shapes, flood-fill on the active layer, in-place text, color-based selection, and an eyedropper (K) to sample colors from the canvas
- **Text tool** — click to place (T); type in place; Enter finishes, Shift+Enter inserts a new line, Esc cancels; toolbar supports font family, size, bold/italic/underline, and left/center/right alignment
- **Shape modifiers** — Shift constrains lines to 45°, rectangles to squares, ellipses to circles; Alt draws from center
- **Shape style** — outline, filled, or filled with outline (rectangle & ellipse)
- **Toolbar** — tool picker on the left, brush width above the canvas

### Canvas & color
- **Document size** — the canvas has its own dimensions; crop and resize operations shrink or grow the document, not just the window
- **Zoom & pan** — scroll wheel zooms toward the cursor; Space+drag or middle-mouse drag pans; **macOS:** ⌘+/- zoom, ⌘0 fit, ⌘1 100% · **Windows/Linux:** Ctrl+/- zoom, Ctrl+0 fit, Ctrl+1 100%
- **Canvas background** — separate from layers; choose via the background color well or when creating a new image (includes transparent)
- **Color wells** — classic overlapping primary and background swatches with swap and reset; click a well, then pick a preset (background well includes transparent)
- **Color picker** — double-click either well to open a full picker with hue/saturation wheel, HSV and RGB sliders, alpha, hex input, and foreground/background preview with swap

### Layers
- **Layers** — stack transparent layers (top of list = front), show/hide, reorder, opacity, blend modes, duplicate, merge down, and rename; eraser clears pixels on the active layer
- **Undo & redo** — step through stroke history on the active layer (toolbar buttons or ⌘Z / ⌘⇧Z)

### Selection
- **Selection tools** — rectangle, ellipse, and lasso select with custom toolbar icons
- **Marching ants** — animated selection outline with resize handles and proper edge/corner cursors
- **Selection editing** — select all, deselect, invert, move, delete; switch rectangle ↔ ellipse after creating a box selection; zero-area selections deselect automatically
- **Edit menu** — selection commands with keyboard shortcuts (macOS menu bar; in-window on Windows and Linux)

### Image
- **Image menu** — crop to selection, auto crop, resize image, resize canvas (with anchor), flip horizontal/vertical, rotate 90° CW/CCW, rotate 180°, and flatten layers (macOS menu bar; in-window on Windows and Linux)
- **AI Enhance** — macOS toolbar sparkle button silently enhances the active layer (or selection) with Apple Intelligence `ImageCreator` and applies the result in place (undoable). Requires a supported Mac with Apple Intelligence enabled; keep VibePaint frontmost when enhancing

### Files
- **File menu** — New, Open, Save, and Save As (macOS menu bar; in-window on Windows and Linux)
- **Image formats** — Save As supports PNG, JPEG, BMP, GIF, and WebP; macOS uses the system save panel format menu
- **Document title** — filename in the window title; `*` prefix when there are unsaved changes

### Platform
- **Desktop** — macOS, Windows, and Linux
- **macOS native menus** — File, Edit, and Image live in the system menu bar with standard keyboard shortcuts
- **Keyboard shortcuts** — undo/redo, zoom (⌘+/- / ⌘0 / ⌘1 on Mac), tools, and document commands; see menus for the full list

Third-party assets are tracked in [ATTRIBUTIONS.md](ATTRIBUTIONS.md) and [`assets/ATTRIBUTIONS.yaml`](assets/ATTRIBUTIONS.yaml).

## Roadmap

Rough order of obvious next steps:

- [x] **Color picker** — full HSV/RGB/hex dialog on double-click
- [x] **Brush size** — adjustable width
- [x] **Eraser** — paint back to transparent/background
- [x] **Undo / redo** — history for brush strokes
- [x] **New / clear** — reset the canvas
- [x] **Save & open** — PNG export and import
- [x] **Selection tools** — rectangle, ellipse, and lasso select with move, resize, and reshape
- [x] **Image menu** — crop, resize, flip, rotate, and flatten
- [x] **More tools** — fill bucket (G) and magic wand (W); tolerance follows brush size
- [x] **Toolbar** — tool buttons on the side
- [x] **Zoom & pan** — scroll to zoom, Space or middle-mouse to pan, keyboard zoom shortcuts
- [x] **Layers** — stack and edit images independently

## Install (macOS)

Download **`VibePaint-<version>-macos.dmg`** from [Releases](https://github.com/merklegroot/vibepaint/releases).

1. Open the DMG
2. Drag **VibePaint** into **Applications**
3. **First launch only:** in Applications, **right-click** VibePaint → **Open** → click **Open** again

macOS blocks unsigned apps downloaded from the internet until you confirm once. After that, double-click works normally. More detail: [docs/macos-distribution.md](docs/macos-distribution.md).

Alternative: download `VibePaint-<version>-macos.app.zip`, unzip, move `VibePaint.app` to Applications, then right-click → Open.

## Run from source

Requires [Flutter](https://docs.flutter.dev/get-started/install) with desktop support enabled.

```bash
flutter pub get
flutter run -d macos    # or windows / linux
```

### Apple Silicon (M1–M4)

Use the arm64 Flutter SDK from flutter.dev (the default), then:

```bash
flutter doctor          # confirm macOS desktop toolchain is OK
flutter pub get
flutter run -d macos
```

Release build locally:

```bash
flutter build macos --release
open build/macos/Build/Products/Release/VibePaint.app
```

Optional DMG (`create-dmg` via Homebrew for a nicer layout; otherwise `hdiutil`):

```bash
scripts/macos/package_dmg.sh \
  build/macos/Build/Products/Release/VibePaint.app \
  VibePaint-local-macos.dmg
```

## Releases

CI runs on every push and pull request to `master`.

To publish a release with Windows, Linux, and macOS binaries:

**Automatic (recommended):** open **Actions → Release → Run workflow** and click **Run workflow**. The version auto-increments the patch number from the latest `v*` tag (or uses `pubspec.yaml` for the first release), updates `pubspec.yaml`, and creates the GitHub release.

You can optionally enter a specific version (e.g. `0.2.0`) to override auto-increment.

**Manual tag:**

```bash
git tag v0.1.0
git push origin v0.1.0
```

### Release artifacts

| Platform | Artifact |
| --- | --- |
| macOS | `VibePaint-<version>-macos.dmg` (drag into Applications) and `VibePaint-<version>-macos.app.zip` |
| Windows | `VibePaint-<version>-win-x64.zip` |
| Linux | `VibePaint-<version>-linux-x64.tar.gz` |

No Apple Developer account is required. macOS builds are unsigned; users open once via **right-click → Open**.

## License

MIT — see [LICENSE](LICENSE).
