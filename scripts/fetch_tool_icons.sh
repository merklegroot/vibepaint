#!/usr/bin/env bash
set -euo pipefail

# Downloads toolbar SVGs tracked in assets/ATTRIBUTIONS.yaml (tabler-toolbar-icons).
# See ATTRIBUTIONS.md for license and attribution requirements.

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/assets/icons/tools"
mkdir -p "$out"

declare -A icons=(
  [brush]=brush
  [pencil]=ballpen
  [line]=line
  [rectangle]=rectangle
  [ellipse]=oval
  [gradient]=background
  [eraser]=eraser
  [fill_bucket]=bucket
  [text]=typography
  [magic_wand]=wand
  [eyedropper]=color-picker
  [rect_select]=square
  [ellipse_select]=circle-dashed
  [lasso]=lasso
)

base="https://raw.githubusercontent.com/tabler/tabler-icons/main/icons/outline"

for name in "${!icons[@]}"; do
  src="${icons[$name]}"
  curl -sL "$base/${src}.svg" \
    | sed '/^<!--/,/^-->/d' \
    | sed 's/stroke-width="2"/stroke-width="1.75"/' \
    > "$out/${name}.svg"
  echo "wrote ${name}.svg"
done

"$root/scripts/check_attributions.sh"
