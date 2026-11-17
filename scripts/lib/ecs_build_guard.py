#!/usr/bin/env python3
"""Build guard: verify build tree is configured before running cmake --build."""

from __future__ import annotations

import importlib.util
import os
import sys
from pathlib import Path

_LIB_DIR = Path(__file__).resolve().parent
_spec = importlib.util.spec_from_file_location("ecs_preset_query", _LIB_DIR / "ecs_preset_query.py")
if _spec is None or _spec.loader is None:
    raise RuntimeError("failed to load ecs_preset_query.py")
_preset = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_preset)


def main() -> int:
    if len(sys.argv) != 2:
        print("usage: ecs_build_guard.py <build-preset>", file=sys.stderr)
        return 2

    build_preset = sys.argv[1].strip()
    root = Path(os.environ.get("ECS_ROOT", ".")).resolve()

    try:
        configure_preset = _preset._resolve_field(build_preset, "configurePreset", root)
        binary_dir = Path(_preset._resolve_field(build_preset, "binaryDir", root))
    except SystemExit as exc:
        print(f"[ecs.sh build] {exc}", file=sys.stderr)
        return 1

    cache = binary_dir / "CMakeCache.txt"
    if not cache.is_file():
        print(
            f"[ecs.sh build] 构建树未配置：{binary_dir}\n"
            f"  请先对应当前 preset 显式 configure：\n"
            f"    scripts/ecs.sh configure {configure_preset}",
            file=sys.stderr,
        )
        return 1

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
