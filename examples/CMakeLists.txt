# examples/CMakeLists.txt

if(NOT TARGET ${PROJECT_ALIAS})
    message(FATAL_ERROR "${PROJECT_ALIAS} target not found. Ensure src/CMakeLists.txt is processed first")
endif()

add_executable(ecs_basic_example basic/main.cpp)
target_link_libraries(ecs_basic_example PRIVATE ${PROJECT_ALIAS})
if(PROJECT_ENABLE_SPDLOG)
    target_link_libraries(ecs_basic_example PRIVATE ${PROJECT_SPDLOG_TARGET})
endif()
ecs_apply_target_configuration(TARGETS ecs_basic_example)
