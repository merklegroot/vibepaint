# Vibe Paint

A vibe coded paint app.

![VibePaint screenshot](docs/screenshot.png)

## Features

- **Canvas** — white document that fills the space between the toolbar and color bar
- **Brush & eraser** — paint with color or erase back to white
- **Toolbar** — tool picker on the left, brush width above the canvas
- **Color palette** — primary swatch and 12 preset colors (below the canvas)
- **Undo & redo** — step through stroke history (toolbar buttons or ⌘Z / ⌘⇧Z)
- **Status bar** — shows active tool and current color
- **Desktop** — macOS, Windows, and Linux

## Roadmap

Rough order of obvious next steps:

- [x] **Color picker** — primary color swatch (and eventually secondary)
- [x] **Brush size** — adjustable width
- [x] **Eraser** — paint back to white
- [x] **Undo / redo** — history for brush strokes
- [ ] **New / clear** — reset the canvas
- [ ] **Save & open** — PNG export and import
- [ ] **More tools** — line, rectangle, ellipse, fill bucket
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

```bash
git tag v0.1.0
git push origin v0.1.0
```

Or open **Actions → Release → Run workflow**, enter a version like `0.1.0`, and GitHub will build the archives and create the release.

## License

MIT — see [LICENSE](LICENSE).
