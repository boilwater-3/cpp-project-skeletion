# ProjectOptions.cmake
# 项目构建选项入口：集中声明所有用户可配置开关
# cmake/project 的唯一选项边界，业务模块不重复定义缓存变量

# 共享库 / 测试 / 示例 / 安装四个顶层开关。
option(BUILD_SHARED_LIBS "Build shared libraries instead of static" OFF)
option(ENABLE_TESTING "Enable testing support" OFF)
option(ENABLE_EXAMPLES "Build example programs" OFF)
option(ENABLE_INSTALL "Enable installation rules" OFF)

# Unity Build 依赖 set_source_files_properties 的 UNITY_BUILD 属性，CMake 3.16 引入。
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.16")
    option(ENABLE_UNITY_BUILD "Enable Unity Build for faster compilation" OFF)
else()
    set(ENABLE_UNITY_BUILD OFF CACHE INTERNAL "Unity Build requires CMake 3.16+")
endif()

# ccache 是 UNIX 下的编译缓存工具，Windows 原生不支持。
if(UNIX)
    option(USE_CCACHE "Use ccache to accelerate rebuilds" ON)
else()
    set(USE_CCACHE OFF CACHE INTERNAL "ccache is primarily for Linux/macOS")
endif()

# 预编译头同样依赖 CMake 3.16 的 target_precompile_headers。
if(CMAKE_VERSION VERSION_GREATER_EQUAL "3.16")
    option(ENABLE_PCH "Enable precompiled headers" OFF)
    mark_as_advanced(ENABLE_PCH)
else()
    set(ENABLE_PCH OFF CACHE INTERNAL "Precompiled headers require CMake 3.16+")
endif()

# 编译期告警 / 静态分析 / LTO 开关。
option(ENABLE_WARNINGS "Enable additional compiler warnings" ON)
option(ENABLE_CLANG_TIDY "Enable clang-tidy static analysis" OFF)
mark_as_advanced(ENABLE_CLANG_TIDY)
option(ENABLE_LTO "Enable Link-Time Optimization in Release/MinSizeRel builds" OFF)

# 运行期 Sanitizers 开关（ASan 与 TSan 互斥）。
option(ENABLE_ASAN "Enable AddressSanitizer (ASan)" OFF)
option(ENABLE_UBSAN "Enable UndefinedBehaviorSanitizer (UBSan)" OFF)
option(ENABLE_TSAN "Enable ThreadSanitizer (TSan)" OFF)
if(ENABLE_ASAN AND ENABLE_TSAN)
    message(FATAL_ERROR "ENABLE_ASAN and ENABLE_TSAN cannot be enabled simultaneously")
endif()

# clang-tidy 检查项白名单：聚焦 readability/modernize/performance/bugprone 四类，
# 保留可直接机械修复的项，排除需人工判断语义的高噪声检查。
set(CLANG_TIDY_CHECKS
    "-*,readability-braces-around-statements,readability-else-after-return,readability-isolate-declaration,readability-qualified-auto,readability-redundant-access-specifiers,readability-redundant-control-flow,readability-redundant-preprocessor,readability-static-accessed-through-instance,modernize-redundant-void-arg,modernize-use-bool-literals,modernize-use-default-member-init,modernize-use-equals-default,modernize-use-equals-delete,modernize-use-nullptr,modernize-use-override,modernize-use-using,performance-for-range-copy,performance-implicit-conversion-in-loop,performance-move-constructor-init,performance-unnecessary-copy-initialization,performance-unnecessary-value-param,bugprone-macro-parentheses,bugprone-string-constructor,bugprone-string-integer-assignment"
    CACHE STRING "clang-tidy checks whitelist")
mark_as_advanced(CLANG_TIDY_CHECKS)

# 包管理器 / 依赖 provider：当前仅支持 conan。
set(PACKAGE_MANAGER "conan" CACHE STRING
    "ecs dependency provider: 'conan' (run scripts/bootstrap_conan.sh)")
set_property(CACHE PACKAGE_MANAGER PROPERTY STRINGS "conan")
if(NOT PACKAGE_MANAGER STREQUAL "conan")
    message(FATAL_ERROR
        "Unsupported PACKAGE_MANAGER: '${PACKAGE_MANAGER}'. "
        "ecs currently supports 'conan' (run scripts/bootstrap_conan.sh <preset>).")
endif()
message(STATUS "Package Manager: Conan")
