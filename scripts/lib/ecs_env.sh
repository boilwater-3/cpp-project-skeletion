#!/usr/bin/env bash
# ECS 环境初始化：补 PATH（cmake/ctest），导出 ECS_ROOT。

if [[ -n "${ECS_ENV_LOADED:-}" ]]; then
  return 0 2>/dev/null || exit 0
fi
ECS_ENV_LOADED=1

if [[ -z "${ECS_ROOT:-}" ]]; then
  ECS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
fi
export ECS_ROOT

if [[ -f "${ECS_ROOT}/scripts/ecs_env.local.sh" ]]; then
  # shellcheck source=/dev/null
  source "${ECS_ROOT}/scripts/ecs_env.local.sh"
fi

_ecs_prepend_path_if_dir() {
  local dir="$1"
  [[ -d "$dir" ]] || return 0
  case ":${PATH}:" in
    *":${dir}:"*) ;;
    *) PATH="${dir}:${PATH}" ;;
  esac
}

if [[ -z "${ECS_REAL_CMAKE:-}" ]]; then
  if command -v cmake >/dev/null 2>&1; then
    export ECS_REAL_CMAKE="$(command -v cmake)"
  fi
fi

if [[ -n "${ECS_REAL_CMAKE:-}" ]]; then
  _ecs_prepend_path_if_dir "$(dirname "${ECS_REAL_CMAKE}")"
fi

unset _ecs_prepend_path_if_dir
