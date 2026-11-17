# CMake 架构

本目录按 ownership 分层：顶层负责 project 生命周期，`src/` 负责产品装配，
模块目录负责自己的 object/interface target 与直接依赖。编译选项始终以
target 为粒度应用，不污染 vendor、tests 或 examples。

## 目录

```text
cmake/
├── compilers/                         编译器族 target option helpers
├── features/                          ccache、format/tidy、PCH、sanitizers、unity helpers
└── project/
    ├── ProjectOptions.cmake           build/module option boundary
    ├── ProjectSetup.cmake             prepare/configure lifecycle entry points
    ├── ProjectDependencies.cmake      ecs_find_project_dependencies()
    ├── ProjectTargets.cmake           component registry + target policy/public library helpers
    ├── ProjectInstall.cmake           export/package/public-tree installation
    ├── ProjectSummary.cmake           final configuration summary
    └── dependencies/
        └── ConanPackages.cmake        imported package discovery
```

## 主调用链

```text
CMakeLists.txt
  ├── ecs_prepare_project() / project() / ecs_configure_project()
  ├── setup owns language/options/tooling/compiler/project APIs and dependency discovery
  ├── add_subdirectory(src)
  │     ├── create ecs_lib / ecs::core
  │     ├── add_subdirectory(<module>)
  │     └── link registered object components into ecs_lib
  ├── ecs_install_project()
  └── tests / examples
```

每个 `src/<module>/CMakeLists.txt` 直接声明 source、component target（`OBJECT` 或 `INTERFACE`）与 direct
dependency。`src/CMakeLists.txt` 不维护 module source list 或 link matrix。

## 约束

- `ecs::core` 和 `ecs_lib` 是稳定的产品/导出 target（安装树同步提供 `ecs::core` 别名）。
- `PACKAGE_MANAGER=conan` 是唯一受支持的 provider。可直接运行
  `scripts/ecs.sh configure <preset>`（会自动触发 `scripts/bootstrap_conan.sh <preset>`）。
- `include/ecs` 是唯一 public header 物理边界。`ProjectInstall.cmake` 镜像安装该目录。
- compiler/feature helper 只定义函数或显式工具入口；禁止目录级
  `add_compile_options()` / `add_link_options()`。
