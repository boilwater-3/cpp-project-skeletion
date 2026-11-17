#!/usr/bin/env bash
# 构建门禁：禁止 cmake --build 隐式 reconfigure；CMake/依赖变更须显式 configure。
# shellcheck disable=SC2034

_ecs_run_build_guard() {
  if command -v python3 >/dev/null 2>&1; then
    python3 "${ECS_ROOT}/scripts/lib/ecs_build_guard.py" "$1"
  else
    python "${ECS_ROOT}/scripts/lib/ecs_build_guard.py" "$1"
  fi
}
