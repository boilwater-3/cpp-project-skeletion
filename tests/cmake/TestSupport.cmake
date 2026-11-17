# Dependency discovery, source collection and the common ecs gtest harness.

if(PACKAGE_MANAGER STREQUAL "conan")
    find_package(GTest CONFIG REQUIRED)
endif()

include(GoogleTest)

function(add_ecs_gtest target_name suite_label discovery_timeout)
    if(NOT ARGN)
        return()
    endif()

    add_executable(${target_name} ${ARGN})
    target_link_libraries(${target_name} PRIVATE
        GTest::gtest_main
        GTest::gmock
        ${PROJECT_ALIAS})
    if(PROJECT_ENABLE_SPDLOG)
        target_link_libraries(${target_name} PRIVATE ${PROJECT_SPDLOG_TARGET})
    endif()
    target_include_directories(${target_name} PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR})

    ecs_apply_target_configuration(TARGETS ${target_name})

    if(WIN32 AND BUILD_SHARED_LIBS)
        add_custom_command(TARGET ${target_name} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:${PROJECT_CORE_TARGET}>
                $<TARGET_FILE_DIR:${target_name}>
            COMMENT "Copying ${PROJECT_CORE_TARGET} DLL to test directory")
    endif()

    string(REPLACE ";" "\\;" _suite_label_escaped "${suite_label}")
    gtest_discover_tests(${target_name}
        TEST_PREFIX "${suite_label}::${target_name}::"
        DISCOVERY_MODE PRE_TEST
        PROPERTIES
            LABELS "${_suite_label_escaped}"
            TIMEOUT "${discovery_timeout}")
endfunction()

# type x domain 分区注册 API：
# ecs_add_test_partition(
#   TYPE <unit|integration>
#   DOMAIN <core|...>
#   SOURCES <source...>
#   [TIMEOUT <seconds>]
#   [LABELS <label...>]
#   [LINK_LIBS <lib...>]
#   [INCLUDE_DIRS <dir...>]
#   [COMPILE_DEFS <def...>]
#   [DEPENDS <target...>]
#   [EXTRA_SOURCES <non-test-source...>]
# )
function(ecs_add_test_partition)
    cmake_parse_arguments(_ecs_part
        "" "TYPE;DOMAIN;TIMEOUT" "SOURCES;LABELS;LINK_LIBS;INCLUDE_DIRS;COMPILE_DEFS;DEPENDS;EXTRA_SOURCES"
        ${ARGN})
    if(NOT _ecs_part_SOURCES)
        return()
    endif()

    set(_target "${PROJECT_NAME}_${_ecs_part_DOMAIN}_${_ecs_part_TYPE}_tests")

    add_executable(${_target} ${_ecs_part_SOURCES} ${_ecs_part_EXTRA_SOURCES})
    target_link_libraries(${_target} PRIVATE
        GTest::gtest_main
        GTest::gmock
        ${PROJECT_ALIAS})
    if(PROJECT_ENABLE_SPDLOG)
        target_link_libraries(${_target} PRIVATE ${PROJECT_SPDLOG_TARGET})
    endif()
    if(_ecs_part_LINK_LIBS)
        target_link_libraries(${_target} PRIVATE ${_ecs_part_LINK_LIBS})
    endif()
    target_include_directories(${_target} PRIVATE
        ${CMAKE_SOURCE_DIR}/include
        ${CMAKE_SOURCE_DIR}/src
        ${CMAKE_CURRENT_SOURCE_DIR})
    if(_ecs_part_INCLUDE_DIRS)
        target_include_directories(${_target} PRIVATE ${_ecs_part_INCLUDE_DIRS})
    endif()
    if(_ecs_part_COMPILE_DEFS)
        target_compile_definitions(${_target} PRIVATE ${_ecs_part_COMPILE_DEFS})
    endif()

    ecs_apply_target_configuration(TARGETS ${_target})

    if(WIN32 AND BUILD_SHARED_LIBS)
        add_custom_command(TARGET ${_target} POST_BUILD
            COMMAND ${CMAKE_COMMAND} -E copy_if_different
                $<TARGET_FILE:${PROJECT_CORE_TARGET}>
                $<TARGET_FILE_DIR:${_target}>
            COMMENT "Copying ${PROJECT_CORE_TARGET} DLL to test directory")
    endif()
    if(_ecs_part_DEPENDS)
        add_dependencies(${_target} ${_ecs_part_DEPENDS})
    endif()

    set(_labels "${_ecs_part_TYPE};${_ecs_part_DOMAIN}")
    if(_ecs_part_LABELS)
        list(APPEND _labels ${_ecs_part_LABELS})
    endif()
    set(_timeout 60)
    if(_ecs_part_TIMEOUT)
        set(_timeout "${_ecs_part_TIMEOUT}")
    endif()

    string(REPLACE ";" "\\;" _labels_escaped "${_labels}")
    gtest_discover_tests(${_target}
        TEST_PREFIX "${_ecs_part_TYPE}::${_ecs_part_DOMAIN}::"
        DISCOVERY_MODE PRE_TEST
        PROPERTIES
            LABELS "${_labels_escaped}"
            TIMEOUT "${_timeout}")

    set_property(GLOBAL APPEND PROPERTY "ECS_REGISTERED_TEST_TARGETS_${_ecs_part_TYPE}" "${_target}")
endfunction()
