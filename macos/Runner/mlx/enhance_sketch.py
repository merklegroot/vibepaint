#!/usr/bin/env python3
"""Enhance a sketch PNG using MLX (mflux image-to-image).

Downloads model weights to disk first (Hugging Face cache), reports byte
progress, then loads from the local cache only after the download is complete.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import threading
import time
from pathlib import Path


DEFAULT_MODEL = "flux2-klein-4b"
DEFAULT_PROMPT = (
    "colorful finished illustration, polished digital art, vivid colors"
)
# Keep enhance resolution modest to reduce peak RAM on laptops.
MAX_ENHANCE_SIDE = 512

# Keep HF cache under ~/.vibepaint so downloads are predictable and on disk.
VIBE_HF_HOME = Path.home() / ".vibepaint" / "huggingface"
_DOWNLOAD_STARTED_AT: float | None = None


def _emit(payload: dict) -> None:
    print(json.dumps(payload), flush=True)


def _format_bytes(num: float | int | None) -> str:
    if num is None or num < 0:
        return "?"
    value = float(num)
    units = ["B", "KB", "MB", "GB", "TB"]
    for unit in units:
        if value < 1024 or unit == units[-1]:
            if unit == "B":
                return f"{int(value)} {unit}"
            return f"{value:.1f} {unit}"
        value /= 1024
    return f"{value:.1f} TB"


def _dir_size(path: Path) -> int:
    total = 0
    if not path.exists():
        return 0
    for root, _, files in os.walk(path):
        for name in files:
            file_path = Path(root) / name
            try:
                if file_path.is_file():
                    total += file_path.stat().st_size
            except OSError:
                pass
    return total


def _progress(
    message: str,
    phase: str = "working",
    *,
    bytes_done: int | None = None,
    bytes_total: int | None = None,
) -> None:
    global _DOWNLOAD_STARTED_AT
    if phase == "download" and _DOWNLOAD_STARTED_AT is None:
        _DOWNLOAD_STARTED_AT = time.time()

    elapsed = 0
    if _DOWNLOAD_STARTED_AT is not None:
        elapsed = int(time.time() - _DOWNLOAD_STARTED_AT)

    payload: dict = {
        "progress": True,
        "phase": phase,
        "message": message,
        "elapsed_seconds": elapsed,
    }
    if bytes_done is not None:
        payload["bytes_done"] = int(bytes_done)
    if bytes_total is not None and bytes_total > 0:
        payload["bytes_total"] = int(bytes_total)
    _emit(payload)


def _friendly_error(exc: BaseException) -> str:
    text = str(exc)
    lowered = text.lower()
    if "out of memory" in lowered or "oom" in lowered:
        return (
            "VibePaint ran out of memory while loading the model.\n\n"
            "The model downloads to disk first, but generating still needs "
            "several GB of free RAM. Try closing other apps, then run AI "
            "Enhance again. You can also use a smaller quantize setting.\n\n"
            f"Original error:\n{text}"
        )
    if "gated" in lowered or "401" in lowered or "must have access" in lowered:
        return (
            "This model is gated on Hugging Face and needs login/access.\n\n"
            "VibePaint defaults to the public flux2-klein-4b model. Update the "
            "script (or re-run scripts/mlx/setup.sh), then try again.\n\n"
            f"Original error:\n{text}"
        )
    return text


def _configure_hf_cache() -> None:
    VIBE_HF_HOME.mkdir(parents=True, exist_ok=True)
    # New downloads go here, but we also search the default HF cache below.
    os.environ.setdefault("HF_HOME", str(VIBE_HF_HOME))
    os.environ.setdefault("HUGGINGFACE_HUB_CACHE", str(VIBE_HF_HOME / "hub"))
    os.environ["HF_HUB_DISABLE_PROGRESS_BARS"] = "1"


def _hf_hub_cache_dirs() -> list[Path]:
    """Hugging Face hub caches to search, most preferred first."""
    seen: set[Path] = set()
    ordered: list[Path] = []

    def add(path: Path) -> None:
        resolved = path.expanduser().resolve()
        if resolved in seen:
            return
        seen.add(resolved)
        if resolved.exists():
            ordered.append(resolved)

    add(VIBE_HF_HOME / "hub")
    add(Path.home() / ".cache" / "huggingface" / "hub")
    hf_home = os.environ.get("HF_HOME")
    if hf_home:
        add(Path(hf_home) / "hub")
    hub_cache = os.environ.get("HUGGINGFACE_HUB_CACHE")
    if hub_cache:
        add(Path(hub_cache))
    return ordered


def _repo_cache_name(repo_id: str) -> str:
    return f"models--{repo_id.replace('/', '--')}"


def _repo_blobs_dir(repo_id: str, hub_cache: Path) -> Path:
    return hub_cache / _repo_cache_name(repo_id) / "blobs"


def _get_required_subdirs_with_safetensors(patterns: list[str]) -> set[str]:
    subdirs: set[str] = set()
    for pattern in patterns:
        if "*.safetensors" not in pattern or "/" not in pattern:
            continue
        subdir = pattern.split("/")[0]
        if "*" not in subdir:
            subdirs.add(subdir)
    return subdirs


def _is_snapshot_complete(
    snapshot_path: Path, required_subdirs: set[str], patterns: list[str]
) -> bool:
    if not required_subdirs:
        for pattern in patterns:
            matches = list(snapshot_path.glob(pattern))
            if not matches:
                return False
            if not any(
                match.is_symlink() and os.path.exists(match) or not match.is_symlink()
                for match in matches
            ):
                return False
        return True

    for subdir in required_subdirs:
        subdir_path = snapshot_path / subdir
        if not subdir_path.exists():
            return False
        has_safetensors = False
        for file_path in subdir_path.iterdir():
            if not file_path.name.endswith(".safetensors"):
                continue
            if file_path.is_symlink():
                if os.path.exists(file_path):
                    has_safetensors = True
                    break
            else:
                has_safetensors = True
                break
        if not has_safetensors:
            return False
    return True


def _find_complete_cached_snapshot(
    repo_id: str, patterns: list[str]
) -> tuple[Path, Path] | None:
    """Return (snapshot_path, hub_cache_dir) if a complete copy exists."""
    required_subdirs = _get_required_subdirs_with_safetensors(patterns)
    for hub_cache in _hf_hub_cache_dirs():
        snapshots_dir = hub_cache / _repo_cache_name(repo_id) / "snapshots"
        if not snapshots_dir.exists():
            continue
        snapshots = sorted(
            snapshots_dir.iterdir(),
            key=lambda path: path.stat().st_mtime,
            reverse=True,
        )
        for snapshot_path in snapshots:
            if not snapshot_path.is_dir():
                continue
            if _is_snapshot_complete(snapshot_path, required_subdirs, patterns):
                return snapshot_path, hub_cache
    return None


def _estimate_download_bytes(repo_id: str, patterns: list[str]) -> int | None:
    from huggingface_hub import snapshot_download

    try:
        files = snapshot_download(
            repo_id=repo_id,
            allow_patterns=patterns,
            dry_run=True,
        )
    except Exception:
        return None
    total = sum(file_info.file_size for file_info in files)
    return total if total > 0 else None


def _start_download_poller(
    repo_id: str,
    hub_cache: Path,
    total_bytes: int | None,
) -> tuple[threading.Event, threading.Thread]:
    """Poll on-disk blob bytes while huggingface_hub downloads in the background."""
    stop = threading.Event()
    blobs_dir = _repo_blobs_dir(repo_id, hub_cache)
    started_at = time.time()
    last_done = -1

    def poll() -> None:
        nonlocal last_done
        while not stop.is_set():
            done = _dir_size(blobs_dir) if blobs_dir.exists() else 0
            if done != last_done:
                last_done = done
                elapsed = max(1, int(time.time() - started_at))
                rate = done / elapsed
                if total_bytes:
                    msg = (
                        f"Downloading to disk: {_format_bytes(done)} / "
                        f"{_format_bytes(total_bytes)} "
                        f"({_format_bytes(rate)}/s)"
                    )
                else:
                    msg = (
                        f"Downloading to disk: {_format_bytes(done)} "
                        f"({_format_bytes(rate)}/s)"
                    )
                _progress(
                    msg,
                    "download",
                    bytes_done=done,
                    bytes_total=total_bytes,
                )
            stop.wait(0.5)

    thread = threading.Thread(target=poll, name="hf-download-poller", daemon=True)
    thread.start()
    return stop, thread


def _weight_definition_for(model_name: str):
    from mflux.models.common.config.model_config import ModelConfig

    config = ModelConfig.from_name(model_name=model_name, base_model=None)
    aliases = config.aliases or []
    if model_name.startswith("flux2") or any(
        "flux2" in alias or "klein" in alias.lower() for alias in aliases
    ):
        from mflux.models.flux2.weights.flux2_weight_definition import (
            Flux2KleinWeightDefinition,
        )

        return Flux2KleinWeightDefinition(), config

    if model_name.startswith("z-image") or any("z-image" in a for a in aliases):
        from mflux.models.z_image.weights.z_image_weight_definition import (
            ZImageWeightDefinition,
        )

        return ZImageWeightDefinition(), config

    from mflux.models.flux.weights.flux_weight_definition import FluxWeightDefinition

    return FluxWeightDefinition(), config


def _is_flux2_klein(model_name: str, config) -> bool:
    aliases = config.aliases or []
    return model_name.startswith("flux2") or any(
        "flux2" in alias or "klein" in alias.lower() for alias in aliases
    )


def _make_download_tqdm():
    from tqdm.auto import tqdm as base_tqdm

    class JsonDownloadProgress(base_tqdm):
        """Feeds huggingface_hub download progress into VibePaint JSON lines."""

        def __init__(self, *args, **kwargs):
            # Do not set disable=True — tqdm skips byte counting when disabled.
            kwargs.setdefault("leave", False)
            kwargs["file"] = open(os.devnull, "w", encoding="utf-8")  # noqa: SIM115
            super().__init__(*args, **kwargs)
            self._last_emit_at = 0.0

        def update(self, n=1):
            result = super().update(n)
            now = time.time()
            total = int(self.total) if self.total else None
            done = int(self.n)
            should_emit = (
                now - self._last_emit_at >= 0.4
                or (total is not None and done >= total)
            )
            if should_emit:
                self._last_emit_at = now
                if total:
                    msg = (
                        f"Downloading to disk: {_format_bytes(done)} / "
                        f"{_format_bytes(total)}"
                    )
                else:
                    msg = f"Downloading to disk: {_format_bytes(done)}"
                _progress(
                    msg,
                    "download",
                    bytes_done=done,
                    bytes_total=total,
                )
            return result

    return JsonDownloadProgress


def _ensure_model_on_disk(repo_id: str, patterns: list[str]) -> Path:
    from huggingface_hub import snapshot_download

    found = _find_complete_cached_snapshot(repo_id, patterns)
    if found is not None:
        cached, hub_cache = found
        size = _dir_size(cached)
        cache_label = (
            "~/.vibepaint/huggingface"
            if hub_cache == (VIBE_HF_HOME / "hub").resolve()
            else str(hub_cache)
        )
        _progress(
            f"Model already on disk ({_format_bytes(size)} in {cache_label})",
            "download",
            bytes_done=size,
            bytes_total=size,
        )
        return cached

    download_cache = VIBE_HF_HOME / "hub"
    total_bytes = _estimate_download_bytes(repo_id, patterns)
    if total_bytes:
        _progress(
            f"Downloading {repo_id} to disk ({_format_bytes(total_bytes)} total, not into RAM)…",
            "download",
            bytes_done=0,
            bytes_total=total_bytes,
        )
    else:
        _progress(
            f"Downloading {repo_id} to disk (not into RAM)…",
            "download",
            bytes_done=0,
            bytes_total=None,
        )

    stop_poller, poller = _start_download_poller(repo_id, download_cache, total_bytes)
    try:
        snapshot_download(
            repo_id=repo_id,
            allow_patterns=patterns,
            cache_dir=str(download_cache),
            tqdm_class=_make_download_tqdm(),
        )
    finally:
        stop_poller.set()
        poller.join(timeout=2)

    found = _find_complete_cached_snapshot(repo_id, patterns)
    if found is None:
        raise RuntimeError(
            f"Download finished but {repo_id} is still incomplete in the cache. "
            "Check your network connection and disk space, then try again."
        )

    cached, _ = found
    size = _dir_size(cached)
    _progress(
        f"Download complete ({_format_bytes(size)} on disk)",
        "download",
        bytes_done=size,
        bytes_total=size,
    )
    return cached


def _register_low_ram(model) -> None:
    from mflux.callbacks.instances.memory_saver import MemorySaver

    model.callbacks.register(
        MemorySaver(
            model=model,
            keep_transformer=False,
            cache_limit_bytes=1000**3,
            num_seeds=1,
        )
    )


def _load_model(model_name: str, quantize: int, local_path: Path):
    try:
        from mflux.models.flux.variants.txt2img.flux import Flux1
        from mflux.models.flux2.variants.txt2img.flux2_klein import Flux2Klein
        from mflux.models.z_image import ZImageTurbo
    except ImportError as exc:
        _emit(
            {
                "ok": False,
                "error": "mflux_not_installed",
                "message": str(exc),
            }
        )
        sys.exit(2)

    _, config = _weight_definition_for(model_name)
    size = _format_bytes(_dir_size(local_path))
    _progress(
        f"Loading model from disk into RAM ({size})… needs several GB free memory",
        "load",
    )

    if _is_flux2_klein(model_name, config):
        model = Flux2Klein(
            model_config=config,
            quantize=quantize,
            model_path=str(local_path),
        )
        _register_low_ram(model)
        return model

    if model_name.startswith("z-image") or "z-image" in (config.aliases or []):
        model = ZImageTurbo(
            model_config=config,
            quantize=quantize,
            model_path=str(local_path),
        )
        _register_low_ram(model)
        return model

    model = Flux1(
        model_config=config,
        quantize=quantize,
        model_path=str(local_path),
    )
    _register_low_ram(model)
    return model


def _image_size(path: Path) -> tuple[int, int]:
    try:
        from PIL import Image
    except ImportError:
        return 1024, 1024

    with Image.open(path) as image:
        width, height = image.size
    side = max(width, height, 512)
    side = min(side, MAX_ENHANCE_SIDE)
    side = max(512, (side + 63) // 64 * 64)
    return side, side


def _default_steps(model_name: str) -> int:
    if model_name.startswith("flux2-klein") or model_name in {
        "schnell",
        "z-image-turbo",
        "ernie-image-turbo",
    }:
        return 4
    if model_name.startswith("z-image"):
        return 8
    if model_name == "dev":
        return 16
    return 4


def _default_guidance(model_name: str, config) -> float | None:
    if _is_flux2_klein(model_name, config):
        return 1.0
    if model_name in {"schnell", "z-image-turbo"}:
        return None
    if model_name == "dev":
        return 3.5
    return None


def main() -> int:
    _configure_hf_cache()

    parser = argparse.ArgumentParser(description="VibePaint MLX sketch enhancer")
    parser.add_argument("--input", required=True, help="Input sketch PNG path")
    parser.add_argument("--output", required=True, help="Output PNG path")
    parser.add_argument("--prompt", default=DEFAULT_PROMPT)
    parser.add_argument("--strength", type=float, default=0.55)
    parser.add_argument(
        "--model",
        default=DEFAULT_MODEL,
        help="mflux model alias (default: flux2-klein-4b)",
    )
    parser.add_argument("--steps", type=int, default=0)
    parser.add_argument("--seed", type=int, default=42)
    parser.add_argument(
        "--quantize",
        type=int,
        default=4,
        help="Weight quantization (4 uses less RAM than 8)",
    )
    args = parser.parse_args()

    input_path = Path(args.input)
    output_path = Path(args.output)
    if not input_path.is_file():
        _emit({"ok": False, "error": "missing_input", "message": str(input_path)})
        return 1

    width, height = _image_size(input_path)
    steps = args.steps or _default_steps(args.model)

    try:
        weight_def, config = _weight_definition_for(args.model)
        patterns = weight_def.get_download_patterns()
        repo_id = config.model_name
        guidance = _default_guidance(args.model, config)

        local_path = _ensure_model_on_disk(repo_id, patterns)
        model = _load_model(args.model, args.quantize, local_path)

        _progress(
            f"Generating ({steps} steps, {width}×{height})…",
            "generate",
        )
        kwargs = {
            "seed": args.seed,
            "prompt": args.prompt,
            "image_path": str(input_path),
            "image_strength": args.strength,
            "num_inference_steps": steps,
            "height": height,
            "width": width,
        }
        if guidance is not None:
            kwargs["guidance"] = guidance
        image = model.generate_image(**kwargs)

        _progress("Saving enhanced image…", "save")
        output_path.parent.mkdir(parents=True, exist_ok=True)
        image.save(path=str(output_path))
    except Exception as exc:  # noqa: BLE001
        _emit(
            {
                "ok": False,
                "error": "generation_failed",
                "message": _friendly_error(exc),
            }
        )
        return 1

    _emit(
        {
            "ok": True,
            "width": width,
            "height": height,
            "model": args.model,
            "steps": steps,
            "output": str(output_path),
        }
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
