# Attributions

Third-party assets and other material vendored into VibePaint are tracked in
[`assets/ATTRIBUTIONS.yaml`](assets/ATTRIBUTIONS.yaml). That file is the source
of truth; this document is the human-readable summary.

Run `scripts/check_attributions.sh` after adding or changing vendored assets.

## Toolbar icons

**Source:** [Tabler Icons](https://tabler.io/icons)  
**License:** [MIT License](https://github.com/tabler/tabler-icons/blob/main/LICENSE)  
**Copyright:** Copyright (c) 2020-2025 Tabler  
**Location:** `assets/icons/tools/`  
**Refresh:** `scripts/fetch_tool_icons.sh`

Outline icons from the Tabler `icons/outline` set, renamed where needed for app
tools. Local changes: comment headers removed, stroke width set to `1.75`.

| File | Upstream icon |
| --- | --- |
| `brush.svg` | `brush` |
| `pencil.svg` | `ballpen` |
| `line.svg` | `line` |
| `rectangle.svg` | `rectangle` |
| `ellipse.svg` | `oval` |
| `eraser.svg` | `eraser` |
| `eyedropper.svg` | `color-picker` |
| `rect_select.svg` | `square` |
| `ellipse_select.svg` | `circle-dashed` |
| `lasso.svg` | `lasso` |

## Adding new assets

1. Place files under `assets/` (for example `assets/icons/…`).
2. Add a `collections` entry to `assets/ATTRIBUTIONS.yaml` with:
   - source name, URL, and repository
   - license SPDX id and license URL
   - copyright / attribution text required by the license
   - local paths and per-file upstream mapping
   - modifications made after download
   - optional `fetch_script` if the assets can be re-fetched
3. Summarize the collection in this file.
4. Run `scripts/check_attributions.sh`.

## Project-owned assets

These are not third-party vendored assets and are not listed in
`assets/ATTRIBUTIONS.yaml`:

- `assets/app_icon.png` — VibePaint application icon
