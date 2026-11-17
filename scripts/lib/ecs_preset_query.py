#!/usr/bin/env python3
"""Resolve CMakePresets.json (+ optional CMakeUserPresets.json) for ecs.sh and bootstrap_conan.sh."""

from __future__ import annotations

import json
import os
import sys
from pathlib import Path
from typing import Any


def _load_preset_files(root: Path) -> list[dict[str, Any]]:
    presets: list[dict[str, Any]] = []
    for name in ("CMakePresets.json", "CMakeUserPresets.json"):
        path = root / name
        if not path.is_file():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        presets.extend(data.get("configurePresets", []))
    return presets


def _load_build_presets(root: Path) -> list[dict[str, Any]]:
    presets: list[dict[str, Any]] = []
    for name in ("CMakePresets.json", "CMakeUserPresets.json"):
        path = root / name
        if not path.is_file():
            continue
        data = json.loads(path.read_text(encoding="utf-8"))
        presets.extend(data.get("buildPresets", []))
    return presets


def _inherit_names(value: Any) -> list[str]:
    """CMake presets 的 `inherits` 允许字符串或字符串数组两种写法。"""
    if value is None:
        return []
    if isinstance(value, str):
        return [value]
    if isinstance(value, list):
        return [item for item in value if isinstance(item, str)]
    raise SystemExit(f"invalid `inherits` value: {value!r}")


def _merge_configure_preset(
    by_name: dict[str, dict[str, Any]], name: str, chain: frozenset[str] = frozenset()
) -> dict[str, Any]:
    if name in chain:
        raise SystemExit(f"circular configure preset inheritance at {name}")
    if name not in by_name:
        raise SystemExit(f"unknown configure preset: {name}")

    preset = dict(by_name[name])
    next_chain = chain | {name}
    merged: dict[str, Any] = {}
    parent_cache: dict[str, Any] = {}
    for parent_name in _inherit_names(preset.pop("inherits", None)):
        parent = _merge_configure_preset(by_name, parent_name, next_chain)
        parent_cache.update(parent.get("cacheVariables", {}))
        merged.update(parent)
    merged.update(preset)
    if parent_cache or "cacheVariables" in preset:
        merged["cacheVariables"] = {**parent_cache, **preset.get("cacheVariables", {})}
    return merged


def _cache_val(merged: dict[str, Any], key: str, default: str = "") -> str:
    raw = merged.get("cacheVariables", {}).get(key, default)
    if isinstance(raw, dict):
        raw = raw.get("value", default)
    return str(raw) if raw is not None else default


def _binary_dir(root: Path, configure_preset: str, merged: dict[str, Any]) -> Path:
    template = merged.get("binaryDir", "${sourceDir}/build/${presetName}")
    resolved = (
        template.replace("${sourceDir}", str(root))
        .replace("${presetName}", configure_preset)
    )
    return Path(resolved)


def _resolve_field(preset_name: str, field: str, root: Path) -> str:
    configure_presets = _load_preset_files(root)
    by_name = {p["name"]: p for p in configure_presets if "name" in p}

    build_presets = _load_build_presets(root)
    build_by_name = {p["name"]: p for p in build_presets if "name" in p}

    configure_name = preset_name
    if preset_name in build_by_name:
        configure_name = build_by_name[preset_name]["configurePreset"]
    elif preset_name not in by_name:
        raise SystemExit(f"unknown preset: {preset_name}")

    merged = _merge_configure_preset(by_name, configure_name)
    if field == "configurePreset":
        return configure_name
    if field == "binaryDir":
        return str(_binary_dir(root, configure_name, merged))
    if field == "toolchain":
        raw = _cache_val(merged, "CMAKE_TOOLCHAIN_FILE", "")
        return raw.replace("${sourceDir}", str(root)).replace("${presetName}", configure_name)
    if field == "buildType":
        return _cache_val(merged, "CMAKE_BUILD_TYPE", "")
    if field == "enableTesting":
        val = _cache_val(merged, "ENABLE_TESTING", "OFF").strip().upper()
        return "True" if val in {"ON", "TRUE", "1", "YES"} else "False"
    if field == "cppstd":
        return _cache_val(merged, "CMAKE_CXX_STANDARD", "17") or "17"
    if field == "generator":
        return str(merged.get("generator", ""))
    if field == "packageManager":
        return _cache_val(merged, "PACKAGE_MANAGER", "conan") or "conan"
    raise SystemExit(f"unknown field: {field}")


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: ecs_preset_query.py <build-preset|configure-preset> <field>", file=sys.stderr)
        print(
            "  field: configurePreset | binaryDir | toolchain | buildType | "
            "enableTesting | cppstd | generator | packageManager",
            file=sys.stderr,
        )
        return 2

    preset_name = sys.argv[1]
    field = sys.argv[2]
    root = Path(os.environ.get("ECS_ROOT", ".")).resolve()

    try:
        print(_resolve_field(preset_name, field, root))
    except SystemExit as exc:
        print(str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
