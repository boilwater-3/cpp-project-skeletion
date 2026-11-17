# Test lifecycle entry point.
# 按 <type>/<domain>/*_test.cpp 分区注册 GoogleTest 目标。

if(NOT ENABLE_TESTING)
    return()
endif()

include(${CMAKE_CURRENT_LIST_DIR}/cmake/TestSupport.cmake)

function(_ecs_register_partitions_for_type test_type)
    set(_type_dir "${CMAKE_CURRENT_SOURCE_DIR}/${test_type}")
    if(NOT IS_DIRECTORY "${_type_dir}")
        return()
    endif()
    file(GLOB _domains RELATIVE "${_type_dir}" "${_type_dir}/*")
    list(SORT _domains)
    foreach(_domain IN LISTS _domains)
        if(IS_DIRECTORY "${_type_dir}/${_domain}")
            file(GLOB_RECURSE _sources CONFIGURE_DEPENDS
                "${_type_dir}/${_domain}/*_test.cpp")
            if(_sources)
                ecs_add_test_partition(
                    TYPE "${test_type}"
                    DOMAIN "${_domain}"
                    SOURCES ${_sources}
                    TIMEOUT 60)
            endif()
        endif()
    endforeach()
endfunction()

_ecs_register_partitions_for_type(unit)
_ecs_register_partitions_for_type(integration)

add_custom_target(${PROJECT_NAME}_unit_tests)
get_property(_ecs_unit_targets GLOBAL PROPERTY ECS_REGISTERED_TEST_TARGETS_unit)
if(_ecs_unit_targets)
    add_dependencies(${PROJECT_NAME}_unit_tests ${_ecs_unit_targets})
endif()

add_custom_target(${PROJECT_NAME}_integration_tests)
get_property(_ecs_integration_targets GLOBAL PROPERTY ECS_REGISTERED_TEST_TARGETS_integration)
if(_ecs_integration_targets)
    add_dependencies(${PROJECT_NAME}_integration_tests ${_ecs_integration_targets})
endif()

add_custom_target(${PROJECT_NAME}_tests)
add_dependencies(${PROJECT_NAME}_tests
    ${PROJECT_NAME}_unit_tests
    ${PROJECT_NAME}_integration_tests)
