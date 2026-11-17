# UnityBuild.cmake
# 定义 Unity Build 的 target 级开关函数
# ENABLE_UNITY_BUILD 为 ON 时，apply_unity_build() 会为指定 target 启用批量源文件合并编译，
# 显著减少重复头文件解析次数，加速整体构建。

function(apply_unity_build)
    set(multi_value_args TARGETS)
    cmake_parse_arguments(ARG "" "" "${multi_value_args}" ${ARGN})

    if(NOT ENABLE_UNITY_BUILD)
        message(STATUS "Unity Build: Disabled")
        return()
    endif()
    if(NOT ARG_TARGETS)
        message(FATAL_ERROR "apply_unity_build() requires TARGETS")
    endif()

    # 批量大小（单个 unity 文件合并多少个源文件）；缺省 16，用户可外部覆盖。
    if(NOT DEFINED CMAKE_UNITY_BUILD_BATCH_SIZE)
        set(CMAKE_UNITY_BUILD_BATCH_SIZE 16 CACHE STRING
            "Number of source files to combine in Unity Build")
    endif()

    foreach(_target IN LISTS ARG_TARGETS)
        if(NOT TARGET "${_target}")
            message(FATAL_ERROR "Unity Build target does not exist: ${_target}")
        endif()
        set_target_properties("${_target}" PROPERTIES
            UNITY_BUILD ON
            UNITY_BUILD_BATCH_SIZE "${CMAKE_UNITY_BUILD_BATCH_SIZE}")
        if(MSVC)
            # 合并后的单翻译单元可能超过 MSVC 默认节数上限，需放宽目标文件格式。
            target_compile_options("${_target}" PRIVATE /bigobj)
        endif()
    endforeach()

    message(STATUS "Unity Build: Enabled")
    message(STATUS "  └─ Batch size: ${CMAKE_UNITY_BUILD_BATCH_SIZE} files per unity")
    if(MSVC)
        message(STATUS "  └─ Added /bigobj flag for MSVC targets")
    endif()
endfunction()
