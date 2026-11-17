# ProjectDependencies.cmake
# 第三方依赖发现入口
# 仅创建/导入 provider target，业务模块在各自 CMakeLists 中消费这些 target

set(ECS_PROJECT_DEPENDENCIES_DIR "${CMAKE_CURRENT_LIST_DIR}")

function(ecs_find_project_dependencies)
    include("${ECS_PROJECT_DEPENDENCIES_DIR}/dependencies/ConanPackages.cmake")

    # 将 provider 解析出的结果变量提升到调用方作用域，供 ProjectTargets / 业务模块使用。
    foreach(_ecs_dependency_var IN ITEMS
            ECS_LINK_DEPENDENCIES
            PROJECT_ENABLE_SPDLOG
            PROJECT_SPDLOG_TARGET)
        if(DEFINED ${_ecs_dependency_var})
            set(${_ecs_dependency_var} "${${_ecs_dependency_var}}" PARENT_SCOPE)
        endif()
    endforeach()
endfunction()
