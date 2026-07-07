# Vibe Paint

A vibe coded paint app.

![VibePaint screenshot](docs/screenshot.png)

## Features

- **Canvas** — white document that fills the space between the toolbar and color bar
- **Brush, line, rectangle & eraser** — freehand paint, straight segments, outlined shapes, or erase to white
- **Toolbar** — tool picker on the left, brush width above the canvas
- **Color palette** — primary swatch and 12 preset colors (below the canvas)
- **Undo & redo** — step through stroke history (toolbar buttons or ⌘Z / ⌘⇧Z)
- **Save & open** — export and import PNG images (toolbar buttons or ⌘S / ⌘O)
- **Clear canvas** — wipe all strokes (toolbar button or ⌘⇧N)
- **Desktop** — macOS, Windows, and Linux

## Roadmap

Rough order of obvious next steps:

- [x] **Color picker** — primary color swatch (and eventually secondary)
- [x] **Brush size** — adjustable width
- [x] **Eraser** — paint back to white
- [x] **Undo / redo** — history for brush strokes
- [x] **New / clear** — reset the canvas
- [x] **Save & open** — PNG export and import
- [ ] **More tools** — ellipse, fill bucket (line & rectangle done)
- [x] **Toolbar** — tool buttons on the side
- [ ] **Zoom & pan** — navigate large canvases
- [ ] **Layers** — stack and edit images independently

## Run

Requires [Flutter](https://docs.flutter.dev/get-started/install) with desktop support enabled.

```bash
flutter pub get
flutter run -d macos    # or windows / linux
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

## License

MIT — see [LICENSE](LICENSE).
