#!/usr/bin/env bash
# Set up a local MLX (mflux) environment for VibePaint AI Enhance on Apple Silicon.
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
venv_dir="${VIBE_MLX_VENV:-$HOME/.vibepaint/mlx-venv}"
mlx_home="$HOME/.vibepaint/mlx"

echo "==> VibePaint MLX setup"
echo "    venv: $venv_dir"

pick_python() {
  for candidate in python3.13 python3.12 python3.11 python3.10 python3; do
    if command -v "$candidate" >/dev/null 2>&1; then
      version="$("$candidate" -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')"
      major="${version%%.*}"
      minor="${version#*.}"
      if [[ "$major" -eq 3 && "$minor" -ge 10 ]]; then
        echo "$candidate"
        return 0
      fi
    fi
  done
  return 1
}

if ! python_bin="$(pick_python)"; then
  echo "error: Python 3.10+ is required (brew install python@3.12)" >&2
  exit 1
fi

echo "    python: $python_bin ($("$python_bin" --version))"

if [[ ! -d "$venv_dir" ]]; then
  "$python_bin" -m venv "$venv_dir"
fi

"$venv_dir/bin/pip" install --upgrade pip
"$venv_dir/bin/pip" install -r "$repo_root/scripts/mlx/requirements.txt"

mkdir -p "$mlx_home"
cp "$repo_root/scripts/mlx/enhance_sketch.py" "$mlx_home/enhance_sketch.py"
chmod +x "$mlx_home/enhance_sketch.py"

echo "==> Verifying mflux import…"
"$venv_dir/bin/python" -c "import mflux; print('mflux OK')"

echo "    python venv: $venv_dir/bin/python3"
echo "    script:      $mlx_home/enhance_sketch.py"
echo "    (Restart VibePaint after setup so it picks up MLX.)"

cat <<EOF

MLX backend is ready.

Default model: flux2-klein-4b (public on Hugging Face — ~16 GB, lower RAM than Z-Image).

Notes:
- Model weights download to ~/.vibepaint/huggingface on disk (not into RAM).
- After download completes, weights are loaded into RAM for generation.
- First download can be several GB and take several minutes.
- Default quantization is 4-bit to reduce memory use.

EOF
