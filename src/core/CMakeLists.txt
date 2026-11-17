# core 模块源文件与组件注册

set(ECS_CORE_SOURCES
    version.cpp
)

ecs_add_component(ecs_core SOURCES ${ECS_CORE_SOURCES})
if(ECS_LINK_DEPENDENCIES)
    target_link_libraries(ecs_core PRIVATE ${ECS_LINK_DEPENDENCIES})
endif()
