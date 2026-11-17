# Product assembly only. Each module owns its sources, component targets,
# and direct dependencies in its own subdirectory.

add_library(${PROJECT_CORE_TARGET})
add_library(${PROJECT_ALIAS} ALIAS ${PROJECT_CORE_TARGET})

include(GenerateExportHeader)
set(PROJECT_GENERATED_INCLUDE_DIR "${CMAKE_CURRENT_BINARY_DIR}/include")
set(PROJECT_GENERATED_EXPORT_HEADER
    "${PROJECT_GENERATED_INCLUDE_DIR}/ecs/ecs_export.h")
file(MAKE_DIRECTORY "${PROJECT_GENERATED_INCLUDE_DIR}/ecs")
generate_export_header(${PROJECT_CORE_TARGET}
    BASE_NAME ECS
    EXPORT_FILE_NAME "${PROJECT_GENERATED_EXPORT_HEADER}"
    STATIC_DEFINE ECS_STATIC_DEFINE)
set(PROJECT_GENERATED_INCLUDE_DIR "${PROJECT_GENERATED_INCLUDE_DIR}" PARENT_SCOPE)
set(PROJECT_GENERATED_EXPORT_HEADER "${PROJECT_GENERATED_EXPORT_HEADER}" PARENT_SCOPE)

target_include_directories(${PROJECT_CORE_TARGET}
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}"
    PUBLIC
        $<BUILD_INTERFACE:${PROJECT_GENERATED_INCLUDE_DIR}>
        $<BUILD_INTERFACE:${CMAKE_SOURCE_DIR}/include>
        $<INSTALL_INTERFACE:include>)
target_compile_features(${PROJECT_CORE_TARGET} PUBLIC "cxx_std_${PROJECT_CXX_STANDARD}")

add_subdirectory(core)

ecs_get_component_targets(ECS_OBJECT_TARGETS)
if(NOT ECS_OBJECT_TARGETS)
    message(FATAL_ERROR "No ecs component targets were registered")
endif()
foreach(ECS_OBJECT_TARGET IN LISTS ECS_OBJECT_TARGETS)
    target_sources(${PROJECT_CORE_TARGET} PRIVATE $<TARGET_OBJECTS:${ECS_OBJECT_TARGET}>)
endforeach()
unset(ECS_OBJECT_TARGET)

# Component targets own compilation dependencies. The public library owns their
# final packaging link closure without exporting implementation object targets.
target_link_libraries(${PROJECT_CORE_TARGET} PRIVATE
    ${ECS_LINK_DEPENDENCIES})
if(PROJECT_ENABLE_SPDLOG)
    target_link_libraries(${PROJECT_CORE_TARGET} PRIVATE ${PROJECT_SPDLOG_TARGET})
endif()

ecs_apply_target_configuration(
    TARGETS ${PROJECT_CORE_TARGET}
    LINK_TARGETS ${PROJECT_CORE_TARGET})
ecs_configure_public_library(${PROJECT_CORE_TARGET})
