#!/usr/bin/env bash
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
out="$root/assets/icons/tools"
mkdir -p "$out"

declare -A icons=(
  [brush]=brush
  [pencil]=ballpen
  [line]=line
  [rectangle]=rectangle
  [ellipse]=oval
  [eraser]=eraser
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
