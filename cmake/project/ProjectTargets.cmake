# ProjectTargets.cmake
# 产品 target 工厂：统一稳定的构建装配
# 源码归属与直接依赖仍归各业务模块可见

# 按 features 层定义的顺序装配 target：Unity Build → 编译器 flag → Sanitizers → 预编译头。
function(ecs_apply_target_configuration)
    set(multi_value_args TARGETS LINK_TARGETS)
    cmake_parse_arguments(ARG "" "" "${multi_value_args}" ${ARGN})
    if(NOT ARG_TARGETS)
        message(FATAL_ERROR "ecs_apply_target_configuration() requires TARGETS")
    endif()
    if(NOT ARG_LINK_TARGETS)
        set(ARG_LINK_TARGETS ${ARG_TARGETS})
    endif()

    apply_unity_build(TARGETS ${ARG_TARGETS})
    if(MSVC)
        apply_msvc_options(
            TARGETS ${ARG_TARGETS}
            LINK_TARGETS ${ARG_LINK_TARGETS}
            ENABLE_WARNINGS ${ENABLE_WARNINGS})
    else()
        apply_clang_gcc_options(
            TARGETS ${ARG_TARGETS}
            LINK_TARGETS ${ARG_LINK_TARGETS}
            ENABLE_WARNINGS ${ENABLE_WARNINGS}
            ENABLE_LTO ${ENABLE_LTO})
    endif()
    apply_sanitizers(TARGETS ${ARG_TARGETS} LINK_TARGETS ${ARG_LINK_TARGETS})
    apply_precompiled_headers(TARGETS ${ARG_TARGETS})
endfunction()

# 装配对外暴露的公共库 target：MSVC 运行时、静态宏、版本号与可见性。
function(ecs_configure_public_library target)
    if(NOT TARGET "${target}")
        message(FATAL_ERROR "ecs_configure_public_library(): target does not exist: ${target}")
    endif()

    # MSVC 运行时覆盖：留空则使用默认动态 CRT（/MD /MDd），可由用户显式指定。
    set(ECS_MSVC_RUNTIME_LIBRARY "" CACHE STRING
        "MSVC runtime override. Empty = default dynamic CRT (/MD /MDd).")
    if(MSVC)
        if(ECS_MSVC_RUNTIME_LIBRARY STREQUAL "")
            set(_ecs_msvc_rt "MultiThreaded$<$<CONFIG:Debug>:Debug>DLL")
        else()
            set(_ecs_msvc_rt "${ECS_MSVC_RUNTIME_LIBRARY}")
        endif()
        set_property(TARGET "${target}" PROPERTY MSVC_RUNTIME_LIBRARY "${_ecs_msvc_rt}")
    endif()

    # 静态构建时对外暴露 ECS_STATIC_DEFINE，供下游头文件正确选择 dllexport/dllimport。
    if(NOT BUILD_SHARED_LIBS)
        target_compile_definitions("${target}" PUBLIC ECS_STATIC_DEFINE)
    endif()

    # 统一 target 属性：导出名、debug 后缀、版本号、SOVERSION。
    set_target_properties("${target}" PROPERTIES
        EXPORT_NAME "${PROJECT_NAME_LOWER}"
        OUTPUT_NAME "${PROJECT_NAME_LOWER}"
        DEBUG_POSTFIX d
        VERSION "${PROJECT_VERSION}"
        SOVERSION "${PROJECT_VERSION_MAJOR}")
    # 非 Windows：隐藏非导出符号，缩减二进制体积并强化 ABI 边界。
    if(NOT WIN32)
        set_target_properties("${target}" PROPERTIES
            CXX_VISIBILITY_PRESET hidden
            VISIBILITY_INLINES_HIDDEN YES)
    endif()
endfunction()

# 创建业务组件 target：支持编译型 OBJECT 库与纯头文件 INTERFACE 库。
# 用法：
#   ecs_add_component(<target> SOURCES a.cpp b.cpp)
#   ecs_add_component(<target> INTERFACE)
function(ecs_add_component target)
    set(options INTERFACE)
    set(multi_value_args SOURCES)
    cmake_parse_arguments(ARG "${options}" "" "${multi_value_args}" ${ARGN})
    if(TARGET "${target}")
        message(FATAL_ERROR "ecs component target already exists: ${target}")
    endif()
    if(ARG_INTERFACE AND ARG_SOURCES)
        message(FATAL_ERROR "ecs_add_component(${target}): INTERFACE component cannot specify SOURCES")
    endif()

    # 纯头文件组件：创建 INTERFACE target，不登记到 ECS_COMPONENT_TARGETS（无编译产物）。
    if(ARG_INTERFACE OR NOT ARG_SOURCES)
        add_library("${target}" INTERFACE)
        target_include_directories("${target}" INTERFACE
            $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
            $<BUILD_INTERFACE:${PROJECT_GENERATED_INCLUDE_DIR}>
            $<INSTALL_INTERFACE:include>)
        target_compile_features("${target}" INTERFACE "cxx_std_${PROJECT_CXX_STANDARD}")
        if(NOT BUILD_SHARED_LIBS)
            target_compile_definitions("${target}" INTERFACE ECS_STATIC_DEFINE)
        endif()
        return()
    endif()

    # 源文件统一转为绝对路径，避免不同目录下 CMakeLists 相对路径歧义。
    set(component_sources)
    foreach(component_source IN LISTS ARG_SOURCES)
        if(IS_ABSOLUTE "${component_source}")
            list(APPEND component_sources "${component_source}")
        else()
            list(APPEND component_sources
                "${CMAKE_CURRENT_SOURCE_DIR}/${component_source}")
        endif()
    endforeach()

    # OBJECT 库：编译为独立目标文件，最终由公共库 target 聚合链接。
    add_library("${target}" OBJECT ${component_sources})
    # 三类 include 路径：src（模块互引）、生成头目录、公共 include。
    target_include_directories("${target}" PRIVATE
        "${CMAKE_SOURCE_DIR}/src"
        "${PROJECT_GENERATED_INCLUDE_DIR}"
        "${CMAKE_SOURCE_DIR}/include")
    target_compile_features("${target}" PRIVATE "cxx_std_${PROJECT_CXX_STANDARD}")
    if(NOT BUILD_SHARED_LIBS)
        target_compile_definitions("${target}" PRIVATE ECS_STATIC_DEFINE)
    endif()
    if(PROJECT_ENABLE_SPDLOG)
        target_link_libraries("${target}" PRIVATE "${PROJECT_SPDLOG_TARGET}")
    endif()

    ecs_apply_target_configuration(TARGETS "${target}")
    # 登记到全局属性，供公共库 target 聚合时枚举。
    set_property(GLOBAL APPEND PROPERTY ECS_COMPONENT_TARGETS "${target}")
endfunction()

# 返回所有已登记的组件 OBJECT target 列表，供公共库 target 聚合链接。
function(ecs_get_component_targets out_var)
    get_property(component_targets GLOBAL PROPERTY ECS_COMPONENT_TARGETS)
    set("${out_var}" "${component_targets}" PARENT_SCOPE)
endfunction()
