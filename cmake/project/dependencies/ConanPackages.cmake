# dependencies/ConanPackages.cmake
# Conan 包发现与项目级依赖列表导出

set(PROJECT_ENABLE_SPDLOG ON)
find_package(spdlog CONFIG REQUIRED)
# 仅接受编译型 spdlog::spdlog；header-only 形态在本项目中不被允许。
if(TARGET spdlog::spdlog)
    set(PROJECT_SPDLOG_TARGET spdlog::spdlog)
elseif(TARGET spdlog::spdlog_header_only)
    message(FATAL_ERROR "spdlog header-only target is not allowed in this configuration")
else()
    message(FATAL_ERROR "spdlog target is not available")
endif()

# 导出公共库 target 需链接的通用依赖列表（当前除 spdlog 外保持为空，便于后续扩展）。
set(ECS_LINK_DEPENDENCIES "")
