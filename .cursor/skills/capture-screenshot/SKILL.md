---
name: capture-screenshot
description: >-
  Capture a VibePaint app screenshot for docs or README using a headless Flutter
  widget test. Use when the user asks to take, update, or refresh the app
  screenshot or README image.
---

# Capture Screenshot

## Quick start

From repo root:

```bash
.cursor/skills/capture-screenshot/scripts/capture-screenshot.sh
```

Or:

```bash
flutter test --update-goldens test/generate_screenshot_test.dart
```

To verify without updating (local only — excluded from CI due to cross-platform rendering):

```bash
flutter test test/generate_screenshot_test.dart
```

CI runs `flutter test --exclude-tags golden` so Linux font differences do not fail the build.

Output: `docs/screenshot.png` (1280×720).

## README

The README already references the image:

```markdown
![VibePaint screenshot](docs/screenshot.png)
```

After capturing, confirm that line is still present. Update it only if the path or alt text should change.

## Customizing the demo

Edit `lib/demo/screenshot_demo.dart` to change sample strokes. Adjust `initialColorIndex` in `test/generate_screenshot_test.dart` to change the selected palette color.

`PaintScreen` accepts optional `initialStrokes` and `initialColorIndex` for this test only — the live app does not use them.

## Troubleshooting

- **Gray boxes instead of text/icons**: widget tests need fonts loaded — see `test/test_fonts.dart` and `setUpAll` in the screenshot test.
- **Missing file**: run from repo root so the relative `docs/screenshot.png` path resolves correctly.
- **Layout changed**: update stroke coordinates in `screenshot_demo.dart` if the left toolbar or canvas size shifted.
